const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');

let mongoServer;

// Mock do dotenv para testes
process.env.JWT_SECRET = 'test-secret-key-for-jwt';
process.env.NODE_ENV = 'test';
process.env.IS_TEST = 'true';

beforeAll(async () => {
  try {
    console.log('🔧 Iniciando configuração do banco de testes...');
    
    // MongoDB em memória sem replica set
    mongoServer = await MongoMemoryServer.create({
      instance: {
        port: 27017,
        dbName: 'test_db'
      }
    });
    
    const mongoUri = mongoServer.getUri();
    
    console.log('📡 Conectando ao MongoDB de teste:', mongoUri);
    
    const mongooseOpts = {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 5000,
      bufferCommands: false,
    };

    await mongoose.connect(mongoUri, mongooseOpts);
    
    console.log('✅ MongoDB de teste conectado com sucesso');
    
  } catch (error) {
    console.error('❌ Erro ao configurar banco de teste:', error.message);
    throw error;
  }
});

beforeEach(async () => {
  // Limpar todos os dados antes de cada teste
  const collections = mongoose.connection.collections;
  for (const key in collections) {
    try {
      await collections[key].deleteMany({});
    } catch (error) {
      console.log(`⚠️ Aviso ao limpar coleção ${key}:`, error.message);
    }
  }
});

afterAll(async () => {
  try {
    await mongoose.disconnect();
    if (mongoServer) {
      await mongoServer.stop();
    }
    console.log('✅ MongoDB de teste desconectado');
  } catch (error) {
    console.error('❌ Erro ao limpar banco de teste:', error);
  }
});