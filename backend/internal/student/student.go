package student

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"net/http"
	"strconv"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/ki1bot/absensi-flutter/backend/internal/auth"
	"github.com/ki1bot/absensi-flutter/backend/internal/httpx"
	"github.com/ki1bot/absensi-flutter/backend/internal/middleware"
)

type Handler struct {
	DB       *pgxpool.Pool
	QRSecret []byte
}

type Student struct {
	ID        int64  `json:"id"`
	NIS       string `json:"nis"`
	Name      string `json:"name"`
	ClassName string `json:"class_name"`
	IsActive  bool   `json:"is_active"`
}

type StudentDetail struct {
	Student

	GuardianName  string `json:"guardian_name"`
	GuardianEmail string `json:"guardian_email"`
	GuardianPhone string `json:"guardian_phone"`
}

type SaveRequest struct {
	NIS           string `json:"nis"`
	Name          string `json:"name"`
	ClassName     string `json:"class_name"`
	GuardianName  string `json:"guardian_name"`
	GuardianEmail string `json:"guardian_email"`
	GuardianPhone string `json:"guardian_phone"`
}

func (h Handler) List(
	w http.ResponseWriter,
	r *http.Request,
) {
	identity, _ := middleware.IdentityFromContext(r.Context())

	search := strings.TrimSpace(r.URL.Query().Get("search"))

	rows, err := h.DB.Query(
		r.Context(),
		`
		SELECT
			id,
			nis,
			name,
			class_name,
			is_active
		FROM students
		WHERE
			school_id = $1
			AND is_active = TRUE
			AND (
				$2 = ''
				OR name ILIKE '%' || $2 || '%'
				OR nis ILIKE '%' || $2 || '%'
				OR class_name ILIKE '%' || $2 || '%'
			)
		ORDER BY name
		`,
		identity.SchoolID,
		search,
	)

	if err != nil {
		httpx.Error(
			w,
			http.StatusInternalServerError,
			"gagal mengambil data siswa",
		)
		return
	}

	defer rows.Close()

	students := make([]Student, 0)

	for rows.Next() {
		var value Student

		if err := rows.Scan(
			&value.ID,
			&value.NIS,
			&value.Name,
			&value.ClassName,
			&value.IsActive,
		); err != nil {
			httpx.Error(
				w,
				http.StatusInternalServerError,
				"gagal membaca data siswa",
			)
			return
		}

		students = append(students, value)
	}

	httpx.JSON(w, http.StatusOK, students)
}

func (h Handler) Create(
	w http.ResponseWriter,
	r *http.Request,
) {
	identity, _ := middleware.IdentityFromContext(r.Context())

	var input SaveRequest

	if err := httpx.DecodeJSON(r, &input); err != nil {
		httpx.Error(
			w,
			http.StatusBadRequest,
			"data siswa tidak valid",
		)
		return
	}

	student, parentPassword, err := h.createStudent(
		r.Context(),
		identity.SchoolID,
		input,
	)

	if err != nil {
		httpx.Error(
			w,
			http.StatusBadRequest,
			err.Error(),
		)
		return
	}

	httpx.JSON(
		w,
		http.StatusCreated,
		map[string]any{
			"student":                 student,
			"parent_initial_password": parentPassword,
		},
	)
}

func (h Handler) Detail(
	w http.ResponseWriter,
	r *http.Request,
) {
	identity, _ := middleware.IdentityFromContext(r.Context())

	id, err := strconv.ParseInt(
		r.PathValue("id"),
		10,
		64,
	)

	if err != nil {
		httpx.Error(
			w,
			http.StatusBadRequest,
			"id siswa tidak valid",
		)
		return
	}

	var student StudentDetail

	err = h.DB.QueryRow(
		r.Context(),
		`
		SELECT
			s.id,
			s.nis,
			s.name,
			s.class_name,
			s.is_active,
			COALESCE(u.name, ''),
			COALESCE(u.email, ''),
			COALESCE(u.phone, '')
		FROM students s
		LEFT JOIN student_guardians sg
			ON sg.student_id = s.id
		LEFT JOIN users u
			ON u.id = sg.user_id
		WHERE
			s.id = $1
			AND s.school_id = $2
		LIMIT 1
		`,
		id,
		identity.SchoolID,
	).Scan(
		&student.ID,
		&student.NIS,
		&student.Name,
		&student.ClassName,
		&student.IsActive,
		&student.GuardianName,
		&student.GuardianEmail,
		&student.GuardianPhone,
	)

	if err != nil {
		httpx.Error(
			w,
			http.StatusNotFound,
			"siswa tidak ditemukan",
		)
		return
	}

	httpx.JSON(w, http.StatusOK, student)
}

func (h Handler) QR(
	w http.ResponseWriter,
	r *http.Request,
) {
	identity, _ := middleware.IdentityFromContext(r.Context())

	id, err := strconv.ParseInt(
		r.PathValue("id"),
		10,
		64,
	)

	if err != nil {
		httpx.Error(
			w,
			http.StatusBadRequest,
			"id siswa tidak valid",
		)
		return
	}

	var (
		seed uuid.UUID
		name string
	)

	err = h.DB.QueryRow(
		r.Context(),
		`
		SELECT qr_seed, name
		FROM students
		WHERE
			id = $1
			AND school_id = $2
			AND is_active = TRUE
		`,
		id,
		identity.SchoolID,
	).Scan(&seed, &name)

	if err != nil {
		httpx.Error(
			w,
			http.StatusNotFound,
			"siswa tidak ditemukan",
		)
		return
	}

	token := h.qrToken(seed)

	httpx.JSON(
		w,
		http.StatusOK,
		map[string]any{
			"student_id": id,
			"name":       name,
			"payload":    "ABSENSI:" + token,
		},
	)
}

func (h Handler) Delete(
	w http.ResponseWriter,
	r *http.Request,
) {
	identity, _ := middleware.IdentityFromContext(r.Context())

	id, err := strconv.ParseInt(
		r.PathValue("id"),
		10,
		64,
	)

	if err != nil {
		httpx.Error(
			w,
			http.StatusBadRequest,
			"id siswa tidak valid",
		)
		return
	}

	command, err := h.DB.Exec(
		r.Context(),
		`
		UPDATE students
		SET
			is_active = FALSE,
			updated_at = NOW()
		WHERE
			id = $1
			AND school_id = $2
		`,
		id,
		identity.SchoolID,
	)

	if err != nil || command.RowsAffected() == 0 {
		httpx.Error(
			w,
			http.StatusNotFound,
			"siswa tidak ditemukan",
		)
		return
	}

	httpx.JSON(
		w,
		http.StatusOK,
		map[string]string{
			"message": "Siswa dinonaktifkan",
		},
	)
}

func (h Handler) createStudent(
	ctx context.Context,
	schoolID int64,
	input SaveRequest,
) (Student, string, error) {
	input.NIS = strings.TrimSpace(input.NIS)
	input.Name = strings.TrimSpace(input.Name)
	input.ClassName = strings.TrimSpace(input.ClassName)
	input.GuardianEmail = strings.ToLower(
		strings.TrimSpace(input.GuardianEmail),
	)

	if input.NIS == "" ||
		input.Name == "" ||
		input.ClassName == "" {
		return Student{}, "", fmt.Errorf(
			"NIS, nama dan kelas wajib diisi",
		)
	}

	tx, err := h.DB.Begin(ctx)
	if err != nil {
		return Student{}, "", err
	}

	defer tx.Rollback(ctx)

	seed := uuid.New()
	token := h.qrToken(seed)

	var result Student

	err = tx.QueryRow(
		ctx,
		`
		INSERT INTO students (
			school_id,
			nis,
			name,
			class_name,
			qr_seed,
			qr_token_hash
		)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING
			id,
			nis,
			name,
			class_name,
			is_active
		`,
		schoolID,
		input.NIS,
		input.Name,
		input.ClassName,
		seed,
		hashToken(token),
	).Scan(
		&result.ID,
		&result.NIS,
		&result.Name,
		&result.ClassName,
		&result.IsActive,
	)

	if err != nil {
		return Student{}, "", fmt.Errorf(
			"NIS sudah digunakan atau data siswa tidak valid",
		)
	}

	parentPassword := ""

	if input.GuardianEmail != "" {
		var parentID int64

		err = tx.QueryRow(
			ctx,
			`
			SELECT id
			FROM users
			WHERE
				email = $1
				AND school_id = $2
			LIMIT 1
			`,
			input.GuardianEmail,
			schoolID,
		).Scan(&parentID)

		if err != nil {
			if err != pgx.ErrNoRows {
				return Student{}, "", err
			}

			parentPassword, err = auth.RandomToken(9)
			if err != nil {
				return Student{}, "", err
			}

			passwordHash, err := auth.HashPassword(parentPassword)
			if err != nil {
				return Student{}, "", err
			}

			err = tx.QueryRow(
				ctx,
				`
				INSERT INTO users (
					school_id,
					name,
					email,
					username,
					password_hash,
					role,
					phone
				)
				VALUES (
					$1,
					$2,
					$3,
					$3,
					$4,
					'parent',
					$5
				)
				RETURNING id
				`,
				schoolID,
				input.GuardianName,
				input.GuardianEmail,
				passwordHash,
				input.GuardianPhone,
			).Scan(&parentID)

			if err != nil {
				return Student{}, "", err
			}
		}

		_, err = tx.Exec(
			ctx,
			`
			INSERT INTO student_guardians (
				student_id,
				user_id,
				relationship
			)
			VALUES ($1, $2, 'Orang Tua')
			ON CONFLICT DO NOTHING
			`,
			result.ID,
			parentID,
		)

		if err != nil {
			return Student{}, "", err
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return Student{}, "", err
	}

	return result, parentPassword, nil
}

func (h Handler) qrToken(seed uuid.UUID) string {
	mac := hmac.New(
		sha256.New,
		h.QRSecret,
	)

	mac.Write([]byte(seed.String()))

	return hex.EncodeToString(mac.Sum(nil))
}

func hashToken(token string) string {
	value := sha256.Sum256([]byte(token))

	return hex.EncodeToString(value[:])
}