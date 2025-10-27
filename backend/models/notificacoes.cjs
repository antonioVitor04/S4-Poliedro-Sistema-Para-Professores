const mongoose = require("mongoose");

const notificacaoSchema = new mongoose.Schema({
  mensagem: {
    type: String,
    required: true,
  },
  disciplina: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "CardDisciplina",
    required: true,
  },
  professor: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Professor",
    required: true,
  },
  lida: {
    type: Boolean,
    default: false,
  },
  favorita: {
    type: Boolean,
    default: false,
  },
  dataCriacao: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model("Notificacao", notificacaoSchema);
