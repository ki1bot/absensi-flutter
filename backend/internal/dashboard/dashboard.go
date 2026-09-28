package dashboard

import (
	"net/http"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/ki1bot/absensi-flutter/backend/internal/httpx"
	"github.com/ki1bot/absensi-flutter/backend/internal/middleware"
)

type Handler struct {
	DB *pgxpool.Pool
}

func (h Handler) Admin(
	w http.ResponseWriter,
	r *http.Request,
) {
	identity, _ := middleware.IdentityFromContext(r.Context())

	var (
		totalStudents int
		present       int
		late          int
	)

	err := h.DB.QueryRow(
		r.Context(),
		`
		SELECT COUNT(*)
		FROM students
		WHERE
			school_id = $1
			AND is_active = TRUE
		`,
		identity.SchoolID,
	).Scan(&totalStudents)

	if err != nil {
		httpx.Error(
			w,
			http.StatusInternalServerError,
			"gagal membaca statistik",
		)
		return
	}

	err = h.DB.QueryRow(
		r.Context(),
		`
		SELECT
			COUNT(*) FILTER (
				WHERE status = 'present'
			),
			COUNT(*) FILTER (
				WHERE status = 'late'
			)
		FROM attendances
		WHERE
			school_id = $1
			AND attendance_date = CURRENT_DATE
		`,
		identity.SchoolID,
	).Scan(&present, &late)

	if err != nil {
		httpx.Error(
			w,
			http.StatusInternalServerError,
			"gagal membaca statistik absensi",
		)
		return
	}

	attended := present + late
	notPresent := totalStudents - attended

	if notPresent < 0 {
		notPresent = 0
	}

	httpx.JSON(
		w,
		http.StatusOK,
		map[string]any{
			"total_students": totalStudents,
			"present_today":  present,
			"late_today":     late,
			"not_present":    notPresent,
			"date":           time.Now().Format("2006-01-02"),
		},
	)
}