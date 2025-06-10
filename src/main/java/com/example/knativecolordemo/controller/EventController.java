package com.example.knativecolordemo.controller;

import com.example.knativecolordemo.model.CloudEventRecord;
import com.example.knativecolordemo.service.CloudEventService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/events")
@CrossOrigin(origins = "*")
public class EventController {

    @Autowired
    private CloudEventService cloudEventService;

    @GetMapping
    public ResponseEntity<List<CloudEventRecord>> getAllEvents() {
        List<CloudEventRecord> events = cloudEventService.getAllEvents();
        return ResponseEntity.ok(events);
    }
}
