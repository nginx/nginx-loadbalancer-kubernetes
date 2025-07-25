/*
 * Copyright (c) 2023 F5 Inc. All rights reserved.
 * Use of this source code is governed by the Apache License that can be found in the LICENSE file.
 */

package observation

import (
	"sync"

	v1 "k8s.io/api/core/v1"
)

// register holds references to the services that the user has configured for use with NLK
type register struct {
	mu       sync.RWMutex // protects register
	services map[registerKey]*v1.Service
}

type registerKey struct {
	serviceName string
	namespace   string
}

func newRegister() *register {
	return &register{
		services: make(map[registerKey]*v1.Service),
	}
}

// addOrUpdateService adds the service to the register if not found, else updates the existing service
func (r *register) addOrUpdateService(service *v1.Service) {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.services[registerKey{namespace: service.Namespace, serviceName: service.Name}] = service
}

// removeService removes the service from the register
func (r *register) removeService(service *v1.Service) {
	r.mu.Lock()
	defer r.mu.Unlock()

	delete(r.services, registerKey{namespace: service.Namespace, serviceName: service.Name})
}

// getService returns the service from the register if found
func (r *register) getService(namespace string, serviceName string) (*v1.Service, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	s, ok := r.services[registerKey{namespace: namespace, serviceName: serviceName}]
	return s, ok
}

// listServices returns all the services in the register
func (r *register) listServices() []*v1.Service {
	r.mu.RLock()
	defer r.mu.RUnlock()

	services := make([]*v1.Service, 0, len(r.services))

	for _, service := range r.services {
		services = append(services, service)
	}

	return services
}
