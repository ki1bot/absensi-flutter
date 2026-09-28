package main

import (
	"context"
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

type Application struct {
	DB *pgxpool.Pool
}

type HealthResponse struct {
	Status   string    `json:"status"`
	Service  string    `json:"service"`
	Database string    `json:"database"`
	Time     time.Time `json:"time"`
}

func main() {
	databaseURL := os.Getenv("DATABASE_URL")

	if databaseURL == "" {
		log.Fatal("DATABASE_URL belum dikonfigurasi")
	}

	pool, err := pgxpool.New(context.Background(), databaseURL)
	if err != nil {
		log.Fatalf("gagal membuat database pool: %v", err)
	}

	defer pool.Close()

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := pool.Ping(ctx); err != nil {
		log.Fatalf("gagal terhubung ke PostgreSQL: %v", err)
	}

	app := &Application{
		DB: pool,
	}

	mux := http.NewServeMux()

	mux.HandleFunc("GET /", app.homeHandler)
	mux.HandleFunc("GET /health", app.healthHandler)

	port := os.Getenv("API_PORT")
	if port == "" {
		port = "8080"
	}

	server := &http.Server{
		Addr:              ":" + port,
		Handler:           mux,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      10 * time.Second,
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

		shutdownContext, cancelShutdown := context.WithTimeout(
			context.Background(),
			10*time.Second,
		)
		defer cancelShutdown()

		if err := server.Shutdown(shutdownContext); err != nil {
			log.Printf("gagal melakukan graceful shutdown: %v", err)
		}
	}()

	log.Printf("API berjalan pada http://0.0.0.0:%s", port)

	err = server.ListenAndServe()

	if err != nil && !errors.Is(err, http.ErrServerClosed) {
		log.Fatalf("server error: %v", err)
	}
}

func (app *Application) homeHandler(w http.ResponseWriter, r *http.Request) {
	response := map[string]string{
		"message": "Absensi API",
	}

	writeJSON(w, http.StatusOK, response)
}

func (app *Application) healthHandler(w http.ResponseWriter, r *http.Request) {
	var databaseTime time.Time

	err := app.DB.QueryRow(
		r.Context(),
		"SELECT NOW()",
	).Scan(&databaseTime)

	if err != nil {
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{
			"status":   "error",
			"database": "disconnected",
		})

		return
	}

	response := HealthResponse{
		Status:   "ok",
		Service:  "absensi-api",
		Database: "connected",
		Time:     databaseTime,
	}

	writeJSON(w, http.StatusOK, response)
}

func writeJSON(w http.ResponseWriter, status int, data any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)

	if err := json.NewEncoder(w).Encode(data); err != nil {
		log.Printf("gagal encode response JSON: %v", err)
	}
}