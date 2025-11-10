# Performance Testing Guide

## Performance Requirements

### API Performance Targets
- **Health Check Endpoint**: < 50ms
- **List Endpoints** (datasets, models, etc.): < 200ms
- **Single Record GET**: < 100ms
- **Image Analysis**: < 5 seconds
- **Database Queries**: < 100ms (simple), < 500ms (complex joins)

### Frontend Performance Targets
- **Page Load Time**: < 2 seconds
- **Time to Interactive (TTI)**: < 3 seconds
- **Largest Contentful Paint (LCP)**: < 2.5s
- **First Input Delay (FID)**: < 100ms
- **Cumulative Layout Shift (CLS)**: < 0.1

### Concurrent Users
- Minimum: 10 concurrent users
- Target: 50 concurrent users
- Maximum: 100 concurrent users

## Load Testing with Locust

### Installation

```bash
pip install locust
```

### Locust Test Script

Create `locustfile.py`:

```python
from locust import HttpUser, task, between
import random
import json
from io import BytesIO

class PraAnalysisUser(HttpUser):
    wait_time = between(1, 3)
    
    def on_start(self):
        """Setup for each user"""
        # Create a test dataset
        response = self.client.post("/v1/admin/datasets", json={
            "name": f"Load Test Dataset {random.randint(1, 10000)}"
        })
        if response.status_code == 200:
            self.dataset_id = response.json()["id"]
        else:
            self.dataset_id = None
    
    @task(5)
    def health_check(self):
        """Test health endpoint - most frequent"""
        self.client.get("/health")
    
    @task(10)
    def list_datasets(self):
        """Test listing datasets"""
        self.client.get("/v1/admin/datasets?limit=20")
    
    @task(3)
    def get_dataset(self):
        """Test getting specific dataset"""
        if self.dataset_id:
            self.client.get(f"/v1/admin/datasets/{self.dataset_id}")
    
    @task(8)
    def labeling_queue(self):
        """Test labeling queue"""
        self.client.get("/v1/admin/labeling/queue?limit=10")
    
    @task(2)
    def list_training_jobs(self):
        """Test listing training jobs"""
        self.client.get("/v1/admin/training/jobs")
    
    @task(2)
    def list_models(self):
        """Test listing models"""
        self.client.get("/v1/admin/models")
    
    @task(1)
    def analyze_image(self):
        """Test image analysis - less frequent but important"""
        # Create a small test image
        from PIL import Image
        img = Image.new('RGB', (200, 200), color='red')
        img_bytes = BytesIO()
        img.save(img_bytes, format='JPEG')
        img_bytes.seek(0)
        
        files = {"file": ("test.jpg", img_bytes, "image/jpeg")}
        self.client.post("/v1/analyze", files=files)
```

### Running Load Tests

```bash
# Run with Web UI
locust -f locustfile.py --host=http://localhost:8000

# Run headless
locust -f locustfile.py --host=http://localhost:8000 --users 50 --spawn-rate 5 --run-time 5m --headless
```

### Performance Metrics to Collect

#### Request Metrics
- Total requests
- Requests per second (RPS)
- Response times (min, max, avg, median, 95th percentile, 99th percentile)
- Error rate
- Timeout rate

#### System Metrics
- CPU usage (%)
- Memory usage (MB)
- Database connections
- Disk I/O
- Network I/O

## Database Performance Testing

### Query Performance Test Script

```python
# apps/amulet-ai-service/tests/test_performance.py

import pytest
import time
from sqlalchemy.orm import Session
from apps.amulet_ai_service.models.database_models import Image, Dataset

@pytest.mark.performance
class TestDatabasePerformance:
    
    def test_list_images_with_1000_records(self, db_session: Session, sample_dataset):
        """Test query performance with 1000 images"""
        # Create 1000 images
        for i in range(1000):
            image = Image(
                source="upload",
                mime="image/jpeg",
                minio_path=f"test{i}.jpg",
                dataset_id=sample_dataset.id
            )
            db_session.add(image)
        db_session.commit()
        
        # Measure query time
        start = time.time()
        images = db_session.query(Image).filter(
            Image.dataset_id == sample_dataset.id
        ).limit(100).all()
        duration = time.time() - start
        
        assert len(images) == 100
        assert duration < 0.1  # Should complete in < 100ms
    
    def test_complex_join_query_performance(self, db_session: Session):
        """Test complex join query performance"""
        start = time.time()
        
        # Complex query joining multiple tables
        results = db_session.query(Image).join(
            Dataset
        ).filter(
            Dataset.status == "active"
        ).all()
        
        duration = time.time() - start
        
        # Should complete in reasonable time even with joins
        assert duration < 0.5
    
    def test_pagination_efficiency(self, db_session: Session, sample_dataset):
        """Test that pagination is efficient"""
        # Create 500 images
        for i in range(500):
            image = Image(
                source="upload",
                mime="image/jpeg",
                minio_path=f"test{i}.jpg",
                dataset_id=sample_dataset.id
            )
            db_session.add(image)
        db_session.commit()
        
        # Test different pagination offsets
        timings = []
        for skip in [0, 100, 200, 300, 400]:
            start = time.time()
            images = db_session.query(Image).offset(skip).limit(50).all()
            duration = time.time() - start
            timings.append(duration)
            assert len(images) == 50
        
        # All pagination queries should be similarly fast
        assert max(timings) < 0.15
        assert max(timings) / min(timings) < 3  # No query > 3x slower
```

## Frontend Performance Testing

### Lighthouse CI

Add to `package.json`:

```json
{
  "scripts": {
    "lighthouse": "lighthouse http://localhost:3000 --output=html --output-path=./lighthouse-report.html"
  }
}
```

### Web Vitals Monitoring

Add to Next.js app:

```typescript
// app/layout.tsx
import { Analytics } from '@vercel/analytics/react'

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <Analytics />
      </body>
    </html>
  )
}
```

### Bundle Size Analysis

```bash
# Add to package.json
"analyze": "ANALYZE=true next build"

# Install analyzer
npm install @next/bundle-analyzer
```

## Performance Test Execution Plan

### 1. Baseline Performance Test
- [ ] Run with 1 user
- [ ] Record all metrics
- [ ] Document baseline performance

### 2. Load Test - 10 Users
- [ ] Run with 10 concurrent users
- [ ] Monitor for 10 minutes
- [ ] Record metrics
- [ ] Check for errors

### 3. Load Test - 50 Users
- [ ] Run with 50 concurrent users
- [ ] Monitor for 10 minutes
- [ ] Record metrics
- [ ] Check for errors

### 4. Stress Test - 100 Users
- [ ] Run with 100 concurrent users
- [ ] Monitor for 10 minutes
- [ ] Record metrics
- [ ] Identify breaking point

### 5. Spike Test
- [ ] Gradually increase from 10 to 100 users
- [ ] Monitor system behavior
- [ ] Check recovery after spike

### 6. Endurance Test
- [ ] Run with 25 users for 1 hour
- [ ] Monitor for memory leaks
- [ ] Check database connection pool
- [ ] Verify no degradation over time

## Performance Optimization Checklist

### Backend Optimizations
- [ ] Database indexes created on frequently queried columns
- [ ] Database connection pooling configured
- [ ] Pagination implemented for all list endpoints
- [ ] N+1 query problems eliminated
- [ ] Heavy computations moved to background tasks
- [ ] Response caching implemented where appropriate
- [ ] Database query optimization (use EXPLAIN)
- [ ] Async operations used for I/O

### Frontend Optimizations
- [ ] Code splitting implemented
- [ ] Images lazy loaded
- [ ] Bundle size optimized (< 200KB initial)
- [ ] CDN used for static assets
- [ ] Server-side rendering for initial load
- [ ] Prefetching for navigation
- [ ] Memoization for expensive computations
- [ ] Debouncing for frequent operations

### Infrastructure Optimizations
- [ ] Load balancer configured
- [ ] Auto-scaling enabled
- [ ] CDN configured
- [ ] Database read replicas (if needed)
- [ ] Caching layer (Redis) implemented
- [ ] Asset compression enabled
- [ ] HTTP/2 enabled

## Performance Monitoring in Production

### Metrics to Monitor
1. **Request Latency**
   - p50, p95, p99 response times
   - By endpoint
   - By time of day

2. **Throughput**
   - Requests per second
   - By endpoint
   - Peak vs average

3. **Error Rate**
   - 4xx errors
   - 5xx errors
   - By endpoint

4. **Resource Usage**
   - CPU utilization
   - Memory usage
   - Disk usage
   - Network bandwidth

5. **Database Performance**
   - Query execution time
   - Connection pool usage
   - Lock waits
   - Cache hit rate

6. **User Experience**
   - Time to First Byte (TTFB)
   - First Contentful Paint (FCP)
   - Largest Contentful Paint (LCP)
   - Time to Interactive (TTI)
   - Total Blocking Time (TBT)
   - Cumulative Layout Shift (CLS)

### Tools
- **APM**: New Relic, Datadog, or Prometheus
- **Frontend**: Google Analytics, Vercel Analytics
- **Database**: pgAdmin, DataDog Database Monitoring
- **Logs**: ELK Stack, CloudWatch, Loki

## Performance Test Results Template

```
## Performance Test Results - [Date]

### Test Configuration
- Users: [number]
- Duration: [time]
- Ramp-up: [time]
- Environment: [staging/production]

### Results Summary
- Total Requests: [number]
- Successful: [number] ([percentage]%)
- Failed: [number] ([percentage]%)
- RPS: [number]

### Response Times
- Min: [time]ms
- Max: [time]ms
- Average: [time]ms
- Median: [time]ms
- 95th Percentile: [time]ms
- 99th Percentile: [time]ms

### By Endpoint
| Endpoint | Requests | Avg Time | p95 | p99 | Errors |
|----------|----------|----------|-----|-----|--------|
| /health | 1000 | 20ms | 30ms | 40ms | 0 |
| /v1/analyze | 100 | 2500ms | 4000ms | 5000ms | 1 |

### System Resources
- Average CPU: [percentage]%
- Peak CPU: [percentage]%
- Average Memory: [MB]
- Peak Memory: [MB]
- Database Connections: [number]

### Issues Found
1. [Issue description]
2. [Issue description]

### Recommendations
1. [Recommendation]
2. [Recommendation]

### Status
[ ] PASS - Meets all performance requirements
[ ] CONDITIONAL PASS - Meets most requirements with minor issues
[ ] FAIL - Does not meet performance requirements
```

