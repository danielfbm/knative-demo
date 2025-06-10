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

1. **Build and deploy:**
   ```bash
   ./deploy.sh
   ```

2. **Send test CloudEvents:**
   ```bash
   # Get the service URL
   SERVICE_URL=$(kubectl get ksvc color-demo-app -n knative-demo -o jsonpath='{.status.url}')

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
src/main/java/com/example/knativecolordemo/
├── KnativeColorDemoApplication.java    # Main Spring Boot application
├── controller/
│   ├── ColorController.java            # Color REST API
│   ├── EventController.java            # Events REST API
│   ├── CloudEventSinkController.java   # CloudEvents sink
│   └── WebController.java              # Web UI controller
├── model/
│   ├── ColorChange.java                # Color change entity
│   └── CloudEventRecord.java           # CloudEvent record entity
├── repository/
│   ├── ColorChangeRepository.java      # Color change data access
│   └── CloudEventRepository.java       # CloudEvent data access
└── service/
    ├── ColorService.java               # Color business logic
    └── CloudEventService.java          # CloudEvent business logic

src/main/resources/
├── application.properties              # Spring Boot configuration
├── templates/
│   └── index.html                      # Main web UI
└── static/
    ├── css/style.css                   # UI styles
    └── js/app.js                       # Frontend JavaScript
```

### Database

Uses H2 in-memory database for simplicity. Data is stored in two tables:
- `color_changes` - Tracks color changes over time
- `cloud_events` - Stores all received CloudEvents

### Configuration Files

- `config/color-demo-service.yaml` - Knative Service definition
- `config/color-change-trigger.yaml` - Knative Trigger for color events
- `config/color-event-sender.yaml` - Test event sender (optional)

## Monitoring

- **Timeline**: Visual representation of color changes over time
- **Events Panel**: Real-time list of received CloudEvents
- **Auto-refresh**: UI updates every 5 seconds automatically
- **Manual Refresh**: Ctrl+R or refresh buttons

## Troubleshooting

1. **Service not accessible**: Check Knative serving installation and service status
2. **Events not received**: Verify broker configuration and trigger setup
3. **UI not loading**: Check if static resources are properly served
4. **Database issues**: H2 console available at `/h2-console` (dev only)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally and in Knative
5. Submit a pull request
