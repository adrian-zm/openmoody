package main

import (
	"log"
	"net/http"
)

func main() {
	mux := http.NewServeMux()
	mux.Handle("/js/", http.FileServer(http.Dir(".")))
	mux.Handle("/index.css", http.FileServer(http.Dir(".")))
	mux.HandleFunc("GET /{$}", func(w http.ResponseWriter, r *http.Request) {
		http.ServeFile(w, r, "index.html")
	})
	log.Fatal(http.ListenAndServe(":8080", mux))
}
