package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/health", handleHealth)
	mux.HandleFunc("/work", handleWork)

	srv := &http.Server{
		Addr:    ":8081",
		Handler: mux,
	}

	// Graceful shutdown: wait for SIGTERM or SIGINT, then give in-flight
	// requests up to 30s to complete before exiting.
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGTERM, syscall.SIGINT)

	go func() {
		log.Printf("job-worker listening on %s", srv.Addr)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("listen: %v", err)
		}
	}()

	<-stop
	log.Println("shutting down — draining in-flight requests")

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("shutdown error: %v", err)
	}
	log.Println("clean exit")
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	fmt.Fprintln(w, `{"status":"up"}`)
}

func handleWork(w http.ResponseWriter, r *http.Request) {
	// Stub: in later blocks this will call job-api over mTLS
	w.Header().Set("Content-Type", "application/json")
	resp := map[string]string{"worker": "ok", "ts": time.Now().UTC().Format(time.RFC3339)}
	_ = json.NewEncoder(w).Encode(resp)
}
