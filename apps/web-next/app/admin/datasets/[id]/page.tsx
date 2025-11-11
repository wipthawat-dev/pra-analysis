'use client';

import { useState, useEffect } from 'react';
import { useParams } from 'next/navigation';
import { datasetsApi, importApi } from '@/lib/api';
import { Upload, Download, Image as ImageIcon } from 'lucide-react';

export default function DatasetDetailPage() {
  const params = useParams();
  const datasetId = params.id as string;
  
  const [dataset, setDataset] = useState<any>(null);
  const [images, setImages] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [uploading, setUploading] = useState(false);
  const [showImportForm, setShowImportForm] = useState(false);
  const [importForm, setImportForm] = useState({ minio_bucket: '', minio_prefix: '' });

  useEffect(() => {
    if (datasetId) {
      loadDataset();
      loadImages();
    }
  }, [datasetId]);

  const loadDataset = async () => {
    try {
      const data = await datasetsApi.get(datasetId);
      setDataset(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load dataset');
    }
  };

  const loadImages = async () => {
    try {
      const data = await datasetsApi.listImages(datasetId);
      setImages(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load images');
    } finally {
      setLoading(false);
    }
  };

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || []);
    if (files.length === 0) return;

    try {
      setUploading(true);
      await datasetsApi.uploadImages(datasetId, files);
      loadImages();
      alert(`Uploaded ${files.length} images successfully`);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to upload images');
    } finally {
      setUploading(false);
    }
  };

  const handleImport = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await importApi.createJob({
        dataset_id: datasetId,
        minio_bucket: importForm.minio_bucket,
        minio_prefix: importForm.minio_prefix || undefined,
      });
      setShowImportForm(false);
      setImportForm({ minio_bucket: '', minio_prefix: '' });
      alert('Import job created. Images will be imported in the background.');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create import job');
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          <p className="mt-2 text-gray-600">Loading...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 py-12">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-8">{dataset?.name || 'Dataset'}</h1>
        
        {error && (
          <div className="mb-6 rounded-md bg-red-50 p-4">
            <div className="text-sm text-red-700">{error}</div>
          </div>
        )}

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-xl font-semibold mb-4 flex items-center">
              <Upload className="h-5 w-5 mr-2" />
              Upload Images
            </h2>
            <input
              type="file"
              multiple
              accept="image/jpeg,image/png"
              onChange={handleFileUpload}
              disabled={uploading}
              className="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100"
            />
            {uploading && (
              <div className="mt-4 text-sm text-blue-600">Uploading...</div>
            )}
          </div>

          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-xl font-semibold mb-4 flex items-center">
              <Download className="h-5 w-5 mr-2" />
              Import from MinIO
            </h2>
            <button
              onClick={() => setShowImportForm(!showImportForm)}
              className="px-4 py-2 bg-gray-100 text-gray-700 rounded-md hover:bg-gray-200"
            >
              {showImportForm ? 'Cancel' : 'Import from MinIO'}
            </button>
            
            {showImportForm && (
              <form onSubmit={handleImport} className="mt-4 space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    MinIO Bucket *
                  </label>
                  <input
                    type="text"
                    value={importForm.minio_bucket}
                    onChange={(e) => setImportForm({ ...importForm, minio_bucket: e.target.value })}
                    required
                    className="w-full px-3 py-2 border border-gray-300 rounded-md"
                    placeholder="e.g., images"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Prefix (optional)
                  </label>
                  <input
                    type="text"
                    value={importForm.minio_prefix}
                    onChange={(e) => setImportForm({ ...importForm, minio_prefix: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md"
                    placeholder="e.g., dataset1/images"
                  />
                </div>
                <button
                  type="submit"
                  className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
                >
                  Start Import
                </button>
              </form>
            )}
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-md p-6">
          <h2 className="text-xl font-semibold mb-4 flex items-center">
            <ImageIcon className="h-5 w-5 mr-2" />
            Images ({images.length})
          </h2>
          {images.length === 0 ? (
            <div className="text-center py-12 text-gray-500">
              No images in this dataset yet.
            </div>
          ) : (
            <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
              {images.map((img) => (
                <div key={img.id} className="border border-gray-200 rounded-lg overflow-hidden hover:shadow-md transition-shadow">
                  {img.presigned_url ? (
                    <div className="aspect-square bg-gray-100 relative">
                      <img 
                        src={img.presigned_url} 
                        alt={img.id.slice(0, 8)}
                        className="w-full h-full object-cover"
                        loading="lazy"
                      />
                    </div>
                  ) : (
                    <div className="aspect-square bg-gray-100 flex items-center justify-center">
                      <ImageIcon className="h-8 w-8 text-gray-400" />
                    </div>
                  )}
                  <div className="p-2">
                    <div className="text-xs text-gray-600 mb-1 truncate">{img.id.slice(0, 8)}...</div>
                    <div className={`text-xs px-2 py-1 rounded text-center ${
                      img.is_labeled ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'
                    }`}>
                      {img.is_labeled ? '✓ Labeled' : '○ Unlabeled'}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

