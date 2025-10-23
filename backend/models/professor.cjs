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
      data: String,
      contentType: String,
      filename: String,
      size: Number,
    },
    disciplinas: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "CardDisciplina",
      },
    ],
  },
  { timestamps: true }
);

module.exports = mongoose.model("Professor", professorSchema);
