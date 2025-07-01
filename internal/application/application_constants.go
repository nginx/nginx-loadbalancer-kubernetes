/*
 * Copyright (c) 2023 F5 Inc. All rights reserved.
 * Use of this source code is governed by the Apache License that can be found in the LICENSE file.
 */

package application

// These constants determine which Border Server client will be used. The name
// of the port on the desired service needs to be formattted as follows:
// "http-tea", where the first part is the protocol ("http" or "stream") and the
// second part is the name of the upstream (in this case "tea").
//
// Note, this is an extensibility point. To add a Border Server client... 1.
// Create a module that implements the BorderClient interface; 2. Add a new
// constant to this group that acts as a key for selecting the client; 3. Update
// the NewBorderClient factory method in border_client.go that returns the
// client;
const (

	// ClientTypeNginxStream creates a NginxStreamBorderClient that uses the Stream* methods of the NGINX Plus client.
	ClientTypeNginxStream = "stream"

	// ClientTypeNginxHTTP creates an NginxHTTPBorderClient that uses the HTTP* methods of the NGINX Plus client.
	ClientTypeNginxHTTP = "http"
)
