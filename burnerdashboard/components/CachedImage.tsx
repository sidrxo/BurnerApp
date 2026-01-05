import Image from "next/image";
import { useState } from "react";
import { Calendar } from "lucide-react";

interface CachedImageProps {
  src: string | null | undefined;
  alt: string;
  className?: string;
  fallbackIcon?: React.ReactNode;
  fill?: boolean;
  width?: number;
  height?: number;
  priority?: boolean;
}

/**
 * Cached image component using Next.js Image optimization
 * Provides automatic caching, lazy loading, and fallback UI
 */
export function CachedImage({
  src,
  alt,
  className = "",
  fallbackIcon,
  fill = false,
  width,
  height,
  priority = false,
}: CachedImageProps) {
  const [error, setError] = useState(false);

  // Show fallback if no src or error occurred
  if (!src || error) {
    return (
      <div
        className={`bg-gradient-to-br from-muted via-muted/50 to-muted/30 flex items-center justify-center ${className}`}
      >
        {fallbackIcon || <Calendar className="h-16 w-16 text-muted-foreground/30" />}
      </div>
    );
  }

  // For Firebase Storage URLs or absolute URLs, we need to handle them differently
  const isAbsoluteUrl = src.startsWith("http://") || src.startsWith("https://");

  if (isAbsoluteUrl) {
    // Use unoptimized for external URLs (Firebase Storage)
    return (
      <Image
        src={src}
        alt={alt}
        className={className}
        fill={fill}
        width={!fill ? width : undefined}
        height={!fill ? height : undefined}
        priority={priority}
        unoptimized // Firebase Storage URLs can't be optimized by Next.js
        onError={() => setError(true)}
        style={{ objectFit: "cover" }}
      />
    );
  }

  // For relative URLs, use optimized images
  return (
    <Image
      src={src}
      alt={alt}
      className={className}
      fill={fill}
      width={!fill ? width : undefined}
      height={!fill ? height : undefined}
      priority={priority}
      onError={() => setError(true)}
      style={{ objectFit: "cover" }}
    />
  );
}
