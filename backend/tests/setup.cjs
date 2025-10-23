// tests/setup.cjs
const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

let mongoServer;

// Mock do dotenv para testes
process.env.JWT_SECRET = 'test-secret-key-for-jwt';
process.env.NODE_ENV = 'test';

beforeAll(async () => {
  // Inicia o MongoDB em memória
  mongoServer = await MongoMemoryServer.create();
  const mongoUri = mongoServer.getUri();

  // Conecta o Mongoose ao banco em memória
  await mongoose.connect(mongoUri);
  console.log('✅ MongoDB em memória conectado para testes');
});

beforeEach(async () => {
  // Limpar todos os dados antes de cada teste
  const collections = mongoose.connection.collections;
  for (const key in collections) {
    await collections[key].deleteMany({});
  }
});

afterAll(async () => {
  // Desconecta e para o servidor em memória
  await mongoose.disconnect();
  await mongoServer.stop();
  console.log('✅ MongoDB em memória desconectado');
});

// REMOVIDO: Mock do console para permitir logs durante os testes
// Agora os console.log nos testes e middlewares serão visíveis
// Se quiser mockar só em produção de testes, use conditional
if (process.env.NO_LOGS) {
  jest.spyOn(console, 'log').mockImplementation(() => {});
  jest.spyOn(console, 'error').mockImplementation(() => {});
  jest.spyOn(console, 'warn').mockImplementation(() => {});
  jest.spyOn(console, 'info').mockImplementation(() => {});
}