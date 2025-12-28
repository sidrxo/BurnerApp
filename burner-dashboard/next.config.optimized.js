/** @type {import('next').NextConfig} */
const nextConfig = {
  // Reduce bundle size in production
  compiler: {
    // Remove console.logs in production
    removeConsole: process.env.NODE_ENV === 'production' ? {
      exclude: ['error', 'warn'],
    } : false,
  },

  // Optimize images
  images: {
    formats: ['image/avif', 'image/webp'],
    minimumCacheTTL: 60,
    deviceSizes: [640, 750, 828, 1080, 1200, 1920],
    imageSizes: [16, 32, 48, 64, 96, 128, 256],
  },

  // Enable SWC minification (faster than Terser)
  swcMinify: true,

  // Optimize production builds
  productionBrowserSourceMaps: false,

  // Reduce JavaScript sent to client
  experimental: {
    // Optimize package imports for tree-shaking
    optimizePackageImports: [
      '@radix-ui/react-alert-dialog',
      '@radix-ui/react-avatar',
      '@radix-ui/react-checkbox',
      '@radix-ui/react-dialog',
      '@radix-ui/react-dropdown-menu',
      '@radix-ui/react-label',
      '@radix-ui/react-popover',
      '@radix-ui/react-progress',
      '@radix-ui/react-select',
      '@radix-ui/react-separator',
      '@radix-ui/react-slot',
      '@radix-ui/react-switch',
      '@radix-ui/react-tooltip',
      'lucide-react',
      'recharts',
    ],

    // Enable faster refresh
    optimizeCss: true,
  },

  // Webpack optimizations
  webpack: (config, { dev, isServer }) => {
    // Production optimizations
    if (!dev && !isServer) {
      // Enable tree shaking
      config.optimization = {
        ...config.optimization,
        usedExports: true,
        sideEffects: false,
      };

      // Split chunks more aggressively
      config.optimization.splitChunks = {
        chunks: 'all',
        cacheGroups: {
          default: false,
          vendors: false,
          // Vendor chunk for node_modules
          vendor: {
            name: 'vendor',
            chunks: 'all',
            test: /node_modules/,
            priority: 20,
          },
          // Common chunk for shared code
          common: {
            name: 'common',
            minChunks: 2,
            chunks: 'all',
            priority: 10,
            reuseExistingChunk: true,
            enforce: true,
          },
          // Radix UI components
          radix: {
            test: /[\\/]node_modules[\\/]@radix-ui/,
            name: 'radix',
            chunks: 'all',
            priority: 30,
          },
        },
      };
    }

    return config;
  },

  // Output settings
  output: 'standalone', // For Docker/smaller deployments

  // Disable x-powered-by header
  poweredByHeader: false,
};

module.exports = nextConfig;
