// tests/integration/materiais.test.cjs
const request = require("supertest");
const mongoose = require("mongoose");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");
const app = require("../../server.cjs");
const CardDisciplina = require("../../models/cardDisciplina.cjs");
const Professor = require("../../models/professor.cjs");

describe("Materiais Routes", () => {
  let professorToken, disciplina, topicoId;
  let professor;

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
    // Criar uma disciplina e um tópico antes de cada teste
    await CardDisciplina.deleteMany({}); // Limpar antes de criar
    disciplina = new CardDisciplina({
      titulo: "Matemática",
      slug: "matematica",
      imagem: { data: Buffer.from("fake-image"), contentType: "image/jpeg" },
      icone: { data: Buffer.from("fake-icon"), contentType: "image/png" },
      topicos: [{ titulo: "Álgebra Linear", ordem: 0 }],
    });
    await disciplina.save();
    topicoId = disciplina.topicos[0]._id;
  });

  afterEach(async () => {
    await CardDisciplina.deleteMany({});
  });

  afterAll(async () => {
    await Professor.deleteMany({});
    await mongoose.connection.close();
  });

  describe("POST /api/cardsDisciplinas/:slug/topicos/:topicoId/materiais", () => {
    test("should create a new material", async () => {
      const response = await request(app)
        .post(`/api/cardsDisciplinas/matematica/topicos/${topicoId}/materiais`)
        .set("Authorization", `Bearer ${professorToken}`) // Add token
        .field("tipo", "pdf")
        .field("titulo", "Matrizes")
        .field("peso", 2)
        .attach("arquivo", Buffer.from("fake-pdf-data"), "matrizes.pdf");

      expect(response.status).toBe(201);
      expect(response.body).toHaveProperty("message", "Material criado com sucesso");
      expect(response.body.data).toHaveProperty("titulo", "Matrizes");
      expect(response.body.data).toHaveProperty("tipo", "pdf");
    });

    test("should return 401 without authentication", async () => {
      const response = await request(app)
        .post(`/api/cardsDisciplinas/matematica/topicos/${topicoId}/materiais`)
        .field("tipo", "pdf")
        .field("titulo", "Matrizes");

      expect(response.status).toBe(401);
    });
  });

  describe("PUT /api/cardsDisciplinas/:slug/topicos/:topicoId/materiais/:materialId", () => {
    test("should update a material", async () => {
      // Adicionar um material ao tópico
      const material = { tipo: "pdf", titulo: "Matrizes", ordem: 0 };
      disciplina.topicos[0].materiais.push(material);
      await disciplina.save();
      const materialId = disciplina.topicos[0].materiais[0]._id;

      const response = await request(app)
        .put(`/api/cardsDisciplinas/matematica/topicos/${topicoId}/materiais/${materialId}`)
        .set("Authorization", `Bearer ${professorToken}`) // Add token
        .field("titulo", "Matrizes Avançadas")
        .field("descricao", "Atualizado");

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty("message", "Material atualizado com sucesso");
      expect(response.body.data).toHaveProperty("titulo", "Matrizes Avançadas");
    });

    test("should return 401 without authentication", async () => {
      const material = { tipo: "pdf", titulo: "Matrizes", ordem: 0 };
      disciplina.topicos[0].materiais.push(material);
      await disciplina.save();
      const materialId = disciplina.topicos[0].materiais[0]._id;

      const response = await request(app)
        .put(`/api/cardsDisciplinas/matematica/topicos/${topicoId}/materiais/${materialId}`)
        .field("titulo", "Matrizes Avançadas");

      expect(response.status).toBe(401);
    });
  });

  describe("DELETE /api/cardsDisciplinas/:slug/topicos/:topicoId/materiais/:materialId", () => {
    test("should delete a material", async () => {
      // Adicionar um material ao tópico
      const material = { tipo: "pdf", titulo: "Matrizes", ordem: 0 };
      disciplina.topicos[0].materiais.push(material);
      await disciplina.save();
      const materialId = disciplina.topicos[0].materiais[0]._id;

      const response = await request(app)
        .delete(`/api/cardsDisciplinas/matematica/topicos/${topicoId}/materiais/${materialId}`)
        .set("Authorization", `Bearer ${professorToken}`); // Add token

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty("message", "Material deletado com sucesso");
    });

    test("should return 401 without authentication", async () => {
      const material = { tipo: "pdf", titulo: "Matrizes", ordem: 0 };
      disciplina.topicos[0].materiais.push(material);
      await disciplina.save();
      const materialId = disciplina.topicos[0].materiais[0]._id;

      const response = await request(app)
        .delete(`/api/cardsDisciplinas/matematica/topicos/${topicoId}/materiais/${materialId}`);

      expect(response.status).toBe(401);
    });
  });

  describe("GET /api/cardsDisciplinas/:slug/topicos/:topicoId/materiais/:materialId/download", () => {
    test("should download a material", async () => {
      // Adicionar um material ao tópico
      const material = {
        tipo: "pdf",
        titulo: "Matrizes",
        arquivo: {
          data: Buffer.from("fake-pdf-data"),
          contentType: "application/pdf",
          nomeOriginal: "matrizes.pdf",
        },
        ordem: 0,
      };
      disciplina.topicos[0].materiais.push(material);
      await disciplina.save();
      const materialId = disciplina.topicos[0].materiais[0]._id;

      const response = await request(app)
        .get(`/api/cardsDisciplinas/matematica/topicos/${topicoId}/materiais/${materialId}/download`)
        .set("Authorization", `Bearer ${professorToken}`); // Add token

      expect(response.status).toBe(200);
      expect(response.headers["content-type"]).toBe("application/pdf");
      expect(response.headers["content-disposition"]).toContain("matrizes.pdf");
    });

  
  });
});