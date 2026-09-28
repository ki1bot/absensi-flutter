package main

import (
	"context"
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"os/signal"
	"syscall"
	"time"

	"github.com/ki1bot/absensi-flutter/backend/internal/attendance"
	"github.com/ki1bot/absensi-flutter/backend/internal/auth"
	"github.com/ki1bot/absensi-flutter/backend/internal/config"
	"github.com/ki1bot/absensi-flutter/backend/internal/dashboard"
	"github.com/ki1bot/absensi-flutter/backend/internal/database"
	"github.com/ki1bot/absensi-flutter/backend/internal/middleware"
	"github.com/ki1bot/absensi-flutter/backend/internal/parent"
	"github.com/ki1bot/absensi-flutter/backend/internal/school"
	"github.com/ki1bot/absensi-flutter/backend/internal/student"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatal(err)
	}

	db, err := database.Open(cfg.DatabaseURL)
	if err != nil {
		log.Fatal(err)
	}

	defer db.Close()

	if err := database.Migrate(
		context.Background(),
		db,
		"/app/migrations",
	); err != nil {
		log.Fatal(err)
	}

	authService := auth.Service{
		DB:              db,
		Secret:          []byte(cfg.JWTSecret),
		AccessTokenTTL:  cfg.AccessTokenTTL,
		RefreshTokenTTL: cfg.RefreshTokenTTL,
	}

	authHandler := auth.Handler{
		Service: authService,
		DB:      db,
	}

	schoolHandler := school.Handler{
		DB: db,
	}

	studentHandler := student.Handler{
		DB:       db,
		QRSecret: []byte(cfg.QRSecret),
	}

	attendanceHandler := attendance.Handler{
		DB: db,
	}

	dashboardHandler := dashboard.Handler{
		DB: db,
	}

	parentHandler := parent.Handler{
		DB: db,
	}

	authMiddleware := middleware.Authentication(
		[]byte(cfg.JWTSecret),
	)

	adminOnly := middleware.RequireRoles("admin")
	scannerRoles := middleware.RequireRoles(
		"admin",
		"operator",
	)
	parentOnly := middleware.RequireRoles("parent")

	mux := http.NewServeMux()

	mux.HandleFunc(
		"GET /",
		func(w http.ResponseWriter, r *http.Request) {
			writeJSON(
				w,
				http.StatusOK,
				map[string]string{
					"message": "Absensi API",
				},
			)
		},
	)

	mux.HandleFunc(
		"GET /health",
		func(w http.ResponseWriter, r *http.Request) {
			var databaseTime time.Time

			err := db.QueryRow(
				r.Context(),
				"SELECT NOW()",
			).Scan(&databaseTime)

			if err != nil {
				writeJSON(
					w,
					http.StatusServiceUnavailable,
					map[string]string{
						"status":   "error",
						"database": "disconnected",
					},
				)
				return
			}

			writeJSON(
				w,
				http.StatusOK,
				map[string]any{
					"status":   "ok",
					"service":  "absensi-api",
					"database": "connected",
					"time":     databaseTime,
				},
			)
		},
	)

	mux.HandleFunc(
		"POST /api/v1/schools/register",
		schoolHandler.Register,
	)

	mux.HandleFunc(
		"POST /api/v1/auth/login",
		authHandler.Login,
	)

	mux.HandleFunc(
		"POST /api/v1/auth/refresh",
		authHandler.Refresh,
	)

	mux.Handle(
		"POST /api/v1/auth/logout",
		authMiddleware(
			http.HandlerFunc(authHandler.Logout),
		),
	)

	mux.Handle(
		"GET /api/v1/auth/me",
		authMiddleware(
			http.HandlerFunc(authHandler.Me),
		),
	)

	mux.Handle(
		"GET /api/v1/school",
		authMiddleware(
			http.HandlerFunc(schoolHandler.Detail),
		),
	)

	mux.Handle(
		"GET /api/v1/dashboard",
		authMiddleware(
			adminOnly(
				http.HandlerFunc(
					dashboardHandler.Admin,
				),
			),
		),
	)

	mux.Handle(
		"GET /api/v1/students",
		authMiddleware(
			scannerRoles(
				http.HandlerFunc(studentHandler.List),
			),
		),
	)

	mux.Handle(
		"POST /api/v1/students",
		authMiddleware(
			adminOnly(
				http.HandlerFunc(studentHandler.Create),
			),
		),
	)

	mux.Handle(
		"GET /api/v1/students/{id}",
		authMiddleware(
			scannerRoles(
				http.HandlerFunc(studentHandler.Detail),
			),
		),
	)

	mux.Handle(
		"GET /api/v1/students/{id}/qr",
		authMiddleware(
			adminOnly(
				http.HandlerFunc(studentHandler.QR),
			),
		),
	)

	mux.Handle(
		"DELETE /api/v1/students/{id}",
		authMiddleware(
			adminOnly(
				http.HandlerFunc(studentHandler.Delete),
			),
		),
	)

	mux.Handle(
		"POST /api/v1/attendance/check-in",
		authMiddleware(
			scannerRoles(
				http.HandlerFunc(
					attendanceHandler.CheckIn,
				),
			),
		),
	)

	mux.Handle(
		"GET /api/v1/attendances",
		authMiddleware(
			scannerRoles(
				http.HandlerFunc(
					attendanceHandler.List,
				),
			),
		),
	)

	mux.Handle(
		"GET /api/v1/parent/dashboard",
		authMiddleware(
			parentOnly(
				http.HandlerFunc(
					parentHandler.Dashboard,
				),
			),
		),
	)

	mux.Handle(
		"GET /api/v1/notifications",
		authMiddleware(
			parentOnly(
				http.HandlerFunc(
					parentHandler.Notifications,
				),
			),
		),
	)

	server := &http.Server{
		Addr:              ":" + cfg.Port,
		Handler:           mux,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       15 * time.Second,
		WriteTimeout:      15 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	shutdownSignal, stop := signal.NotifyContext(
		context.Background(),
		syscall.SIGINT,
		syscall.SIGTERM,
	)

	defer stop()

	go func() {
		<-shutdownSignal.Done()

		ctx, cancel := context.WithTimeout(
			context.Background(),
			10*time.Second,
		)
		defer cancel()

		if err := server.Shutdown(ctx); err != nil {
			log.Printf(
				"graceful shutdown gagal: %v",
				err,
			)
		}
	}()

	log.Printf(
		"API berjalan pada http://0.0.0.0:%s",
		cfg.Port,
	)

	err = server.ListenAndServe()

	if err != nil &&
		!errors.Is(err, http.ErrServerClosed) {
		log.Fatal(err)
	}
}

func writeJSON(
	w http.ResponseWriter,
	status int,
	value any,
) {
	w.Header().Set(
		"Content-Type",
		"application/json",
	)

	w.WriteHeader(status)

	if err := json.NewEncoder(w).Encode(value); err != nil {
		log.Printf("JSON encode error: %v", err)
	}
}
