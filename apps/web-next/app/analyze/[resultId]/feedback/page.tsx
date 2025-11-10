'use client';

import { useState } from 'react';
import { useParams } from 'next/navigation';
import { feedbackApi } from '@/lib/api';
import { MessageSquare, CheckCircle, XCircle, AlertCircle } from 'lucide-react';

export default function FeedbackPage() {
  const params = useParams();
  const resultId = params.resultId as string;
  
  const [feedback, setFeedback] = useState({
    is_correct: true,
    correct_verdict: '',
    notes: '',
  });
  const [submitting, setSubmitting] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      setSubmitting(true);
      await feedbackApi.create({
        prediction_id: resultId,
        ...feedback,
      });
      setSubmitted(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to submit feedback');
    } finally {
      setSubmitting(false);
    }
  };

  if (submitted) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center py-12">
        <div className="max-w-md mx-auto px-4">
          <div className="bg-white rounded-lg shadow-md p-8 text-center">
            <CheckCircle className="mx-auto h-16 w-16 text-green-600 mb-4" />
            <h1 className="text-2xl font-bold text-gray-900 mb-2">Thank you!</h1>
            <p className="text-gray-600">Your feedback has been submitted successfully.</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 py-12">
      <div className="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="bg-white rounded-lg shadow-md p-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-6 flex items-center">
            <MessageSquare className="mr-3 h-8 w-8" />
            Provide Feedback
          </h1>
          
          {error && (
            <div className="mb-6 rounded-md bg-red-50 p-4">
              <div className="text-sm text-red-700">{error}</div>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-6">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-3">
                Was the prediction correct?
              </label>
              <div className="space-y-2">
                <label className="flex items-center p-4 border border-gray-300 rounded-md hover:bg-gray-50 cursor-pointer">
                  <input
                    type="radio"
                    name="is_correct"
                    checked={feedback.is_correct === true}
                    onChange={() => setFeedback({ ...feedback, is_correct: true, correct_verdict: '' })}
                    className="mr-3"
                  />
                  <CheckCircle className="h-5 w-5 text-green-600 mr-2" />
                  <span>Yes, the prediction is correct</span>
                </label>
                <label className="flex items-center p-4 border border-gray-300 rounded-md hover:bg-gray-50 cursor-pointer">
                  <input
                    type="radio"
                    name="is_correct"
                    checked={feedback.is_correct === false}
                    onChange={() => setFeedback({ ...feedback, is_correct: false })}
                    className="mr-3"
                  />
                  <XCircle className="h-5 w-5 text-red-600 mr-2" />
                  <span>No, the prediction is incorrect</span>
                </label>
              </div>
            </div>

            {!feedback.is_correct && (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  What is the correct verdict?
                </label>
                <select
                  value={feedback.correct_verdict}
                  onChange={(e) => setFeedback({ ...feedback, correct_verdict: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="">Select...</option>
                  <option value="authentic">Authentic</option>
                  <option value="fake">Fake</option>
                  <option value="uncertain">Uncertain</option>
                </select>
              </div>
            )}

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Notes (optional)
              </label>
              <textarea
                value={feedback.notes}
                onChange={(e) => setFeedback({ ...feedback, notes: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                rows={4}
                placeholder="Any additional comments..."
              />
            </div>

            <button
              type="submit"
              disabled={submitting || (!feedback.is_correct && !feedback.correct_verdict)}
              className="w-full px-4 py-3 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors"
            >
              {submitting ? 'Submitting...' : 'Submit Feedback'}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}

