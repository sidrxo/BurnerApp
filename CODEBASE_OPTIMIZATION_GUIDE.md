# 🚀 Burner Dashboard Codebase Optimization Guide

## Current Size Analysis
- **With node_modules**: ~750MB
- **Without node_modules**: ~500MB (this seems unusually large)
- **Source code only**: ~38MB (actual code)
- **Android**: ~33MB
- **.git**: ~10MB

## ⚡ Immediate Actions (Est. 200-300MB savings)

### 1. Remove Firebase Dependencies (150-200MB)
**Status**: ✅ Firebase is NOT used anywhere in your code

```bash
cd burner-dashboard
npm uninstall firebase firebase-admin firebase-functions
```

**Verification**: No imports of Firebase found in your TypeScript/React files.

### 2. Remove/Move Unused Testing Libraries (30-50MB)
If not actively testing:

```bash
# Option A: Remove completely
npm uninstall @testing-library/dom @testing-library/jest-dom @testing-library/react jest

# Option B: Keep in devDependencies for future use (already there)
# No action needed - they won't be installed in production
```

### 3. Audit Radix UI Components (10-20MB)
You have 14 Radix UI packages. Only keep what you use:

```bash
# Check actual usage
grep -r "from '@radix-ui" burner-dashboard/{components,app} | \
  sed 's/.*@radix-ui\/react-\([^'"'"']*\).*/\1/' | \
  sort | uniq -c | sort -rn
```

Remove unused ones:
```bash
# Example if a component is unused:
npm uninstall @radix-ui/react-collapsible  # if not used
```

---

## 🔧 Configuration Optimizations

### 4. Update next.config.js for Tree Shaking

```javascript
// burner-dashboard/next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
  // Reduce bundle size
  compiler: {
    removeConsole: process.env.NODE_ENV === 'production',
  },

  // Optimize images
  images: {
    formats: ['image/avif', 'image/webp'],
    minimumCacheTTL: 60,
  },

  // Enable SWC minification
  swcMinify: true,

  // Optimize production builds
  productionBrowserSourceMaps: false,

  // Reduce JavaScript sent to client
  experimental: {
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
  },
};

module.exports = nextConfig;
```

### 5. Optimize Package Imports

Create proper barrel exports to enable tree-shaking:

```typescript
// Instead of:
import * as Icons from 'lucide-react'

// Do:
import { ArrowRight, User, Settings } from 'lucide-react'
```

### 6. Use .gitignore to Exclude Build Artifacts

```bash
# Add to .gitignore if not already there:
cat >> .gitignore << 'EOF'

# Build outputs
.next/
out/
dist/
build/
*.tsbuildinfo

# Caches
.turbo/
.cache/
.parcel-cache/

# Testing
coverage/
.nyc_output/

# Environment
.env.local
.env.*.local

# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo
*~
EOF
```

---

## 📦 Advanced Optimizations

### 7. Use pnpm Instead of npm (30-50% node_modules reduction)

```bash
# Install pnpm globally
npm install -g pnpm

# In burner-dashboard:
rm -rf node_modules package-lock.json
pnpm install
```

**Benefits**:
- Hard links shared dependencies across projects
- ~30-50% smaller node_modules
- Faster installs

### 8. Bundle Analysis

Analyze what's actually in your bundles:

```bash
# Install analyzer
npm install --save-dev @next/bundle-analyzer

# Update next.config.js:
const withBundleAnalyzer = require('@next/bundle-analyzer')({
  enabled: process.env.ANALYZE === 'true',
})

module.exports = withBundleAnalyzer(nextConfig)

# Run analysis
ANALYZE=true npm run build
```

### 9. Clean Up Android Folder (If Not Needed)

If you're not building for Android:
```bash
# Move to separate repo or remove
rm -rf android/
```

**Savings**: 33MB

### 10. Reduce Git Repository Size

```bash
# Clean up git history
git gc --aggressive --prune=now

# Remove large files from history (if any found)
git filter-repo --strip-blobs-bigger-than 10M
```

---

## 🎯 Package.json Optimization

### Updated package.json (Cleaned)

```json
{
  "name": "burner-dashboard",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "clean": "rm -rf .next out node_modules/.cache"
  },
  "dependencies": {
    "@radix-ui/react-alert-dialog": "^1.1.15",
    "@radix-ui/react-avatar": "^1.1.10",
    "@radix-ui/react-checkbox": "^1.3.3",
    "@radix-ui/react-dialog": "^1.1.15",
    "@radix-ui/react-dropdown-menu": "^2.1.16",
    "@radix-ui/react-label": "^2.1.7",
    "@radix-ui/react-popover": "^1.1.15",
    "@radix-ui/react-progress": "^1.1.7",
    "@radix-ui/react-select": "^2.2.6",
    "@radix-ui/react-separator": "^1.1.7",
    "@radix-ui/react-slot": "^1.2.3",
    "@radix-ui/react-switch": "^1.2.6",
    "@radix-ui/react-tooltip": "^1.2.8",
    "@supabase/supabase-js": "^2.87.3",
    "@tailwindcss/postcss": "^4.1.18",
    "class-variance-authority": "^0.7.1",
    "clsx": "^2.1.1",
    "lucide-react": "^0.539.0",
    "next": "^15.5.9",
    "next-themes": "^0.4.6",
    "react": "19.1.0",
    "react-day-picker": "^9.11.3",
    "react-dom": "19.1.0",
    "recharts": "^3.1.2",
    "sonner": "^2.0.7",
    "tailwind-merge": "^3.3.1",
    "tailwindcss-animate": "^1.0.7"
  },
  "devDependencies": {
    "@types/node": "^20.19.17",
    "@types/react": "^19.2.2",
    "@types/react-dom": "^19.2.2",
    "typescript": "5.9.3"
  }
}
```

**Changes**:
- ❌ Removed: `firebase`, `firebase-admin`, `firebase-functions`
- ❌ Removed: `@radix-ui/react-collapsible` (check if used)
- ❌ Removed testing libraries from dependencies (move to devDependencies or remove)

---

## 📊 Expected Size Reductions

| Action | Size Savings | Difficulty |
|--------|--------------|------------|
| Remove Firebase | 150-200MB | ⭐ Easy |
| Remove unused tests | 30-50MB | ⭐ Easy |
| Audit Radix UI | 10-20MB | ⭐⭐ Medium |
| Switch to pnpm | 100-150MB | ⭐⭐ Medium |
| Remove Android (if unused) | 33MB | ⭐ Easy |
| Clean git history | 5-10MB | ⭐⭐⭐ Hard |
| Optimize imports | Variable | ⭐⭐ Medium |
| **TOTAL ESTIMATED** | **328-463MB** | |

---

## 🚀 Quick Start Script

```bash
#!/bin/bash
# save as: optimize-dashboard.sh

echo "🧹 Optimizing Burner Dashboard..."

cd burner-dashboard

# Remove unused dependencies
echo "📦 Removing Firebase dependencies..."
npm uninstall firebase firebase-admin firebase-functions

# Remove testing libraries (optional)
read -p "Remove testing libraries? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    npm uninstall @testing-library/dom @testing-library/jest-dom @testing-library/react jest
fi

# Clean build artifacts
echo "🗑️  Cleaning build artifacts..."
rm -rf .next out node_modules/.cache

# Reinstall with optimizations
echo "📥 Reinstalling dependencies..."
npm install

# Run bundle analysis
echo "📊 Analyzing bundle size..."
npm run build

echo "✅ Optimization complete!"
```

---

## 🔍 Verification Commands

After optimization, verify sizes:

```bash
# Check node_modules size
du -sh burner-dashboard/node_modules

# Check source code only
du -sh burner-dashboard --exclude=node_modules

# Count dependencies
cd burner-dashboard && npm ls --depth=0 | wc -l

# Check build size
du -sh burner-dashboard/.next

# List largest packages
cd burner-dashboard && npm ls --depth=0 --parseable | \
  xargs du -sh 2>/dev/null | sort -hr | head -20
```

---

## 💡 Best Practices Going Forward

1. **Before adding dependencies**:
   ```bash
   npx bundle-phobia-cli <package-name>
   ```

2. **Regular audits**:
   ```bash
   npx depcheck  # Find unused dependencies
   npx npm-check-updates  # Check for updates
   ```

3. **Use dynamic imports** for large components:
   ```typescript
   const HeavyComponent = dynamic(() => import('./HeavyComponent'), {
     loading: () => <p>Loading...</p>,
   })
   ```

4. **Monitor bundle size** in CI/CD:
   ```bash
   npm run build
   ls -lh .next/static/chunks/*.js | awk '{if($5 > 100000) print $0}'
   ```

---

## 📈 Tracking Progress

| Metric | Before | After | Goal |
|--------|--------|-------|------|
| node_modules | 750MB | ? | <400MB |
| Source code | 500MB | ? | <50MB |
| Build output | ? | ? | <10MB |
| Dependencies | 40+ | ? | <25 |

**Update this table as you make optimizations!**

---

## 🎯 Priority Order

1. ✅ Remove Firebase (Immediate, Easy, 150-200MB)
2. ✅ Configure .npmrc (Immediate, Easy)
3. ⬜ Audit unused Radix UI (1 hour, 10-20MB)
4. ⬜ Update next.config.js (30 min)
5. ⬜ Switch to pnpm (30 min, 100-150MB)
6. ⬜ Bundle analysis (Ongoing)
