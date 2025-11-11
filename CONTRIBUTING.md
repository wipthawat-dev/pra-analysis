# Contributing to Pra Analysis

Thank you for your interest in contributing to Pra Analysis! This document provides guidelines and best practices for contributing to this project.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Code Standards](#code-standards)
- [Testing Guidelines](#testing-guidelines)
- [Submitting Changes](#submitting-changes)
- [Project Structure](#project-structure)

## Getting Started

### Prerequisites

- **Python 3.11 or 3.12** (NOT 3.13)
- **Node.js 18+** with npm or pnpm
- **Docker Desktop**
- **Git**
- **PowerShell** (Windows) or Make (Linux/Mac)

### Initial Setup

1. **Clone the repository**
```bash
git clone <repository-url>
cd pra-analysis
```

2. **Copy environment file**
```powershell
Copy-Item .env.example .env
```

3. **Start development services**
```powershell
.\make.ps1 up-cpu
```

4. **Initialize databases**
```powershell
.\make.ps1 qdrant-init
.\make.ps1 embed-index
```

5. **Run tests to verify setup**
```powershell
cd apps\amulet-ai-service
.\venv\Scripts\Activate.ps1
pytest tests/ -v --no-cov
```

## Development Workflow

### Branch Strategy

- `main` - Production-ready code
- `develop` - Development branch
- `feature/*` - Feature branches
- `bugfix/*` - Bug fix branches
- `hotfix/*` - Urgent production fixes

### Creating a Feature Branch

```bash
git checkout develop
git pull origin develop
git checkout -b feature/your-feature-name
```

### Making Changes

1. **Read `.cursorrules`** - Understand project standards
2. **Follow existing patterns** - Check similar code in the project
3. **Write tests first** (TDD recommended)
4. **Implement your changes**
5. **Run tests** - Ensure all tests pass
6. **Format code** - Run formatting tools
7. **Commit with clear messages**

## Code Standards

### Backend (Python/FastAPI)

#### Import Rules (CRITICAL)

**Always use absolute imports:**

```python
# ✅ CORRECT
from apps.amulet_ai_service.services.database import get_db
from apps.amulet_ai_service.models.database_models import Image

# ❌ WRONG
from services.database import get_db
from ..models.database_models import Image
```

#### Code Style

- Use **Black** for formatting: `black .`
- Use **Ruff** for linting: `ruff check .`
- Add type hints to all functions
- Write docstrings for public functions

```python
from typing import List, Optional
from sqlalchemy.orm import Session

def get_images(
    db: Session,
    status: Optional[str] = None,
    limit: int = 100
) -> List[Image]:
    """
    Retrieve images with optional status filter.
    
    Args:
        db: Database session
        status: Optional status filter
        limit: Maximum number of results
        
    Returns:
        List of Image objects
    """
    query = db.query(Image)
    if status:
        query = query.filter(Image.status == status)
    return query.limit(limit).all()
```

#### API Endpoints

- Use proper HTTP methods (GET, POST, PUT, DELETE)
- Return consistent response formats
- Handle errors with appropriate status codes
- Add input validation with Pydantic

```python
from fastapi import APIRouter, HTTPException, status, Depends
from pydantic import BaseModel

router = APIRouter(prefix="/api/v1", tags=["example"])

class CreateRequest(BaseModel):
    name: str
    description: Optional[str] = None

@router.post("/items", status_code=status.HTTP_201_CREATED)
async def create_item(
    request: CreateRequest,
    db: Session = Depends(get_db)
):
    try:
        # Implementation
        return {"success": True, "data": result}
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
```

### Frontend (Next.js/React)

#### Component Structure

```typescript
// components/feature-card.tsx
import { ReactNode } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"

interface FeatureCardProps {
  title: string
  description: string
  icon?: ReactNode
}

export function FeatureCard({ title, description, icon }: FeatureCardProps) {
  return (
    <Card>
      <CardHeader>
        {icon && <div className="mb-2">{icon}</div>}
        <CardTitle>{title}</CardTitle>
      </CardHeader>
      <CardContent>
        <p className="text-muted-foreground">{description}</p>
      </CardContent>
    </Card>
  )
}
```

#### TypeScript Standards

- Use interfaces over types
- Avoid enums, use const objects
- Define proper types for API responses

```typescript
// lib/types.ts
export interface AnalysisResult {
  verdict: string
  score: number
  model_version: string
  processing_time: number
}

export const ANALYSIS_STATUS = {
  PENDING: "pending",
  PROCESSING: "processing",
  COMPLETED: "completed",
  FAILED: "failed",
} as const

export type AnalysisStatus = typeof ANALYSIS_STATUS[keyof typeof ANALYSIS_STATUS]
```

#### Styling Guidelines

- Use Tailwind CSS utility classes
- Follow mobile-first responsive design
- Use Shadcn UI components when available
- Maintain consistent spacing and colors

```tsx
export function ExampleComponent() {
  return (
    <div className="container mx-auto px-4 py-8">
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {/* Content */}
      </div>
    </div>
  )
}
```

## Testing Guidelines

### Backend Testing

#### Writing Tests

Create test files in `apps/amulet-ai-service/tests/`

```python
# tests/test_feature.py
import pytest
from fastapi.testclient import TestClient

def test_endpoint_success(client: TestClient, sample_data):
    """Test successful API call"""
    response = client.post("/api/endpoint", json=sample_data)
    assert response.status_code == 200
    assert "expected_field" in response.json()

def test_endpoint_validation_error(client: TestClient):
    """Test input validation"""
    response = client.post("/api/endpoint", json={})
    assert response.status_code == 422
```

#### Running Tests

```powershell
# All tests
pytest tests/ -v --no-cov

# Specific test file
pytest tests/test_feature.py -v

# With coverage
pytest tests/ -v --cov

# Specific test
pytest tests/test_feature.py::test_endpoint_success -v
```

### Frontend Testing

#### Writing Tests

Create test files in `apps/web-next/__tests__/`

```typescript
// __tests__/components/feature-card.test.tsx
import { render, screen } from "@testing-library/react"
import { FeatureCard } from "@/components/feature-card"

describe("FeatureCard", () => {
  it("renders title and description", () => {
    render(
      <FeatureCard 
        title="Test Title" 
        description="Test Description" 
      />
    )
    
    expect(screen.getByText("Test Title")).toBeInTheDocument()
    expect(screen.getByText("Test Description")).toBeInTheDocument()
  })
})
```

#### Running Tests

```bash
cd apps/web-next
npm test
```

### Test Coverage Requirements

- **Backend**: Maintain ≥85% coverage
- **Frontend**: Maintain ≥70% coverage
- All new features must include tests
- Bug fixes should include regression tests

## Submitting Changes

### Pre-submission Checklist

- [ ] All tests pass locally
- [ ] Code is formatted (Black for Python, Prettier for TypeScript)
- [ ] No linting errors
- [ ] Added tests for new features
- [ ] Updated documentation if needed
- [ ] Tested Docker build (if backend changes)
- [ ] Checked API documentation at `/docs`
- [ ] Commit messages are clear and descriptive

### Commit Message Format

Use conventional commit format:

```
type(scope): brief description

Detailed explanation if needed

Fixes #issue-number
```

**Types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting, etc.)
- `refactor:` - Code refactoring
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks

**Examples:**
```
feat(api): add image batch analysis endpoint

Implemented batch analysis endpoint that accepts multiple images
and processes them concurrently.

Fixes #123
```

```
fix(database): prevent connection leak in image service

Added proper session cleanup in exception handlers.

Fixes #456
```

### Creating Pull Requests

1. **Push your branch**
```bash
git push origin feature/your-feature-name
```

2. **Create PR** with:
   - Clear title and description
   - Reference related issues
   - Screenshots (for UI changes)
   - Testing instructions

3. **Address review comments** promptly

4. **Keep PR updated** with develop branch
```bash
git checkout develop
git pull origin develop
git checkout feature/your-feature-name
git merge develop
```

## Project Structure

Understanding the project layout:

```
pra-analysis/
├── apps/
│   ├── amulet-ai-service/      # Backend API
│   │   ├── main.py             # Entry point
│   │   ├── routes/             # API endpoints (thin layer)
│   │   ├── services/           # Business logic
│   │   ├── models/             # Database models
│   │   ├── schemas/            # Request/response schemas
│   │   └── tests/              # Test suite
│   └── web-next/               # Frontend
│       ├── app/                # App Router pages
│       ├── components/         # React components
│       ├── lib/                # Utilities
│       └── __tests__/          # Frontend tests
├── ml/                         # ML models
│   ├── inference/              # Triton models
│   ├── training/               # Training scripts
│   └── xai/                    # Explainable AI
├── scripts/                    # Utility scripts
├── shared/                     # Shared code
├── .cursorrules                # Development rules
└── docker-compose.*.yml        # Docker configs
```

### Where to Add Code

- **New API endpoint**: `apps/amulet-ai-service/routes/`
- **Business logic**: `apps/amulet-ai-service/services/`
- **Database model**: `apps/amulet-ai-service/models/`
- **Request/response schema**: `apps/amulet-ai-service/schemas/`
- **React component**: `apps/web-next/components/`
- **Page**: `apps/web-next/app/`
- **Utility function**: `apps/web-next/lib/`
- **Tests**: `tests/` directory in respective app

## Common Tasks

### Adding a New API Endpoint

1. Create schema in `schemas/`:
```python
# schemas/my_feature_schemas.py
from pydantic import BaseModel

class MyFeatureRequest(BaseModel):
    param: str

class MyFeatureResponse(BaseModel):
    result: str
```

2. Implement service logic in `services/`:
```python
# services/my_feature_service.py
def process_feature(param: str) -> str:
    # Implementation
    return result
```

3. Create route in `routes/`:
```python
# routes/my_feature.py
from fastapi import APIRouter
from apps.amulet_ai_service.schemas.my_feature_schemas import MyFeatureRequest, MyFeatureResponse
from apps.amulet_ai_service.services.my_feature_service import process_feature

router = APIRouter(prefix="/api/v1/my-feature", tags=["my-feature"])

@router.post("/", response_model=MyFeatureResponse)
async def my_endpoint(request: MyFeatureRequest):
    result = process_feature(request.param)
    return MyFeatureResponse(result=result)
```

4. Register router in `main.py`:
```python
from apps.amulet_ai_service.routes import my_feature
app.include_router(my_feature.router)
```

5. Add tests in `tests/`:
```python
# tests/test_my_feature.py
def test_my_endpoint(client):
    response = client.post("/api/v1/my-feature/", json={"param": "test"})
    assert response.status_code == 200
```

### Adding a New React Component

1. Create component:
```typescript
// components/my-component.tsx
export function MyComponent() {
  return <div>Content</div>
}
```

2. Add tests:
```typescript
// __tests__/components/my-component.test.tsx
import { render } from "@testing-library/react"
import { MyComponent } from "@/components/my-component"

describe("MyComponent", () => {
  it("renders correctly", () => {
    render(<MyComponent />)
    // Assertions
  })
})
```

3. Use in pages:
```typescript
// app/page.tsx
import { MyComponent } from "@/components/my-component"

export default function Page() {
  return <MyComponent />
}
```

## Getting Help

- **Check `.cursorrules`** - Project-specific guidelines
- **Read existing code** - Learn from examples
- **Check documentation** - README files throughout project
- **Ask questions** - Open an issue or discussion
- **API Documentation** - http://localhost:8000/docs

## Additional Resources

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Next.js Documentation](https://nextjs.org/docs)
- [Shadcn UI Components](https://ui.shadcn.com/)
- [SQLAlchemy Documentation](https://docs.sqlalchemy.org/)
- [pytest Documentation](https://docs.pytest.org/)

---

Thank you for contributing to Pra Analysis! 🎉

