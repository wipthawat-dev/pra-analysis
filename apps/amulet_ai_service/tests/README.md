# Testing Guide for Pra Analysis Backend

## Quick Start

### Method 1: Using Test Script (Recommended for Windows)

```powershell
# From project root
.\run_tests.ps1
```

### Method 2: Manual Setup

```powershell
# Navigate to backend directory
cd apps/amulet-ai-service

# Create virtual environment (if not exists)
python -m venv venv

# Activate virtual environment
.\venv\Scripts\Activate.ps1

# Upgrade pip
python -m pip install --upgrade pip

# Install dependencies
pip install -r requirements.txt
pip install -r requirements-test.txt

# Start test containers
cd ../..
docker-compose -f docker-compose.test.yml up -d

# Wait for services to be ready (about 10 seconds)
Start-Sleep -Seconds 10

# Run tests
cd apps/amulet-ai-service
pytest tests/ -v
```

## Troubleshooting

### Error: `ModuleNotFoundError: No module named 'fastapi'`

**Cause:** Dependencies not installed or virtual environment not activated

**Solution:**
```powershell
cd apps/amulet-ai-service

# Make sure virtual environment is activated
.\venv\Scripts\Activate.ps1

# Upgrade pip first
python -m pip install --upgrade pip

# Reinstall dependencies
pip install -r requirements.txt
pip install -r requirements-test.txt

# Verify installation
pip list | Select-String "fastapi"
```

### Error: `ModuleNotFoundError: No module named 'apps.amulet_ai_service'`

**Cause:** Python path not set correctly

**Solution:**
```powershell
# Run from apps/amulet-ai-service directory, not project root
cd apps/amulet-ai-service
pytest tests/ -v
```

### Error: Database connection refused

**Cause:** Test containers not running

**Solution:**
```powershell
# Start test containers
cd path/to/project/root
docker-compose -f docker-compose.test.yml up -d

# Check containers are running
docker ps

# Wait for PostgreSQL to be ready
Start-Sleep -Seconds 10

# Run tests again
cd apps/amulet-ai-service
pytest tests/ -v
```

### Error: Port already in use

**Cause:** Test containers already running or ports in use

**Solution:**
```powershell
# Stop existing test containers
docker-compose -f docker-compose.test.yml down

# Start fresh
docker-compose -f docker-compose.test.yml up -d
```

## Running Specific Tests

### Run by marker
```powershell
# API tests only
pytest tests/ -v -m "api"

# Database tests only
pytest tests/ -v -m "database"

# Security tests only
pytest tests/ -v -m "security"

# Integration tests only
pytest tests/ -v -m "integration"

# Exclude slow tests
pytest tests/ -v -m "not slow"
```

### Run specific test file
```powershell
pytest tests/test_api_analyze.py -v
pytest tests/test_database.py -v
pytest tests/test_security.py -v
```

### Run specific test function
```powershell
pytest tests/test_api_analyze.py::TestAnalyzeEndpoint::test_analyze_valid_jpeg -v
```

## Test Coverage

### Generate HTML coverage report
```powershell
pytest tests/ -v --cov --cov-report=html

# Open report
start htmlcov/index.html
```

### Generate terminal coverage report
```powershell
pytest tests/ -v --cov --cov-report=term-missing
```

### Coverage by module
```powershell
pytest tests/ -v --cov=apps.amulet_ai_service.routes --cov-report=term
pytest tests/ -v --cov=apps.amulet_ai_service.models --cov-report=term
pytest tests/ -v --cov=apps.amulet_ai_service.services --cov-report=term
```

## Test Markers

Available test markers:
- `unit` - Unit tests
- `api` - API endpoint tests
- `database` - Database tests
- `integration` - Integration tests
- `security` - Security tests
- `slow` - Slow running tests
- `services` - Service layer tests

## Environment Variables

Tests use separate environment variables from development:
- `POSTGRES_PORT=5433` (test database)
- `MINIO_ENDPOINT=localhost:9010` (test MinIO)
- `QDRANT_PORT=6334` (test Qdrant)

These are automatically set in `conftest.py`.

## Clean Up

### Stop test containers
```powershell
docker-compose -f docker-compose.test.yml down
```

### Remove test database volumes
```powershell
docker-compose -f docker-compose.test.yml down -v
```

### Clean Python cache
```powershell
# Remove __pycache__ directories
Get-ChildItem -Path . -Filter __pycache__ -Recurse | Remove-Item -Recurse -Force

# Remove .pytest_cache
Remove-Item -Path .pytest_cache -Recurse -Force

# Remove coverage files
Remove-Item -Path .coverage -Force
Remove-Item -Path htmlcov -Recurse -Force
```

## CI/CD Integration

### GitHub Actions Example
```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: testpass
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Install dependencies
        run: |
          cd apps/amulet-ai-service
          pip install -r requirements.txt
          pip install -r requirements-test.txt
      
      - name: Run tests
        run: |
          cd apps/amulet-ai-service
          pytest tests/ -v --cov --cov-report=xml
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
```

## Common Issues

### Issue: Tests fail with "fixture not found"
**Solution:** Make sure you're running from the correct directory (`apps/amulet-ai-service`)

### Issue: Import errors for project modules
**Solution:** Check that `conftest.py` has correct import paths

### Issue: Database tests fail
**Solution:** 
1. Check test containers are running: `docker ps`
2. Check PostgreSQL is accessible: `docker-compose -f docker-compose.test.yml logs postgres-test`
3. Wait longer for database to be ready

### Issue: Tests are very slow
**Solution:**
1. Run specific test markers instead of all tests
2. Skip slow tests: `pytest -m "not slow"`
3. Run tests in parallel: `pip install pytest-xdist` then `pytest -n auto`

## Best Practices

1. **Always run tests from `apps/amulet-ai-service` directory**
2. **Keep virtual environment activated during development**
3. **Run tests before committing code**
4. **Check coverage regularly** (aim for >80%)
5. **Use appropriate markers** to run specific test suites
6. **Clean up test data** between test runs
7. **Don't commit test database changes**

## Test Writing Guidelines

### Naming Convention
- Test files: `test_*.py`
- Test classes: `Test*`
- Test functions: `test_*`

### Example Test
```python
import pytest
from fastapi.testclient import TestClient

@pytest.mark.api
class TestMyEndpoint:
    """Test cases for my endpoint"""
    
    def test_successful_request(self, client: TestClient):
        """Test successful API request"""
        response = client.get("/api/my-endpoint")
        assert response.status_code == 200
        assert "expected_field" in response.json()
    
    def test_error_handling(self, client: TestClient):
        """Test error handling"""
        response = client.get("/api/my-endpoint?invalid=param")
        assert response.status_code == 400
```

## Resources

- [Pytest Documentation](https://docs.pytest.org/)
- [FastAPI Testing](https://fastapi.tiangolo.com/tutorial/testing/)
- [SQLAlchemy Testing](https://docs.sqlalchemy.org/en/14/orm/session_transaction.html#joining-a-session-into-an-external-transaction-such-as-for-test-suites)
- [Coverage.py Documentation](https://coverage.readthedocs.io/)

