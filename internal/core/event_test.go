/*
 * Copyright (c) 2023 F5 Inc. All rights reserved.
 * Use of this source code is governed by the Apache License that can be found in the LICENSE file.
 */

package core

import (
	"testing"

	v1 "k8s.io/api/core/v1"
)

func TestNewEvent(t *testing.T) {
	t.Parallel()
	expectedType := Created
	expectedService := &v1.Service{}

	event := NewEvent(expectedType, expectedService)

	if event.Type != expectedType {
		t.Errorf("expected Created, got %v", event.Type)
	}

	if event.Service != expectedService {
		t.Errorf("expected service, got %#v", event.Service)
	}
}
