'use client';

import { useState, useEffect } from 'react';
import { useParams } from 'next/navigation';
import { trainingApi } from '@/lib/api';
import { Brain, Clock, CheckCircle } from 'lucide-react';

export default function TrainingJobPage() {
  const params = useParams();
  const jobId = params.jobId as string;
  
  const [job, setJob] = useState<any>(null);
  const [logs, setLogs] = useState<string>('');
  const [metrics, setMetrics] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (jobId) {
      loadJob();
      loadLogs();
      loadMetrics();
    }
  }, [jobId]);

  const loadJob = async () => {
    try {
      const data = await trainingApi.getJob(jobId);
      setJob(data);
    } catch (err) {
      console.error('Failed to load job:', err);
    } finally {
      setLoading(false);
    }
  };

  const loadLogs = async () => {
    try {
      const data = await trainingApi.getLogs(jobId);
      setLogs(data.logs || 'No logs available yet');
    } catch (err) {
      setLogs('Failed to load logs');
    }
  };

  const loadMetrics = async () => {
    try {
      const data = await trainingApi.getMetrics(jobId);
      setMetrics(data);
    } catch (err) {
      console.error('Failed to load metrics:', err);
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

  if (!job) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <p className="text-gray-600">Job not found</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 py-12">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-8 flex items-center">
          <Brain className="mr-3 h-8 w-8" />
          Training Job: {job.model_type}
        </h1>
        
        <div className="bg-white rounded-lg shadow-md p-6 mb-6">
          <h2 className="text-xl font-semibold mb-4">Status: {job.status}</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
            {job.started_at && (
              <div className="flex items-center">
                <Clock className="h-5 w-5 mr-2 text-gray-400" />
                <div>
                  <div className="font-medium">Started</div>
                  <div className="text-gray-600">{new Date(job.started_at).toLocaleString()}</div>
                </div>
              </div>
            )}
            {job.completed_at && (
              <div className="flex items-center">
                <CheckCircle className="h-5 w-5 mr-2 text-green-600" />
                <div>
                  <div className="font-medium">Completed</div>
                  <div className="text-gray-600">{new Date(job.completed_at).toLocaleString()}</div>
                </div>
              </div>
            )}
            {job.model_version && (
              <div>
                <div className="font-medium">Model Version</div>
                <div className="text-gray-600">{job.model_version}</div>
              </div>
            )}
          </div>
        </div>

        {metrics && Object.keys(metrics).length > 0 && (
          <div className="bg-white rounded-lg shadow-md p-6 mb-6">
            <h2 className="text-xl font-semibold mb-4">Metrics</h2>
            <pre className="bg-gray-50 p-4 rounded-md overflow-x-auto text-sm">
              {JSON.stringify(metrics, null, 2)}
            </pre>
          </div>
        )}

        <div className="bg-white rounded-lg shadow-md p-6">
          <h2 className="text-xl font-semibold mb-4">Logs</h2>
          <pre className="bg-gray-900 text-green-400 p-4 rounded-md overflow-auto max-h-96 text-sm font-mono">
            {logs}
          </pre>
        </div>
      </div>
    </div>
  );
}

