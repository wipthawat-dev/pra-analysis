'use client';

import { useState, useEffect } from 'react';
import { datasetsApi } from '@/lib/api';
import Link from 'next/link';
import { Database, Plus, Trash2 } from 'lucide-react';

interface Dataset {
  id: string;
  name: string;
  description?: string;
  status: string;
  minio_bucket?: string;
  created_at: string;
}

export default function DatasetsPage() {
  const [datasets, setDatasets] = useState<Dataset[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [newDataset, setNewDataset] = useState({ name: '', description: '' });

  useEffect(() => {
    loadDatasets();
  }, []);

  const loadDatasets = async () => {
    try {
      setLoading(true);
      const data = await datasetsApi.list();
      setDatasets(data);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load datasets');
    } finally {
      setLoading(false);
    }
  };

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await datasetsApi.create(newDataset);
      setShowCreateForm(false);
      setNewDataset({ name: '', description: '' });
      loadDatasets();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create dataset');
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this dataset?')) return;
    try {
      await datasetsApi.delete(id);
      loadDatasets();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete dataset');
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 py-12">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 flex items-center">
              <Database className="mr-3 h-8 w-8" />
              Datasets
            </h1>
            <p className="mt-2 text-gray-600">Manage your image datasets</p>
          </div>
          <button
            onClick={() => setShowCreateForm(!showCreateForm)}
            className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
          >
            <Plus className="h-5 w-5 mr-2" />
            {showCreateForm ? 'Cancel' : 'Create Dataset'}
          </button>
        </div>

        {showCreateForm && (
          <div className="mb-6 bg-white rounded-lg shadow-md p-6">
            <h2 className="text-xl font-semibold mb-4">Create New Dataset</h2>
            <form onSubmit={handleCreate} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Name *
                </label>
                <input
                  type="text"
                  value={newDataset.name}
                  onChange={(e) => setNewDataset({ ...newDataset, name: e.target.value })}
                  required
                  className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                  placeholder="Dataset name"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Description
                </label>
                <textarea
                  value={newDataset.description}
                  onChange={(e) => setNewDataset({ ...newDataset, description: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                  rows={3}
                  placeholder="Dataset description"
                />
              </div>
              <button
                type="submit"
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
              >
                Create Dataset
              </button>
            </form>
          </div>
        )}

        {error && (
          <div className="mb-6 rounded-md bg-red-50 p-4">
            <div className="text-sm text-red-700">{error}</div>
          </div>
        )}

        {loading ? (
          <div className="text-center py-12">
            <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
            <p className="mt-2 text-gray-600">Loading datasets...</p>
          </div>
        ) : datasets.length === 0 ? (
          <div className="bg-white rounded-lg shadow-md p-12 text-center">
            <Database className="mx-auto h-12 w-12 text-gray-400" />
            <h3 className="mt-4 text-lg font-medium text-gray-900">No datasets</h3>
            <p className="mt-2 text-sm text-gray-500">Get started by creating a new dataset.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {datasets.map((dataset) => (
              <div key={dataset.id} className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
                <div className="flex justify-between items-start mb-4">
                  <h3 className="text-lg font-semibold text-gray-900">
                    <Link href={`/admin/datasets/${dataset.id}`} className="hover:text-blue-600">
                      {dataset.name}
                    </Link>
                  </h3>
                  <button
                    onClick={() => handleDelete(dataset.id)}
                    className="text-red-600 hover:text-red-800"
                  >
                    <Trash2 className="h-5 w-5" />
                  </button>
                </div>
                {dataset.description && (
                  <p className="text-sm text-gray-600 mb-4 line-clamp-2">{dataset.description}</p>
                )}
                <div className="space-y-2 text-sm text-gray-500">
                  <div className="flex items-center">
                    <span className="font-medium mr-2">Status:</span>
                    <span className={`px-2 py-1 rounded text-xs ${
                      dataset.status === 'active' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'
                    }`}>
                      {dataset.status}
                    </span>
                  </div>
                  {dataset.minio_bucket && (
                    <div>
                      <span className="font-medium">Bucket:</span> {dataset.minio_bucket}
                    </div>
                  )}
                  <div>
                    <span className="font-medium">Created:</span> {new Date(dataset.created_at).toLocaleDateString()}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

