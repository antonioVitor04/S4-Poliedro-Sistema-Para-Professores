const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const Aluno = require("../models/aluno.cjs");
const auth = require("../middleware/auth.cjs");
const multer = require("multer");

const router = express.Router();

// Configuração do Multer para memória (não salva arquivo)
const upload = multer({
  storage: multer.memoryStorage(),
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

// Registro Aluno pelo professor
router.post(
  "/register",
  auth("professor"),
  upload.single("imagem"),
  async (req, res) => {
    try {
      const { nome, ra, email } = req.body;

      if (!ra) return res.status(400).json({ msg: "RA é obrigatório" });
      if (await Aluno.findOne({ ra }))
        return res.status(400).json({ msg: "RA já cadastrado" });

      const hashedPassword = await bcrypt.hash(ra, 10);

      // Preparar dados do aluno
      const alunoData = {
        nome,
        ra,
        email: email || null,
        senha: hashedPassword,
      };

      // Adicionar imagem Base64 se foi enviada
      if (req.file) {
        alunoData.imagem = {
          data: req.file.buffer.toString("base64"),
          contentType: req.file.mimetype,
          filename: req.file.originalname,
          size: req.file.size,
        };
      }

      const aluno = new Aluno(alunoData);
      await aluno.save();

      res.status(201).json({
        msg: "Aluno registrado com sucesso!",
        aluno: {
          id: aluno._id,
          nome: aluno.nome,
          ra: aluno.ra,
          email: aluno.email,
          imagem: aluno.imagem
            ? {
                contentType: aluno.imagem.contentType,
                filename: aluno.imagem.filename,
                size: aluno.imagem.size,
              }
            : null,
        },
      });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// Login Aluno (RA + senha)
router.post("/login", async (req, res) => {
  try {
    const { ra, senha } = req.body;
    const aluno = await Aluno.findOne({ ra });
    if (!aluno) return res.status(400).json({ msg: "Aluno não encontrado" });

    const isMatch = await bcrypt.compare(senha, aluno.senha);
    if (!isMatch) return res.status(400).json({ msg: "Senha incorreta" });

    const token = jwt.sign(
      { id: aluno._id, role: "aluno" },
      process.env.JWT_SECRET,
      { expiresIn: "1h" }
    );

    // Não enviar dados da imagem no login (pode ser muito grande)
    const alunoResponse = {
      id: aluno._id,
      nome: aluno.nome,
      ra: aluno.ra,
      email: aluno.email,
      hasImage: !!aluno.imagem,
    };

    res.json({ token, aluno: alunoResponse });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update Aluno
router.put(
  "/update",
  auth("aluno"),
  upload.single("imagem"),
  async (req, res) => {
    try {
      const { nome, email, senha } = req.body;
      const aluno = await Aluno.findById(req.user.id);
      if (!aluno) return res.status(404).json({ msg: "Aluno não encontrado" });

      if (nome) aluno.nome = nome;
      if (email) aluno.email = email;
      if (senha) aluno.senha = await bcrypt.hash(senha, 10);

      // Atualizar imagem Base64 se foi enviada
      if (req.file) {
        aluno.imagem = {
          data: req.file.buffer.toString("base64"),
          contentType: req.file.mimetype,
          filename: req.file.originalname,
          size: req.file.size,
        };
      }

      await aluno.save();

      const alunoResponse = {
        id: aluno._id,
        nome: aluno.nome,
        ra: aluno.ra,
        email: aluno.email,
        hasImage: !!aluno.imagem,
      };

      res.json({
        msg: "Aluno atualizado com sucesso",
        aluno: alunoResponse,
      });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// Rota específica para obter imagem do aluno
router.get("/image", auth("aluno"), async (req, res) => {
  try {
    const aluno = await Aluno.findById(req.user.id).select("imagem");
    if (!aluno || !aluno.imagem || !aluno.imagem.data) {
      return res.status(404).json({ msg: "Imagem não encontrada" });
    }

    // Converter Base64 para buffer
    const imageBuffer = Buffer.from(aluno.imagem.data, "base64");

    res.set("Content-Type", aluno.imagem.contentType);
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
    const aluno = await Aluno.findById(req.params.id).select("imagem");
    if (!aluno || !aluno.imagem || !aluno.imagem.data) {
      return res.status(404).json({ msg: "Imagem não encontrada" });
    }

    const imageBuffer = Buffer.from(aluno.imagem.data, "base64");

    res.set("Content-Type", aluno.imagem.contentType);
    res.set("Content-Length", imageBuffer.length);
    res.set("Cache-Control", "public, max-age=86400");

    res.send(imageBuffer);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Rota específica para atualizar apenas a imagem
// Rota para upload de imagem via base64
router.put("/update-image-base64", auth("aluno"), async (req, res) => {
  try {
    const { imagem, filename, contentType } = req.body;

    if (!imagem) {
      return res.status(400).json({ msg: "Nenhuma imagem enviada" });
    }

    const aluno = await Aluno.findById(req.user.id);
    if (!aluno) return res.status(404).json({ msg: "Aluno não encontrado" });

    aluno.imagem = {
      data: imagem,
      contentType: contentType || "image/jpeg",
      filename: filename || "imagem.jpg",
      size: Buffer.from(imagem, "base64").length,
    };

    await aluno.save();
    res.json({
      msg: "Imagem atualizada com sucesso",
      imagem: {
        contentType: aluno.imagem.contentType,
        filename: aluno.imagem.filename,
        size: aluno.imagem.size,
      },
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Remover imagem do perfil
router.delete("/remove-image", auth("aluno"), async (req, res) => {
  try {
    const aluno = await Aluno.findById(req.user.id);
    if (!aluno) return res.status(404).json({ msg: "Aluno não encontrado" });

    if (aluno.imagem) {
      aluno.imagem = undefined;
      await aluno.save();
      res.json({ msg: "Imagem removida com sucesso" });
    } else {
      res.status(400).json({ msg: "Nenhuma imagem para remover" });
    }
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

// ADICIONE ESTA ROTA - Perfil do aluno (GET /)
router.get("/", auth("aluno"), async (req, res) => {
  try {
    console.log("=== ROTA ALUNO GET / CHAMADA ===");
    console.log("User ID:", req.user.id);

    const aluno = await Aluno.findById(req.user.id);
    if (!aluno) {
      console.log("Aluno não encontrado para ID:", req.user.id);
      return res.status(404).json({ msg: "Aluno não encontrado" });
    }

    console.log("Aluno encontrado:", aluno.nome);

    res.json({
      aluno: {
        id: aluno._id,
        nome: aluno.nome,
        ra: aluno.ra,
        email: aluno.email,
        hasImage: !!aluno.imagem,
      },
    });
  } catch (err) {
    console.log("Erro na rota GET /:", err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
