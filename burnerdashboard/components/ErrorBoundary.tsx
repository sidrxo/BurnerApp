"use client";

import React, { Component, ErrorInfo, ReactNode } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { AlertTriangle, Home, RefreshCw } from "lucide-react";

interface Props {
  children: ReactNode;
  fallbackTitle?: string;
  fallbackMessage?: string;
}

interface State {
  hasError: boolean;
  error: Error | null;
  errorInfo: ErrorInfo | null;
}

class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = {
      hasError: false,
      error: null,
      errorInfo: null,
    };
  }

  static getDerivedStateFromError(error: Error): State {
    // Update state so the next render will show the fallback UI
    return {
      hasError: true,
      error,
      errorInfo: null,
    };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    // Log error to console for debugging
    console.error("ErrorBoundary caught an error:", error, errorInfo);

    // Update state with error details
    this.setState({
      error,
      errorInfo,
    });

    // You could also log to an error reporting service here
    // e.g., Sentry, LogRocket, etc.
  }

  handleReset = () => {
    this.setState({
      hasError: false,
      error: null,
      errorInfo: null,
    });
  };

  handleGoHome = () => {
    window.location.href = "/";
  };

  render() {
    if (this.state.hasError) {
      const { error, errorInfo } = this.state;
      const { fallbackTitle, fallbackMessage } = this.props;

      return (
        <div className="min-h-screen flex items-center justify-center p-4 bg-gray-50 dark:bg-gray-900">
          <Card className="max-w-2xl w-full">
            <CardHeader>
              <div className="flex items-center space-x-2 text-red-600 dark:text-red-400">
                <AlertTriangle className="h-6 w-6" />
                <CardTitle>{fallbackTitle || "Something went wrong"}</CardTitle>
              </div>
              <CardDescription>
                {fallbackMessage ||
                  "An unexpected error occurred. You can try refreshing the page or going back to the home page."}
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              {process.env.NODE_ENV === "development" && error && (
                <div className="space-y-2">
                  <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4">
                    <p className="text-sm font-semibold text-red-800 dark:text-red-200 mb-2">
                      Error Details (Development Only):
                    </p>
                    <p className="text-sm text-red-700 dark:text-red-300 font-mono break-all">
                      {error.toString()}
                    </p>
                  </div>

                  {errorInfo && (
                    <details className="bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg p-4">
                      <summary className="text-sm font-semibold text-gray-800 dark:text-gray-200 cursor-pointer">
                        Component Stack Trace
                      </summary>
                      <pre className="text-xs text-gray-700 dark:text-gray-300 mt-2 overflow-auto max-h-64">
                        {errorInfo.componentStack}
                      </pre>
                    </details>
                  )}
                </div>
              )}

              <div className="flex space-x-3">
                <Button onClick={this.handleReset} variant="default" className="flex items-center space-x-2">
                  <RefreshCw className="h-4 w-4" />
                  <span>Try Again</span>
                </Button>
                <Button onClick={this.handleGoHome} variant="outline" className="flex items-center space-x-2">
                  <Home className="h-4 w-4" />
                  <span>Go Home</span>
                </Button>
              </div>

              {process.env.NODE_ENV === "production" && (
                <p className="text-sm text-gray-600 dark:text-gray-400">
                  If this problem persists, please contact support with details about what you were doing when this
                  error occurred.
                </p>
              )}
            </CardContent>
          </Card>
        </div>
      );
    }

    return this.props.children;
  }
}

export default ErrorBoundary;
