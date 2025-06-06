
function say () {
    echo "==> $1"
}

say "Installing knative v1.18.1 crds..."
kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.18.1/eventing-crds.yaml

say "Installing knative v1.18.1 core..."
kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.18.1/eventing-core.yaml

say "Installing knative v1.18.1 in-memory channel..."
kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.18.1/in-memory-channel.yaml

say "Installing knative v1.18.1 mt-channel-broker..."
kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.18.1/mt-channel-broker.yaml

