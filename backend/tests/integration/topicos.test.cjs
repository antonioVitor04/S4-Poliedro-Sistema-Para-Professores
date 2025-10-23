// tests/integration/topicos.test.cjs
const request = require("supertest");
const mongoose = require("mongoose");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");
const app = require("../../server.cjs");
const CardDisciplina = require("../../models/cardDisciplina.cjs");
const Professor = require("../../models/professor.cjs");

describe("Tópicos Routes", () => {
  let professorToken, professor, disciplina, topicoId;

  beforeAll(async () => {
    process.env.JWT_SECRET = 'test-secret-key-for-jwt';
    
    // Criar professor
    const hashedPassword = await bcrypt.hash("senha123", 10);
    professor = new Professor({
      nome: "Prof Teste",
      email: "prof@sistemapoliedro.br",
      senha: hashedPassword,
      tipo: "professor"
    });
    await professor.save();
    
    professorToken = jwt.sign(
      { id: professor._id.toString(), role: "professor" },
      process.env.JWT_SECRET
    );
  });

  beforeEach(async () => {
    await CardDisciplina.deleteMany({});
    
    // Criar disciplina com estrutura correta
    disciplina = new CardDisciplina({
      titulo: "Matemática Teste",
      slug: "matematica-teste",
      imagem: { 
        data: Buffer.from("fake-image-data"), 
        contentType: "image/jpeg" 
      },
      icone: { 
        data: Buffer.from("fake-icon-data"), 
        contentType: "image/png" 
      },
      professores: [professor._id],
      criadoPor: professor._id,
      topicos: []
    });
    
    await disciplina.save();
  });

  afterEach(async () => {
    await CardDisciplina.deleteMany({});
  });

  afterAll(async () => {
    await Professor.deleteMany({});
    await mongoose.connection.close();
  });

  describe("POST /api/cardsDisciplinas/:slug/topicos", () => {
    test("should create a new tópico", async () => {
      const response = await request(app)
        .post(`/api/cardsDisciplinas/${disciplina.slug}/topicos`)
        .set("Authorization", `Bearer ${professorToken}`)
        .send({ 
          titulo: "Geometria", 
          descricao: "Introdução à geometria" 
        });

      console.log("POST Response:", response.status, response.body);

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty("titulo", "Geometria");
    });

    test("should return 401 without authentication", async () => {
      const response = await request(app)
        .post(`/api/cardsDisciplinas/${disciplina.slug}/topicos`)
        .send({ titulo: "Geometria" });

      expect(response.status).toBe(401);
    });

    test("should return 400 for invalid data", async () => {
      const response = await request(app)
        .post(`/api/cardsDisciplinas/${disciplina.slug}/topicos`)
        .set("Authorization", `Bearer ${professorToken}`)
        .send({}); // título ausente

      expect(response.status).toBe(400);
    });
  });

  describe("GET /api/cardsDisciplinas/:slug/topicos", () => {
    beforeEach(async () => {
      // Adicionar um tópico antes dos testes GET
      const topico = {
        titulo: "Álgebra",
        descricao: "Introdução à álgebra",
        ordem: 0,
        materiais: []
      };
      
      disciplina.topicos.push(topico);
      await disciplina.save();
      topicoId = disciplina.topicos[0]._id.toString();
    });

    test("should get all tópicos for authorized user", async () => {
      const response = await request(app)
        .get(`/api/cardsDisciplinas/${disciplina.slug}/topicos`)
        .set("Authorization", `Bearer ${professorToken}`);

      console.log("GET Response:", response.status, response.body);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(Array.isArray(response.body.data)).toBe(true);
    });

    test("should return 401 without authentication", async () => {
      const response = await request(app)
        .get(`/api/cardsDisciplinas/${disciplina.slug}/topicos`);

      expect(response.status).toBe(401);
    });

    test("should return 404 for non-existent disciplina", async () => {
      const response = await request(app)
        .get(`/api/cardsDisciplinas/nao-existe/topicos`)
        .set("Authorization", `Bearer ${professorToken}`);

      expect(response.status).toBe(404);
    });
  });

  describe("PUT /api/cardsDisciplinas/:slug/topicos/:topicoId", () => {
    beforeEach(async () => {
      // Adicionar um tópico antes dos testes PUT
      const topico = {
        titulo: "Álgebra Linear",
        descricao: "Introdução",
        ordem: 0,
        materiais: []
      };
      
      disciplina.topicos.push(topico);
      await disciplina.save();
      topicoId = disciplina.topicos[0]._id.toString();
    });

    test("should update a tópico", async () => {
      const response = await request(app)
        .put(`/api/cardsDisciplinas/${disciplina.slug}/topicos/${topicoId}`)
        .set("Authorization", `Bearer ${professorToken}`)
        .send({ 
          titulo: "Álgebra Avançada", 
          descricao: "Atualizado" 
        });

      console.log("PUT Response:", response.status, response.body);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.titulo).toBe("Álgebra Avançada");
    });

    test("should return 404 for non-existent tópico", async () => {
      const fakeId = new mongoose.Types.ObjectId();
      const response = await request(app)
        .put(`/api/cardsDisciplinas/${disciplina.slug}/topicos/${fakeId}`)
        .set("Authorization", `Bearer ${professorToken}`)
        .send({ titulo: "Atualizado" });

      expect(response.status).toBe(404);
    });
  });

  describe("DELETE /api/cardsDisciplinas/:slug/topicos/:topicoId", () => {
    beforeEach(async () => {
      // Adicionar um tópico antes dos testes DELETE
      const topico = {
        titulo: "Álgebra Linear",
        descricao: "Introdução",
        ordem: 0,
        materiais: []
      };
      
      disciplina.topicos.push(topico);
      await disciplina.save();
      topicoId = disciplina.topicos[0]._id.toString();
    });

    test("should delete a tópico", async () => {
      const response = await request(app)
        .delete(`/api/cardsDisciplinas/${disciplina.slug}/topicos/${topicoId}`)
        .set("Authorization", `Bearer ${professorToken}`);

      console.log("DELETE Response:", response.status, response.body);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });

    test("should return 404 for non-existent tópico", async () => {
      const fakeId = new mongoose.Types.ObjectId();
      const response = await request(app)
        .delete(`/api/cardsDisciplinas/${disciplina.slug}/topicos/${fakeId}`)
        .set("Authorization", `Bearer ${professorToken}`);

      expect(response.status).toBe(404);
    });
  });
});