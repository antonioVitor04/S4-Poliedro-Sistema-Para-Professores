// tests/integration/disciplinas.test.cjs
const request = require("supertest");
const mongoose = require("mongoose");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");
const app = require("../../server.cjs");
const CardDisciplina = require("../../models/cardDisciplina.cjs");
const Professor = require("../../models/professor.cjs");

describe("Disciplinas Routes", () => {
  let professorToken, disciplinaId;
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
    // Criar uma disciplina para testes
    await CardDisciplina.deleteMany({});
    const disciplina = new CardDisciplina({
      titulo: "Matemática",
      slug: "matematica",
      imagem: { data: Buffer.from("fake-image"), contentType: "image/jpeg" },
      icone: { data: Buffer.from("fake-icon"), contentType: "image/png" },
    });
    await disciplina.save();
    disciplinaId = disciplina._id;
  });

  afterEach(async () => {
    await CardDisciplina.deleteMany({});
  });

  afterAll(async () => {
    await Professor.deleteMany({});
    await mongoose.connection.close();
  });

  describe("POST /api/cardsDisciplinas", () => {
    test("should create a new disciplina", async () => {
      const response = await request(app)
        .post("/api/cardsDisciplinas")
        .set("Authorization", `Bearer ${professorToken}`) // Add token
        .field("titulo", "Física")
        .attach("imagem", Buffer.from("fake-image-data"), "image.jpg")
        .attach("icone", Buffer.from("fake-icon-data"), "icon.png");

      expect(response.status).toBe(201);
      expect(response.body).toHaveProperty("message", "Card criado com sucesso");
      expect(response.body.data).toHaveProperty("titulo", "Física");
      expect(response.body.data).toHaveProperty("slug", "fisica");
    });

    test("should return 401 without authentication", async () => {
      const response = await request(app)
        .post("/api/cardsDisciplinas")
        .field("titulo", "Física")
        .attach("imagem", Buffer.from("fake-image-data"), "image.jpg")
        .attach("icone", Buffer.from("fake-icon-data"), "icon.png");

      expect(response.status).toBe(401);
    });

    test("should return 400 for missing required fields", async () => {
      const response = await request(app)
        .post("/api/cardsDisciplinas")
        .set("Authorization", `Bearer ${professorToken}`) // Add token
        .field("titulo", "Física");

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty(
        "error",
        "Todos os campos (imagem, icone, titulo) são obrigatórios"
      );
    });
  });

  describe("GET /api/cardsDisciplinas", () => {
    test("should get all disciplinas", async () => {
      const response = await request(app).get("/api/cardsDisciplinas");

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty("success", true);
      expect(response.body.data).toBeInstanceOf(Array);
      expect(response.body.data[0]).toHaveProperty("titulo", "Matemática");
    });
  });

  describe("GET /api/cardsDisciplinas/disciplina/:slug", () => {
    test("should get a disciplina by slug", async () => {
      const response = await request(app).get(
        "/api/cardsDisciplinas/disciplina/matematica"
      );

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty("success", true);
      expect(response.body.data).toHaveProperty("titulo", "Matemática");
    });

    test("should return 404 for non-existing slug", async () => {
      const response = await request(app).get(
        "/api/cardsDisciplinas/disciplina/naoexiste"
      );

      expect(response.status).toBe(404);
      expect(response.body).toHaveProperty("error", "Disciplina não encontrada");
    });
  });

  describe("PUT /api/cardsDisciplinas/:id", () => {
    test("should update a disciplina", async () => {
      const response = await request(app)
        .put(`/api/cardsDisciplinas/${disciplinaId}`)
        .set("Authorization", `Bearer ${professorToken}`) // Add token
        .field("titulo", "Matemática Avançada")
        .attach("imagem", Buffer.from("new-fake-image-data"), "new-image.jpg");

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty("message", "Card atualizado com sucesso");
      expect(response.body.data).toHaveProperty("titulo", "Matemática Avançada");
    });

    test("should return 401 without authentication", async () => {
      const response = await request(app)
        .put(`/api/cardsDisciplinas/${disciplinaId}`)
        .field("titulo", "Matemática Avançada");

      expect(response.status).toBe(401);
    });

    test("should return 400 for invalid id", async () => {
      const response = await request(app)
        .put("/api/cardsDisciplinas/invalid-id")
        .set("Authorization", `Bearer ${professorToken}`) // Add token
        .field("titulo", "Matemática Avançada");

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty("error", "ID inválido");
    });
  });

  describe("DELETE /api/cardsDisciplinas/:id", () => {
    test("should delete a disciplina", async () => {
      const response = await request(app)
        .delete(`/api/cardsDisciplinas/${disciplinaId}`)
        .set("Authorization", `Bearer ${professorToken}`); // Add token

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty("message", "Card deletado com sucesso");
    });

    test("should return 401 without authentication", async () => {
      const response = await request(app).delete(
        `/api/cardsDisciplinas/${disciplinaId}`
      );

      expect(response.status).toBe(401);
    });

    test("should return 400 for invalid id", async () => {
      const response = await request(app)
        .delete("/api/cardsDisciplinas/invalid-id")
        .set("Authorization", `Bearer ${professorToken}`); // Add token

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty("error", "ID inválido");
    });
  });

  describe("GET /api/cardsDisciplinas/imagem/:id/:tipo", () => {
    test("should get disciplina image", async () => {
      const response = await request(app).get(
        `/api/cardsDisciplinas/imagem/${disciplinaId}/imagem`
      );

      expect(response.status).toBe(200);
      expect(response.headers["content-type"]).toBe("image/jpeg");
    });

    test("should return 400 for invalid tipo", async () => {
      const response = await request(app).get(
        `/api/cardsDisciplinas/imagem/${disciplinaId}/invalid`
      );

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty(
        "error",
        "Tipo inválido. Use 'imagem' ou 'icone'"
      );
    });
  });
});