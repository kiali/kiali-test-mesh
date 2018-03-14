package main

import (
	"fmt"
	"os"
	"os/signal"

	"github.com/kiali/kiali-test-mesh/web"
)

// vars to be set during the build.
var (
	name       = "unknown"
	version    = "unknown"
	commitHash = "unknown"
)

func main() {
	fmt.Printf("Starting %v version %v (%v)\n", name, version, commitHash)

	server := web.CreateServer(version, commitHash)

	server.Start()

	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt)
	<-c

	fmt.Printf("%v has exited\n", name)
}
