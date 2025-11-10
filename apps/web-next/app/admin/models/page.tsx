'use client';

import { useState, useEffect } from 'react';
import { modelsApi } from '@/lib/api';
import Link from 'next/link';
import { Package, CheckCircle, XCircle } from 'lucide-react';

export default function ModelsPage() {
  const [models, setModels] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadModels();
  }, []);

  const loadModels = async () => {
    try {
      setLoading(true);
      const data = await modelsApi.list();
      setModels(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load models');
    } finally {
      setLoading(false);
    }
  };

  const handleDeploy = async (version: string) => {
    if (!confirm(`Deploy model ${version}?`)) return;
    try {
      await modelsApi.deploy(version);
      loadModels();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to deploy model');
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 py-12">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-8 flex items-center">
          <Package className="mr-3 h-8 w-8" />
          Models
        </h1>

        {error && (
          <div className="mb-6 rounded-md bg-red-50 p-4">
            <div className="text-sm text-red-700">{error}</div>
          </div>
        )}

        {loading ? (
          <div className="text-center py-12">
            <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
            <p className="mt-2 text-gray-600">Loading models...</p>
          </div>
        ) : models.length === 0 ? (
          <div className="bg-white rounded-lg shadow-md p-12 text-center">
            <Package className="mx-auto h-12 w-12 text-gray-400" />
            <h3 className="mt-4 text-lg font-medium text-gray-900">No models</h3>
            <p className="mt-2 text-sm text-gray-500">Models will appear here after training jobs complete.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {models.map((model) => (
              <div key={model.id} className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
                <div className="flex justify-between items-start mb-4">
                  <h3 className="text-lg font-semibold text-gray-900">
                    <Link href={`/admin/models/${model.version}`} className="hover:text-blue-600">
                      {model.version}
                    </Link>
                  </h3>
                  {model.is_deployed ? (
                    <CheckCircle className="h-6 w-6 text-green-600" />
                  ) : (
                    <XCircle className="h-6 w-6 text-gray-400" />
                  )}
                </div>
                <div className="space-y-2 text-sm text-gray-600">
                  <div>
                    <span className="font-medium">Type:</span> {model.model_type}
                  </div>
                  <div>
                    <span className="font-medium">Deployed:</span>{' '}
                    <span className={model.is_deployed ? 'text-green-600' : 'text-gray-500'}>
                      {model.is_deployed ? 'Yes' : 'No'}
                    </span>
                  </div>
                  {model.deployed_at && (
                    <div>
                      <span className="font-medium">Deployed At:</span>{' '}
                      {new Date(model.deployed_at).toLocaleString()}
                    </div>
                  )}
                  <div>
                    <span className="font-medium">Created:</span>{' '}
                    {new Date(model.created_at).toLocaleString()}
                  </div>
                </div>
                {!model.is_deployed && (
                  <button
                    onClick={() => handleDeploy(model.version)}
                    className="mt-4 w-full px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
                  >
                    Deploy
                  </button>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

