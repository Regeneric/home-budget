package models

type Post struct {
	Id          int64    `json:"id"`
	OwnerID     int64    `json:"ownerID"`
	Title       string   `json:"title"`
	Description string   `json:"description"`
	Amount      int64    `json:"amount"`
	Priority    int64    `json:"priority"`
	Tags        []string `json:"tags"`
	Categories  []string `json:"categories"`
	Comments    []string `json:"comments"`
	IsActive    bool     `json:"isActive"`
	CreatedAt   string   `json:"createdAt"`
	UpdatedAt   string   `json:"updatedAt"`
}
