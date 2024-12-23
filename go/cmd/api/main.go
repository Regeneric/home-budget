package main

import (
	"hkk/budget/internal/env"
	"hkk/budget/internal/store"
	"log"
)

func main() {
	cfg := config{
		addr: env.GetString("APP_ADDRESS", ":8989"),
		db: dbConfig{
			addr:         env.GetString("SQL_ADDRESS", "mysql://root@tcp(localhost:3306)/mysql"),
			maxOpenConns: env.GetInt("SQL_MAX_OPEN_CONNS", 30),
			maxIdleConns: env.GetInt("SQL_MAX_IDLE_CONNS", 30),
			maxIdleTime:  env.GetString("SQL_MAX_IDLE_TIME", "10m"),
		},
	}

	store := store.NewStorage(nil)

	app := &application{
		config: cfg,
		store:  store,
	}

	mux := app.mount()
	log.Fatal(app.run(mux))
}
