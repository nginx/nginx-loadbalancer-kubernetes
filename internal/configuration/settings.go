/*
 * Copyright 2023 F5 Inc. All rights reserved.
 * Use of this source code is governed by the Apache License that can be found in the LICENSE file.
 */

package configuration

import (
	"encoding/base64"
	"fmt"
	"log/slog"
	"time"

	"github.com/spf13/viper"
)

const (
	// ServiceAnnotationMatchKey is the key name of the annotation that
	// identifies the services whose events will be monitored.
	ServiceAnnotationMatchKey = "service-annotation-match"

	// DefaultServiceAnnotation is the default name of the services whose events will be
	// monitored.
	DefaultServiceAnnotation = "nginxaas"
)

// WorkQueueSettings contains the configuration for the nlk-synchronizer queue.
// The queues are NamedDelayingQueue objects that use an ItemExponentialFailureRateLimiter
// as the underlying rate limiter.
type WorkQueueSettings struct {
	// Name is the name of the queue.
	Name string

	// RateLimiterBase is the value used to calculate the exponential backoff rate limiter.
	// The formula is: RateLimiterBase * 2 ^ (num_retries - 1)
	RateLimiterBase time.Duration

	// RateLimiterMax limits the amount of time retries are allowed to be attempted.
	RateLimiterMax time.Duration
}

// WatcherSettings contains the configuration values needed by the Watcher.
type WatcherSettings struct {
	// ServiceAnnotation is the annotation of the ingress service whose events the watcher should monitor.
	ServiceAnnotation string

	// ResyncPeriod is the value used to set the resync period for the underlying SharedInformer.
	ResyncPeriod time.Duration
}

// SynchronizerSettings contains the configuration values needed by the Synchronizer.
type SynchronizerSettings struct {
	// Threads is the number of threads that will be used to process messages.
	Threads int

	// WorkQueueSettings is the configuration for the Synchronizer's queue.
	WorkQueueSettings WorkQueueSettings
}

// Settings contains the configuration values needed by the application.
type Settings struct {
	// LogLevel is the user-specified log level. Defaults to warn.
	LogLevel string

	// NginxPlusHosts is a list of Nginx Plus hosts that will be used to update the Border Servers.
	NginxPlusHosts []string

	// SkipVerifyTLS determines whether the http client will skip TLS verification or not.
	SkipVerifyTLS bool

	// APIKey is the api key used to authenticate with the dataplane API.
	APIKey string

	// Synchronizer contains the configuration values needed by the Synchronizer.
	Synchronizer SynchronizerSettings

	// Watcher contains the configuration values needed by the Watcher.
	Watcher WatcherSettings
}

// Read parses all the config and returns the values
func Read(configName, configPath string) (s Settings, err error) {
	v := viper.New()
	v.SetConfigName(configName)
	v.SetConfigType("yaml")
	v.AddConfigPath(configPath)
	if err = v.ReadInConfig(); err != nil {
		return s, err
	}

	if err = v.BindEnv("NGINXAAS_DATAPLANE_API_KEY"); err != nil {
		return s, err
	}

	skipVerifyTLS, err := ValidateTLSMode(v.GetString("tls-mode"))
	if err != nil {
		slog.Error("could not validate tls mode", "error", err)
	}

	if skipVerifyTLS {
		slog.Warn("skipping TLS verification for NGINX hosts")
	}

	serviceAnnotation := DefaultServiceAnnotation
	if sa := v.GetString(ServiceAnnotationMatchKey); sa != "" {
		serviceAnnotation = sa
	}

	return Settings{
		LogLevel:       v.GetString("log-level"),
		NginxPlusHosts: v.GetStringSlice("nginx-hosts"),
		SkipVerifyTLS:  skipVerifyTLS,
		APIKey:         base64.StdEncoding.EncodeToString([]byte(v.GetString("NGINXAAS_DATAPLANE_API_KEY"))),
		Synchronizer: SynchronizerSettings{
			Threads: 1,
			WorkQueueSettings: WorkQueueSettings{
				RateLimiterBase: time.Second * 2,
				RateLimiterMax:  time.Second * 60,
				Name:            "nlk-synchronizer",
			},
		},
		Watcher: WatcherSettings{
			ResyncPeriod:      0,
			ServiceAnnotation: serviceAnnotation,
		},
	}, nil
}

func ValidateTLSMode(tlsConfigMode string) (skipVerify bool, err error) {
	if tlsConfigMode == "" {
		return false, nil
	}

	var tlsModeFound bool
	if skipVerify, tlsModeFound = tlsModeMap[tlsConfigMode]; tlsModeFound {
		return skipVerify, nil
	}

	return false, fmt.Errorf(`invalid tls-mode value: %s`, tlsConfigMode)
}
