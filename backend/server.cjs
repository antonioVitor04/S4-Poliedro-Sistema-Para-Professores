// server.cjs (ou seu arquivo principal)
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

const Professor = require("./models/professor.cjs");
mongoose.connect(process.env.MONGO_URL)
  .then(() => console.log("✅ MongoDB conectado"))
  .catch((err) => console.error("❌ Erro no MongoDB:", err));

// Rotas existentes
app.use("/api/alunos", require("./routes/rotaAluno.cjs"));
app.use("/api/professores", require("./routes/rotaProfessor.cjs"));
app.use("/api/enviarEmail", require("./routes/recuperacao_senha/enviarEmail.cjs"));
app.use("/api/recuperarSenha", require("./routes/recuperacao_senha/recuperarSenha.cjs"));

// Rotas das disciplinas
app.use("/api/cardsDisciplinas", require("./routes/cards/disciplinas.cjs"));
app.use("/api/cardsDisciplinas", require("./routes/disciplina/topicos.cjs"));
app.use("/api/cardsDisciplinas", require("./routes/disciplina/materiais.cjs"));

// Rota de saúde
app.get('/api/health', (req, res) => {
  res.json({ 
    success: true, 
    message: 'Servidor funcionando'
  });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Servidor rodando na porta ${PORT}`));