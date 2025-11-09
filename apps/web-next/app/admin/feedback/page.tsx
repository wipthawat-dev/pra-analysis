'use client';

import { useState, useEffect } from 'react';
import { feedbackApi } from '@/lib/api';
import { MessageSquare, CheckCircle, XCircle, Clock } from 'lucide-react';

export default function FeedbackPage() {
  const [feedbacks, setFeedbacks] = useState<any[]>([]);
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadFeedbacks();
    loadStats();
  }, []);

  const loadFeedbacks = async () => {
    try {
      setLoading(true);
      const data = await feedbackApi.list();
      setFeedbacks(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load feedbacks');
    } finally {
      setLoading(false);
    }
  };

  const loadStats = async () => {
    try {
      const data = await feedbackApi.getStats();
      setStats(data);
    } catch (err) {
      console.error('Failed to load stats:', err);
    }
  };

  const handleApprove = async (id: string) => {
    try {
      await feedbackApi.approve(id);
      loadFeedbacks();
      loadStats();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to approve feedback');
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 py-12">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-8 flex items-center">
          <MessageSquare className="mr-3 h-8 w-8" />
          Feedback Management
        </h1>

        {stats && (
          <div className="mb-8 bg-white rounded-lg shadow-md p-6">
            <h2 className="text-xl font-semibold mb-4">Statistics</h2>
            <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
              <div className="text-center">
                <div className="text-3xl font-bold text-gray-900">{stats.total}</div>
                <div className="text-sm text-gray-600 mt-1">Total</div>
              </div>
              <div className="text-center">
                <div className="text-3xl font-bold text-blue-600">{stats.reviewed}</div>
                <div className="text-sm text-gray-600 mt-1">Reviewed</div>
              </div>
              <div className="text-center">
                <div className="text-3xl font-bold text-yellow-600">{stats.unreviewed}</div>
                <div className="text-sm text-gray-600 mt-1">Unreviewed</div>
              </div>
              <div className="text-center">
                <div className="text-3xl font-bold text-green-600">{stats.correct}</div>
                <div className="text-sm text-gray-600 mt-1">Correct</div>
              </div>
              <div className="text-center">
                <div className="text-3xl font-bold text-red-600">{stats.incorrect}</div>
                <div className="text-sm text-gray-600 mt-1">Incorrect</div>
              </div>
            </div>
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
            <p className="mt-2 text-gray-600">Loading feedback...</p>
          </div>
        ) : feedbacks.length === 0 ? (
          <div className="bg-white rounded-lg shadow-md p-12 text-center">
            <MessageSquare className="mx-auto h-12 w-12 text-gray-400" />
            <h3 className="mt-4 text-lg font-medium text-gray-900">No feedback</h3>
            <p className="mt-2 text-sm text-gray-500">No feedback has been submitted yet.</p>
          </div>
        ) : (
          <div className="space-y-4">
            {feedbacks.map((fb) => (
              <div key={fb.id} className="bg-white rounded-lg shadow-md p-6">
                <div className="flex justify-between items-start">
                  <div className="flex-1">
                    <div className="flex items-center space-x-2 mb-2">
                      <span className="text-sm font-medium text-gray-700">Prediction ID:</span>
                      <span className="text-sm text-gray-600 font-mono">{fb.prediction_id}</span>
                    </div>
                    <div className="mb-2">
                      <span className="text-sm font-medium text-gray-700">Is Correct:</span>{' '}
                      {fb.is_correct === null ? (
                        <span className="text-gray-500">N/A</span>
                      ) : fb.is_correct ? (
                        <span className="text-green-600 flex items-center inline-flex">
                          <CheckCircle className="h-4 w-4 mr-1" />
                          Yes
                        </span>
                      ) : (
                        <span className="text-red-600 flex items-center inline-flex">
                          <XCircle className="h-4 w-4 mr-1" />
                          No
                        </span>
                      )}
                    </div>
                    {fb.correct_verdict && (
                      <div className="mb-2">
                        <span className="text-sm font-medium text-gray-700">Correct Verdict:</span>{' '}
                        <span className="text-sm text-gray-600">{fb.correct_verdict}</span>
                      </div>
                    )}
                    {fb.notes && (
                      <div className="mb-2">
                        <span className="text-sm font-medium text-gray-700">Notes:</span>
                        <p className="text-sm text-gray-600 mt-1">{fb.notes}</p>
                      </div>
                    )}
                    <div className="text-xs text-gray-500 mt-2">
                      Created: {new Date(fb.created_at).toLocaleString()}
                      {fb.reviewed_at && (
                        <> | Reviewed: {new Date(fb.reviewed_at).toLocaleString()}</>
                      )}
                    </div>
                  </div>
                  {!fb.reviewed_at && (
                    <button
                      onClick={() => handleApprove(fb.id)}
                      className="ml-4 px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 flex items-center"
                    >
                      <CheckCircle className="h-4 w-4 mr-2" />
                      Approve
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

