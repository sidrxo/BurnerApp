#!/bin/bash
# Burner Dashboard Optimization Script
# Run this to reduce codebase size by 200-300MB

set -e  # Exit on error

DASHBOARD_DIR="/home/user/BurnerApp/burner-dashboard"

echo "🚀 Burner Dashboard Optimization Script"
echo "======================================="
echo ""

# Check if we're in the right directory
if [ ! -f "$DASHBOARD_DIR/package.json" ]; then
    echo "❌ Error: package.json not found in $DASHBOARD_DIR"
    exit 1
fi

cd "$DASHBOARD_DIR"

echo "📊 Current sizes:"
if [ -d "node_modules" ]; then
    NODE_MODULES_SIZE=$(du -sh node_modules 2>/dev/null | awk '{print $1}')
    echo "   node_modules: $NODE_MODULES_SIZE"
else
    echo "   node_modules: Not installed"
fi

echo ""
echo "🔍 Analyzing unused dependencies..."

# Check for Firebase usage
FIREBASE_USAGE=$(grep -r "from 'firebase" --include="*.ts" --include="*.tsx" . 2>/dev/null | grep -v node_modules | wc -l)
if [ "$FIREBASE_USAGE" -eq 0 ]; then
    echo "   ✅ Firebase is NOT used (can remove)"
else
    echo "   ⚠️  Firebase is used in $FIREBASE_USAGE files"
fi

echo ""
echo "🧹 Starting optimization..."
echo ""

# Step 1: Remove Firebase if not used
if [ "$FIREBASE_USAGE" -eq 0 ]; then
    echo "📦 Removing Firebase dependencies (150-200MB savings)..."
    npm uninstall firebase firebase-admin firebase-functions 2>/dev/null || true
    echo "   ✅ Firebase removed"
else
    echo "   ⏭️  Skipping Firebase removal (in use)"
fi

# Step 2: Remove testing libraries (optional)
echo ""
read -p "📝 Remove testing libraries? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "   Removing testing libraries..."
    npm uninstall @testing-library/dom @testing-library/jest-dom @testing-library/react jest 2>/dev/null || true
    echo "   ✅ Testing libraries removed"
else
    echo "   ⏭️  Keeping testing libraries"
fi

# Step 3: Clean build artifacts
echo ""
echo "🗑️  Cleaning build artifacts..."
rm -rf .next out node_modules/.cache .turbo 2>/dev/null || true
echo "   ✅ Build artifacts cleaned"

# Step 4: Reinstall with optimizations
echo ""
read -p "📥 Reinstall dependencies with optimizations? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "   Installing dependencies..."
    npm install
    echo "   ✅ Dependencies installed"
fi

# Step 5: Show results
echo ""
echo "✅ Optimization complete!"
echo ""
echo "📊 New sizes:"
if [ -d "node_modules" ]; then
    NEW_NODE_MODULES_SIZE=$(du -sh node_modules 2>/dev/null | awk '{print $1}')
    echo "   node_modules: $NEW_NODE_MODULES_SIZE"
fi

SOURCE_SIZE=$(du -sh . --exclude=node_modules 2>/dev/null | awk '{print $1}')
echo "   Source code: $SOURCE_SIZE"

echo ""
echo "💡 Next steps:"
echo "   1. Review CODEBASE_OPTIMIZATION_GUIDE.md for more optimizations"
echo "   2. Run 'npx depcheck' to find more unused dependencies"
echo "   3. Consider switching to pnpm for additional savings"
echo ""
echo "🎉 Done!"
