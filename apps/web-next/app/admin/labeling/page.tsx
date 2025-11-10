'use client';

import { useState, useEffect } from 'react';
import { labelingApi, datasetsApi } from '@/lib/api';
import { Tag, CheckCircle, XCircle, AlertCircle } from 'lucide-react';

export default function LabelingPage() {
  const [queue, setQueue] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [datasets, setDatasets] = useState<any[]>([]);
  const [selectedDataset, setSelectedDataset] = useState<string>('');
  const [currentImage, setCurrentImage] = useState<any>(null);
  const [label, setLabel] = useState({ verdict: 'uncertain', notes: '' });

  useEffect(() => {
    loadDatasets();
    loadQueue();
  }, [selectedDataset]);

  const loadDatasets = async () => {
    try {
      const data = await datasetsApi.list();
      setDatasets(data);
    } catch (err) {
      console.error('Failed to load datasets:', err);
    }
  };

  const loadQueue = async () => {
    try {
      setLoading(true);
      const data = await labelingApi.getQueue(selectedDataset || undefined);
      setQueue(data);
      if (data.length > 0 && !currentImage) {
        setCurrentImage(data[0]);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load queue');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmitLabel = async () => {
    if (!currentImage) return;
    
    try {
      await labelingApi.createLabel(currentImage.id, label);
      setLabel({ verdict: 'uncertain', notes: '' });
      loadQueue();
      if (queue.length > 1) {
        setCurrentImage(queue[1]);
      } else {
        setCurrentImage(null);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to submit label');
    }
  };

  const getVerdictIcon = (verdict: string) => {
    switch (verdict) {
      case 'authentic':
        return <CheckCircle className="h-5 w-5 text-green-600" />;
      case 'fake':
        return <XCircle className="h-5 w-5 text-red-600" />;
      default:
        return <AlertCircle className="h-5 w-5 text-yellow-600" />;
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
        <h1 className="text-3xl font-bold text-gray-900 mb-8 flex items-center">
          <Tag className="mr-3 h-8 w-8" />
          Labeling
        </h1>
        
        <div className="mb-6">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Filter by Dataset:
          </label>
          <select
            value={selectedDataset}
            onChange={(e) => setSelectedDataset(e.target.value)}
            className="px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="">All</option>
            {datasets.map((ds) => (
              <option key={ds.id} value={ds.id}>
                {ds.name}
              </option>
            ))}
          </select>
        </div>

        {error && (
          <div className="mb-6 rounded-md bg-red-50 p-4">
            <div className="text-sm text-red-700">{error}</div>
          </div>
        )}

        {queue.length === 0 ? (
          <div className="bg-white rounded-lg shadow-md p-12 text-center">
            <Tag className="mx-auto h-12 w-12 text-gray-400" />
            <h3 className="mt-4 text-lg font-medium text-gray-900">No images in queue</h3>
            <p className="mt-2 text-sm text-gray-500">All images are labeled.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <div className="lg:col-span-2">
              {currentImage && (
                <div className="bg-white rounded-lg shadow-md p-6">
                  <h2 className="text-xl font-semibold mb-4">Current Image</h2>
                  {currentImage.presigned_url ? (
                    <img
                      src={currentImage.presigned_url}
                      alt="Labeling"
                      className="w-full border border-gray-200 rounded-lg"
                    />
                  ) : (
                    <div className="text-center py-12 text-gray-500">Image not available</div>
                  )}
                </div>
              )}
            </div>
            
            <div className="bg-white rounded-lg shadow-md p-6">
              <h3 className="text-lg font-semibold mb-4">Label Form</h3>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Verdict</label>
                  <select
                    value={label.verdict}
                    onChange={(e) => setLabel({ ...label, verdict: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="authentic">Authentic</option>
                    <option value="fake">Fake</option>
                    <option value="uncertain">Uncertain</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Notes</label>
                  <textarea
                    value={label.notes}
                    onChange={(e) => setLabel({ ...label, notes: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    rows={4}
                    placeholder="Any additional notes..."
                  />
                </div>
                <button
                  onClick={handleSubmitLabel}
                  disabled={!currentImage}
                  className="w-full px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Submit Label
                </button>
              </div>
            </div>
          </div>
        )}

        <div className="mt-8 bg-white rounded-lg shadow-md p-6">
          <h3 className="text-lg font-semibold mb-4">Queue ({queue.length} remaining)</h3>
          <div className="flex flex-wrap gap-2">
            {queue.map((img, idx) => (
              <button
                key={img.id}
                onClick={() => setCurrentImage(img)}
                className={`px-3 py-2 rounded-md text-sm border transition-colors ${
                  currentImage?.id === img.id
                    ? 'bg-blue-100 border-blue-500 text-blue-700'
                    : 'bg-gray-50 border-gray-200 text-gray-700 hover:bg-gray-100'
                }`}
              >
                #{idx + 1}
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

