package main

import "net/http"

func (app *application) healtCheckHandler(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("ok"))
}
