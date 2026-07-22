/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'randompicturegenerator.com',
      },
    ],
  },
};

module.exports = nextConfig;
