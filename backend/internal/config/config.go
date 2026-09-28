package config

import (
	"fmt"
	"os"
	"time"
)

type Config struct {
	DatabaseURL     string
	Port            string
	JWTSecret       string
	QRSecret        string
	AccessTokenTTL  time.Duration
	RefreshTokenTTL time.Duration
}

func Load() (Config, error) {
	cfg := Config{
		DatabaseURL: os.Getenv("DATABASE_URL"),
		Port:        os.Getenv("API_PORT"),
		JWTSecret:   os.Getenv("JWT_SECRET"),
		QRSecret:    os.Getenv("QR_SECRET"),
	}

	if cfg.Port == "" {
		cfg.Port = "8080"
	}

	if cfg.DatabaseURL == "" {
		return Config{}, fmt.Errorf("DATABASE_URL belum dikonfigurasi")
	}

	if cfg.JWTSecret == "" {
		return Config{}, fmt.Errorf("JWT_SECRET belum dikonfigurasi")
	}

	if cfg.QRSecret == "" {
		return Config{}, fmt.Errorf("QR_SECRET belum dikonfigurasi")
	}

	accessTTL := os.Getenv("ACCESS_TOKEN_TTL")
	if accessTTL == "" {
		accessTTL = "15m"
	}

	refreshTTL := os.Getenv("REFRESH_TOKEN_TTL")
	if refreshTTL == "" {
		refreshTTL = "168h"
	}

	var err error

	cfg.AccessTokenTTL, err = time.ParseDuration(accessTTL)
	if err != nil {
		return Config{}, fmt.Errorf("ACCESS_TOKEN_TTL tidak valid: %w", err)
	}

	cfg.RefreshTokenTTL, err = time.ParseDuration(refreshTTL)
	if err != nil {
		return Config{}, fmt.Errorf("REFRESH_TOKEN_TTL tidak valid: %w", err)
	}

	return cfg, nil
}