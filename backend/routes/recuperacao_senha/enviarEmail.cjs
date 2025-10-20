const express = require("express");
const nodemailer = require("nodemailer");
const bcrypt = require("bcrypt");
const routerEmail = express.Router();
const Aluno = require("../../models/aluno.cjs");
const Professor = require("../../models/professor.cjs");
const CodigoVerificacao = require("../../models/codigoVerificacao.cjs");

require("dotenv").config();

// Função para gerar código aleatório de 6 dígitos
function gerarCodigo() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// Função para gerar senha aleatória (8 caracteres alfanuméricos)
function gerarSenhaAleatoria() {
  return Math.random().toString(36).slice(-8); // Ex: "k3j9m2p8"
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

// Rota para enviar código de verificação (mantida original)
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

// Rota para verificar o código (mantida original)
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

// NOVA ROTA: Enviar senha inicial para novo usuário
routerEmail.post("/enviar-senha-inicial", async (req, res) => {
  const { email, tipo } = req.body;

  if (!email || !tipo) {
    return res.status(400).json({ error: "Email e tipo são obrigatórios" });
  }

  if (!["aluno", "professor"].includes(tipo)) {
    return res
      .status(400)
      .json({ error: "Tipo inválido: deve ser 'aluno' ou 'professor'" });
  }

  try {
    // Buscar usuário pelo email na collection correta
    let user;
    if (tipo === "aluno") {
      user = await Aluno.findOne({ email });
    } else {
      user = await Professor.findOne({ email });
    }

    if (!user) {
      return res.status(404).json({ error: "Usuário não encontrado" });
    }

    // Gerar senha aleatória
    const senhaAleatoria = gerarSenhaAleatoria();

    // Hash da senha (ajuste o campo 'senha' se for diferente no seu model)
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(senhaAleatoria, saltRounds);

    // Atualizar usuário com a senha hasheada
    if (tipo === "aluno") {
      await Aluno.updateOne({ email }, { senha: hashedPassword }); // Assuma campo 'senha'
    } else {
      await Professor.updateOne({ email }, { senha: hashedPassword });
    }

    // Enviar e-mail com a senha temporária
    await transporter.sendMail({
      from: '"Poliedro" <avaflgpi@gmail.com>',
      to: email,
      subject: "Sua Senha Inicial - Sistema Poliedro",
      text: `Olá ${user.nome},\n\nSua conta foi criada com sucesso!\n\nSenha temporária: ${senhaAleatoria}\n\nUse esta senha para fazer login pela primeira vez. Após o login, altere sua senha nas configurações.\n\nAtenciosamente,\nEquipe Poliedro`,
      html: `
        <h2>Olá, <b>${user.nome}</b>!</h2>
        <p>Sua conta foi criada com sucesso no Sistema Poliedro.</p>
        <p><strong>Senha temporária:</strong> ${senhaAleatoria}</p>
        <p>Use esta senha para fazer login pela primeira vez. <em>Após o login, altere sua senha entrando no seu perfil e indo na opção editar perfil.</em></p>
        <hr>
        <p>Atenciosamente,<br>Equipe Poliedro</p>
      `,
    });

    return res.json({ message: "Senha inicial enviada com sucesso" });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "Erro ao enviar a senha inicial" });
  }
});

module.exports = routerEmail;
