// models/nota.cjs
const mongoose = require("mongoose");

// Updated backend model (models/nota.cjs) - add tipo to avaliacaoSchema
const avaliacaoSchema = new mongoose.Schema({
  nome: { type: String, required: true },
  tipo: { type: String, enum: ["prova", "atividade"], required: true }, // Added
  nota: { type: Number, min: 0, max: 10 },
  peso: { type: Number, default: 1 },
  data: { type: Date, default: Date.now },
});

const notaSchema = new mongoose.Schema(
  {
    disciplina: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "CardDisciplina",
      required: true,
    },
    aluno: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Aluno",
      required: true,
    },
    avaliacoes: [avaliacaoSchema],
  },
  { timestamps: true }
);

// Index para buscas rápidas
notaSchema.index({ disciplina: 1, aluno: 1 }, { unique: true });

module.exports = mongoose.model("Nota", notaSchema);
