package mariadb

import (
	"context"
	"database/sql"
	"encoding/json"
	"hkk/budget/internal/models"
)

type PostStore struct {
	DB *sql.DB
}

func (s *PostStore) Create(ctx context.Context, post *models.Post) error {
	query := `
		INSERT INTO posts (ownerID, title, description, amount, priority, tags, categories, comments, isActive)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING id, createdAt, updatedAt
	`

	tags, _ := json.Marshal(post.Tags)
	comments, _ := json.Marshal(post.Comments)
	categories, _ := json.Marshal(post.Categories)

	err := s.DB.QueryRowContext(
		ctx, query,
		post.OwnerID,
		post.Title,
		post.Description,
		post.Amount,
		post.Priority,
		tags,
		categories,
		comments,
		post.IsActive,
	).Scan(
		&post.Id,
		&post.CreatedAt,
		&post.UpdatedAt,
	)

	if err != nil {
		return err
	}

	return nil
}
