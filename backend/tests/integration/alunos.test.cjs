// tests/integration/alunos.test.cjs
const request = require("supertest");
const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const app = require("../../server.cjs");
const { executeWithTestFallback } = require('../helpers/transactionHelper.cjs');
const Aluno = require("../../models/aluno.cjs");
const Professor = require("../../models/professor.cjs");

describe("Aluno Routes", () => {
  let professorToken;
  let alunoToken;
  let aluno;
  let professor;

  beforeAll(async () => {
    // Criar professor para autenticação
    const hashedPassword = await bcrypt.hash("senha123", 10);
    professor = new Professor({
      nome: "Professor Teste",
      email: "prof@sistemapoliedro.br",
      senha: hashedPassword,
    });
    await professor.save();
    professorToken = jwt.sign(
      { id: professor._id, role: "professor" },
      process.env.JWT_SECRET
    );
  });

  afterEach(async () => {
    await Aluno.deleteMany({});
  });

  afterAll(async () => {
    await Professor.deleteMany({});
    await mongoose.connection.close();
  });

  // =======================
  //  POST /api/alunos/register
  // =======================
  describe("POST /api/alunos/register", () => {
    test("should register a new aluno", async () => {
      const response = await request(app)
        .post("/api/alunos/register")
        .set("Authorization", `Bearer ${professorToken}`)
        .send({
          nome: "Aluno Teste",
          ra: "123456",
          email: "aluno@alunosistemapoliedro.br",
        });

      expect(response.status).toBe(201);
      expect(response.body).toHaveProperty("msg", "Aluno registrado com sucesso!");
      expect(response.body.aluno).toHaveProperty("ra", "123456");
    });

    test("should return 400 for duplicate RA", async () => {
      await request(app)
        .post("/api/alunos/register")
        .set("Authorization", `Bearer ${professorToken}`)
        .send({
          nome: "Aluno 1",
          ra: "111111",
          email: "a1@alunosistemapoliedro.br",
        });

      const response = await request(app)
        .post("/api/alunos/register")
        .set("Authorization", `Bearer ${professorToken}`)
        .send({
          nome: "Aluno 2",
          ra: "111111",
          email: "a2@alunosistemapoliedro.br",
        });

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty("msg", "RA já cadastrado");
    });

    test("should return 401 without professor token", async () => {
      const response = await request(app)
        .post("/api/alunos/register")
        .send({ nome: "Aluno Teste", ra: "222222" });

      expect(response.status).toBe(401);
    });
  });

  // =======================
  //  POST /api/alunos/login
  // =======================
  describe("POST /api/alunos/login", () => {
    test("should login aluno with correct credentials", async () => {
      const hashedPassword = await bcrypt.hash("123456", 10);
      await Aluno.create({
        nome: "Aluno Login",
        ra: "123456",
        email: "login@alunosistemapoliedro.br",
        senha: hashedPassword,
      });

      const response = await request(app)
        .post("/api/alunos/login")
        .send({ ra: "123456", senha: "123456" });

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty("token");
      expect(response.body.aluno).toHaveProperty("ra", "123456");
    });

    test("should return 400 for invalid credentials", async () => {
      const response = await request(app)
        .post("/api/alunos/login")
        .send({ ra: "999999", senha: "wrong" });

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty("msg", "Aluno não encontrado");
    });
  });

  // =======================
  //  GET /api/alunos
  // =======================
  describe("GET /api/alunos", () => {
    test("should return aluno profile", async () => {
      const alunoCriado = await Aluno.create({
        nome: "Aluno Perfil",
        ra: "333333",
        email: "perfil@alunosistemapoliedro.br",
        senha: await bcrypt.hash("333333", 10),
      });

      const token = jwt.sign(
        { id: alunoCriado._id, role: "aluno" },
        process.env.JWT_SECRET
      );

      const response = await request(app)
        .get("/api/alunos")
        .set("Authorization", `Bearer ${token}`);

      expect(response.status).toBe(200);
      expect(response.body.aluno).toHaveProperty("ra", "333333");
    });

    test("should return 401 without token", async () => {
      const response = await request(app).get("/api/alunos");
      expect(response.status).toBe(401);
    });
  });

  // =======================
  //  PUT /api/alunos/update
  // =======================
  describe("PUT /api/alunos/update", () => {
    test("should update aluno info", async () => {
      aluno = await Aluno.create({
        nome: "Antigo Nome",
        ra: "444444",
        email: "old@alunosistemapoliedro.br",
        senha: await bcrypt.hash("444444", 10),
      });
      alunoToken = jwt.sign(
        { id: aluno._id, role: "aluno" },
        process.env.JWT_SECRET
      );

      const response = await request(app)
        .put("/api/alunos/update")
        .set("Authorization", `Bearer ${alunoToken}`)
        .send({ nome: "Novo Nome" });

      expect(response.status).toBe(200);
      expect(response.body.aluno).toHaveProperty("nome", "Novo Nome");
    });
  });

  // =======================
  //  GET /api/alunos/list
  // =======================
  describe("GET /api/alunos/list", () => {
    test("should list all alunos for professor", async () => {
      await Aluno.create([
        { nome: "A1", ra: "555111", senha: await bcrypt.hash("1", 10) },
        { nome: "A2", ra: "555222", senha: await bcrypt.hash("2", 10) },
      ]);

      const response = await request(app)
        .get("/api/alunos/list")
        .set("Authorization", `Bearer ${professorToken}`);

      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body.length).toBeGreaterThanOrEqual(2);
    });
  });

  // =======================
  //  PUT /api/alunos/:id
  // =======================
  describe("PUT /api/alunos/:id", () => {
    test("should update aluno by ID as professor", async () => {
      const alunoCriado = await Aluno.create({
        nome: "Aluno Original",
        ra: "777777",
        email: "orig@alunosistemapoliedro.br",
        senha: await bcrypt.hash("777777", 10),
      });

      const response = await request(app)
        .put(`/api/alunos/${alunoCriado._id}`)
        .set("Authorization", `Bearer ${professorToken}`)
        .send({ nome: "Aluno Editado" });

      expect(response.status).toBe(200);
      expect(response.body.aluno).toHaveProperty("nome", "Aluno Editado");
    });
  });

  // =======================
  //  DELETE /api/alunos/:id
  // =======================
  describe("DELETE /api/alunos/:id", () => {
    test("should delete aluno by ID as professor", async () => {
      const alunoCriado = await Aluno.create({
        nome: "Aluno Deletar",
        ra: "999999",
        email: "del@alunosistemapoliedro.br",
        senha: await bcrypt.hash("999999", 10),
      });

      const response = await request(app)
        .delete(`/api/alunos/${alunoCriado._id}`)
        .set("Authorization", `Bearer ${professorToken}`);

      console.log("DELETE Aluno Response:", response.status, response.body);

      // Verifica se a operação foi bem sucedida
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty("success", true);
      expect(response.body).toHaveProperty("message", "Aluno e todos os dados associados foram deletados com sucesso");

      // Verifica se o aluno foi realmente deletado do banco
      const alunoExists = await Aluno.findById(alunoCriado._id);
      expect(alunoExists).toBeNull();
    });
  });});