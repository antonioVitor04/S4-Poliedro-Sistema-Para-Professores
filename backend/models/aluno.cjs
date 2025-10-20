// models/aluno.cjs
const mongoose = require("mongoose");

const alunoSchema = new mongoose.Schema(
  {
    nome: { type: String, sparse: true },
    ra: { type: String, required: true, unique: true },
    email: {
      type: String,
      unique: true,
      sparse: true,
    },
    senha: { type: String, required: true },
    imagem: {
      data: String, // Base64 string
      contentType: String, // image/jpeg, image/png, etc.
      filename: String,
      size: Number,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Aluno", alunoSchema);
