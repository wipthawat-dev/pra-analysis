# Manual Testing Checklist

## Browser Compatibility Testing

### Desktop Browsers
- [ ] Chrome (latest version)
  - [ ] All pages load correctly
  - [ ] Forms work properly
  - [ ] File uploads function
  - [ ] Navigation works
- [ ] Firefox (latest version)
  - [ ] All pages load correctly
  - [ ] Forms work properly
  - [ ] File uploads function
  - [ ] Navigation works
- [ ] Safari (latest version)
  - [ ] All pages load correctly
  - [ ] Forms work properly
  - [ ] File uploads function
  - [ ] Navigation works
- [ ] Edge (latest version)
  - [ ] All pages load correctly
  - [ ] Forms work properly
  - [ ] File uploads function
  - [ ] Navigation works

### Mobile Browsers
- [ ] iOS Safari
  - [ ] Responsive layout
  - [ ] Touch interactions
  - [ ] File upload from camera/gallery
- [ ] Chrome Mobile (Android)
  - [ ] Responsive layout
  - [ ] Touch interactions
  - [ ] File upload from camera/gallery

## Responsive Design Testing

### Mobile (320px - 480px)
- [ ] Home page layout adapts
- [ ] Navigation menu collapses
- [ ] Feature cards stack vertically
- [ ] Forms are usable
- [ ] Images scale properly
- [ ] Text is readable

### Tablet (481px - 768px)
- [ ] Layout adapts to medium screens
- [ ] Navigation is accessible
- [ ] Cards display in grid
- [ ] Forms fit properly

### Desktop (769px+)
- [ ] Full layout displays correctly
- [ ] All features accessible
- [ ] Optimal spacing and sizing

## Page-by-Page Testing

### Home Page (/)
- [ ] Page loads without errors
- [ ] All 6 feature cards display
- [ ] Icons render correctly
- [ ] Navigation links work
- [ ] Hover effects function
- [ ] Quick start section visible
- [ ] Responsive on all screen sizes

### Analyze Page (/analyze)
- [ ] File upload area displays
- [ ] Drag and drop works
- [ ] Click to upload works
- [ ] File type validation (JPEG, PNG only)
- [ ] File size validation (max 15MB)
- [ ] Upload progress shows
- [ ] Analysis results display
- [ ] Verdict shown correctly (authentic/fake/uncertain)
- [ ] Score displays
- [ ] Top-K similar images show
- [ ] Heatmaps render (if available)
- [ ] Error messages display properly
- [ ] Loading states work
- [ ] Can navigate to feedback page

### Result Detail Page (/analyze/[resultId])
- [ ] Loads prediction by ID
- [ ] Original image displays
- [ ] All metrics show
- [ ] Heatmap visualization works
- [ ] Similar images grid displays
- [ ] Link to feedback form works
- [ ] 404 handling for invalid result ID

### Feedback Page (/analyze/[resultId]/feedback)
- [ ] Feedback form renders
- [ ] Radio buttons work (is_correct)
- [ ] Dropdown for correct_verdict functions
- [ ] Textarea for notes works
- [ ] Form validation works
- [ ] Submit button functions
- [ ] Success message displays
- [ ] Error handling works
- [ ] Can navigate back to result

### Admin Datasets Page (/admin/datasets)
- [ ] Dataset list displays
- [ ] Create dataset button works
- [ ] Create dataset form validates
- [ ] Dataset creation succeeds
- [ ] Delete confirmation prompts
- [ ] Dataset deletion works
- [ ] Navigate to dataset detail works
- [ ] Empty state displays when no datasets
- [ ] Loading states work
- [ ] Pagination works (if many datasets)

### Dataset Detail Page (/admin/datasets/[id])
- [ ] Dataset info displays
- [ ] Image upload component works
- [ ] Multiple file selection works
- [ ] Upload progress shows
- [ ] Image grid displays
- [ ] Image thumbnails load
- [ ] Pagination for images works
- [ ] Filter by is_labeled works
- [ ] Can navigate to labeling
- [ ] Delete dataset option works
- [ ] Breadcrumb navigation functions

### Admin Labeling Page (/admin/labeling)
- [ ] Labeling queue loads
- [ ] Unlabeled images display
- [ ] Image preview works
- [ ] Verdict selector functions (authentic/fake/uncertain)
- [ ] Confidence slider works
- [ ] Notes input works
- [ ] Submit label button functions
- [ ] Next image button works
- [ ] Statistics display correctly
- [ ] Filter by dataset works
- [ ] Empty queue message shows when done

### Admin Training Page (/admin/training)
- [ ] Training jobs list displays
- [ ] Create training job button works
- [ ] Dataset dropdown populated
- [ ] Model type dropdown works
- [ ] Training parameters inputs work
- [ ] Submit training job succeeds
- [ ] Job status displays (pending/running/completed/failed)
- [ ] Progress indicator shows
- [ ] Cancel job button works
- [ ] Navigate to job detail works
- [ ] Empty state displays
- [ ] Auto-refresh for running jobs

### Training Job Detail Page (/admin/training/[jobId])
- [ ] Job details display
- [ ] Status badge shows
- [ ] Timestamps display correctly
- [ ] Configuration displays
- [ ] Metrics display (after completion)
- [ ] Metrics charts render
- [ ] Training logs viewer works
- [ ] Cancel job button functions
- [ ] Link to trained model works
- [ ] Error messages show for failed jobs

### Admin Models Page (/admin/models)
- [ ] Models list displays
- [ ] Filter by model type works
- [ ] Filter by deployment status works
- [ ] Model version displays
- [ ] Deployment badge shows
- [ ] Metrics summary displays
- [ ] Evaluate model button works
- [ ] Deploy model button works
- [ ] Deploy confirmation prompts
- [ ] Only one deployed per type enforced
- [ ] Empty state displays

### Admin Feedback Page (/admin/feedback)
- [ ] Feedback list displays
- [ ] Filter by reviewed status works
- [ ] Feedback item details show
- [ ] Original prediction link works
- [ ] Approve feedback button works
- [ ] Review timestamp displays
- [ ] Statistics dashboard shows
- [ ] Empty state displays
- [ ] Pagination works

### Navigation Component
- [ ] All navigation links work
- [ ] Active page highlights
- [ ] Responsive mobile menu works
- [ ] Logo/branding displays
- [ ] Breadcrumbs work (if applicable)

## Functional Testing

### Image Upload & Analysis
- [ ] Upload valid JPEG (small, medium, large)
- [ ] Upload valid PNG
- [ ] Upload GIF (should reject)
- [ ] Upload file > 15MB (should reject)
- [ ] Upload corrupted file (should reject)
- [ ] Upload without file selected (should prevent)
- [ ] Concurrent uploads work
- [ ] Analysis completes successfully
- [ ] Results saved to database
- [ ] Can submit feedback on results

### Dataset Management
- [ ] Create dataset with all fields
- [ ] Create dataset with minimum fields
- [ ] Upload single image to dataset
- [ ] Upload multiple images (batch)
- [ ] View dataset images
- [ ] Delete dataset without images
- [ ] Delete dataset with images (CASCADE)
- [ ] Pagination works with many images

### Image Labeling
- [ ] View unlabeled images queue
- [ ] Label image as authentic
- [ ] Label image as fake
- [ ] Label image as uncertain
- [ ] Add confidence score
- [ ] Add notes to label
- [ ] is_labeled flag updates
- [ ] Batch labeling works
- [ ] Statistics update correctly

### Model Training
- [ ] Create training job with sufficient labeled images
- [ ] Cannot create job with insufficient labels
- [ ] Job status updates correctly
- [ ] Training metrics generate
- [ ] Model version created
- [ ] Logs accessible
- [ ] Can cancel pending/running job
- [ ] Cannot cancel completed job

### Model Management
- [ ] List all models
- [ ] Filter by model type
- [ ] Filter by deployment status
- [ ] View model details
- [ ] Evaluate model
- [ ] Deploy model
- [ ] Previous model undeployed when new one deployed
- [ ] Deployed model indicated

### Feedback System
- [ ] Submit correct prediction feedback
- [ ] Submit incorrect prediction feedback
- [ ] Add notes to feedback
- [ ] View all feedback
- [ ] Filter reviewed/unreviewed
- [ ] Approve feedback
- [ ] Statistics calculate correctly

## Security Testing

### Input Validation
- [ ] XSS attempts in text fields blocked
- [ ] SQL injection attempts blocked
- [ ] Path traversal in file uploads prevented
- [ ] Malicious file upload blocked
- [ ] File size limits enforced
- [ ] File type restrictions enforced

### Error Handling
- [ ] Errors don't expose sensitive data
- [ ] Stack traces hidden in production
- [ ] Appropriate error messages shown
- [ ] Failed requests don't crash app

## Performance Testing

### Page Load Times
- [ ] Home page loads < 2 seconds
- [ ] Dataset list loads < 2 seconds
- [ ] Image analysis completes < 5 seconds
- [ ] Large lists paginate efficiently

### User Experience
- [ ] Loading states show during operations
- [ ] Optimistic UI updates where appropriate
- [ ] No layout shifts during page load
- [ ] Images lazy load
- [ ] Smooth transitions and animations

## Accessibility Testing

### Keyboard Navigation
- [ ] Can navigate with Tab key
- [ ] Can activate with Enter/Space
- [ ] Focus indicators visible
- [ ] Tab order logical

### Screen Reader
- [ ] Page landmarks identified
- [ ] Form labels present
- [ ] Alt text on images
- [ ] ARIA labels where needed

## Edge Cases & Error Scenarios

### Network Issues
- [ ] Graceful handling of network timeout
- [ ] Retry logic for failed requests
- [ ] Offline detection
- [ ] Error messages for connection issues

### Empty States
- [ ] Empty dataset list
- [ ] Empty labeling queue
- [ ] No training jobs
- [ ] No models in registry
- [ ] No feedback items

### Boundary Conditions
- [ ] 1x1 pixel image
- [ ] 15MB image (max size)
- [ ] Very long dataset name
- [ ] Very long notes text
- [ ] Special characters in names

## Test Sign-off

| Area | Tester | Date | Status | Notes |
|------|--------|------|--------|-------|
| Browser Compatibility | | | | |
| Responsive Design | | | | |
| All Pages | | | | |
| Functional Tests | | | | |
| Security | | | | |
| Performance | | | | |
| Accessibility | | | | |
| Edge Cases | | | | |

**Overall Status:** [ ] PASS / [ ] FAIL

**Production Ready:** [ ] YES / [ ] NO

**Tester Signature:** _________________ **Date:** _________

