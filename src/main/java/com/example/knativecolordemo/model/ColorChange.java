package com.example.knativecolordemo.model;

import jakarta.persistence.*;
import java.time.ZonedDateTime;

@Entity
@Table(name = "color_changes")
public class ColorChange {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Color color;

    @Column(nullable = false)
    private ZonedDateTime timestamp;

    @Column
    private String source;

    public ColorChange() {}

    public ColorChange(Color color, ZonedDateTime timestamp, String source) {
        this.color = color;
        this.timestamp = timestamp;
        this.source = source;
    }

    // Getters and setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Color getColor() { return color; }
    public void setColor(Color color) { this.color = color; }

    public ZonedDateTime getTimestamp() { return timestamp; }
    public void setTimestamp(ZonedDateTime timestamp) { this.timestamp = timestamp; }

    public String getSource() { return source; }
    public void setSource(String source) { this.source = source; }

    public enum Color {
        RED, GREEN, BLUE, YELLOW, PURPLE, ORANGE, BLACK, WHITE
    }
}
