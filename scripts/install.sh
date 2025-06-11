#!/bin/bash

# Source the common library
source "$(dirname "$0")/library.sh"

say "Installing knative v1.18.1 crds..."
kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.18.1/eventing-crds.yaml

say "Installing knative v1.18.1 core..."
kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.18.1/eventing-core.yaml

say "Installing knative v1.18.1 in-memory channel..."
kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.18.1/in-memory-channel.yaml

say "Installing knative v1.18.1 mt-channel-broker..."
kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.18.1/mt-channel-broker.yaml

say_success "Knative Eventing installation completed!"


