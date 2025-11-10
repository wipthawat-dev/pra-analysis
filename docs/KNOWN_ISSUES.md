# Known Issues Tracker

> **Last Updated:** [Date]

## Critical Issues
> Issues that prevent core functionality or pose security risks. Must be fixed before production.

### None Currently

---

## High Priority Issues
> Issues that significantly impact user experience or system performance.

### None Currently

---

## Medium Priority Issues
> Issues that affect some features but have workarounds.

### ISSUE-001: Mock ML Pipeline
**Severity:** Medium  
**Component:** Backend API - Image Analysis  
**Status:** Known Limitation  
**Reported:** 2024-11-09  

**Description:**  
The current image analysis endpoint (`/v1/analyze`) uses a mock ML pipeline that generates random predictions instead of performing actual image authenticity analysis.

**Steps to Reproduce:**
1. Upload any image via `/v1/analyze`
2. Observe that the verdict and score are generated randomly
3. Note that heatmaps are always empty
4. Top-K similar images are placeholder data

**Expected Behavior:**  
- Real ML model inference using NVIDIA Triton
- Actual forensic analysis of image
- Valid heatmaps showing manipulation regions
- Real similar images from vector database

**Actual Behavior:**  
- Random verdict (authentic/fake/uncertain)
- Random score
- Empty heatmaps
- Placeholder similar images

**Workaround:**  
This is a placeholder for development. Real implementation requires:
1. Trained ML models (detector, classifier, embedder)
2. NVIDIA Triton server with loaded models
3. Qdrant vector database with indexed embeddings

**Fix Status:**  
🔄 Planned - Will be implemented after model training workflow is complete

**Target Fix Date:** TBD

**Dependencies:**
- Complete model training workflow
- Deploy trained models to Triton
- Index reference images in Qdrant

---

## Low Priority Issues
> Minor issues that don't significantly impact functionality.

### None Currently

---

## Issue Template

```markdown
### ISSUE-XXX: [Short Description]
**Severity:** [Critical/High/Medium/Low]  
**Component:** [Backend/Frontend/Database/Infrastructure]  
**Status:** [Open/In Progress/Resolved/Won't Fix]  
**Reported:** [Date]  
**Assigned To:** [Name]  

**Description:**  
[Detailed description of the issue]

**Steps to Reproduce:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Behavior:**  
[What should happen]

**Actual Behavior:**  
[What actually happens]

**Workaround:**  
[Temporary solution if available]

**Fix Status:**  
[Status update and progress]

**Target Fix Date:** [Date]

**Related Issues:**  
[Links to related issues]

**Notes:**  
[Any additional information]
```

---

## Issue Statistics

| Severity | Open | In Progress | Resolved | Total |
|----------|------|-------------|----------|-------|
| Critical | 0 | 0 | 0 | 0 |
| High | 0 | 0 | 0 | 0 |
| Medium | 1 | 0 | 0 | 1 |
| Low | 0 | 0 | 0 | 0 |
| **Total** | **1** | **0** | **0** | **1** |

---

## Recently Resolved Issues

### None Yet

---

## Won't Fix / By Design

### None Currently

---

## Change Log

| Date | Issue ID | Action | Notes |
|------|----------|--------|-------|
| 2024-11-09 | ISSUE-001 | Created | Mock ML pipeline documented |

---

## Issue Triage Process

### Severity Definitions

**Critical**
- Security vulnerabilities
- Data loss or corruption
- Complete system outage
- No workaround available
- **Response Time:** Immediate
- **Fix Timeline:** 24-48 hours

**High**
- Major feature broken
- Significant performance degradation
- Affects many users
- Workaround exists but complex
- **Response Time:** Same day
- **Fix Timeline:** 1 week

**Medium**
- Feature partially broken
- Minor performance issues
- Affects some users
- Simple workaround available
- **Response Time:** 2-3 days
- **Fix Timeline:** 2-4 weeks

**Low**
- Cosmetic issues
- Minor inconvenience
- Affects few users
- Easy workaround
- **Response Time:** 1 week
- **Fix Timeline:** Next release cycle

### Issue Workflow

1. **Report** - Issue is reported and logged
2. **Triage** - Issue is evaluated and assigned severity
3. **Investigate** - Root cause analysis performed
4. **Plan** - Fix approach determined
5. **Develop** - Fix implemented and tested
6. **Review** - Code review and QA testing
7. **Deploy** - Fix deployed to production
8. **Verify** - Issue verified as resolved
9. **Close** - Issue marked as resolved

---

## Contact for Issue Reporting

**Development Team:**  
- Email: dev-team@example.com
- Issue Tracker: [GitHub Issues URL]
- Slack: #pra-analysis-bugs

**Emergency Contact (Critical Issues):**  
- On-call: [Phone number]
- Email: oncall@example.com

