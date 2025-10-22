// tests/integration/disciplinas.test.cjs
const request = require("supertest");
const mongoose = require("mongoose");
const app = require("../../server.cjs");
const CardDisciplina = require("../../models/cardDisciplina.cjs");
const AuthHelper = require("../helpers/authHelper.cjs");

describe("Disciplinas Routes", () => {
  let professorToken, professor, disciplinaId;

  beforeAll(async () => {
    const auth = await AuthHelper.createProfessorAndLogin();
    professor = auth.professor;
    professorToken = auth.token;
  });

  beforeEach(async () => {
    await CardDisciplina.deleteMany({});
    
    const disciplina = new CardDisciplina({
      titulo: "Matemática",
      slug: "matematica",
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
    });
    await disciplina.save();
    disciplinaId = disciplina._id.toString();
  });

  afterEach(async () => {
    await CardDisciplina.deleteMany({});
  });

  afterAll(async () => {
    await mongoose.connection.close();
  });

  describe("POST /api/cardsDisciplinas", () => {
    test("should create a new disciplina", async () => {
      const response = await request(app)
        .post("/api/cardsDisciplinas")
        .set("Authorization", `Bearer ${professorToken}`)
        .field("titulo", "Física")
        .attach("imagem", Buffer.from("fake-image-data"), "image.jpg")
        .attach("icone", Buffer.from("fake-icon-data"), "icon.png");

      console.log("POST Disciplina Response:", response.status, response.body);

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty("titulo", "Física");
    });

    test("should return 401 without authentication", async () => {
      const response = await request(app)
        .post("/api/cardsDisciplinas")
        .field("titulo", "Física");

      expect(response.status).toBe(401);
    });

    test("should return 400 for invalid data", async () => {
      const response = await request(app)
        .post("/api/cardsDisciplinas")
        .set("Authorization", `Bearer ${professorToken}`)
        .field("titulo", ""); // título vazio

      expect(response.status).toBe(400);
    });
  });

  describe("GET /api/cardsDisciplinas", () => {
    test("should get all disciplinas for authenticated user", async () => {
      const response = await request(app)
        .get("/api/cardsDisciplinas")
        .set("Authorization", `Bearer ${professorToken}`);

      console.log("GET Disciplinas Response:", response.status, response.body);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(Array.isArray(response.body.data)).toBe(true);
    });

    test("should return 401 without authentication", async () => {
      const response = await request(app)
        .get("/api/cardsDisciplinas");

      expect(response.status).toBe(401);
    });
  });

  describe("GET /api/cardsDisciplinas/disciplina/:slug", () => {
    test("should get a disciplina by slug for authorized user", async () => {
      const response = await request(app)
        .get("/api/cardsDisciplinas/disciplina/matematica")
        .set("Authorization", `Bearer ${professorToken}`);

      console.log("GET Disciplina by Slug Response:", response.status, response.body);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty("titulo", "Matemática");
    });

    test("should return 401 without authentication", async () => {
      const response = await request(app)
        .get("/api/cardsDisciplinas/disciplina/matematica");

      expect(response.status).toBe(401);
    });

    test("should return 404 for non-existent disciplina", async () => {
      const response = await request(app)
        .get("/api/cardsDisciplinas/disciplina/nao-existe")
        .set("Authorization", `Bearer ${professorToken}`);

      expect(response.status).toBe(404);
    });
  });

  describe("PUT /api/cardsDisciplinas/:id", () => {
    test("should update a disciplina", async () => {
      const response = await request(app)
        .put(`/api/cardsDisciplinas/${disciplinaId}`)
        .set("Authorization", `Bearer ${professorToken}`)
        .field("titulo", "Matemática Avançada");

      console.log("PUT Disciplina Response:", response.status, response.body);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.titulo).toBe("Matemática Avançada");
    });

    test("should return 401 without authentication", async () => {
      const response = await request(app)
        .put(`/api/cardsDisciplinas/${disciplinaId}`)
        .field("titulo", "Matemática Avançada");

      expect(response.status).toBe(401);
    });

    test("should return 404 for non-existent disciplina", async () => {
      const fakeId = new mongoose.Types.ObjectId();
      const response = await request(app)
        .put(`/api/cardsDisciplinas/${fakeId}`)
        .set("Authorization", `Bearer ${professorToken}`)
        .field("titulo", "Matemática Avançada");

      expect(response.status).toBe(404);
    });
  });

  describe("DELETE /api/cardsDisciplinas/:id", () => {
    test("should delete a disciplina", async () => {
      const response = await request(app)
        .delete(`/api/cardsDisciplinas/${disciplinaId}`)
        .set("Authorization", `Bearer ${professorToken}`);

      console.log("DELETE Disciplina Response:", response.status, response.body);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });

    test("should return 401 without authentication", async () => {
      const response = await request(app)
        .delete(`/api/cardsDisciplinas/${disciplinaId}`);

      expect(response.status).toBe(401);
    });
  });
});