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
const Professor = require("./models/professor.cjs");

// Função de conexão (segue o padrão que você pediu)
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

// Só conecta se não estiver em ambiente de teste (os testes cuidam disso)
if (process.env.NODE_ENV !== "test") {
  conectarAoMongoDB();
} else {
  console.log("✅ Ambiente de teste - conexão MongoDB gerenciada pelos testes");
}

// Rotas existentes (mantidas)
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

// Rotas das disciplinas
app.use("/api/cardsDisciplinas", require("./routes/cards/disciplinas.cjs"));
app.use("/api/cardsDisciplinas", require("./routes/disciplina/topicos.cjs"));
app.use("/api/cardsDisciplinas", require("./routes/disciplina/materiais.cjs"));

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
