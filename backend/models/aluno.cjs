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
      data: String,
      contentType: String,
      filename: String,
      size: Number,
    },
    disciplinas: [{ 
      type: mongoose.Schema.Types.ObjectId, 
      ref: "CardDisciplina" 
    }],
  },
  { timestamps: true }
);

module.exports = mongoose.model("Aluno", alunoSchema);