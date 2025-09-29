const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const Aluno = require("../models/aluno.cjs");
const auth = require("../middleware/auth.cjs");

const router = express.Router();

// Registro Aluno pelo professor
router.post("/register", auth("professor"), async (req, res) => {
  try {
    const { nome, ra, email } = req.body;

    if (!ra) return res.status(400).json({ msg: "RA é obrigatório" });
    if (await Aluno.findOne({ ra })) return res.status(400).json({ msg: "RA já cadastrado" });

    const hashedPassword = await bcrypt.hash(ra, 10); // senha inicial igual ao RA

    const aluno = new Aluno({ nome, ra, email: email || null, senha: hashedPassword });
    await aluno.save();

    res.status(201).json({ msg: "Aluno registrado com sucesso!", aluno });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Login Aluno (RA + senha)
router.post("/login", async (req, res) => {
  try {
    const { ra, senha } = req.body;
    const aluno = await Aluno.findOne({ ra });
    if (!aluno) return res.status(400).json({ msg: "Aluno não encontrado" });

    const isMatch = await bcrypt.compare(senha, aluno.senha);
    if (!isMatch) return res.status(400).json({ msg: "Senha incorreta" });

    const token = jwt.sign({ id: aluno._id, role: "aluno" }, process.env.JWT_SECRET, { expiresIn: "1h" });

    res.json({ token, aluno });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update Aluno
router.put("/update", auth("aluno"), async (req, res) => {
  try {
    const { nome, email, senha } = req.body;
    const aluno = await Aluno.findById(req.user.id);
    if (!aluno) return res.status(404).json({ msg: "Aluno não encontrado" });

    if (nome) aluno.nome = nome;
    if (email) aluno.email = email;
    if (senha) aluno.senha = await bcrypt.hash(senha, 10);

    await aluno.save();
    res.json({ msg: "Aluno atualizado com sucesso", aluno });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete Aluno
router.delete("/delete", auth("aluno"), async (req, res) => {
  try {
    await Aluno.findByIdAndDelete(req.user.id);
    res.json({ msg: "Aluno deletado com sucesso" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
