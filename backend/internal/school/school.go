package school

import (
	"fmt"
	"net/http"
	"regexp"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/ki1bot/absensi-flutter/backend/internal/auth"
	"github.com/ki1bot/absensi-flutter/backend/internal/httpx"
	"github.com/ki1bot/absensi-flutter/backend/internal/middleware"
)

type Handler struct {
	DB *pgxpool.Pool
}

type RegisterRequest struct {
	SchoolName string `json:"school_name"`
	AdminName  string `json:"admin_name"`
	EntryTime  string `json:"entry_time"`
	Email      string `json:"email"`
}

func (h Handler) Register(
	w http.ResponseWriter,
	r *http.Request,
) {
	var input RegisterRequest

	if err := httpx.DecodeJSON(r, &input); err != nil {
		httpx.Error(
			w,
			http.StatusBadRequest,
			"data registrasi tidak valid",
		)
		return
	}

	input.SchoolName = strings.TrimSpace(input.SchoolName)
	input.AdminName = strings.TrimSpace(input.AdminName)
	input.Email = strings.ToLower(strings.TrimSpace(input.Email))

	if input.SchoolName == "" ||
		input.AdminName == "" ||
		input.Email == "" ||
		input.EntryTime == "" {
		httpx.Error(
			w,
			http.StatusBadRequest,
			"semua field wajib diisi",
		)
		return
	}

	if _, err := time.Parse("15:04", input.EntryTime); err != nil {
		httpx.Error(
			w,
			http.StatusBadRequest,
			"format jam masuk harus HH:mm",
		)
		return
	}

	password, err := auth.RandomToken(9)
	if err != nil {
		httpx.Error(
			w,
			http.StatusInternalServerError,
			"gagal membuat password",
		)
		return
	}

	passwordHash, err := auth.HashPassword(password)
	if err != nil {
		httpx.Error(
			w,
			http.StatusInternalServerError,
			"gagal memproses password",
		)
		return
	}

	tx, err := h.DB.Begin(r.Context())
	if err != nil {
		httpx.Error(
			w,
			http.StatusInternalServerError,
			"gagal memulai transaksi",
		)
		return
	}

	defer tx.Rollback(r.Context())

	slug := slugify(input.SchoolName)

	if slug == "" {
		slug = fmt.Sprintf("school-%d", time.Now().Unix())
	}

	var schoolID int64

	err = tx.QueryRow(
		r.Context(),
		`
		INSERT INTO schools (
			name,
			slug,
			entry_time
		)
		VALUES ($1, $2, $3::time)
		RETURNING id
		`,
		input.SchoolName,
		slug,
		input.EntryTime,
	).Scan(&schoolID)

	if err != nil {
		httpx.Error(
			w,
			http.StatusConflict,
			"sekolah atau slug sudah digunakan",
		)
		return
	}

	var adminID int64

	err = tx.QueryRow(
		r.Context(),
		`
		INSERT INTO users (
			school_id,
			name,
			email,
			username,
			password_hash,
			role
		)
		VALUES ($1, $2, $3, $3, $4, 'admin')
		RETURNING id
		`,
		schoolID,
		input.AdminName,
		input.Email,
		passwordHash,
	).Scan(&adminID)

	if err != nil {
		httpx.Error(
			w,
			http.StatusConflict,
			"email admin sudah digunakan",
		)
		return
	}

	_, err = tx.Exec(
		r.Context(),
		`
		INSERT INTO subscriptions (
			school_id,
			plan,
			status,
			trial_started_at,
			trial_ends_at
		)
		VALUES (
			$1,
			'monthly',
			'trial',
			NOW(),
			NOW() + INTERVAL '7 days'
		)
		`,
		schoolID,
	)

	if err != nil {
		httpx.Error(
			w,
			http.StatusInternalServerError,
			"gagal membuat trial sekolah",
		)
		return
	}

	if err := tx.Commit(r.Context()); err != nil {
		httpx.Error(
			w,
			http.StatusInternalServerError,
			"gagal menyimpan registrasi",
		)
		return
	}

	httpx.JSON(
		w,
		http.StatusCreated,
		map[string]any{
			"message":          "Sekolah berhasil didaftarkan",
			"school_id":        schoolID,
			"admin_id":         adminID,
			"admin_email":      input.Email,
			"initial_password": password,
			"trial_days":       7,
		},
	)
}

func (h Handler) Detail(
	w http.ResponseWriter,
	r *http.Request,
) {
	identity, _ := middleware.IdentityFromContext(r.Context())

	var result struct {
		ID        int64  `json:"id"`
		Name      string `json:"name"`
		Slug      string `json:"slug"`
		EntryTime string `json:"entry_time"`
		Timezone  string `json:"timezone"`
	}

	err := h.DB.QueryRow(
		r.Context(),
		`
		SELECT
			id,
			name,
			slug,
			TO_CHAR(entry_time, 'HH24:MI'),
			timezone
		FROM schools
		WHERE id = $1
		`,
		identity.SchoolID,
	).Scan(
		&result.ID,
		&result.Name,
		&result.Slug,
		&result.EntryTime,
		&result.Timezone,
	)

	if err != nil {
		httpx.Error(
			w,
			http.StatusNotFound,
			"sekolah tidak ditemukan",
		)
		return
	}

	httpx.JSON(w, http.StatusOK, result)
}

func slugify(value string) string {
	value = strings.ToLower(value)

	reg := regexp.MustCompile(`[^a-z0-9]+`)
	value = reg.ReplaceAllString(value, "-")

	return strings.Trim(value, "-")
}
