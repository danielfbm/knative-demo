package com.example.eventconsumer;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
public class EventTriggerController {

    @Autowired
    private EventPublisherService eventPublisherService;

    @PostMapping("/users")
    public ResponseEntity<String> createUser(@RequestBody CreateUserRequest request) {
        // Simulate user creation logic
        String userId = "user-" + System.currentTimeMillis();

        // Publish user created event
        eventPublisherService.publishUserCreatedEvent(userId, request.getEmail());

        return ResponseEntity.ok("User created with ID: " + userId);
    }

    @PostMapping("/orders")
    public ResponseEntity<String> placeOrder(@RequestBody CreateOrderRequest request) {
        // Simulate order placement logic
        String orderId = "order-" + System.currentTimeMillis();

        // Publish order placed event
        eventPublisherService.publishOrderPlacedEvent(orderId, request.getCustomerId(), request.getAmount());

        return ResponseEntity.ok("Order placed with ID: " + orderId);
    }

    public static class CreateUserRequest {
        private String email;

        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
    }

    public static class CreateOrderRequest {
        private String customerId;
        private double amount;

        public String getCustomerId() { return customerId; }
        public void setCustomerId(String customerId) { this.customerId = customerId; }
        public double getAmount() { return amount; }
        public void setAmount(double amount) { this.amount = amount; }
    }
}
