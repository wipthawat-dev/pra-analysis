CREATE TABLE IF NOT EXISTS images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID,
  upload_ts TIMESTAMP DEFAULT now(),
  mime TEXT,
  exif JSONB,
  c2pa_status TEXT,
  source TEXT, -- 'upload', 'minio_import', 'dataset'
  dataset_id UUID,
  is_labeled BOOLEAN DEFAULT FALSE,
  minio_path TEXT, -- Path in MinIO bucket
  metadata_path TEXT -- Path to metadata JSON in MinIO
);

CREATE TABLE IF NOT EXISTS predictions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  image_id UUID REFERENCES images(id),
  model_version TEXT,
  verdict TEXT,
  score REAL,
  topk JSONB,
  heatmaps JSONB,
  created_at TIMESTAMP DEFAULT now(),
  result_path TEXT -- Path to full result JSON in MinIO
);

-- Datasets
CREATE TABLE IF NOT EXISTS datasets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'active',
  minio_bucket TEXT, -- MinIO bucket name for this dataset
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- Dataset Images (many-to-many relationship)
CREATE TABLE IF NOT EXISTS dataset_images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dataset_id UUID REFERENCES datasets(id) ON DELETE CASCADE,
  image_id UUID REFERENCES images(id) ON DELETE CASCADE,
  metadata JSONB,
  created_at TIMESTAMP DEFAULT now(),
  UNIQUE(dataset_id, image_id)
);

-- Labels
CREATE TABLE IF NOT EXISTS labels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  image_id UUID REFERENCES images(id) ON DELETE CASCADE,
  labeler_id UUID,
  verdict TEXT NOT NULL, -- 'authentic', 'fake', 'uncertain'
  bbox JSONB, -- bounding box coordinates
  confidence REAL,
  notes TEXT,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- Labeling Sessions
CREATE TABLE IF NOT EXISTS labeling_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  labeler_id UUID,
  started_at TIMESTAMP DEFAULT now(),
  completed_at TIMESTAMP,
  images_labeled INTEGER DEFAULT 0
);

-- Training Jobs
CREATE TABLE IF NOT EXISTS training_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dataset_id UUID REFERENCES datasets(id),
  model_type TEXT NOT NULL, -- 'detector', 'embedder', 'classifier'
  config JSONB NOT NULL,
  status TEXT DEFAULT 'pending', -- 'pending', 'running', 'completed', 'failed', 'cancelled'
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  metrics JSONB,
  model_version TEXT,
  model_path TEXT, -- Path to model artifacts in MinIO
  logs_path TEXT, -- Path to training logs in MinIO
  created_at TIMESTAMP DEFAULT now()
);

-- Model Registry
CREATE TABLE IF NOT EXISTS models (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  version TEXT NOT NULL UNIQUE,
  model_type TEXT NOT NULL, -- 'detector', 'embedder', 'classifier'
  training_job_id UUID REFERENCES training_jobs(id),
  minio_path TEXT NOT NULL, -- Path to model files in MinIO
  config JSONB,
  metrics JSONB,
  is_deployed BOOLEAN DEFAULT FALSE,
  deployed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT now()
);

-- Feedback
CREATE TABLE IF NOT EXISTS feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prediction_id UUID REFERENCES predictions(id) ON DELETE CASCADE,
  user_id UUID,
  is_correct BOOLEAN,
  correct_verdict TEXT,
  notes TEXT,
  created_at TIMESTAMP DEFAULT now(),
  reviewed_at TIMESTAMP,
  reviewed_by UUID
);

-- Import Jobs (for MinIO imports)
CREATE TABLE IF NOT EXISTS import_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dataset_id UUID REFERENCES datasets(id),
  minio_bucket TEXT NOT NULL,
  minio_prefix TEXT, -- Prefix path in MinIO bucket
  status TEXT DEFAULT 'pending', -- 'pending', 'running', 'completed', 'failed'
  total_files INTEGER,
  imported_files INTEGER DEFAULT 0,
  failed_files INTEGER DEFAULT 0,
  error_log JSONB,
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_images_dataset_id ON images(dataset_id);
CREATE INDEX IF NOT EXISTS idx_images_is_labeled ON images(is_labeled);
CREATE INDEX IF NOT EXISTS idx_dataset_images_dataset_id ON dataset_images(dataset_id);
CREATE INDEX IF NOT EXISTS idx_dataset_images_image_id ON dataset_images(image_id);
CREATE INDEX IF NOT EXISTS idx_labels_image_id ON labels(image_id);
CREATE INDEX IF NOT EXISTS idx_training_jobs_status ON training_jobs(status);
CREATE INDEX IF NOT EXISTS idx_training_jobs_dataset_id ON training_jobs(dataset_id);
CREATE INDEX IF NOT EXISTS idx_feedback_prediction_id ON feedback(prediction_id);
CREATE INDEX IF NOT EXISTS idx_import_jobs_status ON import_jobs(status);
