'use client';

import { useState } from 'react';
import { Upload, Loader2 } from 'lucide-react';

const MAX_FILE_SIZE_MB = 15;
const MAX_FILE_SIZE_BYTES = MAX_FILE_SIZE_MB * 1024 * 1024;
const ALLOWED_TYPES = ['image/jpeg', 'image/png'];

export default function AnalyzePage() {
  const [file, setFile] = useState<File | null>(null);
  const [resp, setResp] = useState<any>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const apiBase = process.env.NEXT_PUBLIC_API_BASE || 'http://localhost:8000';

  const validateFile = (file: File): string | null => {
    if (!ALLOWED_TYPES.includes(file.type)) {
      return `รองรับเฉพาะไฟล์ JPEG และ PNG เท่านั้น (ไฟล์ที่เลือก: ${file.type})`;
    }
    if (file.size > MAX_FILE_SIZE_BYTES) {
      return `ขนาดไฟล์ต้องไม่เกิน ${MAX_FILE_SIZE_MB}MB (ไฟล์ที่เลือก: ${(file.size / 1024 / 1024).toFixed(2)}MB)`;
    }
    return null;
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFile = e.target.files?.[0] || null;
    setError(null);
    setResp(null);
    
    if (selectedFile) {
      const validationError = validateFile(selectedFile);
      if (validationError) {
        setError(validationError);
        setFile(null);
        e.target.value = '';
        return;
      }
    }
    
    setFile(selectedFile);
  };

  const onSubmit = async () => {
    if (!file) return;
    
    setError(null);
    setResp(null);
    setLoading(true);

    console.log('🚀 Starting upload...', {
      fileName: file.name,
      fileSize: file.size,
      fileType: file.type,
      apiBase,
      url: `${apiBase}/v1/analyze`
    });

    try {
      const form = new FormData();
      form.append('file', file);
      
      console.log('📤 Sending request to:', `${apiBase}/v1/analyze`);
      
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 30000);
      
      const response = await fetch(`${apiBase}/v1/analyze`, {
        method: 'POST',
        body: form,
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      console.log('📥 Response received:', {
        status: response.status,
        statusText: response.statusText,
        ok: response.ok,
        headers: Object.fromEntries(response.headers.entries())
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({ detail: response.statusText }));
        console.error('❌ Error response:', errorData);
        throw new Error(errorData.detail || `เกิดข้อผิดพลาด: ${response.status} ${response.statusText}`);
      }

      const data = await response.json();
      console.log('✅ Success:', data);
      setResp(data);
    } catch (err) {
      let errorMessage = 'เกิดข้อผิดพลาดในการอัปโหลด';
      
      console.error('💥 Fetch error:', err);
      
      if (err instanceof Error) {
        if (err.name === 'AbortError') {
          errorMessage = 'การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง';
        } else if (err.message.includes('Failed to fetch') || err.message.includes('NetworkError')) {
          errorMessage = `ไม่สามารถเชื่อมต่อกับ API server ได้ (${apiBase}) กรุณาตรวจสอบว่า API server กำลังทำงานอยู่หรือไม่`;
        } else {
          errorMessage = err.message;
        }
      }
      
      setError(errorMessage);
      console.error('Upload error:', err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="min-h-screen bg-gray-50 py-12">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="bg-white rounded-lg shadow-md p-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-6">Analyze Image</h1>
          
          <div className="space-y-6">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Upload Image
              </label>
              <div className="mt-1 flex justify-center px-6 pt-5 pb-6 border-2 border-gray-300 border-dashed rounded-lg hover:border-blue-400 transition-colors">
                <div className="space-y-1 text-center">
                  <Upload className="mx-auto h-12 w-12 text-gray-400" />
                  <div className="flex text-sm text-gray-600">
                    <label htmlFor="file-upload" className="relative cursor-pointer bg-white rounded-md font-medium text-blue-600 hover:text-blue-500 focus-within:outline-none focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-blue-500">
                      <span>Upload a file</span>
                      <input
                        id="file-upload"
                        name="file-upload"
                        type="file"
                        accept="image/jpeg,image/png"
                        onChange={handleFileChange}
                        disabled={loading}
                        className="sr-only"
                      />
                    </label>
                    <p className="pl-1">or drag and drop</p>
                  </div>
                  <p className="text-xs text-gray-500">PNG, JPG up to {MAX_FILE_SIZE_MB}MB</p>
                </div>
              </div>
              {file && (
                <div className="mt-4 p-4 bg-blue-50 rounded-lg">
                  <p className="text-sm text-gray-700">
                    <span className="font-medium">ไฟล์ที่เลือก:</span> {file.name} ({(file.size / 1024 / 1024).toFixed(2)}MB)
                  </p>
                </div>
              )}
            </div>

            <button
              onClick={onSubmit}
              disabled={!file || loading}
              className="w-full flex items-center justify-center px-4 py-3 border border-transparent rounded-md shadow-sm text-base font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              {loading ? (
                <>
                  <Loader2 className="animate-spin h-5 w-5 mr-2" />
                  กำลังวิเคราะห์...
                </>
              ) : (
                'Analyze'
              )}
            </button>

            {error && (
              <div className="rounded-md bg-red-50 p-4">
                <div className="flex">
                  <div className="ml-3">
                    <h3 className="text-sm font-medium text-red-800">ข้อผิดพลาด</h3>
                    <div className="mt-2 text-sm text-red-700">
                      <p>{error}</p>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {resp && (
              <div className="mt-6">
                <h2 className="text-xl font-semibold text-gray-900 mb-4">Results</h2>
                <div className="bg-gray-900 rounded-lg p-6 overflow-x-auto">
                  <pre className="text-green-400 text-sm">
                    {JSON.stringify(resp, null, 2)}
                  </pre>
                </div>
                {resp.prediction_id && (
                  <div className="mt-4">
                    <a
                      href={`/analyze/${resp.prediction_id}/feedback`}
                      className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors"
                    >
                      Provide Feedback
                    </a>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      </div>
    </main>
  );
}

