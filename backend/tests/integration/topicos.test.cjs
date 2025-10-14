// tests/integration/topicos.test.cjs
const request = require("supertest");
const mongoose = require("mongoose");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");
const app = require("../../server.cjs");
const CardDisciplina = require("../../models/cardDisciplina.cjs");
const Professor = require("../../models/professor.cjs");

describe("Tópicos Routes", () => {
  let professorToken;
  let professor;
  let disciplina;

  beforeAll(async () => {
    // Criar um professor para autenticação
    const hashedPassword = await bcrypt.hash("senha123", 10);
    professor = new Professor({
      nome: "Prof Teste",
      email: "prof@sistemapoliedro.br",
      senha: hashedPassword,
    });
    await professor.save();
    professorToken = jwt.sign(
      { id: professor._id, role: "professor" },
      process.env.JWT_SECRET
    );
  });

  beforeEach(async () => {
    // Criar uma disciplina para os testes
    await CardDisciplina.deleteMany({});
    disciplina = new CardDisciplina({
      titulo: "Matemática",
      slug: "matematica",
      imagem: { data: Buffer.from("fake-image"), contentType: "image/jpeg" },
      icone: { data: Buffer.from("fake-icon"), contentType: "image/png" },
      topicos: [{ titulo: "Álgebra Linear", ordem: 0 }],
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
        .post(`/api/cardsDisciplinas/matematica/topicos`)
        .set("Authorization", `Bearer ${professorToken}`) // Already included, kept for clarity
        .send({ titulo: "Geometria", descricao: "Introdução à geometria" });

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty("titulo", "Geometria");
    });

    test("should return 401 without authentication", async () => {
      const response = await request(app)
        .post(`/api/cardsDisciplinas/matematica/topicos`)
        .send({ titulo: "Geometria", descricao: "Introdução à geometria" });

      expect(response.status).toBe(401);
    });

    test("should return 400 for missing title", async () => {
      const response = await request(app)
        .post(`/api/cardsDisciplinas/matematica/topicos`)
        .set("Authorization", `Bearer ${professorToken}`)
        .send({ descricao: "Descrição sem título" });

      expect(response.status).toBe(400);
    });
  });

  describe("GET /api/cardsDisciplinas/:slug/topicos", () => {
    test("should get all tópicos", async () => {
      const response = await request(app)
        .get(`/api/cardsDisciplinas/matematica/topicos`)
        .set("Authorization", `Bearer ${professorToken}`); // Add token

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toBeInstanceOf(Array);
      expect(response.body.data[0]).toHaveProperty("titulo", "Álgebra Linear");
    });

    test("should return 401 without authentication", async () => {
      const response = await request(app).get(
        `/api/cardsDisciplinas/matematica/topicos`
      );

      expect(response.status).toBe(401);
    });
  });

  describe("PUT /api/cardsDisciplinas/:slug/topicos/:topicoId", () => {
    test("should update a tópico", async () => {
      const topicoId = disciplina.topicos[0]._id;
      const response = await request(app)
        .put(`/api/cardsDisciplinas/matematica/topicos/${topicoId}`)
        .set("Authorization", `Bearer ${professorToken}`) // Add token
        .send({ titulo: "Álgebra Avançada", descricao: "Atualizado" });

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty("message", "Tópico atualizado com sucesso");
      expect(response.body.data).toHaveProperty("titulo", "Álgebra Avançada");
    });

    test("should return 401 without authentication", async () => {
      const topicoId = disciplina.topicos[0]._id;
      const response = await request(app)
        .put(`/api/cardsDisciplinas/matematica/topicos/${topicoId}`)
        .send({ titulo: "Álgebra Avançada" });

      expect(response.status).toBe(401);
    });
  });

  describe("DELETE /api/cardsDisciplinas/:slug/topicos/:topicoId", () => {
    test("should delete a tópico", async () => {
      const topicoId = disciplina.topicos[0]._id;
      const response = await request(app)
        .delete(`/api/cardsDisciplinas/matematica/topicos/${topicoId}`)
        .set("Authorization", `Bearer ${professorToken}`); // Add token

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty("message", "Tópico deletado com sucesso");
    });

    test("should return 401 without authentication", async () => {
      const topicoId = disciplina.topicos[0]._id;
      const response = await request(app).delete(
        `/api/cardsDisciplinas/matematica/topicos/${topicoId}`
      );

      expect(response.status).toBe(401);
    });
  });

  describe("PUT /api/cardsDisciplinas/:slug/topicos/:topicoId/reordenar", () => {
    test("should reorder tópicos", async () => {
      // Adicionar um segundo tópico
      disciplina.topicos.push({ titulo: "Geometria", ordem: 1 });
      await disciplina.save();
      const topicoId = disciplina.topicos[0]._id;

      const response = await request(app)
        .put(`/api/cardsDisciplinas/matematica/topicos/${topicoId}/reordenar`)
        .set("Authorization", `Bearer ${professorToken}`) // Add token
        .send({ novaOrdem: 1 });

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty("message", "Tópicos reordenados com sucesso");
      expect(response.body.data[1]).toHaveProperty("titulo", "Álgebra Linear");
    });

    test("should return 401 without authentication", async () => {
      const topicoId = disciplina.topicos[0]._id;
      const response = await request(app)
        .put(`/api/cardsDisciplinas/matematica/topicos/${topicoId}/reordenar`)
        .send({ novaOrdem: 1 });

      expect(response.status).toBe(401);
    });
  });
});