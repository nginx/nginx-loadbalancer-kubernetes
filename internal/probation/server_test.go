/*
 * Copyright 2023 F5 Inc. All rights reserved.
 * Use of this source code is governed by the Apache License that can be found in the LICENSE file.
 */

package probation

import (
	"log/slog"
	"net/http"
	"testing"

	"github.com/nginx/kubernetes-nginx-ingress/test/mocks"
)

func TestHealthServer_HandleLive(t *testing.T) {
	t.Parallel()
	server := NewHealthServer()
	writer := mocks.NewMockResponseWriter()
	server.HandleLive(writer, nil)

	if string(writer.Body()) != Ok {
		t.Errorf("HandleLive should return %s", Ok)
	}
}

func TestHealthServer_HandleReady(t *testing.T) {
	t.Parallel()
	server := NewHealthServer()
	writer := mocks.NewMockResponseWriter()
	server.HandleReady(writer, nil)

	if string(writer.Body()) != Ok {
		t.Errorf("HandleReady should return %s", Ok)
	}
}

func TestHealthServer_HandleStartup(t *testing.T) {
	t.Parallel()
	server := NewHealthServer()
	writer := mocks.NewMockResponseWriter()
	server.HandleStartup(writer, nil)

	if string(writer.Body()) != Ok {
		t.Errorf("HandleStartup should return %s", Ok)
	}
}

func TestHealthServer_HandleFailCheck(t *testing.T) {
	t.Parallel()
	failCheck := mocks.NewMockCheck(false)
	server := NewHealthServer()
	writer := mocks.NewMockResponseWriter()
	server.handleProbe(writer, nil, failCheck)

	body := string(writer.Body())
	if body != "Service Not Available" {
		t.Errorf("Expected 'Service Not Available', got %v", body)
	}
}

func TestHealthServer_Start(t *testing.T) {
	t.Parallel()
	server := NewHealthServer()
	server.Start()

	defer server.Stop()

	response, err := http.Get("http://localhost:51031/livez")
	if err != nil {
		t.Error(err)
	}
	defer response.Body.Close()

	if response.StatusCode != http.StatusOK {
		t.Errorf("Expected status code %v, got %v", http.StatusAccepted, response.StatusCode)
	}

	slog.Info("received a response from the probe server", "response", response)
}
