// setupTests.js
const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');

let mongoServer;

beforeAll(async () => {
  // Inicia o MongoDB em memória
  mongoServer = await MongoMemoryServer.create();
  const mongoUri = mongoServer.getUri();

  // Conecta o Mongoose ao banco em memória
  await mongoose.connect(mongoUri, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  });

  console.log('✅ MongoDB em memória conectado para testes');
});

afterAll(async () => {
  // Desconecta e para o servidor em memória
  await mongoose.disconnect();
  await mongoServer.stop();
  console.log('✅ MongoDB em memória desconectado');
});

afterEach(async () => {
  // Limpa todas as coleções entre os testes
  const collections = mongoose.connection.collections;
  for (const key in collections) {
    await collections[key].deleteMany({});
  }
});
