const mongoose = require("mongoose");

const detalheSchema = new mongoose.Schema({
  tipo: {
    type: String,
    enum: ["prova", "atividade"],
    required: true,
  },
  descricao: {
    type: String,
    required: true,
  },
  nota: {
    type: Number,
    default: 0,
    min: 0,
    max: 10,
  },
  peso: {
    type: Number,
    default: 1,
    min: 0.1,
  },
});

const disciplinaNotaSchema = new mongoose.Schema(
  {
    nome: {
      type: String,
      required: true,
    },
    alunoId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Aluno", // Assumindo modelo Aluno existe
      required: true,
    },
    detalhes: [detalheSchema],
    mediaProvas: {
      type: Number,
      default: 0,
    },
    mediaAtividades: {
      type: Number,
      default: 0,
    },
    mediaFinal: {
      type: Number,
      default: 0,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("DisciplinaNota", disciplinaNotaSchema);
