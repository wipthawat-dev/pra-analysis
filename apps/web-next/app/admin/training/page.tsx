'use client';

import { useState, useEffect } from 'react';
import { trainingApi, datasetsApi } from '@/lib/api';
import Link from 'next/link';
import { Brain, Plus, Play, Clock, CheckCircle, XCircle, AlertCircle } from 'lucide-react';

export default function TrainingPage() {
  const [jobs, setJobs] = useState<any[]>([]);
  const [datasets, setDatasets] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [newJob, setNewJob] = useState({
    dataset_id: '',
    model_type: 'classifier',
    config: JSON.stringify({ epochs: 10, batch_size: 32 }, null, 2),
  });

  useEffect(() => {
    loadJobs();
    loadDatasets();
  }, []);

  const loadJobs = async () => {
    try {
      setLoading(true);
      const data = await trainingApi.listJobs();
      setJobs(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load jobs');
    } finally {
      setLoading(false);
    }
  };

  const loadDatasets = async () => {
    try {
      const data = await datasetsApi.list();
      setDatasets(data);
    } catch (err) {
      console.error('Failed to load datasets:', err);
    }
  };

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const config = JSON.parse(newJob.config);
      await trainingApi.createJob({
        dataset_id: newJob.dataset_id,
        model_type: newJob.model_type,
        config,
      });
      setShowCreateForm(false);
      setNewJob({ dataset_id: '', model_type: 'classifier', config: JSON.stringify({ epochs: 10, batch_size: 32 }, null, 2) });
      loadJobs();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create job');
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'completed':
        return <CheckCircle className="h-5 w-5 text-green-600" />;
      case 'running':
        return <Play className="h-5 w-5 text-blue-600 animate-pulse" />;
      case 'failed':
        return <XCircle className="h-5 w-5 text-red-600" />;
      case 'pending':
        return <Clock className="h-5 w-5 text-yellow-600" />;
      default:
        return <AlertCircle className="h-5 w-5 text-gray-600" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed': return 'bg-green-100 text-green-800';
      case 'running': return 'bg-blue-100 text-blue-800';
      case 'failed': return 'bg-red-100 text-red-800';
      case 'pending': return 'bg-yellow-100 text-yellow-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 py-12">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 flex items-center">
              <Brain className="mr-3 h-8 w-8" />
              Training Jobs
            </h1>
            <p className="mt-2 text-gray-600">Create and monitor ML model training jobs</p>
          </div>
          <button
            onClick={() => setShowCreateForm(!showCreateForm)}
            className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
          >
            <Plus className="h-5 w-5 mr-2" />
            {showCreateForm ? 'Cancel' : 'Create Training Job'}
          </button>
        </div>

        {showCreateForm && (
          <div className="mb-6 bg-white rounded-lg shadow-md p-6">
            <h2 className="text-xl font-semibold mb-4">Create Training Job</h2>
            <form onSubmit={handleCreate} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Dataset *</label>
                <select
                  value={newJob.dataset_id}
                  onChange={(e) => setNewJob({ ...newJob, dataset_id: e.target.value })}
                  required
                  className="w-full px-3 py-2 border border-gray-300 rounded-md"
                >
                  <option value="">Select dataset</option>
                  {datasets.map((ds) => (
                    <option key={ds.id} value={ds.id}>
                      {ds.name}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Model Type *</label>
                <select
                  value={newJob.model_type}
                  onChange={(e) => setNewJob({ ...newJob, model_type: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md"
                >
                  <option value="detector">Detector</option>
                  <option value="embedder">Embedder</option>
                  <option value="classifier">Classifier</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Config (JSON) *</label>
                <textarea
                  value={newJob.config}
                  onChange={(e) => setNewJob({ ...newJob, config: e.target.value })}
                  required
                  className="w-full px-3 py-2 border border-gray-300 rounded-md font-mono text-sm"
                  rows={8}
                />
              </div>
              <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700">
                Create Job
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
            <p className="mt-2 text-gray-600">Loading jobs...</p>
          </div>
        ) : jobs.length === 0 ? (
          <div className="bg-white rounded-lg shadow-md p-12 text-center">
            <Brain className="mx-auto h-12 w-12 text-gray-400" />
            <h3 className="mt-4 text-lg font-medium text-gray-900">No training jobs</h3>
            <p className="mt-2 text-sm text-gray-500">Create your first training job to get started.</p>
          </div>
        ) : (
          <div className="space-y-4">
            {jobs.map((job) => (
              <div key={job.id} className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
                <div className="flex justify-between items-start">
                  <div className="flex-1">
                    <h3 className="text-lg font-semibold text-gray-900 mb-2">
                      <Link href={`/admin/training/${job.id}`} className="hover:text-blue-600">
                        {job.model_type} - {job.id.slice(0, 8)}
                      </Link>
                    </h3>
                    <div className="flex items-center space-x-4 text-sm text-gray-600">
                      <div className="flex items-center">
                        {getStatusIcon(job.status)}
                        <span className={`ml-2 px-2 py-1 rounded text-xs ${getStatusColor(job.status)}`}>
                          {job.status}
                        </span>
                      </div>
                      {job.model_version && (
                        <div>
                          <span className="font-medium">Version:</span> {job.model_version}
                        </div>
                      )}
                      {job.started_at && (
                        <div>
                          <span className="font-medium">Started:</span> {new Date(job.started_at).toLocaleString()}
                        </div>
                      )}
                    </div>
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

