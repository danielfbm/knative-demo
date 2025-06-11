# Knative Color Demo

A Spring Boot application that demonstrates Knative eventing capabilities with a color timeline and CloudEvents integration.

## Features

- **Color Timeline UI**: Visual timeline showing color changes over time
- **CloudEvents Sink**: Receives color change events from Knative eventing
- **REST APIs**:
  - `/api/colors/current` - Get current color with timestamp
  - `/api/colors/history` - Get color change history
  - `/api/events` - List all received CloudEvents
- **Manual Color Control**: Web UI for manually changing colors
- **Real-time Updates**: Auto-refreshing timeline and event list

## Supported Colors

- RED, GREEN, BLUE, YELLOW, PURPLE, ORANGE, BLACK, WHITE

## Platform Compatibility

This application supports multiple deployment scenarios:

- **Knative Serving + Eventing**: Full featured deployment with auto-scaling and event-driven architecture
- **Knative Serving only**: Serverless deployment without eventing (manual color changes only)
- **Standard Kubernetes**: Traditional deployment with port-forwarding for local access
- **Local Development**: Spring Boot application with embedded H2 database

The deployment scripts automatically detect available platform features and adapt accordingly.

## Quick Start

### Prerequisites

- Java 17+
- Maven 3.6+
- Docker
- Kubernetes cluster with Knative installed
- kubectl configured

### Local Development

1. **Build and run locally:**
   ```bash
   ./mvnw spring-boot:run
   ```

2. **Access the application:**
   - Open http://localhost:8080 in your browser
   - Use the timeline to see color changes
   - Use the manual controls to change colors
   - Monitor received CloudEvents on the right panel

### Deploy to Knative

1. **Install Knative components (if needed):**
   ```bash
   ./scripts/install-cert-manager.sh
   ./scripts/install.sh
   ```

2. **Deploy the application:**
   ```bash
   # Quick deployment (requires Knative Serving)
   ./scripts/deploy.sh

   # Smart deployment (adapts to available platform)
   ./scripts/deploy-k8s.sh

   # Complete deployment with full monitoring
   ./scripts/deploy-complete.sh
   ```

3. **Test the deployment:**
   ```bash
   # Basic CloudEvents testing
   ./scripts/test-cloudevents.sh

   # Comprehensive test suite
   ./scripts/test-complete.sh
   ```

4. **Send test CloudEvents:**
   ```bash
   # Get the service URL (for Knative)
   SERVICE_URL=$(kubectl get ksvc color-demo-app -n eventing-demo -o jsonpath='{.status.url}')

   # Or use localhost for standard K8s deployment
   SERVICE_URL="http://localhost:8080"

   # Send a color change event
   curl -X POST ${SERVICE_URL}/cloudevents \
     -H 'Content-Type: application/json' \
     -H 'Ce-Id: test-123' \
     -H 'Ce-Source: manual-test' \
     -H 'Ce-Type: com.example.color.change' \
     -H 'Ce-Specversion: 1.0' \
     -d '{"color": "BLUE"}'
   ```

## CloudEvent Format

The application expects CloudEvents with the following format:

```json
{
  "specversion": "1.0",
  "type": "com.example.color.change",
  "source": "your-source",
  "id": "unique-id",
  "data": {
    "color": "RED"
  }
}
```

## API Endpoints

### Color APIs
- `GET /api/colors/current` - Current color and timestamp
- `GET /api/colors/history` - All color changes (newest first)
- `GET /api/colors/available` - List of supported colors
- `POST /api/colors/set` - Manually set color

### Event APIs
- `GET /api/events` - All received CloudEvents (newest first)

### CloudEvents Sink
- `POST /cloudevents` - Knative CloudEvents sink endpoint
- `GET /cloudevents/health` - Health check for Knative

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Event Source  │───▶│  Knative Broker │───▶│  Color Demo App │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                               ┌─────────────────┐
                                               │   Web Browser   │
                                               │  (Timeline UI)  │
                                               └─────────────────┘
```

## Development

### Project Structure

```
knative-demo/
├── README.md                           # This file
├── IMPLEMENTATION_SUMMARY.md           # Technical implementation details
├── K8S_DEPLOYMENT.md                   # Kubernetes deployment guide
├── Dockerfile                          # Container build configuration
├── pom.xml                            # Maven build configuration
├── mvnw / mvnw.cmd                    # Maven wrapper scripts
│
├── src/                               # Source code
│   └── main/
│       ├── java/com/example/knativecolordemo/
│       │   ├── KnativeColorDemoApplication.java    # Main Spring Boot application
│       │   ├── controller/
│       │   │   ├── ColorController.java            # Color REST API
│       │   │   ├── EventController.java            # Events REST API
│       │   │   ├── CloudEventSinkController.java   # CloudEvents sink
│       │   │   └── WebController.java              # Web UI controller
│       │   ├── model/
│       │   │   ├── ColorChange.java                # Color change entity
│       │   │   └── CloudEventRecord.java           # CloudEvent record entity
│       │   ├── repository/
│       │   │   ├── ColorChangeRepository.java      # Color change data access
│       │   │   └── CloudEventRepository.java       # CloudEvent data access
│       │   └── service/
│       │       ├── ColorService.java               # Color business logic
│       │       └── CloudEventService.java          # CloudEvent business logic
│       └── resources/
│           ├── application.properties              # Spring Boot configuration
│           ├── templates/
│           │   └── index.html                      # Main web UI template
│           └── static/
│               ├── css/style.css                   # UI styles
│               └── js/app.js                       # Frontend JavaScript
│
├── config/                            # Kubernetes manifests
│   ├── namespace.yaml                 # Namespace definition
│   ├── broker.yaml                    # Knative Broker configuration
│   ├── auth/                          # RBAC configurations
│   │   ├── sa.yaml                    # Service Account
│   │   ├── role.yaml                  # Role definition
│   │   └── rolebinding.yaml           # Role binding
│   ├── colors/                        # Color demo specific configs
│   │   ├── color-change-trigger.yaml  # Knative Trigger for color events
│   │   ├── color-event-producer.yaml  # Test event producer
│   │   ├── k8s-deployment.yaml        # Standard Kubernetes deployment
│   │   └── serving/
│   │       └── color-demo-service.yaml # Knative Service definition
│   ├── cloudevents-player/            # CloudEvents testing tool
│   │   ├── cloudevents-player.yaml    # CloudEvents Player deployment
│   │   └── trigger.yaml               # Trigger for CloudEvents Player
│   └── eventdisplay/                  # Event display utility
│       ├── event-display.yaml         # Event display deployment
│       └── trigger.yaml               # Event display trigger
│
└── scripts/                           # Deployment and testing scripts
    ├── README.md                      # Scripts documentation
    ├── library.sh                     # Common functions library
    ├── install-cert-manager.sh        # Install cert-manager
    ├── install.sh                     # Install Knative Eventing
    ├── deploy.sh                      # Basic Knative deployment
    ├── deploy-k8s.sh                  # Smart deployment (Knative or K8s)
    ├── deploy-complete.sh             # Complete deployment with monitoring
    ├── test-cloudevents.sh            # Basic CloudEvents testing
    └── test-complete.sh               # Comprehensive test suite
```

### Database

Uses H2 in-memory database for simplicity. Data is stored in two tables:
- `color_changes` - Tracks color changes over time
- `cloud_events` - Stores all received CloudEvents

### Scripts Organization

All deployment and testing scripts are located in the `scripts/` directory and use a common library (`library.sh`) for shared functionality:

- **Installation Scripts**: Install Knative components and dependencies
- **Deployment Scripts**: Deploy the application with different strategies
- **Testing Scripts**: Test CloudEvents functionality and endpoints
- **Library Functions**: Common utilities for path resolution, Kubernetes operations, and colored output

See `scripts/README.md` for detailed documentation on each script.

### Configuration Files

The `config/` directory contains all Kubernetes manifests organized by function:

- **Core**: namespace, broker, and RBAC configurations
- **Application**: Knative Service and standard Kubernetes deployments
- **Events**: Triggers and event producers for testing
- **Testing Tools**: CloudEvents Player and Event Display utilities

## Monitoring

- **Timeline**: Visual representation of color changes over time
- **Events Panel**: Real-time list of received CloudEvents
- **Auto-refresh**: UI updates every 5 seconds automatically
- **Manual Refresh**: Ctrl+R or refresh buttons

## Testing Tools

### CloudEvents Player

The project includes configuration for the [CloudEvents Player](https://github.com/ruromero/cloudevents-player), a useful tool for testing CloudEvents:

```bash
# Deploy CloudEvents Player
kubectl apply -f config/cloudevents-player/

# Access via port-forward
kubectl port-forward -n eventing-demo service/cloudevents-player 8081:80

# Open http://localhost:8081 to use the web interface
```

### Event Display

For debugging CloudEvents, you can deploy the event display utility:

```bash
# Deploy Event Display
kubectl apply -f config/eventdisplay/

# View logs to see all events
kubectl logs -l app=event-display -n eventing-demo -f
```

### Manual Testing

The `test-complete.sh` script provides comprehensive testing of all endpoints and functionality:

- Health checks
- API endpoint validation
- CloudEvent sending and verification
- Color change validation
- Event recording verification

## Troubleshooting

1. **Service not accessible**:
   - Check Knative serving installation: `kubectl get pods -n knative-serving`
   - Verify service status: `kubectl get ksvc -n eventing-demo`
   - For standard K8s: Check port-forwarding is active

2. **Events not received**:
   - Verify broker configuration: `kubectl get brokers -n eventing-demo`
   - Check trigger setup: `kubectl get triggers -n eventing-demo`
   - Test with CloudEvents Player for debugging

3. **UI not loading**:
   - Check if static resources are properly served
   - Verify application is running: `curl http://localhost:8080/cloudevents/health`

4. **Database issues**:
   - H2 console available at `/h2-console` (dev only)
   - Check application logs for SQL errors

5. **Scripts not working**:
   - Ensure all scripts are executable: `chmod +x scripts/*.sh`
   - Check that kubectl is configured correctly
   - Verify Docker is running (for image builds)

### Common Commands

```bash
# Check application status
kubectl get all -n eventing-demo

# View application logs
kubectl logs -l app=color-demo-app -n eventing-demo -f

# Test health endpoint
curl http://localhost:8080/cloudevents/health

# Send manual CloudEvent
./scripts/test-cloudevents.sh

# Run comprehensive tests
./scripts/test-complete.sh
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally and in Knative
5. Submit a pull request
