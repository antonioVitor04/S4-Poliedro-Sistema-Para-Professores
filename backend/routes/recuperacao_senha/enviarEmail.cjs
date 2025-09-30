const express = require("express");
const nodemailer = require("nodemailer");
const routerEmail = express.Router();
const Aluno = require("../../models/aluno.cjs");
const Professor = require("../../models/professor.cjs");
const CodigoVerificacao = require("../../models/codigoVerificacao.cjs"); // seu model TTL

require("dotenv").config();

// Função para gerar código aleatório de 6 dígitos
function gerarCodigo() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// Configuração do transportador de e-mail
const transporter = nodemailer.createTransport({
  host: "smtp.gmail.com",
  port: 465,
  secure: true,
  auth: {
    user: "avaflgpi@gmail.com",
    pass: process.env.APP_PASSWORD,
  },
});

// Rota para enviar código de verificação
routerEmail.post("/enviar-codigo", async (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({ error: "O e-mail é obrigatório" });
  }

  try {
    // Verificar se o email existe em alguma collection
    const aluno = await Aluno.findOne({ email });
    const professor = await Professor.findOne({ email });

    if (!aluno && !professor) {
      return res.status(404).json({ error: "E-mail não cadastrado" });
    }

    const codigo = gerarCodigo();

    // Enviar e-mail com o código
    await transporter.sendMail({
      from: '"Poliedro" <avaflgpi@gmail.com>',
      to: email,
      subject: "Código de verificação",
      text: `Seu código de verificação é: ${codigo}`,
      html: `<p>Seu código de verificação é: <b>${codigo}</b></p>`,
    });

    // Salvar código no MongoDB com TTL de 5 minutos
    await CodigoVerificacao.create({ email, codigo });

    return res.json({ message: "Código enviado com sucesso" });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "Erro ao enviar o e-mail" });
  }
});

// Rota para verificar o código
routerEmail.post("/verificar-codigo", async (req, res) => {
  const { email, codigo } = req.body;

  if (!email || !codigo) {
    return res.status(400).json({ error: "Email e código são obrigatórios" });
  }

  try {
    // Procurar código no MongoDB
    const registro = await CodigoVerificacao.findOne({ email, codigo });

    if (!registro) {
      return res.status(400).json({ error: "Código inválido ou expirado" });
    }

    return res.json({ message: "Código verificado com sucesso" });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "Erro ao verificar código" });
  }
});

module.exports = routerEmail;
