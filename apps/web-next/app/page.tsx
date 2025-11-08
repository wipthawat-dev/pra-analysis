'use client';
import { useState } from 'react';

export default function Home() {
  const [file, setFile] = useState<File | null>(null);
  const [resp, setResp] = useState<any>(null);
  const apiBase = process.env.NEXT_PUBLIC_API_BASE || 'http://localhost:8000';

  const onSubmit = async () => {
    if (!file) return;
    const form = new FormData();
    form.append('file', file);
    const r = await fetch(`${apiBase}/v1/analyze`, { method: 'POST', body: form });
    const j = await r.json();
    setResp(j);
  };

  return (
    <main style={{ maxWidth: 720, margin: '32px auto', padding: 16 }}>
      <h1>Amulet Authenticity (Safe OSS)</h1>
      <input type="file" accept="image/*" onChange={(e)=> setFile(e.target.files?.[0] || null)} />
      <button onClick={onSubmit} disabled={!file} style={{ marginLeft: 12 }}>Analyze</button>
      {resp && (
        <pre style={{ marginTop: 24, background: '#111', color: '#0f0', padding: 16 }}>
{JSON.stringify(resp, null, 2)}
        </pre>
      )}
    </main>
  );
}
