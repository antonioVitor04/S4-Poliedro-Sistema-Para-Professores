// tests/integration/notas.test.cjs
const request = require("supertest");
const mongoose = require("mongoose");
const app = require("../../server.cjs");
const Nota = require("../../models/nota.cjs");
const CardDisciplina = require("../../models/cardDisciplina.cjs");
const Aluno = require("../../models/aluno.cjs");
const AuthHelper = require("../helpers/authHelper.cjs");

describe("Notas Routes", () => {
  let professorToken, professor, aluno, disciplina;

  beforeAll(async () => {
    const auth = await AuthHelper.createProfessorAndLogin();
    professor = auth.professor;
    professorToken = auth.token;
  });

  beforeEach(async () => {
    await Nota.deleteMany({});

    // FIX: Criar aluno e disciplina FRESH em cada teste para IDs consistentes
    aluno = new Aluno({
      nome: "Aluno Teste",
      ra: "123456",
      email: "aluno.teste@sistemapoliedro.br",
      senha: "senha123",
    });
    await aluno.save();

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
      alunos: [aluno._id],
      criadoPor: professor._id,
    });
    await disciplina.save();
  });

  afterEach(async () => {
    await Nota.deleteMany({});
  });

  afterAll(async () => {
    await CardDisciplina.deleteMany({});
    await Aluno.deleteMany({});
    await AuthHelper.cleanup();
    await mongoose.connection.close();
  });

  describe("GET /api/notas/:disciplinaId", () => {
    test("should get all notas for a disciplina", async () => {
      // Criar uma nota de teste
      const nota = new Nota({
        disciplina: disciplina._id,
        aluno: aluno._id,
        avaliacoes: [
          {
            nome: "Prova 1",
            tipo: "prova",
            nota: 8.5,
            peso: 2,
            data: new Date()
          }
        ]
      });
      await nota.save();

      const response = await request(app)
        .get(`/api/notas/${disciplina._id}`)
        .set("Authorization", `Bearer ${professorToken}`);

      console.log("GET Notas Response:", response.status, response.body);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.count).toBe(1);
      expect(Array.isArray(response.body.data)).toBe(true);
      expect(response.body.data[0]).toHaveProperty("alunoNome", "Aluno Teste");
      expect(response.body.data[0]).toHaveProperty("alunoRa", "123456");
      expect(response.body.data[0].avaliacoes).toHaveLength(1);
    });

    test("should return 401 without authentication", async () => {
      const response = await request(app)
        .get(`/api/notas/${disciplina._id}`);

      expect(response.status).toBe(401);
    });

    test("should return 403 for professor not in disciplina", async () => {
      // Criar outro professor que não está na disciplina
      const otherAuth = await AuthHelper.createProfessorAndLogin();
      
      const response = await request(app)
        .get(`/api/notas/${disciplina._id}`)
        .set("Authorization", `Bearer ${otherAuth.token}`);

      console.log("GET Notas Unauthorized Professor Response:", response.status, response.body);

      expect(response.status).toBe(403);
    });

    test("should return empty array for disciplina without notas", async () => {
      const response = await request(app)
        .get(`/api/notas/${disciplina._id}`)
        .set("Authorization", `Bearer ${professorToken}`);

      console.log("GET Empty Notas Response:", response.status, response.body);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.count).toBe(0);
      expect(response.body.data).toHaveLength(0);
    });

    test("should return 404 for non-existent disciplina", async () => {
      const fakeId = new mongoose.Types.ObjectId();
      
      const response = await request(app)
        .get(`/api/notas/${fakeId}`)
        .set("Authorization", `Bearer ${professorToken}`);

      expect(response.status).toBe(404);
    });
  });

  describe("POST /api/notas", () => {
    test("should create a new nota", async () => {
      const novaNota = {
        disciplina: disciplina._id.toString(),
        aluno: aluno._id.toString(),
        avaliacoes: [
          {
            nome: "Prova 1",
            tipo: "prova",
            nota: 9.0,
            peso: 2
          },
          {
            nome: "Atividade 1",
            tipo: "atividade",
            nota: 8.0,
            peso: 1
          }
        ]
      };

      const response = await request(app)
        .post("/api/notas")
        .set("Authorization", `Bearer ${professorToken}`)
        .send(novaNota);

      console.log("POST Nota Response:", response.status, response.body);

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.message).toBe("Nota criada com sucesso");
      expect(response.body.data).toHaveProperty("alunoNome", "Aluno Teste");
      expect(response.body.data).toHaveProperty("alunoRa", "123456");
      expect(response.body.data.avaliacoes).toHaveLength(2);

      // Verificar se foi salvo no banco
      const notaSalva = await Nota.findOne({
        disciplina: disciplina._id,
        aluno: aluno._id
      });
      expect(notaSalva).not.toBeNull();
      expect(notaSalva.avaliacoes).toHaveLength(2);
    });

    test("should create nota with empty avaliacoes array", async () => {
      const novaNota = {
        disciplina: disciplina._id.toString(),
        aluno: aluno._id.toString(),
        avaliacoes: []
      };

      const response = await request(app)
        .post("/api/notas")
        .set("Authorization", `Bearer ${professorToken}`)
        .send(novaNota);

      console.log("POST Empty Avaliacoes Response:", response.status, response.body);

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data.avaliacoes).toHaveLength(0);
    });

    test("should return 400 when creating duplicate nota", async () => {
      // Criar nota inicial
      const nota = new Nota({
        disciplina: disciplina._id,
        aluno: aluno._id,
        avaliacoes: [{ nome: "Prova 1", tipo: "prova", nota: 8.5 }]
      });
      await nota.save();

      // Tentar criar outra nota para mesmo aluno/disciplina
      const novaNota = {
        disciplina: disciplina._id.toString(),
        aluno: aluno._id.toString(),
        avaliacoes: [{ nome: "Prova 2", tipo: "prova", nota: 9.0 }]
      };

      const response = await request(app)
        .post("/api/notas")
        .set("Authorization", `Bearer ${professorToken}`)
        .send(novaNota);

      console.log("POST Duplicate Nota Response:", response.status, response.body);

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain("Nota já existe para este aluno na disciplina");
    });

    test("should return 404 for non-existent disciplina", async () => {
      const fakeId = new mongoose.Types.ObjectId();
      
      const novaNota = {
        disciplina: fakeId.toString(),
        aluno: aluno._id.toString(),
        avaliacoes: [{ nome: "Prova 1", tipo: "prova", nota: 8.5 }]
      };

      const response = await request(app)
        .post("/api/notas")
        .set("Authorization", `Bearer ${professorToken}`)
        .send(novaNota);

      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
      expect(response.body.error).toBe("Disciplina não encontrada");  // FIX: Mensagem atualizada
    });

    test("should return 404 for non-existent aluno", async () => {
      const fakeId = new mongoose.Types.ObjectId();
      
      const novaNota = {
        disciplina: disciplina._id.toString(),
        aluno: fakeId.toString(),
        avaliacoes: [{ nome: "Prova 1", tipo: "prova", nota: 8.5 }]
      };

      const response = await request(app)
        .post("/api/notas")
        .set("Authorization", `Bearer ${professorToken}`)
        .send(novaNota);

      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
      expect(response.body.error).toBe("Disciplina ou aluno não encontrado");  // FIX: Mensagem atualizada
    });

    test("should return 401 without authentication", async () => {
      const novaNota = {
        disciplina: disciplina._id.toString(),
        aluno: aluno._id.toString(),
        avaliacoes: [{ nome: "Prova 1", tipo: "prova", nota: 8.5 }]
      };

      const response = await request(app)
        .post("/api/notas")
        .send(novaNota);

      expect(response.status).toBe(401);
    });
  });

  describe("PUT /api/notas/:id", () => {
    let notaId;

    beforeEach(async () => {
      // Criar nota para atualização
      const nota = new Nota({
        disciplina: disciplina._id,
        aluno: aluno._id,
        avaliacoes: [
          {
            nome: "Prova 1",
            tipo: "prova",
            nota: 8.5,
            peso: 2,
            data: new Date()
          }
        ]
      });
      await nota.save();
      notaId = nota._id.toString();
    });

    test("should update a nota", async () => {
      const atualizacao = {
        avaliacoes: [
          {
            nome: "Prova 1 Atualizada",
            tipo: "prova",
            nota: 9.5,
            peso: 3
          },
          {
            nome: "Nova Atividade",
            tipo: "atividade",
            nota: 10.0,
            peso: 1
          }
        ]
      };

      const response = await request(app)
        .put(`/api/notas/${notaId}`)
        .set("Authorization", `Bearer ${professorToken}`)
        .send(atualizacao);

      console.log("PUT Nota Response:", response.status, response.body);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.message).toBe("Nota atualizada com sucesso");
      expect(response.body.data.avaliacoes).toHaveLength(2);
      expect(response.body.data.avaliacoes[0]).toHaveProperty("nome", "Prova 1 Atualizada");
      expect(response.body.data.avaliacoes[0]).toHaveProperty("nota", 9.5);

      // Verificar se foi atualizado no banco
      const notaAtualizada = await Nota.findById(notaId);
      expect(notaAtualizada.avaliacoes).toHaveLength(2);
    });

    test("should update nota with empty avaliacoes", async () => {
      const atualizacao = {
        avaliacoes: []
      };

      const response = await request(app)
        .put(`/api/notas/${notaId}`)
        .set("Authorization", `Bearer ${professorToken}`)
        .send(atualizacao);

      console.log("PUT Empty Avaliacoes Response:", response.status, response.body);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.avaliacoes).toHaveLength(0);
    });

    test("should return 404 for non-existent nota", async () => {
      const fakeId = new mongoose.Types.ObjectId();
      const atualizacao = {
        avaliacoes: [{ nome: "Prova", tipo: "prova", nota: 8.0 }]
      };

      const response = await request(app)
        .put(`/api/notas/${fakeId}`)
        .set("Authorization", `Bearer ${professorToken}`)
        .send(atualizacao);

      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain("Nota não encontrada");
    });

    test("should return 401 without authentication", async () => {
      const atualizacao = {
        avaliacoes: [{ nome: "Prova", tipo: "prova", nota: 8.0 }]
      };

      const response = await request(app)
        .put(`/api/notas/${notaId}`)
        .send(atualizacao);

      expect(response.status).toBe(401);
    });
  });

  describe("DELETE /api/notas/:id", () => {
    let notaId;

    beforeEach(async () => {
      // Criar nota para deletar
      const nota = new Nota({
        disciplina: disciplina._id,
        aluno: aluno._id,
        avaliacoes: [{ nome: "Prova 1", tipo: "prova", nota: 8.5 }]
      });
      await nota.save();
      notaId = nota._id.toString();
    });

    test("should delete a nota", async () => {
      const response = await request(app)
        .delete(`/api/notas/${notaId}`)
        .set("Authorization", `Bearer ${professorToken}`);

      console.log("DELETE Nota Response:", response.status, response.body);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.message).toBe("Nota deletada com sucesso");
      expect(response.body.data).toHaveProperty("_id", notaId);

      // Verificar se foi removido do banco
      const notaDeletada = await Nota.findById(notaId);
      expect(notaDeletada).toBeNull();
    });

    test("should return 404 for non-existent nota", async () => {
      const fakeId = new mongoose.Types.ObjectId();

      const response = await request(app)
        .delete(`/api/notas/${fakeId}`)
        .set("Authorization", `Bearer ${professorToken}`);

      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain("Nota não encontrada");
    });

    test("should return 401 without authentication", async () => {
      const response = await request(app)
        .delete(`/api/notas/${notaId}`);

      expect(response.status).toBe(401);
    });
  });

  describe("Nota validation and business rules", () => {
    test("should validate nota range (0-10)", async () => {
      const notaInvalida = {
        disciplina: disciplina._id.toString(),
        aluno: aluno._id.toString(),
        avaliacoes: [
          {
            nome: "Prova Invalida",
            tipo: "prova",
            nota: 11.0, // nota > 10
            peso: 1
          }
        ]
      };

      const response = await request(app)
        .post("/api/notas")
        .set("Authorization", `Bearer ${professorToken}`)
        .send(notaInvalida);

      console.log("POST Invalid Nota Range Response:", response.status, response.body);

      expect(response.status).toBe(400);
    });

    test("should validate avaliacao tipo enum", async () => {
      const notaInvalida = {
        disciplina: disciplina._id.toString(),
        aluno: aluno._id.toString(),
        avaliacoes: [
          {
            nome: "Prova Invalida",
            tipo: "tipo_invalido", // tipo não permitido
            nota: 8.0,
            peso: 1
          }
        ]
      };

      const response = await request(app)
        .post("/api/notas")
        .set("Authorization", `Bearer ${professorToken}`)
        .send(notaInvalida);

      console.log("POST Invalid Tipo Response:", response.status, response.body);

      expect(response.status).toBe(400);
    });

    test("should accept valid avaliacao tipos", async () => {
      const notaValida = {
        disciplina: disciplina._id.toString(),
        aluno: aluno._id.toString(),
        avaliacoes: [
          {
            nome: "Prova Válida",
            tipo: "prova",
            nota: 8.0,
            peso: 2
          },
          {
            nome: "Atividade Válida",
            tipo: "atividade", 
            nota: 9.0,
            peso: 1
          }
        ]
      };

      const response = await request(app)
        .post("/api/notas")
        .set("Authorization", `Bearer ${professorToken}`)
        .send(notaValida);

      console.log("POST Valid Tipos Response:", response.status, response.body);

      expect(response.status).toBe(201);
    });
  });

  describe("Admin access tests", () => {
    let adminToken;

    beforeAll(async () => {
      const adminAuth = await AuthHelper.createAdminAndLogin();
      adminToken = adminAuth.token;
    });

    test("admin should access notas from any disciplina", async () => {
      // Criar uma disciplina com outro professor
      const otherAuth = await AuthHelper.createProfessorAndLogin();
      const outraDisciplina = new CardDisciplina({
        titulo: "Física",
        slug: "fisica",
        imagem: { 
          data: Buffer.from("fake-image-data"), 
          contentType: "image/jpeg" 
        },
        icone: { 
          data: Buffer.from("fake-icon-data"), 
          contentType: "image/png" 
        },
        professores: [otherAuth.professor._id],
        alunos: [aluno._id],
        criadoPor: otherAuth.professor._id,
      });
      await outraDisciplina.save();

      // Criar nota na outra disciplina
      const nota = new Nota({
        disciplina: outraDisciplina._id,
        aluno: aluno._id,
        avaliacoes: [{ nome: "Prova", tipo: "prova", nota: 8.5 }]
      });
      await nota.save();

      // Admin deve conseguir acessar
      const response = await request(app)
        .get(`/api/notas/${outraDisciplina._id}`)
        .set("Authorization", `Bearer ${adminToken}`);

      console.log("GET Admin Access Response:", response.status, response.body);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.count).toBe(1);
    });
  });
});