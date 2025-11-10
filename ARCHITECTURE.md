# Pra Analysis - System Architecture

## Overview

Pra Analysis is an AI-powered image authenticity analysis system that combines computer vision, deep learning, and forensics techniques to detect manipulated images.

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         Client Layer                             │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │   Next.js Frontend (Port 3000)                            │  │
│  │   - App Router (SSR/SSG)                                  │  │
│  │   - React Components (Shadcn UI)                          │  │
│  │   - Tailwind CSS                                          │  │
│  └──────────────────────────────────────────────────────────┘  │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTP/REST API
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│                      API Gateway Layer                           │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │   FastAPI Backend (Port 8000)                             │  │
│  │   - REST API Endpoints                                    │  │
│  │   - Request Validation (Pydantic)                         │  │
│  │   - Authentication & Authorization                        │  │
│  │   - API Documentation (/docs)                             │  │
│  └──────────────────────────────────────────────────────────┘  │
└──────────────┬──────────────────────────┬──────────────────────┘
               │                          │
               ↓                          ↓
┌──────────────────────────┐   ┌─────────────────────────────────┐
│   Business Logic Layer   │   │     ML Inference Layer          │
│  ┌────────────────────┐  │   │  ┌──────────────────────────┐  │
│  │  Services          │  │   │  │  NVIDIA Triton           │  │
│  │  - Database        │  │   │  │  (Port 8001)             │  │
│  │  - MinIO Client    │  │   │  │  - Preprocessing         │  │
│  │  - Training        │  │   │  │  - Detection Models      │  │
│  │  - Retraining      │  │   │  │  - Classification        │  │
│  └────────────────────┘  │   │  │  - Embedding             │  │
└──────────┬───────────────┘   │  └──────────────────────────┘  │
           │                   │  Mock Mode (CPU Development)   │
           ↓                   └─────────────────────────────────┘
┌─────────────────────────────────────────────────────────────────┐
│                       Data Layer                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │ PostgreSQL   │  │   MinIO      │  │      Qdrant          │  │
│  │ (Port 5432)  │  │ (Port 9000)  │  │    (Port 6333)       │  │
│  │              │  │              │  │                      │  │
│  │ - Metadata   │  │ - Images     │  │ - Vector Embeddings  │  │
│  │ - Analysis   │  │ - Models     │  │ - Similarity Search  │  │
│  │ - Users      │  │ - Datasets   │  │                      │  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Frontend Layer (Next.js)

**Technology Stack:**
- Next.js 14 with App Router
- React 18
- TypeScript
- Shadcn UI + Radix UI
- Tailwind CSS
- nuqs (URL state management)

**Key Features:**
- Server-Side Rendering (SSR)
- Static Site Generation (SSG)
- Client-side interactivity where needed
- Responsive design (mobile-first)
- Optimized asset loading

**Directory Structure:**
```
web-next/
├── app/                    # App Router pages
│   ├── layout.tsx         # Root layout
│   ├── page.tsx           # Home page
│   ├── analyze/           # Analysis page
│   └── admin/             # Admin dashboard
├── components/            # React components
│   ├── ui/               # Shadcn UI components
│   └── navigation.tsx    # Navigation components
└── lib/                  # Utilities
    ├── api.ts           # API client
    └── utils.ts         # Helper functions
```

### 2. API Gateway Layer (FastAPI)

**Technology Stack:**
- FastAPI 0.115+
- Pydantic 2.9+
- Uvicorn (ASGI server)
- Python 3.11+

**Responsibilities:**
- HTTP request handling
- Input validation
- Authentication & authorization
- Rate limiting
- CORS handling
- API documentation generation

**API Endpoints:**

```
/                          # API info
/health                    # Health check
/docs                      # Interactive API docs

/api/v1/analyze           # Image analysis
/api/v1/models            # Model management
/api/v1/training          # Model training
/api/v1/retraining        # Model retraining
/api/v1/feedback          # User feedback
/api/v1/labeling          # Data labeling
/api/v1/admin             # Admin operations
/api/v1/import            # Data import
```

**Directory Structure:**
```
amulet-ai-service/
├── main.py              # Application entry point
├── routes/              # API route handlers
│   ├── admin.py
│   ├── feedback.py
│   ├── import_route.py
│   ├── labeling.py
│   ├── models.py
│   ├── training.py
│   └── retraining.py
├── services/            # Business logic
│   ├── database.py
│   ├── minio_client.py
│   ├── training_service.py
│   └── retraining_service.py
├── models/              # Database models
│   └── database_models.py
└── schemas/             # Request/response schemas
    └── admin_schemas.py
```

### 3. Business Logic Layer (Services)

**Database Service:**
- SQLAlchemy ORM
- Connection pooling
- Transaction management
- Session management

**MinIO Service:**
- Object storage client
- Image upload/download
- Bucket management
- Presigned URL generation

**Training Service:**
- Model training orchestration
- Dataset preparation
- Training job management

**Retraining Service:**
- Continuous learning
- Model update pipeline
- Performance monitoring

### 4. ML Inference Layer (NVIDIA Triton)

**Technology Stack:**
- NVIDIA Triton Inference Server
- ONNX Runtime
- TensorRT (GPU mode)
- Mock implementation (CPU mode)

**Model Pipeline:**

```
Input Image
    ↓
[Preprocessing Model]
    ↓
[Detection Model]
    ↓
[Classification Model]
    ↓
[Embedding Model]
    ↓
Analysis Result
```

**Models:**
1. **Preprocessing**: Image normalization and augmentation
2. **Detector**: Manipulation detection (bounding boxes)
3. **Classifier**: Manipulation type classification
4. **Embedder**: Feature extraction for similarity search

**Directory Structure:**
```
ml/
├── inference/
│   └── triton_model_repo/
│       ├── preprocess/
│       ├── detector/
│       ├── classifier/
│       ├── embedder/
│       └── ensemble/
├── training/
│   ├── mmdet_config.py
│   └── openclip_head.py
├── forensics/
│   └── forensics_baseline.py
└── xai/
    └── gradcam_utils.py
```

### 5. Data Layer

#### PostgreSQL Database

**Schema:**
```sql
-- Core tables
images              # Image metadata
predictions         # Analysis results
users               # User accounts
datasets            # Training datasets
training_jobs       # Training job records
model_versions      # Model version tracking
feedback            # User feedback
labels              # Ground truth labels
```

**Relationships:**
- One image → many predictions
- One dataset → many images
- One training job → one model version
- One image → many labels

#### MinIO Object Storage

**Buckets:**
- `images` - Uploaded images
- `datasets` - Training datasets
- `models` - Model files
- `exports` - Export files

**Features:**
- S3-compatible API
- Versioning support
- Access control
- Presigned URLs

#### Qdrant Vector Database

**Collections:**
- `amulet_clip_v1` - Image embeddings

**Features:**
- HNSW index for fast similarity search
- Cosine similarity metric
- Filtering support
- Batch operations

**Vector Dimensions:** 768 (configurable)

## Data Flow

### Image Analysis Flow

```
1. User uploads image
   ↓
2. Frontend validates file
   ↓
3. POST /api/v1/analyze
   ↓
4. Backend validates request
   ↓
5. Store image in MinIO
   ↓
6. Create database record
   ↓
7. Send to Triton for inference
   ↓
8. Triton processes through pipeline
   ↓
9. Extract embeddings
   ↓
10. Store embeddings in Qdrant
    ↓
11. Search for similar images
    ↓
12. Create prediction record
    ↓
13. Return analysis result
    ↓
14. Frontend displays result
```

### Training Flow

```
1. Admin uploads dataset
   ↓
2. Store in MinIO
   ↓
3. Create dataset record
   ↓
4. Start training job
   ↓
5. Prepare training data
   ↓
6. Train model
   ↓
7. Validate model
   ↓
8. Save model to MinIO
   ↓
9. Create model version record
   ↓
10. Deploy to Triton (optional)
    ↓
11. Update model status
    ↓
12. Notify admin
```

### Continuous Learning Flow

```
1. User provides feedback
   ↓
2. Store feedback in database
   ↓
3. Aggregate feedback data
   ↓
4. Check retraining criteria
   ↓
5. Trigger retraining job
   ↓
6. Train updated model
   ↓
7. Validate performance
   ↓
8. Deploy if improved
   ↓
9. Update active model version
```

## Deployment Architecture

### Development (CPU Mode)

```yaml
services:
  - postgres:15-alpine
  - qdrant:latest
  - minio:latest
  - api (Python, mock Triton)
  - web (Next.js dev server)
```

**Command:** `.\make.ps1 up-cpu`

### Production (GPU Mode)

```yaml
services:
  - postgres:15-alpine
  - qdrant:latest
  - minio:latest
  - triton-server (GPU)
  - api (Python, real Triton)
  - web (Next.js production build)
  - nginx (reverse proxy)
```

**Command:** `.\make.ps1 up-gpu`

### Scaling Considerations

**Horizontal Scaling:**
- API servers: Load balanced
- Triton servers: Multiple instances with model repository sharing
- Database: Read replicas

**Vertical Scaling:**
- GPU memory for Triton
- Database connections
- Worker processes

**Caching Strategy:**
- Redis for API responses
- CDN for static assets
- Qdrant for embedding cache

## Security Architecture

### Authentication & Authorization

```
User Request
    ↓
[JWT Token Validation]
    ↓
[Role-Based Access Control]
    ↓
[Resource Authorization]
    ↓
API Endpoint
```

**Roles:**
- `user` - Basic image analysis
- `admin` - Full system access
- `annotator` - Data labeling
- `trainer` - Model training

### Security Measures

1. **Input Validation**
   - Pydantic schemas
   - File type validation
   - Size limits

2. **SQL Injection Prevention**
   - SQLAlchemy ORM
   - Parameterized queries

3. **XSS Prevention**
   - Input sanitization
   - Content Security Policy

4. **File Upload Security**
   - MIME type validation
   - Virus scanning (optional)
   - Isolated storage

5. **Rate Limiting**
   - Per-user limits
   - Per-IP limits
   - Endpoint-specific limits

6. **CORS Configuration**
   - Whitelist origins
   - Credential handling
   - Method restrictions

## Monitoring & Observability

### Metrics to Track

**Application Metrics:**
- Request rate
- Response time
- Error rate
- Active users

**Business Metrics:**
- Images analyzed
- Accuracy metrics
- User feedback
- Model performance

**Infrastructure Metrics:**
- CPU usage
- Memory usage
- Disk I/O
- Network traffic

**ML Metrics:**
- Inference latency
- Model accuracy
- Prediction confidence
- Embedding quality

### Logging Strategy

**Log Levels:**
- DEBUG: Development debugging
- INFO: Application events
- WARNING: Potential issues
- ERROR: Error conditions
- CRITICAL: System failures

**Structured Logging:**
```python
import structlog

logger = structlog.get_logger()
logger.info("image_analyzed", 
    image_id=image_id,
    verdict=verdict,
    score=score,
    processing_time=elapsed)
```

### Health Checks

```
/health                 # Overall health
/health/database       # Database connection
/health/minio          # MinIO connection
/health/qdrant         # Qdrant connection
/health/triton         # Triton availability
```

## Performance Considerations

### Database Optimization

- Indexes on frequently queried columns
- Connection pooling
- Query optimization
- Pagination for large result sets

### API Optimization

- Async/await for I/O operations
- Response caching
- Compression (gzip)
- Rate limiting

### Frontend Optimization

- Server-side rendering
- Code splitting
- Image optimization (WebP, lazy loading)
- CDN for static assets

### ML Inference Optimization

- Model quantization
- Batch inference
- Model caching
- GPU memory management

## Disaster Recovery

### Backup Strategy

**PostgreSQL:**
- Daily full backups
- Point-in-time recovery
- Backup retention: 30 days

**MinIO:**
- Replication to backup storage
- Versioning enabled
- Lifecycle policies

**Qdrant:**
- Snapshot backups
- Collection exports

### Recovery Procedures

1. **Database Recovery**
   - Restore from backup
   - Apply transaction logs
   - Verify data integrity

2. **Object Storage Recovery**
   - Restore from replicas
   - Verify checksums
   - Rebuild indexes

3. **Vector Database Recovery**
   - Restore snapshots
   - Rebuild indexes
   - Re-embed missing data

## Technology Choices & Rationale

### Why FastAPI?
- Modern, fast async framework
- Automatic API documentation
- Built-in validation (Pydantic)
- Type hints support
- Easy testing

### Why Next.js?
- React framework with SSR
- Excellent performance
- Great developer experience
- Built-in optimization
- Active community

### Why PostgreSQL?
- Robust and reliable
- JSON support
- Full-text search
- Excellent ecosystem
- ACID compliance

### Why Qdrant?
- Purpose-built for vectors
- Fast similarity search
- Filtering capabilities
- Easy deployment
- Good documentation

### Why MinIO?
- S3-compatible API
- Self-hosted solution
- High performance
- Easy to deploy
- Cost effective

### Why NVIDIA Triton?
- Multi-framework support
- GPU optimization
- Dynamic batching
- Model versioning
- Production-ready

## Future Enhancements

### Planned Features

1. **Real-time Processing**
   - WebSocket support
   - Streaming analysis
   - Live updates

2. **Enhanced ML Capabilities**
   - More detection models
   - Ensemble methods
   - Active learning

3. **Collaboration Features**
   - Team workspaces
   - Shared datasets
   - Annotation tools

4. **Advanced Analytics**
   - Dashboard visualizations
   - Trend analysis
   - Report generation

5. **API Enhancements**
   - GraphQL support
   - Webhook notifications
   - Batch operations

### Scalability Roadmap

1. **Phase 1: Current State**
   - Single server deployment
   - Local testing

2. **Phase 2: Horizontal Scaling**
   - Load balancer
   - Multiple API servers
   - Database read replicas

3. **Phase 3: Microservices**
   - Service decomposition
   - Message queue
   - Event-driven architecture

4. **Phase 4: Cloud Native**
   - Kubernetes deployment
   - Auto-scaling
   - Multi-region support

---

**Last Updated:** November 2025  
**Version:** 1.0.0

