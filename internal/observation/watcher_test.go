/*
 * Copyright 2023 F5 Inc. All rights reserved.
 * Use of this source code is governed by the Apache License that can be found in the LICENSE file.
 */

package observation

import (
	"testing"

	"github.com/nginx/kubernetes-nginx-ingress/internal/configuration"
	"github.com/stretchr/testify/require"
)

func TestWatcher_ErrWithNilInformers(t *testing.T) {
	t.Parallel()
	_, err := buildWatcherWithNilInformer()
	require.Error(t, err, "expected construction of watcher with nil informer to fail")
}

func buildWatcherWithNilInformer() (*Watcher, error) {
	return NewWatcher(configuration.Settings{}, nil, nil, nil, nil)
}
