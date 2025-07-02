# nginx-loadbalancer-kubernetes

## Welcome to the NGINX LoadBalancer for Kubernetes Solution

![Nginx K8s LB](media/nlk-logo.png) | ![Nginx K8s LB](media/nginx-2020.png)
--- | ---

This repo contains source code and documents for a `Kubernetes Controller from NGINX`, that provides TCP and HTTP load balancing external to a Kubernetes cluster running on premises.

>>**This is a replacement for a cloud provider's `Service Type Loadbalancer`, that is not available for on premises Kubernetes clusters.**

## Overview

- `NLK - NGINX Loadbalancer for Kubernetes` is a Kubernetes controller from NGINX that monitors specified Kubernetes services, and then sends API calls to an external NGINX Plus server to manage NGINX Upstream servers dynamically.
- This will `synchronize` the Kubernetes service's endpoints with the NGINX server's upstream list.
- One use case is to track the`NodePort` IP:Port definitions for the NGINX Ingress Controller's `nginx-ingress Service`.
- NLK is a native Kubernetes controller, running, configured and managed with standard Kubernetes commands.
- When NLK is paired with the NGINX Plus Server located external to the Kubernetes cluster, this controller will provide a `TCP Load Balancer Service` for on premises Kubernetes clusters, which do not have access to a cloud provider's "Service Type LoadBalancer".
- NLK paired with the NGINX Plus Server located external to the Cluster, using NGINX's advanced HTTP features, provides an `HTTP Load Balancer Service` for enterprise traffic management solutions, such as:
  - MultiCluster Active/Active Load Balancing
  - Horizontal Cluster Scaling
  - HTTP Split Clients - for A/B, Blue/Green, and Canary test and production traffic steering.  Allows Cluster operations/maintainence like upgrades, patching, expansion and troubleshooting with no downtime or reloads
  - Advanced TLS Processing - MutualTLS, OCSP, FIPS, dynamic cert loading
  - Advanced Security features - Oauth, JWT, App Protect WAF Firewall, Rate and Bandwidth limits
  - NGINX Java Script (NJS) for custom solutions
  - NGINX Zone Sync of KeyVal data

## NLK Controller Software Design Overview - How it works

[NLK Controller DESIGN and Architecture](DESIGN.md)

## Reference Diagram for NLK TCP Load Balancer Service

![NLK Stream Diagram](media/nlk-blog-diagram-v1.png)

## Sample Screenshots of Solution at Runtime

![NGINX LB ConfigMap](media/nlk-configmap.png)

### ConfigMap with 2 NGINX LB Servers defined for HA

![NGINX LB Create Nodeport](media/nlk-stream-create-nodeport.png)

### NGINX LB Server Dashboard, NodePort, and NLK Controller Logging

### Legend

- Red - kubectl nodeport commands
- Blue - nodeport and upstreams for http traffic
- Indigo - nodeport and upstreams for https traffic
- Green - NLK log for api calls to LB Server #1
- Orange - NGINX LB Server upstream dashboard details
- Kubernetes Worker Nodes are 10.1.1.8 and 10.1.1.10

The `Installation Guide` for TCP Loadbalancer Solution is located in the tcp folder:

[TCP Installation Guide](tcp/tcp-installation-guide.md)

The `Installation Guide` for HTTP Loadbalancer Solution is located in the http folder:

[HTTP Installation Guide](http/http-installation-guide.md)

## Requirements

Please see the /docs folder and Installation Guides for detailed documentation.

## Development

Read the [`CONTRIBUTING.md`](https://github.com/nginxinc/nginx-loadbalancer-kubernetes/blob/main/CONTRIBUTING.md) file.

## Authors

- Chris Akker - Solutions Architect - Community and Alliances @ F5, Inc.
- Steve Wagner - Solutions Architect - Community and Alliances @ F5, Inc.

## License

[Apache License, Version 2.0](https://github.com/nginxinc/nginx-loadbalancer-kubernetes/blob/main/LICENSE)

&copy; [F5 Networks, Inc.](https://www.f5.com/) 2023
