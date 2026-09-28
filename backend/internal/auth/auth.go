package auth

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/crypto/bcrypt"
)

type User struct {
	ID       int64  `json:"id"`
	SchoolID *int64 `json:"school_id"`
	Name     string `json:"name"`
	Email    string `json:"email"`
	Role     string `json:"role"`
}

type Claims struct {
	UserID   int64  `json:"user_id"`
	SchoolID int64  `json:"school_id"`
	Role     string `json:"role"`

	jwt.RegisteredClaims
}

type Service struct {
	DB              *pgxpool.Pool
	Secret          []byte
	AccessTokenTTL  time.Duration
	RefreshTokenTTL time.Duration
}

type LoginResult struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	User         User   `json:"user"`
}

func HashPassword(password string) (string, error) {
	value, err := bcrypt.GenerateFromPassword(
		[]byte(password),
		bcrypt.DefaultCost,
	)

	return string(value), err
}

func VerifyPassword(hash, password string) bool {
	return bcrypt.CompareHashAndPassword(
		[]byte(hash),
		[]byte(password),
	) == nil
}

func RandomToken(bytesLength int) (string, error) {
	value := make([]byte, bytesLength)

	if _, err := rand.Read(value); err != nil {
		return "", err
	}

	return base64.RawURLEncoding.EncodeToString(value), nil
}

func HashToken(token string) string {
	value := sha256.Sum256([]byte(token))

	return hex.EncodeToString(value[:])
}

func (s Service) Login(
	ctx context.Context,
	email string,
	password string,
) (LoginResult, error) {
	email = strings.ToLower(strings.TrimSpace(email))

	var (
		user         User
		passwordHash string
		isActive     bool
	)

	err := s.DB.QueryRow(
		ctx,
		`
		SELECT
			id,
			school_id,
			name,
			email,
			role,
			password_hash,
			is_active
		FROM users
		WHERE email = $1
		LIMIT 1
		`,
		email,
	).Scan(
		&user.ID,
		&user.SchoolID,
		&user.Name,
		&user.Email,
		&user.Role,
		&passwordHash,
		&isActive,
	)

	if err != nil {
		return LoginResult{}, errors.New("email atau password salah")
	}

	if !isActive {
		return LoginResult{}, errors.New("akun tidak aktif")
	}

	if !VerifyPassword(passwordHash, password) {
		return LoginResult{}, errors.New("email atau password salah")
	}

	accessToken, err := s.createAccessToken(user)
	if err != nil {
		return LoginResult{}, err
	}

	refreshToken, err := RandomToken(48)
	if err != nil {
		return LoginResult{}, err
	}

	_, err = s.DB.Exec(
		ctx,
		`
		INSERT INTO refresh_tokens (
			user_id,
			token_hash,
			expires_at
		)
		VALUES ($1, $2, $3)
		`,
		user.ID,
		HashToken(refreshToken),
		time.Now().Add(s.RefreshTokenTTL),
	)

	if err != nil {
		return LoginResult{}, err
	}

	return LoginResult{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		User:         user,
	}, nil
}

func (s Service) Refresh(
	ctx context.Context,
	refreshToken string,
) (LoginResult, error) {
	hash := HashToken(refreshToken)

	var user User

	err := s.DB.QueryRow(
		ctx,
		`
		SELECT
			u.id,
			u.school_id,
			u.name,
			u.email,
			u.role
		FROM refresh_tokens rt
		JOIN users u ON u.id = rt.user_id
		WHERE
			rt.token_hash = $1
			AND rt.revoked_at IS NULL
			AND rt.expires_at > NOW()
			AND u.is_active = TRUE
		LIMIT 1
		`,
		hash,
	).Scan(
		&user.ID,
		&user.SchoolID,
		&user.Name,
		&user.Email,
		&user.Role,
	)

	if err != nil {
		return LoginResult{}, errors.New("refresh token tidak valid")
	}

	_, _ = s.DB.Exec(
		ctx,
		`
		UPDATE refresh_tokens
		SET revoked_at = NOW()
		WHERE token_hash = $1
		`,
		hash,
	)

	accessToken, err := s.createAccessToken(user)
	if err != nil {
		return LoginResult{}, err
	}

	newRefreshToken, err := RandomToken(48)
	if err != nil {
		return LoginResult{}, err
	}

	_, err = s.DB.Exec(
		ctx,
		`
		INSERT INTO refresh_tokens (
			user_id,
			token_hash,
			expires_at
		)
		VALUES ($1, $2, $3)
		`,
		user.ID,
		HashToken(newRefreshToken),
		time.Now().Add(s.RefreshTokenTTL),
	)

	if err != nil {
		return LoginResult{}, err
	}

	return LoginResult{
		AccessToken:  accessToken,
		RefreshToken: newRefreshToken,
		User:         user,
	}, nil
}

func (s Service) Logout(
	ctx context.Context,
	refreshToken string,
) error {
	_, err := s.DB.Exec(
		ctx,
		`
		UPDATE refresh_tokens
		SET revoked_at = NOW()
		WHERE token_hash = $1
		`,
		HashToken(refreshToken),
	)

	return err
}

func (s Service) createAccessToken(user User) (string, error) {
	schoolID := int64(0)

	if user.SchoolID != nil {
		schoolID = *user.SchoolID
	}

	now := time.Now()

	claims := Claims{
		UserID:   user.ID,
		SchoolID: schoolID,
		Role:     user.Role,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   fmt.Sprintf("%d", user.ID),
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(s.AccessTokenTTL)),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)

	return token.SignedString(s.Secret)
}
