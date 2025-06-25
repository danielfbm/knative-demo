package com.example.knativecolordemo.service;

import com.example.knativecolordemo.model.CloudEventRecord;
import com.example.knativecolordemo.repository.CloudEventRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.ZonedDateTime;
import java.util.List;

@Service
public class CloudEventService {

    @Autowired
    private CloudEventRepository cloudEventRepository;

    public CloudEventRecord saveCloudEvent(String eventId, String eventType, String source,
                                         ZonedDateTime timestamp, String data, String subject) {
        CloudEventRecord record = new CloudEventRecord(eventId, eventType, source, timestamp, data, subject);
        return cloudEventRepository.save(record);
    }

    public List<CloudEventRecord> getAllEvents() {
        return cloudEventRepository.findAllOrderByTimestampDesc();
    }
}
