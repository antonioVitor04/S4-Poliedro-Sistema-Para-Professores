const request = require('supertest');
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const app = require('../../server.cjs');
const Aluno = require('../../models/aluno.cjs');
const Professor = require('../../models/professor.cjs');

describe('Aluno Routes', () => {
  let professorToken;
  let professor;

  beforeAll(async () => {
    // Criar um professor para autenticação
    const hashedPassword = await bcrypt.hash('senha123', 10);
    professor = new Professor({
      nome: 'Prof Teste',
      email: 'prof@sistemapoliedro.br',
      senha: hashedPassword,
    });
    await professor.save();
    professorToken = jwt.sign({ id: professor._id, role: 'professor' }, process.env.JWT_SECRET);
  });

  afterEach(async () => {
    await Aluno.deleteMany({});
  });

  afterAll(async () => {
    await Professor.deleteMany({});
  });

  describe('POST /api/alunos/register', () => {
    test('should register a new aluno', async () => {
      const response = await request(app)
        .post('/api/alunos/register')
        .set('Authorization', `Bearer ${professorToken}`)
        .send({
          nome: 'Aluno Teste',
          ra: '123456',
          email: 'aluno@alunosistemapoliedro.br'
        });

      expect(response.status).toBe(201);
      expect(response.body).toHaveProperty('msg', 'Aluno registrado com sucesso!');
      expect(response.body.aluno).toHaveProperty('ra', '123456');
    });

    test('should return 400 for duplicate RA', async () => {
      // Primeiro registro
      await request(app)
        .post('/api/alunos/register')
        .set('Authorization', `Bearer ${professorToken}`)
        .send({
          nome: 'Aluno Teste',
          ra: '123456',
          email: 'aluno1@alunosistemapoliedro.br'
        });

      // Segundo registro com mesmo RA
      const response = await request(app)
        .post('/api/alunos/register')
        .set('Authorization', `Bearer ${professorToken}`)
        .send({
          nome: 'Outro Aluno',
          ra: '123456',
          email: 'aluno2@alunosistemapoliedro.br'
        });

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('msg', 'RA já cadastrado');
    });

    test('should return 401 without professor token', async () => {
      const response = await request(app)
        .post('/api/alunos/register')
        .send({
          nome: 'Aluno Teste',
          ra: '123456',
          email: 'aluno@alunosistemapoliedro.br'
        });

      expect(response.status).toBe(401);
    });
  });

  describe('POST /api/alunos/login', () => {
    test('should login aluno', async () => {
      const hashedPassword = await bcrypt.hash('123456', 10);
      await Aluno.create({
        nome: 'Aluno Teste',
        ra: '123456',
        email: 'aluno@alunosistemapoliedro.br',
        senha: hashedPassword,
      });

      const response = await request(app)
        .post('/api/alunos/login')
        .send({ ra: '123456', senha: '123456' });

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('token');
      expect(response.body.aluno).toHaveProperty('ra', '123456');
    });

    test('should return 400 for invalid credentials', async () => {
      const response = await request(app)
        .post('/api/alunos/login')
        .send({ ra: '999999', senha: 'wrongpassword' });

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('msg', 'Aluno não encontrado');
    });
  });

  describe('GET /api/alunos', () => {
    test('should get aluno profile', async () => {
      const aluno = await Aluno.create({
        nome: 'Aluno Teste',
        ra: '123456',
        email: 'aluno@alunosistemapoliedro.br',
        senha: await bcrypt.hash('123456', 10),
      });
      const token = jwt.sign({ id: aluno._id, role: 'aluno' }, process.env.JWT_SECRET);

      const response = await request(app)
        .get('/api/alunos')
        .set('Authorization', `Bearer ${token}`);

      expect(response.status).toBe(200);
      expect(response.body.aluno).toHaveProperty('ra', '123456');
    });

    test('should return 401 without token', async () => {
      const response = await request(app)
        .get('/api/alunos');

      expect(response.status).toBe(401);
    });
  });
});