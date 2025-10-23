// tests/integration/materiais.test.cjs
const request = require("supertest");
const mongoose = require("mongoose");
const app = require("../../server.cjs");
const CardDisciplina = require("../../models/cardDisciplina.cjs");
const AuthHelper = require("../helpers/authHelper.cjs");

describe("Materiais Routes", () => {
  let professorToken, professor, disciplina, topicoId;

  beforeAll(async () => {
    const auth = await AuthHelper.createProfessorAndLogin();
    professor = auth.professor;
    professorToken = auth.token;
  });

  beforeEach(async () => {
    await CardDisciplina.deleteMany({});
    
    disciplina = new CardDisciplina({
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
      topicos: [{
        titulo: "Álgebra Linear", 
        descricao: "Introdução à álgebra linear",
        ordem: 0,
        materiais: []
      }],
    });
    
    await disciplina.save();
    topicoId = disciplina.topicos[0]._id.toString();
  });

  afterEach(async () => {
    await CardDisciplina.deleteMany({});
  });

  afterAll(async () => {
    await mongoose.connection.close();
  });

  describe("POST /api/cardsDisciplinas/:slug/topicos/:topicoId/materiais", () => {
    test("should create a new material", async () => {
      const response = await request(app)
        .post(`/api/cardsDisciplinas/${disciplina.slug}/topicos/${topicoId}/materiais`)
        .set("Authorization", `Bearer ${professorToken}`)
        .field("tipo", "pdf")
        .field("titulo", "Matrizes")
        .field("peso", "2");

      console.log("POST Material Response:", response.status, response.body);

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty("titulo", "Matrizes");
    });

    test("should return 401 without authentication", async () => {
      const response = await request(app)
        .post(`/api/cardsDisciplinas/${disciplina.slug}/topicos/${topicoId}/materiais`)
        .field("tipo", "pdf")
        .field("titulo", "Matrizes");

      expect(response.status).toBe(401);
    });

    test("should return 404 for non-existent topico", async () => {
      const fakeTopicoId = new mongoose.Types.ObjectId();
      const response = await request(app)
        .post(`/api/cardsDisciplinas/${disciplina.slug}/topicos/${fakeTopicoId}/materiais`)
        .set("Authorization", `Bearer ${professorToken}`)
        .field("tipo", "pdf")
        .field("titulo", "Matrizes");

      expect(response.status).toBe(404);
    });
  });

  describe("PUT /api/cardsDisciplinas/:slug/topicos/:topicoId/materiais/:materialId", () => {
    let materialId;

    beforeEach(async () => {
      // Adicionar um material antes dos testes PUT
      const material = { 
        tipo: "pdf", 
        titulo: "Matrizes", 
        ordem: 0 
      };
      disciplina.topicos[0].materiais.push(material);
      await disciplina.save();
      
      materialId = disciplina.topicos[0].materiais[0]._id.toString();
    });

    test("should update a material", async () => {
      const response = await request(app)
        .put(`/api/cardsDisciplinas/${disciplina.slug}/topicos/${topicoId}/materiais/${materialId}`)
        .set("Authorization", `Bearer ${professorToken}`)
        .field("titulo", "Matrizes Avançadas");

      console.log("PUT Material Response:", response.status, response.body);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.titulo).toBe("Matrizes Avançadas");
    });

    test("should return 401 without authentication", async () => {
      const response = await request(app)
        .put(`/api/cardsDisciplinas/${disciplina.slug}/topicos/${topicoId}/materiais/${materialId}`)
        .field("titulo", "Matrizes Avançadas");

      expect(response.status).toBe(401);
    });
  });

  describe("DELETE /api/cardsDisciplinas/:slug/topicos/:topicoId/materiais/:materialId", () => {
    let materialId;

    beforeEach(async () => {
      // Adicionar um material antes dos testes DELETE
      const material = { 
        tipo: "pdf", 
        titulo: "Matrizes", 
        ordem: 0 
      };
      disciplina.topicos[0].materiais.push(material);
      await disciplina.save();
      
      materialId = disciplina.topicos[0].materiais[0]._id.toString();
    });

    test("should delete a material", async () => {
      const response = await request(app)
        .delete(`/api/cardsDisciplinas/${disciplina.slug}/topicos/${topicoId}/materiais/${materialId}`)
        .set("Authorization", `Bearer ${professorToken}`);

      console.log("DELETE Material Response:", response.status, response.body);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });

    test("should return 401 without authentication", async () => {
      const response = await request(app)
        .delete(`/api/cardsDisciplinas/${disciplina.slug}/topicos/${topicoId}/materiais/${materialId}`);

      expect(response.status).toBe(401);
    });
  });
});