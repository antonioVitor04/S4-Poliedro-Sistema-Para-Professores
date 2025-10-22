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

// Mock do console para evitar poluição
global.console = {
  ...console,
  log: jest.fn(),
  error: jest.fn(),
  warn: jest.fn(),
  info: jest.fn(),
};