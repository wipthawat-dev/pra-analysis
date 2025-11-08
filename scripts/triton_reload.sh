#!/usr/bin/env bash
set -euo pipefail
curl -s -X POST http://localhost:8000/v2/repository/index || true
echo "Requested model repo reload (adjust endpoint for management API if needed)."
