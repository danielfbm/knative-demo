#!/bin/sh

function say () {
    echo "==> $1"
}

say "Installing cert-manager v1.17.2..."

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.2/cert-manager.yaml

