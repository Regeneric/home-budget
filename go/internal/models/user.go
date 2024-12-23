package models

type User struct {
	Id                   int64  `json:"id"`
	UserName             string `json:"userName"`
	Password             string `json:"-"`
	Email                string `json:"email"`
	FirstName            string `json:"firstName"`
	PersonalBudget       int64  `json:"personalBudget"`
	IsActive             bool   `json:"isActive"`
	PasswordResetRequest bool   `json:"passwordResetRequest"`
	LastPasswordReset    string `json:"lastPasswordReset"`
	IsAdmin              bool   `json:"isAdmin"`
	CreatedAt            string `json:"createdAt"`
	UpdatedAt            string `json:"updatedAt"`
}
