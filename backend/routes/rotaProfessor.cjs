const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const Professor = require("../models/professor.cjs");
const auth = require("../middleware/auth.cjs");
const router = express.Router();
const crypto = require("crypto");
const multer = require("multer");

// Configuração do Multer para memória (não salva arquivo localmente)
const upload = multer({
  storage: multer.memoryStorage(), // Armazena na memória, não no disco
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith("image/")) {
      cb(null, true);
    } else {
      cb(new Error("Apenas arquivos de imagem são permitidos!"), false);
    }
  },
});

// Registrar professor (SOMENTE professor pode registrar outro professor)
router.post(
  "/register",
  auth("professor"),
  upload.single("imagem"),
  async (req, res) => {
    try {
      const { nome, email } = req.body;

      if (!email) {
        return res.status(400).json({ msg: "Email é obrigatório" });
      }

      // Verificar se já existe professor com esse email
      const existing = await Professor.findOne({ email });
      if (existing) {
        return res.status(400).json({ msg: "Esse email já está em uso" });
      }

      // Gerar senha automática
      const senhaGerada = crypto.randomBytes(4).toString("hex");

      // Hashear senha
      const hashedPassword = await bcrypt.hash(senhaGerada, 10);

      // Preparar dados do professor
      const professorData = {
        nome,
        email,
        senha: hashedPassword,
      };

      // Adicionar imagem Base64 se foi enviada
      if (req.file) {
        professorData.imagem = {
          data: req.file.buffer.toString("base64"), // Converter para Base64
          contentType: req.file.mimetype,
          filename: req.file.originalname,
          size: req.file.size,
        };
      }

      // Criar professor
      const novoProfessor = new Professor(professorData);
      await novoProfessor.save();

      // Não enviar dados Base64 na resposta (pode ser muito grande)
      const professorResponse = {
        id: novoProfessor._id,
        nome: novoProfessor.nome,
        email: novoProfessor.email,
        hasImage: !!novoProfessor.imagem,
      };

      res.status(201).json({
        msg: "Professor cadastrado com sucesso",
        professor: professorResponse,
        senhaProvisoria: senhaGerada, // futuramente pode ser enviada por email
      });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

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

    // Não enviar dados da imagem no login (pode ser muito grande)
    const professorResponse = {
      id: prof._id,
      nome: prof.nome,
      email: prof.email,
      hasImage: !!prof.imagem,
    };

    res.json({ token, professor: professorResponse });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update Professor
router.put(
  "/update",
  auth("professor"),
  upload.single("imagem"),
  async (req, res) => {
    try {
      const { nome, senha } = req.body;
      const prof = await Professor.findById(req.user.id);
      if (!prof)
        return res.status(404).json({ msg: "Professor não encontrado" });

      if (nome) prof.nome = nome;
      if (senha) prof.senha = await bcrypt.hash(senha, 10);

      // Atualizar imagem Base64 se foi enviada
      if (req.file) {
        prof.imagem = {
          data: req.file.buffer.toString("base64"), // Converter para Base64
          contentType: req.file.mimetype,
          filename: req.file.originalname,
          size: req.file.size,
        };
      }

      await prof.save();

      const professorResponse = {
        id: prof._id,
        nome: prof.nome,
        email: prof.email,
        hasImage: !!prof.imagem,
      };

      res.json({
        msg: "Professor atualizado com sucesso",
        professor: professorResponse,
      });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// Rota para obter imagem do professor
router.get("/image", auth("professor"), async (req, res) => {
  try {
    const prof = await Professor.findById(req.user.id).select("imagem");
    if (!prof || !prof.imagem || !prof.imagem.data) {
      return res.status(404).json({ msg: "Imagem não encontrada" });
    }

    // Converter Base64 para buffer
    const imageBuffer = Buffer.from(prof.imagem.data, "base64");

    res.set("Content-Type", prof.imagem.contentType);
    res.set("Content-Length", imageBuffer.length);
    res.set("Cache-Control", "public, max-age=86400"); // Cache de 1 dia

    res.send(imageBuffer);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Rota para obter imagem por ID (pública - se necessário)
router.get("/image/:id", async (req, res) => {
  try {
    const prof = await Professor.findById(req.params.id).select("imagem");
    if (!prof || !prof.imagem || !prof.imagem.data) {
      return res.status(404).json({ msg: "Imagem não encontrada" });
    }

    const imageBuffer = Buffer.from(prof.imagem.data, "base64");

    res.set("Content-Type", prof.imagem.contentType);
    res.set("Content-Length", imageBuffer.length);
    res.set("Cache-Control", "public, max-age=86400");

    res.send(imageBuffer);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Rota específica para atualizar apenas a imagem
router.put(
  "/update-image",
  auth("professor"),
  upload.single("imagem"),
  async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({ msg: "Nenhuma imagem enviada" });
      }

      const prof = await Professor.findById(req.user.id);
      if (!prof)
        return res.status(404).json({ msg: "Professor não encontrado" });

      // Atualizar imagem Base64
      prof.imagem = {
        data: req.file.buffer.toString("base64"),
        contentType: req.file.mimetype,
        filename: req.file.originalname,
        size: req.file.size,
      };

      await prof.save();
      res.json({
        msg: "Imagem atualizada com sucesso",
        imagem: {
          contentType: prof.imagem.contentType,
          filename: prof.imagem.filename,
          size: prof.imagem.size,
        },
      });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// Remover imagem do perfil
router.delete("/remove-image", auth("professor"), async (req, res) => {
  try {
    const prof = await Professor.findById(req.user.id);
    if (!prof) return res.status(404).json({ msg: "Professor não encontrado" });

    if (prof.imagem) {
      prof.imagem = undefined;
      await prof.save();
      res.json({ msg: "Imagem removida com sucesso" });
    } else {
      res.status(400).json({ msg: "Nenhuma imagem para remover" });
    }
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
