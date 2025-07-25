/*
 * Copyright 2023 F5 Inc. All rights reserved.
 * Use of this source code is governed by the Apache License that can be found in the LICENSE file.
 */

package application

import (
	"context"
	"fmt"
	"log/slog"

	"github.com/nginx/kubernetes-nginx-ingress/internal/core"
)

// Interface defines the functions required to implement a Border Client.
type Interface interface {
	Update(context.Context, *core.ServerUpdateEvent) error
	Delete(context.Context, *core.ServerUpdateEvent) error
}

// BorderClient defines any state need by the Border Client.
type BorderClient struct{}

// NewBorderClient is the Factory function for creating a Border Client.
//
// Note, this is an extensibility point. To add a Border Server client...
// 1. Create a module that implements the BorderClient interface;
// 2. Add a new constant in application_constants.go that acts as a key for selecting the client;
// 3. Update the NewBorderClient factory method in border_client.go that returns the client;
func NewBorderClient(clientType string, borderClient interface{}) (Interface, error) {
	slog.Debug("NewBorderClient", slog.String("client", clientType))

	switch clientType {
	case ClientTypeNginxStream:
		return NewNginxStreamBorderClient(borderClient)

	case ClientTypeNginxHTTP:
		return NewNginxHTTPBorderClient(borderClient)

	default:
		borderClient, _ := NewNullBorderClient()
		return borderClient, fmt.Errorf(`unknown border client type: %s`, clientType)
	}
}
