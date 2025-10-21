require("dotenv").config();
const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const bcrypt = require("bcryptjs");
const path = require("path");
const fs = require("fs");
const app = express();

app.use(express.json());
app.use(cors());
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ limit: "10mb", extended: true }));

// Função de conexão
async function conectarAoMongoDB() {
  const url =
    process.env.NODE_ENV === "test"
      ? "mongodb://localhost:27017/testdb"
      : process.env.MONGO_URL;

  await mongoose
    .connect(url, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    })
    .then(() => console.log(`✅ MongoDB conectado em ${url}`))
    .catch((err) => console.error("❌ Erro no MongoDB:", err));
}

// Só conecta se não estiver em ambiente de teste
if (process.env.NODE_ENV !== "test") {
  conectarAoMongoDB();
} else {
  console.log("✅ Ambiente de teste - conexão MongoDB gerenciada pelos testes");
}

// ROTA TEMPORÁRIA PARA CRIAR ADMIN (REMOVA DEPOIS!)
app.post("/api/criar-admin-temp", async (req, res) => {
  try {
    const Professor = require("./models/professor.cjs");
    const bcrypt = require("bcryptjs");

    console.log("=== 🛠️ CRIANDO ADMIN TEMPORÁRIO ===");

    // Verificar se já existe
    const adminExistente = await Professor.findOne({
      email: "admin@sistemapoliedro.br",
    });
    if (adminExistente) {
      console.log("⚠️ Admin já existe, atualizando senha...");

      // Atualizar senha do admin existente
      const senhaHash = await bcrypt.hash("Admin123!", 10);
      adminExistente.senha = senhaHash;
      adminExistente.nome = "Joao da Silva";
      await adminExistente.save();

      console.log("✅ Senha do admin atualizada");

      // TESTAR O HASH IMEDIATAMENTE
      const testMatch = await bcrypt.compare("Admin123!", senhaHash);
      console.log("🔐 Teste da senha após update:", testMatch);

      return res.json({
        success: true,
        message: "Admin já existia - senha atualizada!",
        email: adminExistente.email,
        senhaTestada: testMatch,
      });
    }

    // Criar novo admin
    console.log("🆕 Criando novo admin...");
    const senhaHash = await bcrypt.hash("Admin123!", 10);

    console.log("📝 Dados do admin:");
    console.log("- Nome: Joao da Silva");
    console.log("- Email: admin@sistemapoliedro.br");
    console.log("- Senha hash:", senhaHash);
    console.log("- Tipo: admin");

    // TESTAR O HASH ANTES DE SALVAR
    const testMatch = await bcrypt.compare("Admin123!", senhaHash);
    console.log("🔐 Teste da senha antes de salvar:", testMatch);

    if (!testMatch) {
      throw new Error("ERRO: Hash da senha não está funcionando!");
    }

    const admin = new Professor({
      nome: "Joao da Silva",
      email: "admin@sistemapoliedro.br",
      senha: senhaHash,
      tipo: "admin",
      disciplinas: [],
    });

    await admin.save();
    console.log("✅ Admin salvo no banco com ID:", admin._id);

    // VERIFICAR NO BANCO
    const adminVerificado = await Professor.findOne({
      email: "admin@sistemapoliedro.br",
    });
    console.log("🔍 Admin verificado no banco:", {
      id: adminVerificado._id,
      email: adminVerificado.email,
      senhaHash: adminVerificado.senha,
      nome: adminVerificado.nome,
    });

    res.json({
      success: true,
      message: "Admin criado com sucesso!",
      credentials: {
        email: "admin@sistemapoliedro.br",
        senha: "Admin123!",
        senhaHash: senhaHash,
      },
      debug: {
        hashFuncionou: testMatch,
        adminId: admin._id,
      },
    });
  } catch (error) {
    console.error("💥 Erro ao criar admin:", error);
    res.status(500).json({
      success: false,
      error: error.message,
      stack: process.env.NODE_ENV === "development" ? error.stack : undefined,
    });
  }
});

// Rotas existentes
app.use("/api/alunos", require("./routes/rotaAluno.cjs"));
app.use("/api/professores", require("./routes/rotaProfessor.cjs"));
app.use(
  "/api/enviarEmail",
  require("./routes/recuperacao_senha/enviarEmail.cjs")
);
app.use(
  "/api/recuperarSenha",
  require("./routes/recuperacao_senha/recuperarSenha.cjs")
);

// Rotas das disciplinas (ATUALIZADAS)
app.use("/api/cardsDisciplinas", require("./routes/cards/disciplinas.cjs"));
app.use("/api/cardsDisciplinas", require("./routes/disciplina/topicos.cjs"));
app.use("/api/cardsDisciplinas", require("./routes/disciplina/materiais.cjs"));

// Nova rota para gerenciamento de relacionamentos
app.use("/api/relacionamentos", require("./routes/cards/relacionamentos.cjs"));

//nova rota para notas
app.use("/api/notas", require("./routes/notas.cjs"));
// Rota de saúde
app.get("/api/health", (req, res) => {
  res.json({
    success: true,
    message: "Servidor funcionando",
    environment: process.env.NODE_ENV || "development",
  });
});

const PORT = process.env.PORT || 5000;

// Só inicia o servidor se NÃO estiver em ambiente de teste
if (process.env.NODE_ENV !== "test") {
  app.listen(PORT, () => console.log(`Servidor rodando na porta ${PORT}`));
}

// Exporta o app para os testes
module.exports = app;
