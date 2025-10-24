const mongoose = require("mongoose");

const notificacoesSchema = new mongoose.Schema({
  mensagem: {
    type: String,
    required: true,
    trim: true
  },
  disciplina: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Disciplina",
    required: true
  },
  professor: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Professor",
    required: true
  },
  dataCriacao: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model("Notificacoes", notificacoesSchema);