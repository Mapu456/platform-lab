package com.platformlab.jobapi;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/jobs")
public class JobController {

    // Simulates an in-flight request with a configurable delay —
    // useful for Week 1: send a long-running request, then SIGTERM the process
    // and observe whether it completes or is dropped.
    @PostMapping
    public Map<String, String> submit(@RequestBody Map<String, Object> payload) throws InterruptedException {
        int delayMs = payload.containsKey("delayMs")
                ? Integer.parseInt(payload.get("delayMs").toString())
                : 0;
        if (delayMs > 0) {
            Thread.sleep(delayMs);
        }
        return Map.of("jobId", UUID.randomUUID().toString(), "status", "accepted");
    }

    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of("status", "up");
    }
}
