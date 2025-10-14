// jest.config.cjs
module.exports = {
  testEnvironment: 'node',
  setupFilesAfterEnv: ['./tests/setup.cjs'],
  testPathIgnorePatterns: ['/node_modules/', '/client/'],
  testMatch: ['**/tests/**/*.test.cjs'],
  verbose: true,
  testTimeout: 30000, // aumenta timeout global
};
