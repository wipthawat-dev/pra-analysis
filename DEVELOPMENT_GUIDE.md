# Development Guide - Pra Analysis

## Quick Start

### Prerequisites Checklist

- [ ] Python 3.11 or 3.12 installed
- [ ] Node.js 18+ installed
- [ ] Docker Desktop installed and running
- [ ] Git configured
- [ ] Code editor (VS Code/Cursor recommended)

### Initial Setup (5 minutes)

```powershell
# 1. Clone repository
git clone <repository-url>
cd pra-analysis

# 2. Copy environment file
Copy-Item .env.example .env

# 3. Start services
.\make.ps1 up-cpu

# 4. Initialize databases
.\make.ps1 qdrant-init
.\make.ps1 embed-index

# 5. Verify setup
curl http://localhost:8000/health
curl http://localhost:3000
```

## Development Environments

### Option 1: Docker Development (Recommended)

**Pros:**
- Consistent environment
- All services included
- Easy to start/stop
- Matches production

**Cons:**
- Slower startup
- Resource intensive
- Harder to debug

**Commands:**
```powershell
# Start all services
.\make.ps1 up-cpu

# View logs
.\make.ps1 logs

# Stop services
.\make.ps1 down
```

### Option 2: Local Development

**Pros:**
- Fast iteration
- Easy debugging
- Live reload
- Lower resource usage

**Cons:**
- Manual setup
- Service dependencies
- Platform differences

**Setup Backend:**
```powershell
cd apps\amulet-ai-service

# Create virtual environment
python -m venv venv

# Activate
.\venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt

# Run server
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

**Setup Frontend:**
```powershell
cd apps\web-next

# Install dependencies
npm install

# Run dev server
npm run dev
```

### Option 3: Hybrid Development

**Best for:** Frontend-focused or backend-focused work

**Backend in Docker, Frontend Local:**
```powershell
# Start backend services only
docker-compose -f docker-compose.cpu.yml up postgres qdrant minio api

# Run frontend locally
cd apps\web-next
npm run dev
```

**Frontend in Docker, Backend Local:**
```powershell
# Start infrastructure only
docker-compose -f docker-compose.cpu.yml up postgres qdrant minio

# Run backend locally
cd apps\amulet-ai-service
.\venv\Scripts\Activate.ps1
uvicorn main:app --reload
```

## Development Workflow

### Daily Workflow

```powershell
# Morning startup
git pull origin develop
.\make.ps1 up-cpu

# During development
# - Make changes
# - Test changes
# - Run tests frequently

# Before committing
.\make.ps1 fmt                    # Format code
pytest tests/ -v --no-cov         # Run tests
git add .
git commit -m "feat: description"

# End of day
.\make.ps1 down
```

### Feature Development Workflow

1. **Create Feature Branch**
```bash
git checkout develop
git pull
git checkout -b feature/my-feature
```

2. **Implement Feature**
- Write tests first (TDD)
- Implement functionality
- Update documentation
- Add examples

3. **Test Thoroughly**
```powershell
# Run all tests
pytest tests/ -v

# Run specific tests
pytest tests/test_my_feature.py -v

# Check coverage
pytest tests/ -v --cov
```

4. **Format and Lint**
```powershell
# Python
black .
ruff check .

# TypeScript
cd apps/web-next
npm run lint
npm run format
```

5. **Commit Changes**
```bash
git add .
git commit -m "feat(scope): clear description"
```

6. **Push and Create PR**
```bash
git push origin feature/my-feature
# Create PR on GitHub
```

## Common Development Tasks

### Adding a New API Endpoint

**1. Create Schema**
```python
# apps/amulet-ai-service/schemas/my_schemas.py
from pydantic import BaseModel

class MyRequest(BaseModel):
    name: str
    description: str | None = None

class MyResponse(BaseModel):
    id: int
    name: str
    created_at: str
```

**2. Create Service**
```python
# apps/amulet-ai-service/services/my_service.py
from sqlalchemy.orm import Session
from apps.amulet_ai_service.models.database_models import MyModel

def create_item(db: Session, name: str, description: str = None):
    item = MyModel(name=name, description=description)
    db.add(item)
    db.commit()
    db.refresh(item)
    return item
```

**3. Create Route**
```python
# apps/amulet-ai-service/routes/my_route.py
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from apps.amulet_ai_service.services.database import get_db
from apps.amulet_ai_service.schemas.my_schemas import MyRequest, MyResponse
from apps.amulet_ai_service.services.my_service import create_item

router = APIRouter(prefix="/api/v1/items", tags=["items"])

@router.post("/", response_model=MyResponse, status_code=201)
async def create_new_item(request: MyRequest, db: Session = Depends(get_db)):
    item = create_item(db, request.name, request.description)
    return item
```

**4. Register Router**
```python
# apps/amulet-ai-service/main.py
from apps.amulet_ai_service.routes import my_route

app.include_router(my_route.router)
```

**5. Write Tests**
```python
# apps/amulet-ai-service/tests/test_my_route.py
def test_create_item(client):
    response = client.post("/api/v1/items/", json={
        "name": "Test Item",
        "description": "Test Description"
    })
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Test Item"
```

**6. Test Manually**
```powershell
# Using curl
curl -X POST http://localhost:8000/api/v1/items/ `
  -H "Content-Type: application/json" `
  -d '{"name":"Test","description":"Test Desc"}'

# Or visit http://localhost:8000/docs
```

### Adding a New React Component

**1. Create Component**
```typescript
// apps/web-next/components/my-component.tsx
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"

interface MyComponentProps {
  title: string
  content: string
}

export function MyComponent({ title, content }: MyComponentProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>{title}</CardTitle>
      </CardHeader>
      <CardContent>
        <p>{content}</p>
      </CardContent>
    </Card>
  )
}
```

**2. Add Styling**
```typescript
// Use Tailwind classes
export function MyComponent({ title, content }: MyComponentProps) {
  return (
    <Card className="hover:shadow-lg transition-shadow">
      <CardHeader className="bg-primary/5">
        <CardTitle className="text-2xl font-bold">{title}</CardTitle>
      </CardHeader>
      <CardContent className="p-6">
        <p className="text-muted-foreground">{content}</p>
      </CardContent>
    </Card>
  )
}
```

**3. Write Tests**
```typescript
// apps/web-next/__tests__/components/my-component.test.tsx
import { render, screen } from "@testing-library/react"
import { MyComponent } from "@/components/my-component"

describe("MyComponent", () => {
  it("renders title and content", () => {
    render(<MyComponent title="Test Title" content="Test Content" />)
    
    expect(screen.getByText("Test Title")).toBeInTheDocument()
    expect(screen.getByText("Test Content")).toBeInTheDocument()
  })
})
```

**4. Use in Page**
```typescript
// apps/web-next/app/page.tsx
import { MyComponent } from "@/components/my-component"

export default function HomePage() {
  return (
    <div className="container mx-auto py-8">
      <MyComponent 
        title="Welcome" 
        content="This is my component" 
      />
    </div>
  )
}
```

### Working with Database

**Create New Model:**
```python
# apps/amulet-ai-service/models/database_models.py
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime

class MyModel(Base):
    __tablename__ = "my_table"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    description = Column(String(1000))
    created_at = Column(DateTime, default=datetime.utcnow)
    user_id = Column(Integer, ForeignKey("users.id"))
    
    user = relationship("User", back_populates="my_items")
```

**Update Schema:**
```sql
-- shared/schemas/sql.sql
CREATE TABLE IF NOT EXISTS my_table (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description VARCHAR(1000),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_id INTEGER REFERENCES users(id)
);

CREATE INDEX idx_my_table_user_id ON my_table(user_id);
```

**Query Data:**
```python
# Get all
items = db.query(MyModel).all()

# Filter
items = db.query(MyModel).filter(MyModel.user_id == user_id).all()

# Pagination
items = db.query(MyModel).offset(skip).limit(limit).all()

# Join
items = db.query(MyModel).join(User).filter(User.email == email).all()

# Count
count = db.query(MyModel).count()
```

### Working with Object Storage (Ceph RGW)

**Upload File:**
```python
from apps.amulet_ai_service.services.storage_client import storage_client

# Upload image
storage_client.upload_image(
    bucket="images",
    object_name=f"{user_id}/{filename}",
    data=file_data,
    content_type="image/jpeg"
)
```

**Download File:**
```python
# Get object
data = storage_client.download_file(
    bucket="images",
    object_name=f"{user_id}/{filename}"
)
```

**Generate Presigned URL:**
```python
url = storage_client.get_presigned_url(
    bucket="images",
    object_name=f"{user_id}/{filename}",
    expires_seconds=3600  # 1 hour
)
```

### Working with Qdrant

**Insert Vectors:**
```python
from qdrant_client import QdrantClient
from qdrant_client.http.models import PointStruct

qdrant = QdrantClient(url="http://qdrant:6333")

qdrant.upsert(
    collection_name="amulet_clip_v1",
    points=[
        PointStruct(
            id=image_id,
            vector=embedding.tolist(),
            payload={"image_id": image_id, "filename": filename}
        )
    ]
)
```

**Search Vectors:**
```python
results = qdrant.search(
    collection_name="amulet_clip_v1",
    query_vector=query_embedding.tolist(),
    limit=10,
    score_threshold=0.7
)
```

## Debugging

### Backend Debugging

**Using Print Statements:**
```python
print(f"Debug: user_id={user_id}, filename={filename}")
```

**Using Logging:**
```python
import structlog

logger = structlog.get_logger()
logger.info("processing_image", image_id=image_id, user_id=user_id)
logger.error("processing_failed", error=str(e))
```

**Using Debugger:**
```python
import pdb; pdb.set_trace()  # Breakpoint
```

**VS Code/Cursor Debugging:**

Create `.vscode/launch.json`:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Python: FastAPI",
      "type": "python",
      "request": "launch",
      "module": "uvicorn",
      "args": ["main:app", "--reload"],
      "jinja": true,
      "cwd": "${workspaceFolder}/apps/amulet-ai-service"
    }
  ]
}
```

### Frontend Debugging

**Browser DevTools:**
- Console for logs
- Network tab for API calls
- React DevTools for component inspection

**Using Console:**
```typescript
console.log("Debug:", data)
console.error("Error:", error)
console.table(array)
```

**VS Code/Cursor Debugging:**

Create `.vscode/launch.json`:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Next.js: debug client-side",
      "type": "chrome",
      "request": "launch",
      "url": "http://localhost:3000"
    }
  ]
}
```

## Testing

### Backend Testing

**Run All Tests:**
```powershell
pytest tests/ -v
```

**Run Specific Test:**
```powershell
pytest tests/test_api_analyze.py::test_analyze_valid_image -v
```

**Run with Coverage:**
```powershell
pytest tests/ -v --cov --cov-report=html
```

**Run Tests on File Change:**
```powershell
pytest-watch
```

**Writing Good Tests:**
```python
def test_feature_name_scenario():
    """Test description"""
    # Arrange - Setup
    data = {"key": "value"}
    
    # Act - Execute
    result = function_to_test(data)
    
    # Assert - Verify
    assert result is not None
    assert result["key"] == "value"
```

### Frontend Testing

**Run Tests:**
```bash
cd apps/web-next
npm test
```

**Run with Coverage:**
```bash
npm test -- --coverage
```

**Run in Watch Mode:**
```bash
npm test -- --watch
```

## Performance Optimization

### Backend Performance

**Database Queries:**
```python
# ❌ N+1 Query Problem
users = db.query(User).all()
for user in users:
    images = db.query(Image).filter(Image.user_id == user.id).all()

# ✅ Use Eager Loading
users = db.query(User).options(joinedload(User.images)).all()
```

**Async Operations:**
```python
import asyncio

# ❌ Sequential
result1 = await api_call_1()
result2 = await api_call_2()

# ✅ Parallel
result1, result2 = await asyncio.gather(
    api_call_1(),
    api_call_2()
)
```

**Caching:**
```python
from functools import lru_cache

@lru_cache(maxsize=128)
def expensive_computation(param):
    # Cached result
    return result
```

### Frontend Performance

**Code Splitting:**
```typescript
// Dynamic imports
const HeavyComponent = dynamic(() => import("@/components/heavy-component"))
```

**Image Optimization:**
```typescript
import Image from "next/image"

<Image
  src="/image.jpg"
  width={800}
  height={600}
  alt="Description"
  loading="lazy"
/>
```

**Memoization:**
```typescript
import { useMemo } from "react"

const expensiveValue = useMemo(() => {
  return computeExpensiveValue(data)
}, [data])
```

## Troubleshooting

### Common Issues

**Port Already in Use:**
```powershell
# Find process using port
netstat -ano | findstr :8000

# Kill process
taskkill /PID <PID> /F
```

**Docker Issues:**
```powershell
# Reset Docker
.\make.ps1 down
docker system prune -a
.\make.ps1 up-cpu
```

**Database Connection Issues:**
```powershell
# Check PostgreSQL
docker logs pra-analysis-postgres-1

# Restart PostgreSQL
docker restart pra-analysis-postgres-1
```

**Module Import Errors:**
```powershell
# Check PYTHONPATH
echo $env:PYTHONPATH

# Set PYTHONPATH
$env:PYTHONPATH = "C:\wat\pra-analysis\pra-analysis"
```

## Best Practices

### Code Organization

- Keep files small and focused
- One component per file
- Group related code together
- Use clear, descriptive names

### Error Handling

- Always handle exceptions
- Provide clear error messages
- Log errors appropriately
- Fail gracefully

### Documentation

- Write clear comments
- Update README files
- Document complex logic
- Provide examples

### Testing

- Write tests for new features
- Test edge cases
- Maintain coverage
- Run tests before committing

### Git Workflow

- Commit frequently
- Write clear commit messages
- Keep commits focused
- Review before pushing

## Resources

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Next.js Documentation](https://nextjs.org/docs)
- [SQLAlchemy Documentation](https://docs.sqlalchemy.org/)
- [Pydantic Documentation](https://docs.pydantic.dev/)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)

---

**Happy Coding! 🚀**

