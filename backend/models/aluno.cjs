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
      validate: {
        validator: function (v) {
          if (!v) return true; // email opcional
          const emailRegex = /^[\w.-]+@alunosistemapoliedro\.br$/;
          return emailRegex.test(v);
        },
        message: (props) =>
          `${props.value} não é um email válido! O formato deve conter @alunosistemapoliedro.br`,
      },
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
