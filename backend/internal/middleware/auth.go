package middleware

import (
	"context"
	"net/http"
	"strings"

	"github.com/golang-jwt/jwt/v5"
	"github.com/ki1bot/absensi-flutter/backend/internal/auth"
	"github.com/ki1bot/absensi-flutter/backend/internal/httpx"
)

type identityKey struct{}

type Identity struct {
	UserID   int64
	SchoolID int64
	Role     string
}

func Authentication(secret []byte) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(
			func(w http.ResponseWriter, r *http.Request) {
				header := strings.TrimSpace(
					r.Header.Get("Authorization"),
				)

				if !strings.HasPrefix(header, "Bearer ") {
					httpx.Error(
						w,
						http.StatusUnauthorized,
						"token autentikasi diperlukan",
					)
					return
				}

				rawToken := strings.TrimSpace(
					strings.TrimPrefix(header, "Bearer "),
				)

				claims := &auth.Claims{}

				token, err := jwt.ParseWithClaims(
					rawToken,
					claims,
					func(token *jwt.Token) (any, error) {
						return secret, nil
					},
					jwt.WithValidMethods(
						[]string{
							jwt.SigningMethodHS256.Alg(),
						},
					),
				)

				if err != nil || !token.Valid {
					httpx.Error(
						w,
						http.StatusUnauthorized,
						"token tidak valid atau kedaluwarsa",
					)
					return
				}

				identity := Identity{
					UserID:   claims.UserID,
					SchoolID: claims.SchoolID,
					Role:     claims.Role,
				}

				ctx := context.WithValue(
					r.Context(),
					identityKey{},
					identity,
				)

				next.ServeHTTP(
					w,
					r.WithContext(ctx),
				)
			},
		)
	}
}

func RequireRoles(
	roles ...string,
) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(
			func(w http.ResponseWriter, r *http.Request) {
				identity, ok := IdentityFromContext(r.Context())

				if !ok {
					httpx.Error(
						w,
						http.StatusUnauthorized,
						"pengguna tidak terautentikasi",
					)
					return
				}

				for _, role := range roles {
					if identity.Role == role {
						next.ServeHTTP(w, r)
						return
					}
				}

				httpx.Error(
					w,
					http.StatusForbidden,
					"akses ditolak",
				)
			},
		)
	}
}

func IdentityFromContext(
	ctx context.Context,
) (Identity, bool) {
	value, ok := ctx.Value(identityKey{}).(Identity)

	return value, ok
}