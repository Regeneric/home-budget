package store

import (
	"context"
	"database/sql"
	"hkk/budget/internal/models"
)

type UserStore struct {
	db *sql.DB
}

func (s *UserStore) Create(ctx context.Context, user *models.User) error {
	query := `
		INSERT INTO users (userName, password, email, firstName, personalBudget, isActive, passwordResetRequest, lastPasswordReset, isAdmin)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING id, createdAt, updatedAt
	`

	err := s.db.QueryRowContext(
		ctx, query,
		user.UserName,
		user.Password,
		user.Email,
		user.FirstName,
		user.PersonalBudget,
		user.IsActive,
		user.PasswordResetRequest,
		user.LastPasswordReset,
		user.IsAdmin,
	).Scan(
		&user.Id,
		&user.CreatedAt,
		&user.UpdatedAt,
	)

	if err != nil {
		return err
	}

	return nil
}
