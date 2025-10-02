require("dotenv").config();
const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const bcrypt = require("bcryptjs");
const path = require("path"); // Adicione esta linha
const fs = require("fs"); // Adicione esta linha
const app = express();

app.use(express.json());
app.use(cors());


const Professor = require("./models/professor.cjs");
mongoose.connect(process.env.MONGO_URL)
  .then(() => console.log("✅ MongoDB conectado"))
  .catch((err) => console.error("❌ Erro no MongoDB:", err));

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
app.use("/api/cardsDisciplinas", require("./routes/cards/disciplinas.cjs"));

// Rota de saúde para testar o servidor
app.get('/api/health', (req, res) => {
  res.json({ 
    success: true, 
    message: 'Servidor funcionando',
    uploadsPath: uploadsDir
  });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Servidor rodando na porta ${PORT}`));