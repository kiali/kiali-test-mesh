package web

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"strings"
	"time"
)

type Server struct {
	server     *http.ServeMux
	version    string
	commitHash string
}

func CreateServer(version, commitHash string) Server {
	return Server{
		version:    version,
		commitHash: commitHash,
	}
}

func (s Server) Start() error {
	server := http.NewServeMux()

	s.server = server

	server.HandleFunc("/time", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, time.Now().UTC().Format(time.RFC3339))
	})

	server.HandleFunc("/version", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, s.version)
	})

	server.HandleFunc("/commit", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, s.commitHash)
	})

	server.HandleFunc("/route", func(w http.ResponseWriter, r *http.Request) {
		path := r.URL.Query().Get("path")

		if path == "" {
			http.Error(w, "Missing required path parameter", 400)
			return
		}

		commaIndex := strings.Index(path, ",")

		var url string
		if commaIndex > 0 {
			host := path[:commaIndex]
			path = path[(commaIndex + 1):]

			url = "http://" + host + "/route?path=" + path
		} else {
			host := path

			url = "http://" + host
		}

		response, err := http.Get(url)
		if err != nil {
			fmt.Errorf("Error", err)
			http.Error(w, "Oops", 500)
		}

		buf, err := ioutil.ReadAll(response.Body)
		if err != nil {
			fmt.Errorf("Error", err)
			http.Error(w, "Oops", 500)
		}

		message := string(buf)

		fmt.Fprint(w, message)
	})

	server.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, "DONE!")
	})

	return http.ListenAndServe(":8888", server)
}
