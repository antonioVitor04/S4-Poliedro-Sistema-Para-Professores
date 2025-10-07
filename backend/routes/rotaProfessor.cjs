const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const Professor = require("../models/professor.cjs");
const auth = require("../middleware/auth.cjs");
const router = express.Router();
const crypto = require("crypto");
const multer = require("multer");

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

// Middleware para tratar erros do multer
const handleMulterError = (err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    if (err.code === "LIMIT_FILE_SIZE") {
      return res
        .status(400)
        .json({ msg: "Arquivo muito grande. Tamanho máximo: 5MB" });
    }
    if (err.code === "LIMIT_UNEXPECTED_FILE") {
      return res.status(400).json({ msg: "Campo de arquivo inesperado" });
    }
    return res.status(400).json({ msg: `Erro no upload: ${err.message}` });
  } else if (err) {
    return res.status(400).json({ msg: err.message });
  }
  next();
};

// Registrar professor (SOMENTE professor pode registrar outro professor)
router.post(
  "/register",
  auth("professor"),
  (req, res, next) => {
    console.log("=== INICIANDO UPLOAD ===");
    console.log("Headers:", req.headers);
    console.log("Content-Type:", req.headers["content-type"]);
    console.log("Body fields:", Object.keys(req.body));

    upload.single("imagem")(req, res, (err) => {
      if (err) {
        console.log("Erro no multer:", err.message);
        return res.status(400).json({
          msg: `Falha no upload: ${err.message}`,
          details: err.code,
        });
      }
      console.log(
        "Upload bem-sucedido. Arquivo:",
        req.file ? req.file.originalname : "Nenhum arquivo"
      );
      next();
    });
  },
  async (req, res) => {
    try {
      console.log("=== PROCESSANDO REGISTRO ===");
      const { nome, email } = req.body;

      // Validações
      if (!email) {
        return res.status(400).json({
          msg: "Email é obrigatório",
          received: { nome, email },
        });
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
        nome: nome.trim(),
        email: email.trim(),
        senha: hashedPassword,
      };

      // Adicionar imagem Base64 se foi enviada
      if (req.file) {
        console.log("Processando imagem...");
        console.log("Tamanho do buffer:", req.file.buffer.length);
        console.log("Mimetype:", req.file.mimetype);

        professorData.imagem = {
          data: req.file.buffer.toString("base64"),
          contentType: req.file.mimetype,
          filename: req.file.originalname,
          size: req.file.size,
        };

        console.log(
          "Imagem convertida para Base64. Tamanho:",
          professorData.imagem.data.length
        );
      } else {
        console.log("Nenhum arquivo recebido no registro");
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

      console.log("Professor registrado com sucesso:", novoProfessor._id);

      res.status(201).json({
        msg: "Professor cadastrado com sucesso",
        professor: professorResponse,
        senhaProvisoria: senhaGerada, // futuramente pode ser enviada por email
      });
    } catch (err) {
      console.error("Erro no registro:", err);
      res.status(500).json({
        error: err.message,
        stack: process.env.NODE_ENV === "development" ? err.stack : undefined,
      });
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
  (req, res, next) => {
    console.log("=== INICIANDO UPDATE COM IMAGEM ===");

    upload.single("imagem")(req, res, (err) => {
      if (err) {
        console.log("Erro no multer (update):", err.message);
        return res.status(400).json({
          msg: `Falha no upload da imagem: ${err.message}`,
        });
      }
      console.log("Processando update...");
      next();
    });
  },
  async (req, res) => {
    try {
      const { nome, senha } = req.body;
      const prof = await Professor.findById(req.user.id);

      if (!prof) {
        return res.status(404).json({ msg: "Professor não encontrado" });
      }

      // Atualizar campos
      if (nome) prof.nome = nome;
      if (senha) {
        prof.senha = await bcrypt.hash(senha, 10);
      }

      // Atualizar imagem se foi enviada
      if (req.file) {
        console.log("Atualizando imagem do professor...");
        prof.imagem = {
          data: req.file.buffer.toString("base64"),
          contentType: req.file.mimetype,
          filename: req.file.originalname,
          size: req.file.size,
        };
        console.log("Imagem atualizada com sucesso");
      } else {
        console.log("Nenhuma nova imagem no update");
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
      console.error("Erro no update:", err);
      res.status(500).json({ error: err.message });
    }
  }
);

// Rota específica para obter imagem do professor
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

// Rota para upload de imagem via base64
router.put("/update-image-base64", auth("professor"), async (req, res) => {
  try {
    console.log("=== UPLOAD VIA BASE64 ===");
    const { imagem, filename, contentType } = req.body;

    if (!imagem) {
      return res.status(400).json({ msg: "Nenhuma imagem enviada" });
    }

    // Validar se é base64 válido
    if (!imagem.startsWith("data:image/")) {
      return res.status(400).json({ msg: "Formato de imagem inválido" });
    }

    const prof = await Professor.findById(req.user.id);
    if (!prof) return res.status(404).json({ msg: "Professor não encontrado" });

    // Extrair dados da string base64
    const matches = imagem.match(/^data:([A-Za-z-+\/]+);base64,(.+)$/);
    if (!matches || matches.length !== 3) {
      return res.status(400).json({ msg: "String base64 inválida" });
    }

    const imageBuffer = Buffer.from(matches[2], "base64");

    prof.imagem = {
      data: matches[2], // Apenas a parte base64 sem o prefixo
      contentType: matches[1] || contentType || "image/jpeg",
      filename: filename || "imagem.jpg",
      size: imageBuffer.length,
    };

    await prof.save();

    console.log("Imagem atualizada via base64 com sucesso");

    res.json({
      msg: "Imagem atualizada com sucesso",
      imagem: {
        contentType: prof.imagem.contentType,
        filename: prof.imagem.filename,
        size: prof.imagem.size,
      },
    });
  } catch (err) {
    console.error("Erro no upload base64:", err);
    res.status(500).json({ error: err.message });
  }
});

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

// ADICIONE ESTA ROTA - Perfil do professor (GET /)
router.get("/", auth("professor"), async (req, res) => {
  try {
    console.log("=== ROTA PROFESSOR GET / CHAMADA ===");
    console.log("User ID:", req.user.id);

    const professor = await Professor.findById(req.user.id);
    if (!professor) {
      console.log("Professor não encontrado para ID:", req.user.id);
      return res.status(404).json({ msg: "Professor não encontrado" });
    }

    console.log("Professor encontrado:", professor.nome);

    res.json({
      professor: {
        id: professor._id,
        nome: professor.nome,
        email: professor.email,
        hasImage: !!professor.imagem,
      },
    });
  } catch (err) {
    console.log("Erro na rota GET / professor:", err);
    res.status(500).json({ error: err.message });
  }
});

router.use(handleMulterError);

module.exports = router;
