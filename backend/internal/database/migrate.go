package database

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"sort"

	"github.com/jackc/pgx/v5/pgxpool"
)

func Migrate(ctx context.Context, db *pgxpool.Pool, path string) error {
	if _, err := db.Exec(
		ctx,
		`
		CREATE TABLE IF NOT EXISTS schema_migrations (
			filename TEXT PRIMARY KEY,
			applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
		)
		`,
	); err != nil {
		return fmt.Errorf("gagal membuat schema_migrations: %w", err)
	}

	entries, err := os.ReadDir(path)
	if err != nil {
		return fmt.Errorf("gagal membaca migration directory: %w", err)
	}

	var files []string

	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}

		if filepath.Ext(entry.Name()) == ".sql" {
			files = append(files, entry.Name())
		}
	}

	sort.Strings(files)

	for _, filename := range files {
		var exists bool

		err := db.QueryRow(
			ctx,
			`
			SELECT EXISTS(
				SELECT 1
				FROM schema_migrations
				WHERE filename = $1
			)
			`,
			filename,
		).Scan(&exists)

		if err != nil {
			return fmt.Errorf(
				"gagal mengecek migration %s: %w",
				filename,
				err,
			)
		}

		if exists {
			continue
		}

		content, err := os.ReadFile(filepath.Join(path, filename))
		if err != nil {
			return fmt.Errorf(
				"gagal membaca migration %s: %w",
				filename,
				err,
			)
		}

		tx, err := db.Begin(ctx)
		if err != nil {
			return err
		}

		if _, err = tx.Exec(ctx, string(content)); err != nil {
			_ = tx.Rollback(ctx)

			return fmt.Errorf(
				"migration %s gagal: %w",
				filename,
				err,
			)
		}

		if _, err = tx.Exec(
			ctx,
			`
			INSERT INTO schema_migrations (filename)
			VALUES ($1)
			`,
			filename,
		); err != nil {
			_ = tx.Rollback(ctx)

			return err
		}

		if err = tx.Commit(ctx); err != nil {
			return err
		}
	}

	return nil
}
