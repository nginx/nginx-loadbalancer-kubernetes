<!-- markdownlint-disable-next-line first-line-h1 -->
[![CI](https://github.com/nginx/nginx-loadbalancer-kubernetes/actions/workflows/build-test.yml/badge.svg)](https://github.com/nginx/nginx-loadbalancer-kubernetess/actions/workflows/build-test.yml)
[![Go Report Card](https://goreportcard.com/badge/github.com/nginx/nginx-loadbalancer-kubernetes)](https://goreportcard.com/report/github.com/nginx/nginx-loadbalancer-kubernetes)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/nginx/nginx-loadbalancer-kubernetes?logo=github&sort=semver)](https://github.com/nginx/nginx-loadbalancer-kubernetes/releases/latest) ![GitHub go.mod Go version](https://img.shields.io/github/go-mod/go-version/nginx/nginx-loadbalancer-kubernetes?logo=go)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/nginx/nginx-loadbalancer-kubernetes/badge)](https://api.securityscorecards.dev/projects/github.com/nginx/nginx-loadbalancer-kubernetes)
[![CodeQL](https://github.com/nginx/nginx-loadbalancer-kubernetes/workflows/codeql.yml/badge.svg?branch=main&event=push)](https://github.com/nginx/nginx-loadbalancer-kubernetes/actions/codeql.yml)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fnginx%2Fnginx-loadbalancer-kubernetes.svg?type=shield)](/git%2Bgithub.com%2Fnginx%2Fnginx-loadbalancer-kubernetes?ref=badge_shield)
[![Community Support](https://badgen.net/badge/support/community/cyan?icon=awesome)](https://github.com/nginx/nginx-loadbalancer-kubernetes/discussions)
[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)

# nginx-loadbalancer-kubernetes

## Welcome to the NGINX LoadBalancer for Kubernetes Solution

![Nginx K8s LB](docs/media/nlk-logo.png) | ![Nginx K8s LB](docs/media/nginx-2020.png)
--- | ---

This repo contains source code and documents for a `Kubernetes Controller from NGINX`, that provides TCP and HTTP load balancing external to a Kubernetes cluster. The primary supported use case is for NGINXaaS for Azure's [Load Balancer for Kubernetes](https://docs.nginx.com/nginxaas/azure/loadbalancer-kubernetes/), where users integrate an Azure Kubernetes Service service with an NGINXaaS deployment. It should also be possible to use this controller to integrate an on-prem Kubernetes cluster with one or many NGINX plus instances.

## Overview

- `NLK - NGINX Loadbalancer for Kubernetes` is a Kubernetes controller from NGINX that monitors specified Kubernetes services, and then sends API calls to an external NGINX Plus server to manage NGINX Upstream servers dynamically.
- This will `synchronize` the Kubernetes service's endpoints with the NGINX server's upstream list.
- One use case is to track the`NodePort` IP:Port definitions for the NGINX Ingress Controller's `nginx-ingress Service`.
- NLK is a native Kubernetes controller, running, configured and managed with standard Kubernetes commands.
- When NLK is paired with the NGINX Plus Server located external to the Kubernetes cluster, this controller will provide a `TCP Load Balancer Service` to the Kubernetes clusters.
- NLK paired with the NGINX Plus Server located external to the Cluster, using NGINX's advanced HTTP features, provides an `HTTP Load Balancer Service` for enterprise traffic management solutions, such as:
  - MultiCluster Active/Active Load Balancing
  - Horizontal Cluster Scaling
  - HTTP Split Clients - for A/B, Blue/Green, and Canary test and production traffic steering.  Allows Cluster operations/maintainence like upgrades, patching, expansion and troubleshooting with no downtime or reloads
  - Advanced TLS Processing - MutualTLS, OCSP, FIPS, dynamic cert loading
  - Advanced Security features - Oauth, JWT, App Protect WAF Firewall, Rate and Bandwidth limits
  - NGINX Java Script (NJS) for custom solutions
  - NGINX Zone Sync of KeyVal data

## NLK Controller Software Design Overview - How it works

[NLK Controller DESIGN and Architecture](docs/DESIGN.md)

## Development

Read the [`CONTRIBUTING.md`](https://github.com/nginx/nginx-loadbalancer-kubernetes/blob/main/CONTRIBUTING.md) file.

## Authors

- Chris Akker - Solutions Architect - Community and Alliances @ F5, Inc.
- Steve Wagner - Solutions Architect - Community and Alliances @ F5, Inc.

## License

[Apache License, Version 2.0](https://github.com/nginx/nginx-loadbalancer-kubernetes/blob/main/LICENSE)

&copy; [F5 Networks, Inc.](https://www.f5.com/) 2023
