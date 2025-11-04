'use client';

import { useEffect, useState } from 'react';
import { useSearchParams } from 'next/navigation';

export default function SignInPage() {
  const searchParams = useSearchParams();
  const [showManualLink, setShowManualLink] = useState(false);

  useEffect(() => {
    // Log all parameters for debugging
    const params = Object.fromEntries(searchParams.entries());
    console.log('Sign-in page loaded with params:', params);

    // Build the full URL to pass to the app
    const fullUrl = window.location.href;

    // Try to open the app via custom scheme as a fallback
    // The universal link should work automatically, but this is a backup
    const customSchemeUrl = `burner://auth?link=${encodeURIComponent(fullUrl)}`;

    // Attempt to open the custom scheme URL
    const attemptToOpenApp = () => {
      console.log('Attempting to open app with custom scheme:', customSchemeUrl);
      window.location.href = customSchemeUrl;

      // Show manual link after a delay if the app didn't open
      setTimeout(() => {
        setShowManualLink(true);
      }, 2000);
    };

    // Small delay to ensure page is fully loaded
    const timer = setTimeout(attemptToOpenApp, 500);

    return () => clearTimeout(timer);
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
      color: '#fff',
      textAlign: 'center'
    }}>
      <div style={{
        width: '60px',
        height: '60px',
        border: '3px solid #444',
        borderTopColor: '#fff',
        borderRadius: '50%',
        animation: 'spin 1s linear infinite',
        marginBottom: '2rem'
      }} />

      <h1 style={{ fontSize: '2rem', marginBottom: '1rem' }}>
        Opening Burner App...
      </h1>

      <p style={{ color: '#888', marginBottom: '2rem' }}>
        If the app doesn't open automatically, please open it manually.
      </p>

      {showManualLink && (
        <div style={{ marginTop: '1rem' }}>
          <a
            href="burner://"
            style={{
              color: '#007AFF',
              textDecoration: 'underline',
              fontSize: '1rem'
            }}
          >
            Tap here to open Burner
          </a>
        </div>
      )}

      <style jsx>{`
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
      `}</style>
    </div>
  );
}