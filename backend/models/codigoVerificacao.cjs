// models/codigoVerificacao.cjs
const mongoose = require("mongoose");

const codigoSchema = new mongoose.Schema({
  email: { type: String, required: true },
  codigo: { type: String, required: true },
  createdAt: { type: Date, default: Date.now, index: { expires: 300 } }, // 300 segundos = 5 min
});

module.exports = mongoose.model("CodigoVerificacao", codigoSchema);
