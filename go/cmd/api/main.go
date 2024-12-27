package main

import (
	"hkk/budget/internal/db"
	"hkk/budget/internal/env"
	"hkk/budget/internal/store"
	"log"
)

func main() {
	cfg := config{
		addr: env.GetString("APP_ADDRESS", ":8989"),
		db: dbConfig{
			addr:         env.GetString("SQL_ADDRESS", "ERROR READING ENV VAR"),
			maxOpenConns: env.GetInt("SQL_MAX_OPEN_CONNS", 30),
			maxIdleConns: env.GetInt("SQL_MAX_IDLE_CONNS", 30),
			maxIdleTime:  env.GetString("SQL_MAX_IDLE_TIME", "10m"),
		},
	}

	db, err := db.New(
		cfg.db.addr,
		cfg.db.maxOpenConns,
		cfg.db.maxIdleConns,
		cfg.db.maxIdleTime,
	)

	if err != nil {
		log.Panic(err)
	}

	defer db.Close()
	log.Printf("DB connection established to %s:%s",
		env.GetString("SQL_HOST", "ERROR READING ENV VAR"),
		env.GetString("SQL_PORT", "ERROR READING ENV VAR"),
	)

	store := store.NewStorage(db)

	app := &application{
		config: cfg,
		store:  store,
	}

	mux := app.mount()
	log.Fatal(app.run(mux))
}
