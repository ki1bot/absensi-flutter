package attendance

import (
	"crypto/sha256"
	"encoding/hex"
	"net/http"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/ki1bot/absensi-flutter/backend/internal/httpx"
	"github.com/ki1bot/absensi-flutter/backend/internal/middleware"
)

type Handler struct {
	DB *pgxpool.Pool
}

func (h Handler) CheckIn(
	w http.ResponseWriter,
	r *http.Request,
) {
	identity, _ := middleware.IdentityFromContext(r.Context())

	var input struct {
		QRToken string `json:"qr_token"`
	}

	if err := httpx.DecodeJSON(r, &input); err != nil {
		httpx.Error(
			w,
			http.StatusBadRequest,
			"QR tidak valid",
		)
		return
	}

	token := strings.TrimSpace(input.QRToken)
	token = strings.TrimPrefix(token, "ABSENSI:")

	hash := sha256.Sum256([]byte(token))
	tokenHash := hex.EncodeToString(hash[:])

	var (
		studentID int64
		name      string
		className string
		entryTime string
		timezone  string
	)

	err := h.DB.QueryRow(
		r.Context(),
		`
		SELECT
			s.id,
			s.name,
			s.class_name,
			TO_CHAR(sc.entry_time, 'HH24:MI'),
			sc.timezone
		FROM students s
		JOIN schools sc
			ON sc.id = s.school_id
		WHERE
			s.qr_token_hash = $1
			AND s.school_id = $2
			AND s.is_active = TRUE
			AND sc.is_active = TRUE
		LIMIT 1
		`,
		tokenHash,
		identity.SchoolID,
	).Scan(
		&studentID,
		&name,
		&className,
		&entryTime,
		&timezone,
	)

	if err != nil {
		httpx.Error(
			w,
			http.StatusNotFound,
			"QR siswa tidak ditemukan",
		)
		return
	}

	location, err := time.LoadLocation(timezone)
	if err != nil {
		location, _ = time.LoadLocation("Asia/Jakarta")
	}

	now := time.Now().In(location)
	attendanceDate := now.Format("2006-01-02")

	schoolEntry, err := time.ParseInLocation(
		"2006-01-02 15:04",
		attendanceDate+" "+entryTime,
		location,
	)

	if err != nil {
		httpx.Error(
			w,
			http.StatusInternalServerError,
			"jam masuk sekolah tidak valid",
		)
		return
	}

	status := "present"

	if now.After(schoolEntry) {
		status = "late"
	}

	var attendanceID int64

	err = h.DB.QueryRow(
		r.Context(),
		`
		INSERT INTO attendances (
			school_id,
			student_id,
			scanned_by,
			attendance_date,
			scanned_at,
			type,
			status
		)
		VALUES (
			$1,
			$2,
			$3,
			$4::date,
			$5,
			'check_in',
			$6
		)
		RETURNING id
		`,
		identity.SchoolID,
		studentID,
		identity.UserID,
		attendanceDate,
		now,
		status,
	).Scan(&attendanceID)

	if err != nil {
		if pgxErrorIsUnique(err) {
			var existing time.Time

			_ = h.DB.QueryRow(
				r.Context(),
				`
				SELECT scanned_at
				FROM attendances
				WHERE
					student_id = $1
					AND attendance_date = $2::date
					AND type = 'check_in'
				`,
				studentID,
				attendanceDate,
			).Scan(&existing)

			httpx.JSON(
				w,
				http.StatusConflict,
				map[string]any{
					"message": name +
						" sudah melakukan absensi hari ini",
					"student": map[string]any{
						"id":    studentID,
						"name":  name,
						"class": className,
					},
					"time": existing.In(location).Format("15:04"),
				},
			)
			return
		}

		httpx.Error(
			w,
			http.StatusInternalServerError,
			"gagal menyimpan absensi",
		)
		return
	}

	h.createParentNotifications(
		r,
		studentID,
		attendanceID,
		name,
		now.In(location).Format("15:04"),
	)

	httpx.JSON(
		w,
		http.StatusCreated,
		map[string]any{
			"message": "Absensi berhasil",
			"student": map[string]any{
				"id":    studentID,
				"name":  name,
				"class": className,
			},
			"time":   now.Format("15:04"),
			"status": status,
		},
	)
}

func (h Handler) List(
	w http.ResponseWriter,
	r *http.Request,
) {
	identity, _ := middleware.IdentityFromContext(r.Context())

	rows, err := h.DB.Query(
		r.Context(),
		`
		SELECT
			a.id,
			s.name,
			s.class_name,
			a.attendance_date,
			a.scanned_at,
			a.status
		FROM attendances a
		JOIN students s
			ON s.id = a.student_id
		WHERE a.school_id = $1
		ORDER BY a.scanned_at DESC
		LIMIT 200
		`,
		identity.SchoolID,
	)

	if err != nil {
		httpx.Error(
			w,
			http.StatusInternalServerError,
			"gagal mengambil riwayat absensi",
		)
		return
	}

	defer rows.Close()

	values := make([]map[string]any, 0)

	for rows.Next() {
		var (
			id             int64
			name           string
			className      string
			attendanceDate time.Time
			scannedAt      time.Time
			status         string
		)

		if err := rows.Scan(
			&id,
			&name,
			&className,
			&attendanceDate,
			&scannedAt,
			&status,
		); err != nil {
			continue
		}

		values = append(
			values,
			map[string]any{
				"id":              id,
				"name":            name,
				"class_name":      className,
				"attendance_date": attendanceDate,
				"scanned_at":      scannedAt,
				"status":          status,
			},
		)
	}

	httpx.JSON(w, http.StatusOK, values)
}

func (h Handler) createParentNotifications(
	r *http.Request,
	studentID int64,
	attendanceID int64,
	name string,
	timeValue string,
) {
	rows, err := h.DB.Query(
		r.Context(),
		`
		SELECT user_id
		FROM student_guardians
		WHERE student_id = $1
		`,
		studentID,
	)

	if err != nil {
		return
	}

	defer rows.Close()

	for rows.Next() {
		var userID int64

		if err := rows.Scan(&userID); err != nil {
			continue
		}

		_, _ = h.DB.Exec(
			r.Context(),
			`
			INSERT INTO notification_logs (
				user_id,
				student_id,
				attendance_id,
				title,
				body,
				status
			)
			VALUES (
				$1,
				$2,
				$3,
				'E-Absensi Siswa',
				$4,
				'pending'
			)
			`,
			userID,
			studentID,
			attendanceID,
			name+
				" tiba di sekolah pukul "+
				timeValue+".",
		)
	}
}

func pgxErrorIsUnique(err error) bool {
	return strings.Contains(
		strings.ToLower(err.Error()),
		"duplicate key",
	)
}