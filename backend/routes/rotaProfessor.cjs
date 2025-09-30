const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const Professor = require("../models/professor.cjs");
const auth = require("../middleware/auth.cjs");
const router = express.Router();
const crypto = require("crypto");

// Registrar professor (SOMENTE professor pode registrar outro professor)
router.post("/register", auth("professor"), async (req, res) => {
  try {
    const { nome, email } = req.body;

    if ( !email) {
      return res.status(400).json({ msg: "Email é obrigatório" });
    }

    // verificar se já existe professor com esse email
    const existing = await Professor.findOne({ email });
    if (existing) {
      return res.status(400).json({ msg: "Esse email já está em uso" });
    }

    // gerar senha automática
    const senhaGerada = crypto.randomBytes(4).toString("hex");

    // hashear senha
    const hashedPassword = await bcrypt.hash(senhaGerada, 10);

    // criar professor
    const novoProfessor = new Professor({
      nome,
      email,
      senha: hashedPassword
    });

    await novoProfessor.save();

    res.status(201).json({
      msg: "Professor cadastrado com sucesso",
      professor: {
        id: novoProfessor._id,
        nome: novoProfessor.nome,
        email: novoProfessor.email
      },
      senhaProvisoria: senhaGerada // futuramente pode ser enviada por email
    });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Login Professor
router.post("/login", async (req, res) => {
  try {
    const { email, senha } = req.body;
    const prof = await Professor.findOne({ email });
    if (!prof) return res.status(400).json({ msg: "Professor não encontrado" });

    const isMatch = await bcrypt.compare(senha, prof.senha);
    if (!isMatch) return res.status(400).json({ msg: "Senha incorreta" });

    const token = jwt.sign(
      { id: prof._id, role: "professor" },
      process.env.JWT_SECRET,
      { expiresIn: "1h" }
    );

    res.json({ token, professor: prof });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update Professor
router.put("/update", auth("professor"), async (req, res) => {
  try {
    const { nome, senha } = req.body;
    const prof = await Professor.findById(req.user.id);
    if (!prof) return res.status(404).json({ msg: "Professor não encontrado" });

    if (nome) prof.nome = nome;
    if (senha) prof.senha = await bcrypt.hash(senha, 10);

    await prof.save();
    res.json({ msg: "Professor atualizado com sucesso", professor: prof });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete Professor
router.delete("/delete", auth("professor"), async (req, res) => {
  try {
    await Professor.findByIdAndDelete(req.user.id);
    res.json({ msg: "Professor deletado com sucesso" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
