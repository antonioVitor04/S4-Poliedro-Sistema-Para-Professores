// models/professor.cjs
const mongoose = require("mongoose");

const professorSchema = new mongoose.Schema(
  {
    nome: { type: String, sparse: true },
    email: {
      type: String,
      required: true,
      unique: true,
      validate: {
        validator: function (v) {
          const emailRegex = /^[\w.-]+@sistemapoliedro\.br$/;
          return emailRegex.test(v);
        },
        message: (props) =>
          `${props.value} não é um email válido! O formato deve conter @sistemapoliedro.br`,
      },
    },
    senha: { type: String, required: true },
    tipo: { type: String, enum: ["admin", "professor"], default: "professor" },
    imagem: {
      data: String, // Base64 string
      contentType: String, // image/jpeg, image/png, etc.
      filename: String,
      size: Number,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Professor", professorSchema);
