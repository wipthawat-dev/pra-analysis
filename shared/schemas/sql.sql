CREATE TABLE IF NOT EXISTS images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID,
  upload_ts TIMESTAMP DEFAULT now(),
  mime TEXT,
  exif JSONB,
  c2pa_status TEXT
);

CREATE TABLE IF NOT EXISTS predictions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  image_id UUID REFERENCES images(id),
  model_version TEXT,
  verdict TEXT,
  score REAL,
  topk JSONB,
  heatmaps JSONB,
  created_at TIMESTAMP DEFAULT now()
);
