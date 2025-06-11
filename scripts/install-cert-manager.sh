#!/bin/bash

# Source the common library
source "$(dirname "$0")/library.sh"

say "Installing cert-manager v1.17.2..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.2/cert-manager.yaml

say_success "cert-manager installation completed!"

