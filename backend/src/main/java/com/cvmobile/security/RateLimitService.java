package com.cvmobile.security;

import java.time.Duration;

public interface RateLimitService {
    RateLimitResult consume(String key, long capacity, Duration refillPeriod);
}
