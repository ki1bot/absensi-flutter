package parent

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

func (h Handler) Dashboard(
	w http.ResponseWriter,
	r *http.Request,
) {
	identity, _ := middleware.IdentityFromContext(r.Context())

	rows, err := h.DB.Query(
		r.Context(),
		`
		SELECT
			s.id,
			s.name,
			s.class_name,
			COALESCE(
				TO_CHAR(a.scanned_at, 'HH24:MI'),
				''
			),
			COALESCE(a.status, '')
		FROM student_guardians sg
		JOIN students s
			ON s.id = sg.student_id
		LEFT JOIN attendances a
			ON a.student_id = s.id
			AND a.attendance_date = CURRENT_DATE
		WHERE
			sg.user_id = $1
			AND s.is_active = TRUE
		ORDER BY s.name
		`,
		identity.UserID,
	)

	if err != nil {
		httpx.Error(
			w,
			http.StatusInternalServerError,
			"gagal mengambil data anak",
		)
		return
	}

	defer rows.Close()

	children := make([]map[string]any, 0)

	for rows.Next() {
		var (
			id        int64
			name      string
			className string
			timeValue string
			status    string
		)

		if err := rows.Scan(
			&id,
			&name,
			&className,
			&timeValue,
			&status,
		); err != nil {
			continue
		}

		children = append(
			children,
			map[string]any{
				"id":         id,
				"name":       name,
				"class_name": className,
				"time":       timeValue,
				"status":     status,
			},
		)
	}

	httpx.JSON(
		w,
		http.StatusOK,
		map[string]any{
			"children": children,
		},
	)
}

func (h Handler) Notifications(
	w http.ResponseWriter,
	r *http.Request,
) {
	identity, _ := middleware.IdentityFromContext(r.Context())

	rows, err := h.DB.Query(
		r.Context(),
		`
		SELECT
			id,
			title,
			body,
			status,
			created_at
		FROM notification_logs
		WHERE user_id = $1
		ORDER BY created_at DESC
		LIMIT 100
		`,
		identity.UserID,
	)

	if err != nil {
		httpx.Error(
			w,
			http.StatusInternalServerError,
			"gagal mengambil notifikasi",
		)
		return
	}

	defer rows.Close()

	values := make([]map[string]any, 0)

	for rows.Next() {
		var (
			id        int64
			title     string
			body      string
			status    string
			createdAt time.Time
		)

		if err := rows.Scan(
			&id,
			&title,
			&body,
			&status,
			&createdAt,
		); err != nil {
			continue
		}

		values = append(
			values,
			map[string]any{
				"id":         id,
				"title":      title,
				"body":       body,
				"status":     status,
				"created_at": createdAt,
			},
		)
	}

	httpx.JSON(w, http.StatusOK, values)
}