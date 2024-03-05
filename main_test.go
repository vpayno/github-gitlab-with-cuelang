package main

import (
	"bytes"
	"io"
	"os"
	"testing"
)

// This is the main test function. This is the gatekeeper of all the tests in the main package.
func TestMain(m *testing.M) {
	exitCode := m.Run()

	os.Exit(exitCode)
}

// The functions in main() are already tested. Just running them together with zero test questions.
func TestMain_app(t *testing.T) {
	testStdout, writer, err := os.Pipe()
	if err != nil {
		t.Errorf("os.Pipe() err %v; want %v", err, nil)
	}

	osStdout := os.Stdout // keep backup of the real stdout
	os.Stdout = writer

	defer func() {
		// Undo what we changed when this test is done.
		os.Stdout = osStdout
	}()

	want := "Hello world!\n"

	os.Args = []string{}

	main()

	// Stop capturing stdout.
	writer.Close()

	var buf bytes.Buffer

	_, err = io.Copy(&buf, testStdout)
	if err != nil {
		t.Error(err)
	}

	got := buf.String()
	if got != want {
		t.Errorf("helloWorld(): want %q, got %q", want, got)
	}
}

func TestHelloWorld(t *testing.T) {
	testStdout, writer, err := os.Pipe()
	if err != nil {
		t.Errorf("os.Pipe() err %v; want %v", err, nil)
	}

	osStdout := os.Stdout // keep backup of the real stdout
	os.Stdout = writer

	defer func() {
		// Undo what we changed when this test is done.
		os.Stdout = osStdout
	}()

	want := "Hello world!\n"

	os.Args = []string{}

	helloWorld()

	// Stop capturing stdout.
	writer.Close()

	var buf bytes.Buffer

	_, err = io.Copy(&buf, testStdout)
	if err != nil {
		t.Error(err)
	}

	got := buf.String()
	if got != want {
		t.Errorf("helloWorld(): want %q, got %q", want, got)
	}
}
