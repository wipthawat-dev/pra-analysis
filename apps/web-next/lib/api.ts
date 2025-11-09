const API_BASE = process.env.NEXT_PUBLIC_API_BASE || 'http://localhost:8000';

export async function apiRequest<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<T> {
  const url = `${API_BASE}${endpoint}`;
  const response = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options.headers,
    },
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ detail: response.statusText }));
    throw new Error(error.detail || `HTTP error! status: ${response.status}`);
  }

  return response.json();
}

export async function apiUpload(
  endpoint: string,
  formData: FormData
): Promise<any> {
  const url = `${API_BASE}${endpoint}`;
  const response = await fetch(url, {
    method: 'POST',
    body: formData,
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ detail: response.statusText }));
    throw new Error(error.detail || `HTTP error! status: ${response.status}`);
  }

  return response.json();
}

// Dataset APIs
export const datasetsApi = {
  list: () => apiRequest<any[]>('/v1/admin/datasets'),
  get: (id: string) => apiRequest<any>(`/v1/admin/datasets/${id}`),
  create: (data: { name: string; description?: string; minio_bucket?: string }) =>
    apiRequest<any>('/v1/admin/datasets', {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  delete: (id: string) =>
    apiRequest<any>(`/v1/admin/datasets/${id}`, { method: 'DELETE' }),
  uploadImages: (id: string, files: File[]) => {
    const formData = new FormData();
    files.forEach(file => formData.append('files', file));
    return apiUpload(`/v1/admin/datasets/${id}/images`, formData);
  },
  listImages: (id: string) =>
    apiRequest<any[]>(`/v1/admin/datasets/${id}/images`),
};

// Import APIs
export const importApi = {
  listJobs: () => apiRequest<any[]>('/v1/admin/import/jobs'),
  getJob: (id: string) => apiRequest<any>(`/v1/admin/import/jobs/${id}`),
  createJob: (data: { dataset_id?: string; minio_bucket: string; minio_prefix?: string }) =>
    apiRequest<any>('/v1/admin/import/minio', {
      method: 'POST',
      body: JSON.stringify(data),
    }),
};

// Labeling APIs
export const labelingApi = {
  getQueue: (datasetId?: string) =>
    apiRequest<any[]>(`/v1/admin/labeling/queue${datasetId ? `?dataset_id=${datasetId}` : ''}`),
  createLabel: (imageId: string, data: any) =>
    apiRequest<any>(`/v1/admin/labeling/${imageId}`, {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  getStats: (datasetId?: string) =>
    apiRequest<any>(`/v1/admin/labeling/stats${datasetId ? `?dataset_id=${datasetId}` : ''}`),
};

// Training APIs
export const trainingApi = {
  listJobs: () => apiRequest<any[]>('/v1/admin/training/jobs'),
  getJob: (id: string) => apiRequest<any>(`/v1/admin/training/jobs/${id}`),
  createJob: (data: any) =>
    apiRequest<any>('/v1/admin/training/jobs', {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  getLogs: (id: string) => apiRequest<any>(`/v1/admin/training/jobs/${id}/logs`),
  getMetrics: (id: string) => apiRequest<any>(`/v1/admin/training/jobs/${id}/metrics`),
  cancel: (id: string) =>
    apiRequest<any>(`/v1/admin/training/jobs/${id}/cancel`, { method: 'POST' }),
};

// Models APIs
export const modelsApi = {
  list: () => apiRequest<any[]>('/v1/admin/models'),
  get: (version: string) => apiRequest<any>(`/v1/admin/models/${version}`),
  evaluate: (version: string, data: any) =>
    apiRequest<any>(`/v1/admin/models/${version}/evaluate`, {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  deploy: (version: string) =>
    apiRequest<any>(`/v1/admin/models/${version}/deploy`, { method: 'POST' }),
};

// Feedback APIs
export const feedbackApi = {
  create: (data: any) =>
    apiRequest<any>('/v1/feedback', {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  list: () => apiRequest<any[]>('/v1/admin/feedback'),
  approve: (id: string) =>
    apiRequest<any>(`/v1/admin/feedback/${id}/approve`, { method: 'POST' }),
  getStats: () => apiRequest<any>('/v1/admin/feedback/stats'),
};

