/*
 * Copyright (c) 2023 F5 Inc. All rights reserved.
 * Use of this source code is governed by the Apache License that can be found in the LICENSE file.
 */

package application

import (
	"context"

	nginxClient "github.com/nginx/nginx-plus-go-client/v2/client"
)

var _ NginxClientInterface = (*nginxClient.NginxClient)(nil)

// NginxClientInterface defines the functions used on the NGINX Plus client,
// abstracting away the full details of that client.
type NginxClientInterface interface {
	// DeleteStreamServer is used by the NginxStreamBorderClient.
	DeleteStreamServer(ctx context.Context, upstream string, server string) error

	// UpdateStreamServers is used by the NginxStreamBorderClient.
	UpdateStreamServers(
		ctx context.Context,
		upstream string,
		servers []nginxClient.StreamUpstreamServer,
	) ([]nginxClient.StreamUpstreamServer, []nginxClient.StreamUpstreamServer, []nginxClient.StreamUpstreamServer, error)

	// DeleteHTTPServer is used by the NginxHTTPBorderClient.
	DeleteHTTPServer(ctx context.Context, upstream string, server string) error

	// UpdateHTTPServers is used by the NginxHTTPBorderClient.
	UpdateHTTPServers(
		ctx context.Context,
		upstream string,
		servers []nginxClient.UpstreamServer,
	) ([]nginxClient.UpstreamServer, []nginxClient.UpstreamServer, []nginxClient.UpstreamServer, error)
}
