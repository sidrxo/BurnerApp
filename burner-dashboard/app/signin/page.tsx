'use client';

import { useEffect } from 'react';
import { useSearchParams } from 'next/navigation';

export default function SignInPage() {
  const searchParams = useSearchParams();

  useEffect(() => {
    // Log all parameters for debugging
    const params = Object.fromEntries(searchParams.entries());
    console.log('Sign-in page loaded with params:', params);
    
    // The universal link will automatically open the app if installed
    // This page is just a fallback
  }, [searchParams]);

  return (
    <div style={{ 
      display: 'flex', 
      flexDirection: 'column', 
      alignItems: 'center', 
      justifyContent: 'center', 
      minHeight: '100vh',
      fontFamily: 'system-ui, -apple-system, sans-serif',
      padding: '20px',
      backgroundColor: '#000',
      color: '#fff'
    }}>
      <h1 style={{ fontSize: '2rem', marginBottom: '1rem' }}>
        Opening Burner App...
      </h1>
      <p style={{ color: '#888' }}>
        If the app doesn't open automatically, please open it manually.
      </p>
    </div>
  );
}