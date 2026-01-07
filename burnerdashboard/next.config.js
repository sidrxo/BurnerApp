/** @type {import('next').NextConfig} */
const nextConfig = {
  // Removed output: "export" because the app uses dynamic routes with Firestore data
  // Static export doesn't work with dynamic routes like /events/[eventId]/edit
};

module.exports = nextConfig;
