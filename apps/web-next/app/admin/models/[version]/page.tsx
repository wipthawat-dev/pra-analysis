'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { modelsApi } from '@/lib/api';
import { 
  Package, 
  CheckCircle, 
  XCircle, 
  ArrowLeft,
  Calendar,
  Clock,
  Layers,
  TrendingUp
} from 'lucide-react';
import Link from 'next/link';

export default function ModelDetailPage() {
  const params = useParams();
  const router = useRouter();
  const version = params.version as string;
  
  const [model, setModel] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [deploying, setDeploying] = useState(false);

  useEffect(() => {
    if (version) {
      loadModel();
    }
  }, [version]);

  const loadModel = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await modelsApi.get(version);
      setModel(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load model');
    } finally {
      setLoading(false);
    }
  };

  const handleDeploy = async () => {
    if (!confirm(`Deploy model ${version}?`)) return;
    
    try {
      setDeploying(true);
      setError(null);
      await modelsApi.deploy(version);
      await loadModel(); // Reload to get updated deployment status
      alert('Model deployed successfully!');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to deploy model');
    } finally {
      setDeploying(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          <p className="mt-2 text-gray-600">Loading model details...</p>
        </div>
      </div>
    );
  }

  if (error && !model) {
    return (
      <div className="min-h-screen bg-gray-50 py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <Link 
            href="/admin/models"
            className="inline-flex items-center text-blue-600 hover:text-blue-800 mb-6"
          >
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back to Models
          </Link>
          
          <div className="rounded-md bg-red-50 p-4">
            <div className="flex">
              <XCircle className="h-5 w-5 text-red-400 mr-2" />
              <div className="text-sm text-red-700">{error}</div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 py-12">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <Link 
          href="/admin/models"
          className="inline-flex items-center text-blue-600 hover:text-blue-800 mb-6"
        >
          <ArrowLeft className="h-4 w-4 mr-2" />
          Back to Models
        </Link>

        <div className="mb-8">
          <div className="flex items-center justify-between">
            <h1 className="text-3xl font-bold text-gray-900 flex items-center">
              <Package className="mr-3 h-8 w-8" />
              {model?.version || version}
            </h1>
            <div className="flex items-center space-x-4">
              {model?.is_deployed ? (
                <span className="inline-flex items-center px-4 py-2 rounded-full text-sm font-medium bg-green-100 text-green-800">
                  <CheckCircle className="h-4 w-4 mr-2" />
                  Deployed
                </span>
              ) : (
                <span className="inline-flex items-center px-4 py-2 rounded-full text-sm font-medium bg-gray-100 text-gray-800">
                  <XCircle className="h-4 w-4 mr-2" />
                  Not Deployed
                </span>
              )}
            </div>
          </div>
        </div>

        {error && (
          <div className="mb-6 rounded-md bg-red-50 p-4">
            <div className="flex">
              <XCircle className="h-5 w-5 text-red-400 mr-2" />
              <div className="text-sm text-red-700">{error}</div>
            </div>
          </div>
        )}

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
          {/* Model Information Card */}
          <div className="lg:col-span-2 bg-white rounded-lg shadow-md p-6">
            <h2 className="text-xl font-semibold mb-6 flex items-center">
              <Layers className="h-5 w-5 mr-2" />
              Model Information
            </h2>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label className="block text-sm font-medium text-gray-500 mb-1">
                  Version
                </label>
                <div className="text-lg font-semibold text-gray-900">
                  {model?.version || 'N/A'}
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-500 mb-1">
                  Model Type
                </label>
                <div className="text-lg font-semibold text-gray-900">
                  {model?.model_type || 'N/A'}
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-500 mb-1 flex items-center">
                  <Calendar className="h-4 w-4 mr-1" />
                  Created At
                </label>
                <div className="text-lg font-semibold text-gray-900">
                  {model?.created_at 
                    ? new Date(model.created_at).toLocaleString()
                    : 'N/A'}
                </div>
              </div>

              {model?.deployed_at && (
                <div>
                  <label className="block text-sm font-medium text-gray-500 mb-1 flex items-center">
                    <Clock className="h-4 w-4 mr-1" />
                    Deployed At
                  </label>
                  <div className="text-lg font-semibold text-gray-900">
                    {new Date(model.deployed_at).toLocaleString()}
                  </div>
                </div>
              )}

              {model?.training_job_id && (
                <div>
                  <label className="block text-sm font-medium text-gray-500 mb-1">
                    Training Job ID
                  </label>
                  <Link
                    href={`/admin/training/${model.training_job_id}`}
                    className="text-lg font-semibold text-blue-600 hover:text-blue-800 hover:underline"
                  >
                    {model.training_job_id.slice(0, 8)}...
                  </Link>
                </div>
              )}

              {model?.dataset_id && (
                <div>
                  <label className="block text-sm font-medium text-gray-500 mb-1">
                    Dataset ID
                  </label>
                  <Link
                    href={`/admin/datasets/${model.dataset_id}`}
                    className="text-lg font-semibold text-blue-600 hover:text-blue-800 hover:underline"
                  >
                    {model.dataset_id.slice(0, 8)}...
                  </Link>
                </div>
              )}
            </div>

            {/* Metadata */}
            {model?.metadata && Object.keys(model.metadata).length > 0 && (
              <div className="mt-8">
                <label className="block text-sm font-medium text-gray-500 mb-2">
                  Metadata
                </label>
                <div className="bg-gray-50 rounded-lg p-4 overflow-x-auto">
                  <pre className="text-sm text-gray-700">
                    {JSON.stringify(model.metadata, null, 2)}
                  </pre>
                </div>
              </div>
            )}
          </div>

          {/* Actions Card */}
          <div className="space-y-6">
            {/* Deploy Action */}
            <div className="bg-white rounded-lg shadow-md p-6">
              <h3 className="text-lg font-semibold mb-4">Actions</h3>
              
              {!model?.is_deployed ? (
                <button
                  onClick={handleDeploy}
                  disabled={deploying}
                  className={`w-full px-4 py-3 rounded-md font-medium transition-colors ${
                    deploying
                      ? 'bg-gray-300 text-gray-500 cursor-not-allowed'
                      : 'bg-blue-600 text-white hover:bg-blue-700'
                  }`}
                >
                  {deploying ? 'Deploying...' : 'Deploy Model'}
                </button>
              ) : (
                <div className="text-center py-3 text-green-600 font-medium">
                  ✓ Model is currently deployed
                </div>
              )}
            </div>

            {/* Evaluation (if available) */}
            {model?.evaluation_metrics && (
              <div className="bg-white rounded-lg shadow-md p-6">
                <h3 className="text-lg font-semibold mb-4 flex items-center">
                  <TrendingUp className="h-5 w-5 mr-2" />
                  Evaluation Metrics
                </h3>
                <div className="space-y-3">
                  {Object.entries(model.evaluation_metrics).map(([key, value]: [string, any]) => (
                    <div key={key}>
                      <label className="block text-xs font-medium text-gray-500 mb-1">
                        {key.replace(/_/g, ' ').toUpperCase()}
                      </label>
                      <div className="text-lg font-semibold text-gray-900">
                        {typeof value === 'number' ? value.toFixed(4) : String(value)}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* File Information */}
            {(model?.s3_path || model?.file_path) && (
              <div className="bg-white rounded-lg shadow-md p-6">
                <h3 className="text-lg font-semibold mb-4">Storage</h3>
                <div className="space-y-3">
                  {model?.s3_path && (
                    <div>
                      <label className="block text-xs font-medium text-gray-500 mb-1">
                        S3 Path
                      </label>
                      <div className="text-sm text-gray-700 break-all font-mono bg-gray-50 p-2 rounded">
                        {model.s3_path}
                      </div>
                    </div>
                  )}
                  {model?.file_path && (
                    <div>
                      <label className="block text-xs font-medium text-gray-500 mb-1">
                        File Path
                      </label>
                      <div className="text-sm text-gray-700 break-all font-mono bg-gray-50 p-2 rounded">
                        {model.file_path}
                      </div>
                    </div>
                  )}
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

