/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  reactStrictMode: true,
  transpilePackages: [
    '@therapy-sculpt/clinical-core',
    '@therapy-sculpt/contracts',
    '@therapy-sculpt/therapy-content',
    '@therapy-sculpt/ui-kit',
  ],
  async redirects() {
    return [
      {
        source: '/',
        destination: '/en',
        permanent: false,
      },
    ];
  },
};

export default nextConfig;
