package auth

import (
	"errors"
	"net/http"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/ki1bot/absensi-flutter/backend/internal/httpx"
	"github.com/ki1bot/absensi-flutter/backend/internal/middleware"
)

type Handler struct {
	Service Service
	DB      *pgxpool.Pool
}

func (h Handler) Login(
	w http.ResponseWriter,
	r *http.Request,
) {
	var input struct {
		Email    string `json:"email"`
		Password string `json:"password"`
	}

	if err := httpx.DecodeJSON(r, &input); err != nil {
		httpx.Error(
			w,
			http.StatusBadRequest,
			"request login tidak valid",
		)
		return
	}

	result, err := h.Service.Login(
		r.Context(),
		input.Email,
		input.Password,
	)

	if err != nil {
		httpx.Error(
			w,
			http.StatusUnauthorized,
			err.Error(),
		)
		return
	}

	httpx.JSON(
		w,
		http.StatusOK,
		result,
	)
}

func (h Handler) Refresh(
	w http.ResponseWriter,
	r *http.Request,
) {
	var input struct {
		RefreshToken string `json:"refresh_token"`
	}

	if err := httpx.DecodeJSON(r, &input); err != nil {
		httpx.Error(
			w,
			http.StatusBadRequest,
			"refresh token tidak valid",
		)
		return
	}

	result, err := h.Service.Refresh(
		r.Context(),
		input.RefreshToken,
	)

	if err != nil {
		httpx.Error(
			w,
			http.StatusUnauthorized,
			err.Error(),
		)
		return
	}

	httpx.JSON(
		w,
		http.StatusOK,
		result,
	)
}

func (h Handler) Logout(
	w http.ResponseWriter,
	r *http.Request,
) {
	var input struct {
		RefreshToken string `json:"refresh_token"`
	}

	if err := httpx.DecodeJSON(r, &input); err != nil {
		httpx.Error(
			w,
			http.StatusBadRequest,
			"request logout tidak valid",
		)
		return
	}

	if err := h.Service.Logout(
		r.Context(),
		input.RefreshToken,
	); err != nil {
		httpx.Error(
			w,
			http.StatusInternalServerError,
			"gagal logout",
		)
		return
	}

	httpx.JSON(
		w,
		http.StatusOK,
		map[string]string{
			"message": "Logout berhasil",
		},
	)
}

func (h Handler) Me(
	w http.ResponseWriter,
	r *http.Request,
) {
	identity, _ := middleware.IdentityFromContext(
		r.Context(),
	)

	var user User

	err := h.DB.QueryRow(
		r.Context(),
		`
		SELECT
			id,
			school_id,
			name,
			email,
			role
		FROM users
		WHERE
			id = $1
			AND is_active = TRUE
		LIMIT 1
		`,
		identity.UserID,
	).Scan(
		&user.ID,
		&user.SchoolID,
		&user.Name,
		&user.Email,
		&user.Role,
	)

	if err != nil {
		httpx.Error(
			w,
			http.StatusNotFound,
			"pengguna tidak ditemukan",
		)
		return
	}

	user.Email = strings.ToLower(
		user.Email,
	)

	httpx.JSON(
		w,
		http.StatusOK,
		user,
	)
}

func (h Handler) UpdateProfile(
	w http.ResponseWriter,
	r *http.Request,
) {
	identity, _ := middleware.IdentityFromContext(
		r.Context(),
	)

	var input struct {
		Name     string `json:"name"`
		Email    string `json:"email"`
		Password string `json:"password"`
	}

	if err := httpx.DecodeJSON(r, &input); err != nil {
		httpx.Error(
			w,
			http.StatusBadRequest,
			"data profil tidak valid",
		)
		return
	}

	input.Name = strings.TrimSpace(
		input.Name,
	)

	input.Email = strings.ToLower(
		strings.TrimSpace(
			input.Email,
		),
	)

	input.Password = strings.TrimSpace(
		input.Password,
	)

	if input.Name == "" {
		httpx.Error(
			w,
			http.StatusBadRequest,
			"nama admin wajib diisi",
		)
		return
	}

	if input.Email == "" ||
		!strings.Contains(
			input.Email,
			"@",
		) {
		httpx.Error(
			w,
			http.StatusBadRequest,
			"email tidak valid",
		)
		return
	}

	if input.Password != "" &&
		len(input.Password) < 8 {
		httpx.Error(
			w,
			http.StatusBadRequest,
			"password minimal 8 karakter",
		)
		return
	}

	var user User

	if input.Password == "" {
		err := h.DB.QueryRow(
			r.Context(),
			`
			UPDATE users
			SET
				name = $2,
				email = $3,
				username = $3,
				updated_at = NOW()
			WHERE
				id = $1
				AND role = 'admin'
				AND is_active = TRUE
			RETURNING
				id,
				school_id,
				name,
				email,
				role
			`,
			identity.UserID,
			input.Name,
			input.Email,
		).Scan(
			&user.ID,
			&user.SchoolID,
			&user.Name,
			&user.Email,
			&user.Role,
		)

		if err != nil {
			h.handleProfileUpdateError(
				w,
				err,
			)
			return
		}
	} else {
		passwordHash, err := HashPassword(
			input.Password,
		)

		if err != nil {
			httpx.Error(
				w,
				http.StatusInternalServerError,
				"gagal memproses password",
			)
			return
		}

		err = h.DB.QueryRow(
			r.Context(),
			`
			UPDATE users
			SET
				name = $2,
				email = $3,
				username = $3,
				password_hash = $4,
				updated_at = NOW()
			WHERE
				id = $1
				AND role = 'admin'
				AND is_active = TRUE
			RETURNING
				id,
				school_id,
				name,
				email,
				role
			`,
			identity.UserID,
			input.Name,
			input.Email,
			passwordHash,
		).Scan(
			&user.ID,
			&user.SchoolID,
			&user.Name,
			&user.Email,
			&user.Role,
		)

		if err != nil {
			h.handleProfileUpdateError(
				w,
				err,
			)
			return
		}
	}

	httpx.JSON(
		w,
		http.StatusOK,
		map[string]any{
			"message": "Profil admin berhasil diperbarui",
			"user":    user,
		},
	)
}

func (h Handler) handleProfileUpdateError(
	w http.ResponseWriter,
	err error,
) {
	var pgErr *pgconn.PgError

	if errors.As(
		err,
		&pgErr,
	) && pgErr.Code == "23505" {
		httpx.Error(
			w,
			http.StatusConflict,
			"email sudah digunakan akun lain",
		)
		return
	}

	if errors.Is(
		err,
		pgx.ErrNoRows,
	) {
		httpx.Error(
			w,
			http.StatusNotFound,
			"akun admin tidak ditemukan",
		)
		return
	}

	httpx.Error(
		w,
		http.StatusInternalServerError,
		"gagal memperbarui profil admin",
	)
}