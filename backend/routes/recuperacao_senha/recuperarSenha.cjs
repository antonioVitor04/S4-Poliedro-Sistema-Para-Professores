const express = require("express");
const bcrypt = require("bcryptjs");
const routerSenha = express.Router();

const Aluno = require("../../models/aluno.cjs");
const Professor = require("../../models/professor.cjs");
const CodigoVerificacao = require("../../models/codigoVerificacao.cjs"); // model TTL

// Rota para atualizar a senha usando código
routerSenha.post("/atualizar-senha", async (req, res) => {
  const { email, codigo, novaSenha } = req.body;

  if (!email || !codigo || !novaSenha) {
    return res
      .status(400)
      .json({ error: "Email, código e nova senha são obrigatórios" });
  }

  try {
    // Verificar o código no MongoDB
    const registro = await CodigoVerificacao.findOne({
      email,
      codigo,
      usado: false,
    });

    if (!registro) {
      return res.status(400).json({ error: "Código inválido ou expirado" });
    }
    // Marca como usado (mas não apaga imediatamente)
    registro.usado = true;
    await registro.save();
    // Hash da nova senha
    const hashedPassword = await bcrypt.hash(novaSenha, 10);

    // Procurar usuário nas duas collections
    let usuario = await Aluno.findOneAndUpdate(
      { email },
      { senha: hashedPassword },
      { new: true }
    );

    if (!usuario) {
      usuario = await Professor.findOneAndUpdate(
        { email },
        { senha: hashedPassword },
        { new: true }
      );
    }

    if (!usuario) {
      return res.status(404).json({ error: "Usuário não encontrado" });
    }

    return res.json({ message: "Senha atualizada com sucesso" });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "Erro ao atualizar a senha" });
  }
});

module.exports = routerSenha;
