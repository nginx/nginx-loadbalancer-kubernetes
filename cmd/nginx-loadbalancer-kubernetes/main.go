/*
 * Copyright 2023 F5 Inc. All rights reserved.
 * Use of this source code is governed by the Apache License that can be found in the LICENSE file.
 */

package main

import (
	"context"
	"fmt"
	"log/slog"
	"os"

	"github.com/nginx/kubernetes-nginx-ingress/internal/configuration"
	"github.com/nginx/kubernetes-nginx-ingress/internal/observation"
	"github.com/nginx/kubernetes-nginx-ingress/internal/probation"
	"github.com/nginx/kubernetes-nginx-ingress/internal/synchronization"
	"github.com/nginx/kubernetes-nginx-ingress/internal/translation"
	"github.com/nginx/kubernetes-nginx-ingress/pkg/buildinfo"
	"golang.org/x/sync/errgroup"
	"k8s.io/client-go/informers"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/util/workqueue"
)

func main() {
	err := run()
	if err != nil {
		slog.Error(err.Error())
		os.Exit(1)
	}
}

func run() error {
	ctx := context.Background()
	var err error

	k8sClient, err := buildKubernetesClient()
	if err != nil {
		return fmt.Errorf(`error building a Kubernetes client: %w`, err)
	}

	settings, err := configuration.Read("config.yaml", "/etc/nginxaas-loadbalancer-kubernetes")
	if err != nil {
		return fmt.Errorf(`error occurred accessing configuration: %w`, err)
	}

	initializeLogger(settings.LogLevel)

	synchronizerWorkqueue := buildWorkQueue(settings.Synchronizer.WorkQueueSettings)

	factory := informers.NewSharedInformerFactoryWithOptions(
		k8sClient, settings.Watcher.ResyncPeriod,
	)

	serviceInformer := factory.Core().V1().Services()
	endpointSliceInformer := factory.Discovery().V1().EndpointSlices()
	endpointSliceLister := endpointSliceInformer.Lister()
	nodesInformer := factory.Core().V1().Nodes()
	nodesLister := nodesInformer.Lister()

	translator := translation.NewTranslator(endpointSliceLister, nodesLister)

	synchronizer, err := synchronization.NewSynchronizer(
		settings, synchronizerWorkqueue, translator, serviceInformer.Lister())
	if err != nil {
		return fmt.Errorf(`error initializing synchronizer: %w`, err)
	}

	watcher, err := observation.NewWatcher(settings, synchronizer, serviceInformer, endpointSliceInformer, nodesInformer)
	if err != nil {
		return fmt.Errorf(`error occurred creating a watcher: %w`, err)
	}

	factory.Start(ctx.Done())
	results := factory.WaitForCacheSync(ctx.Done())
	for name, success := range results {
		if !success {
			return fmt.Errorf(`error occurred waiting for cache sync for %s`, name)
		}
	}

	g, ctx := errgroup.WithContext(ctx)

	g.Go(func() error { return synchronizer.Run(ctx) })

	probeServer := probation.NewHealthServer()
	probeServer.Start()

	g.Go(func() error { return watcher.Run(ctx) })

	err = g.Wait()
	return err
}

func initializeLogger(logLevel string) {
	programLevel := new(slog.LevelVar)

	switch logLevel {
	case "error":
		programLevel.Set(slog.LevelError)
	case "warn":
		programLevel.Set(slog.LevelWarn)
	case "info":
		programLevel.Set(slog.LevelInfo)
	case "debug":
		programLevel.Set(slog.LevelDebug)
	default:
		programLevel.Set(slog.LevelWarn)
	}

	handler := slog.NewJSONHandler(os.Stderr, &slog.HandlerOptions{Level: programLevel})
	logger := slog.New(handler).With("version", buildinfo.SemVer())
	slog.SetDefault(logger)
	slog.Debug("Settings::setLogLevel", slog.String("level", logLevel))
}

func buildKubernetesClient() (*kubernetes.Clientset, error) {
	slog.Debug("Watcher::buildKubernetesClient")
	k8sConfig, err := rest.InClusterConfig()
	if err == rest.ErrNotInCluster {
		return nil, fmt.Errorf(`not running in a Cluster: %w`, err)
	} else if err != nil {
		return nil, fmt.Errorf(`error occurred getting the Cluster config: %w`, err)
	}

	client, err := kubernetes.NewForConfig(k8sConfig)
	if err != nil {
		return nil, fmt.Errorf(`error occurred creating a client: %w`, err)
	}

	return client, nil
}

func buildWorkQueue(settings configuration.WorkQueueSettings,
) workqueue.TypedRateLimitingInterface[synchronization.ServiceKey] {
	slog.Debug("Watcher::buildSynchronizerWorkQueue")

	rateLimiter := workqueue.NewTypedItemExponentialFailureRateLimiter[synchronization.ServiceKey](
		settings.RateLimiterBase, settings.RateLimiterMax)
	return workqueue.NewTypedRateLimitingQueueWithConfig(
		rateLimiter, workqueue.TypedRateLimitingQueueConfig[synchronization.ServiceKey]{Name: settings.Name})
}
