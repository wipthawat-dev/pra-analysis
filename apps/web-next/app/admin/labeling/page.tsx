'use client';

import { useState, useEffect, useCallback } from 'react';
import { labelingApi, datasetsApi } from '@/lib/api';
import { Tag, CheckCircle, XCircle, AlertCircle, Keyboard, Info } from 'lucide-react';

export default function LabelingPage() {
  const [queue, setQueue] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [datasets, setDatasets] = useState<any[]>([]);
  const [selectedDataset, setSelectedDataset] = useState<string>('');
  const [currentImage, setCurrentImage] = useState<any>(null);
  const [label, setLabel] = useState({ verdict: 'uncertain', notes: '' });
  const [submitting, setSubmitting] = useState(false);
  const [currentIndex, setCurrentIndex] = useState(0);

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
        setCurrentIndex(0);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load queue');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmitLabel = async () => {
    if (!currentImage || submitting) return;
    
    try {
      setSubmitting(true);
      setError(null);
      
      // Include image_id in the label data to match backend schema
      const labelData = {
        ...label,
        image_id: currentImage.id
      };
      await labelingApi.createLabel(currentImage.id, labelData);
      
      // Reset form
      setLabel({ verdict: 'uncertain', notes: '' });
      
      // Move to next image
      const nextIndex = currentIndex + 1;
      if (nextIndex < queue.length) {
        setCurrentImage(queue[nextIndex]);
        setCurrentIndex(nextIndex);
        // Reload queue to update counts
        loadQueue();
      } else {
        // No more images, reload queue
        setCurrentImage(null);
        setCurrentIndex(0);
        loadQueue();
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to submit label');
    } finally {
      setSubmitting(false);
    }
  };

  // Keyboard shortcuts handler
  const handleKeyPress = useCallback((e: KeyboardEvent) => {
    // Don't trigger if user is typing in textarea
    if (e.target instanceof HTMLTextAreaElement) return;
    
    switch (e.key.toLowerCase()) {
      case 'a':
        setLabel(prev => ({ ...prev, verdict: 'authentic' }));
        break;
      case 'f':
        setLabel(prev => ({ ...prev, verdict: 'fake' }));
        break;
      case 'u':
        setLabel(prev => ({ ...prev, verdict: 'uncertain' }));
        break;
      case 'enter':
        if (e.ctrlKey || e.metaKey) {
          handleSubmitLabel();
        }
        break;
    }
  }, [handleSubmitLabel]);

  // Register keyboard shortcuts
  useEffect(() => {
    window.addEventListener('keydown', handleKeyPress);
    return () => window.removeEventListener('keydown', handleKeyPress);
  }, [handleKeyPress]);

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
        <div className="flex items-center justify-between mb-8">
          <h1 className="text-3xl font-bold text-gray-900 flex items-center">
            <Tag className="mr-3 h-8 w-8" />
            Image Labeling
          </h1>
          {queue.length > 0 && (
            <div className="text-sm text-gray-600 bg-white px-4 py-2 rounded-lg shadow">
              Progress: <span className="font-semibold text-blue-600">{currentIndex + 1}</span> / {queue.length}
            </div>
          )}
        </div>
        
        <div className="grid grid-cols-1 lg:grid-cols-4 gap-6 mb-6">
          <div className="lg:col-span-3">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Filter by Dataset:
            </label>
            <select
              value={selectedDataset}
              onChange={(e) => setSelectedDataset(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">All Datasets</option>
              {datasets.map((ds) => (
                <option key={ds.id} value={ds.id}>
                  {ds.name}
                </option>
              ))}
            </select>
          </div>
          
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
            <div className="flex items-center gap-2 mb-2">
              <Keyboard className="h-5 w-5 text-blue-600" />
              <h3 className="text-sm font-semibold text-blue-900">Keyboard Shortcuts</h3>
            </div>
            <div className="text-xs text-blue-800 space-y-1">
              <div><kbd className="px-2 py-1 bg-white rounded border">A</kbd> Authentic</div>
              <div><kbd className="px-2 py-1 bg-white rounded border">F</kbd> Fake</div>
              <div><kbd className="px-2 py-1 bg-white rounded border">U</kbd> Uncertain</div>
              <div><kbd className="px-2 py-1 bg-white rounded border">Ctrl+Enter</kbd> Submit</div>
            </div>
          </div>
        </div>

        {error && (
          <div className="mb-6 rounded-md bg-red-50 border border-red-200 p-4">
            <div className="flex items-center gap-2">
              <AlertCircle className="h-5 w-5 text-red-600" />
              <div className="text-sm text-red-700">{error}</div>
            </div>
          </div>
        )}

        {queue.length === 0 ? (
          <div className="bg-white rounded-lg shadow-md p-12 text-center">
            <CheckCircle className="mx-auto h-16 w-16 text-green-400 mb-4" />
            <h3 className="text-xl font-medium text-gray-900">All Done! 🎉</h3>
            <p className="mt-2 text-sm text-gray-500">
              All images have been labeled. Great work!
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <div className="lg:col-span-2">
              {currentImage && (
                <div className="bg-white rounded-lg shadow-lg p-6">
                  <div className="flex items-center justify-between mb-4">
                    <h2 className="text-xl font-semibold">Current Image</h2>
                    <div className="flex items-center gap-2 text-sm text-gray-500">
                      <Info className="h-4 w-4" />
                      <span>#{currentIndex + 1}</span>
                    </div>
                  </div>
                  {currentImage.presigned_url ? (
                    <div className="relative">
                      <img
                        src={currentImage.presigned_url}
                        alt="Labeling"
                        className="w-full border-2 border-gray-200 rounded-lg shadow-sm hover:shadow-md transition-shadow"
                      />
                    </div>
                  ) : (
                    <div className="flex items-center justify-center py-24 bg-gray-50 rounded-lg border-2 border-dashed border-gray-300">
                      <div className="text-center">
                        <AlertCircle className="mx-auto h-12 w-12 text-gray-400 mb-2" />
                        <p className="text-gray-500">Image not available</p>
                      </div>
                    </div>
                  )}
                  {currentImage.minio_path && (
                    <div className="mt-3 text-xs text-gray-500">
                      Path: {currentImage.minio_path}
                    </div>
                  )}
                </div>
              )}
            </div>
            
            <div className="bg-white rounded-lg shadow-lg p-6">
              <h3 className="text-lg font-semibold mb-4">Label Form</h3>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Verdict <span className="text-gray-400 text-xs">(A/F/U)</span>
                  </label>
                  <select
                    value={label.verdict}
                    onChange={(e) => setLabel({ ...label, verdict: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all"
                  >
                    <option value="authentic">✓ Authentic</option>
                    <option value="fake">✗ Fake</option>
                    <option value="uncertain">? Uncertain</option>
                  </select>
                </div>
                
                <div className="grid grid-cols-3 gap-2">
                  <button
                    onClick={() => setLabel({ ...label, verdict: 'authentic' })}
                    className={`px-3 py-2 text-sm rounded-md border transition-all ${
                      label.verdict === 'authentic'
                        ? 'bg-green-100 border-green-500 text-green-700 font-semibold'
                        : 'bg-white border-gray-300 text-gray-700 hover:bg-gray-50'
                    }`}
                  >
                    <CheckCircle className="h-4 w-4 mx-auto mb-1" />
                    Authentic
                  </button>
                  <button
                    onClick={() => setLabel({ ...label, verdict: 'fake' })}
                    className={`px-3 py-2 text-sm rounded-md border transition-all ${
                      label.verdict === 'fake'
                        ? 'bg-red-100 border-red-500 text-red-700 font-semibold'
                        : 'bg-white border-gray-300 text-gray-700 hover:bg-gray-50'
                    }`}
                  >
                    <XCircle className="h-4 w-4 mx-auto mb-1" />
                    Fake
                  </button>
                  <button
                    onClick={() => setLabel({ ...label, verdict: 'uncertain' })}
                    className={`px-3 py-2 text-sm rounded-md border transition-all ${
                      label.verdict === 'uncertain'
                        ? 'bg-yellow-100 border-yellow-500 text-yellow-700 font-semibold'
                        : 'bg-white border-gray-300 text-gray-700 hover:bg-gray-50'
                    }`}
                  >
                    <AlertCircle className="h-4 w-4 mx-auto mb-1" />
                    Uncertain
                  </button>
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Notes <span className="text-gray-400 text-xs">(optional)</span>
                  </label>
                  <textarea
                    value={label.notes}
                    onChange={(e) => setLabel({ ...label, notes: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none"
                    rows={4}
                    placeholder="Any additional observations or notes..."
                  />
                </div>
                
                <button
                  onClick={handleSubmitLabel}
                  disabled={!currentImage || submitting}
                  className="w-full px-4 py-3 bg-blue-600 text-white font-semibold rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-sm hover:shadow-md"
                >
                  {submitting ? (
                    <span className="flex items-center justify-center gap-2">
                      <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                      Submitting...
                    </span>
                  ) : (
                    'Submit Label (Ctrl+Enter)'
                  )}
                </button>
              </div>
            </div>
          </div>
        )}

        <div className="mt-8 bg-white rounded-lg shadow-md p-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-semibold">
              Queue ({queue.length} {queue.length === 1 ? 'image' : 'images'} remaining)
            </h3>
            <div className="text-sm text-gray-500">
              Click to jump to an image
            </div>
          </div>
          <div className="flex flex-wrap gap-2">
            {queue.map((img, idx) => (
              <button
                key={img.id}
                onClick={() => {
                  setCurrentImage(img);
                  setCurrentIndex(idx);
                }}
                className={`px-4 py-2 rounded-md text-sm border transition-all shadow-sm ${
                  currentImage?.id === img.id
                    ? 'bg-blue-600 border-blue-600 text-white font-semibold shadow-md scale-105'
                    : 'bg-white border-gray-300 text-gray-700 hover:bg-gray-50 hover:border-gray-400'
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

