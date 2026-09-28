package auth

import (
	"net/http"
	"strings"

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

	httpx.JSON(w, http.StatusOK, result)
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

	httpx.JSON(w, http.StatusOK, result)
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
	identity, _ := middleware.IdentityFromContext(r.Context())

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
		WHERE id = $1
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

	user.Email = strings.ToLower(user.Email)

	httpx.JSON(w, http.StatusOK, user)
}
