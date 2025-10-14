// tests/integration/email.test.cjs
const request = require("supertest");
const mongoose = require("mongoose");
const app = require("../../server.cjs");
const Aluno = require("../../models/aluno.cjs");
const CodigoVerificacao = require("../../models/codigoVerificacao.cjs");

// Mock do Nodemailer
jest.mock("nodemailer", () => ({
  createTransport: jest.fn(() => ({
    sendMail: jest.fn().mockResolvedValue({ messageId: "test-message-id" })
  }))
}));

const nodemailer = require("nodemailer");

describe("Email Routes", () => {
  let mockSendMail;

  beforeEach(async () => {
    // Reset dos mocks
    nodemailer.createTransport.mockClear();
    mockSendMail = jest.fn().mockResolvedValue({ messageId: "test-message-id" });
    nodemailer.createTransport.mockReturnValue({ sendMail: mockSendMail });
    
    await Aluno.deleteMany({});
    await CodigoVerificacao.deleteMany({});
  });

  afterAll(async () => {
    await mongoose.connection.close();
  });

  describe("POST /api/enviarEmail/enviar-codigo", () => {
    test("should send verification code for valid email", async () => {
      const aluno = await Aluno.create({
        nome: "Aluno Teste",
        ra: "123456",
        email: "aluno@alunosistemapoliedro.br",
        senha: "hashed",
      });

      const response = await request(app)
        .post("/api/enviarEmail/enviar-codigo")
        .send({ email: "aluno@alunosistemapoliedro.br" });

      console.log("Enviar código response:", JSON.stringify(response.body, null, 2));
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty("message", "Código enviado com sucesso");
      
      // Verificar se o código foi salvo no banco
      const codigo = await CodigoVerificacao.findOne({
        email: "aluno@alunosistemapoliedro.br",
      });
      expect(codigo).toBeTruthy();
      expect(codigo.codigo).toMatch(/^\d{6}$/);
    });

    test("should return 404 for non-existing email", async () => {
      const response = await request(app)
        .post("/api/enviarEmail/enviar-codigo")
        .send({ email: "naoexiste@alunosistemapoliedro.br" });

      console.log("Non-existing email response:", JSON.stringify(response.body, null, 2));
      expect(response.status).toBe(404);
      expect(response.body).toHaveProperty("error", "E-mail não cadastrado");
    });
  });

  describe("POST /api/enviarEmail/verificar-codigo", () => {
    test("should verify valid code", async () => {
      await Aluno.create({
        nome: "Aluno Teste",
        ra: "123456",
        email: "aluno@alunosistemapoliedro.br",
        senha: "hashed",
      });

      await CodigoVerificacao.create({
        email: "aluno@alunosistemapoliedro.br",
        codigo: "123456",
        usado: false,
      });

      const response = await request(app)
        .post("/api/enviarEmail/verificar-codigo")
        .send({ email: "aluno@alunosistemapoliedro.br", codigo: "123456" });

      console.log("Verificar código response:", JSON.stringify(response.body, null, 2));
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty("message", "Código verificado com sucesso");
    });

    test("should return 400 for invalid code", async () => {
      const response = await request(app)
        .post("/api/enviarEmail/verificar-codigo")
        .send({ email: "aluno@alunosistemapoliedro.br", codigo: "999999" });

      console.log("Invalid code response:", JSON.stringify(response.body, null, 2));
      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty("error", "Código inválido ou expirado");
    });
  });
});