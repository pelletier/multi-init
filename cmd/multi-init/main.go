package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/exec"
	"os/signal"
	"sync"
)

func run(i int, ctx context.Context, deadChan chan<- int, args ...string) {
	prefix := fmt.Sprintf("[%d]:", i)
	log.Println(prefix, "starting", args)
	cmd := exec.CommandContext(ctx, args[0], args[1:]...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	if err == nil {
		log.Println(prefix, "terminated gracefully")
	} else {
		log.Println(prefix, "terminated with error:", err)
	}
	deadChan <- i
}

func main() {
	if len(os.Args) <= 1 {
		log.Println("usage: multi-init program-one arg1 arg2 --- program2 arg1 arg2 --- ...")
		os.Exit(1)
	}

	programsArgs := [][]string{}

	var args []string

	for _, arg := range os.Args[1:] {
		if arg == "---" {
			programsArgs = append(programsArgs, args)
			args = nil
		} else {
			args = append(args, arg)
		}
	}
	programsArgs = append(programsArgs, args)
	args = nil

	if len(programsArgs) == 0 {
		log.Println("no child program given. exiting")
		os.Exit(1)
	}

	var wg sync.WaitGroup
	ctx, cancel := context.WithCancel(context.Background())
	deadChan := make(chan int, len(programsArgs))

	for i, args := range programsArgs {
		wg.Add(1)
		go func(i int, args []string) {
			defer wg.Done()
			run(i, ctx, deadChan, args...)
		}(i, args)
	}

	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, os.Kill)
	exitCode := 0
	select {
	case sig := <-sigChan:
		switch sig {
		case os.Interrupt:
			log.Println("- SIGINT -")
		case os.Kill:
			log.Println("- SIGKILL -")
		}
	case i := <-deadChan:
		log.Printf("process [%d] died. stopping everything", i)
		exitCode = 1
	}
	cancel()
	wg.Wait()
	close(deadChan)
	os.Exit(exitCode)
}
