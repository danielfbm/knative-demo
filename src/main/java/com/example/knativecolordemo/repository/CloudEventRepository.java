package com.example.knativecolordemo.repository;

import com.example.knativecolordemo.model.CloudEventRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CloudEventRepository extends JpaRepository<CloudEventRecord, Long> {

    @Query("SELECT c FROM CloudEventRecord c ORDER BY c.timestamp DESC")
    List<CloudEventRecord> findAllOrderByTimestampDesc();
}
