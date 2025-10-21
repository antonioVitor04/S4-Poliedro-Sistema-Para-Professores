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

// Função auxiliar para host correto (para dev com IP)
const getHost = (req) => {
  return process.env.NODE_ENV === "development"
    ? "192.168.15.123:5000"
    : req.get("host");
};

// Registro Aluno pelo professor ou admin
router.post(
  "/register",
  auth(["professor", "admin"]),
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
      const { nome, ra, email } = req.body;

      // Validações
      if (!nome || !ra) {
        return res.status(400).json({
          msg: "Nome e RA são obrigatórios",
          received: { nome, ra, email },
        });
      }

      // Verificar se RA já existe
      const alunoExistente = await Aluno.findOne({ ra });
      if (alunoExistente) {
        return res.status(400).json({ msg: "RA já cadastrado" });
      }

      const hashedPassword = await bcrypt.hash(ra, 10); // Senha inicial = RA

      // Preparar dados do aluno
      const alunoData = {
        nome: nome.trim(),
        ra: ra.trim(),
        email: email ? email.trim() : null,
        senha: hashedPassword,
      };

      // Adicionar imagem Base64 se foi enviada
      if (req.file) {
        console.log("Processando imagem...");
        console.log("Tamanho do buffer:", req.file.buffer.length);
        console.log("Mimetype:", req.file.mimetype);

        alunoData.imagem = {
          data: req.file.buffer.toString("base64"),
          contentType: req.file.mimetype,
          filename: req.file.originalname,
          size: req.file.size,
        };

        console.log(
          "Imagem convertida para Base64. Tamanho:",
          alunoData.imagem.data.length
        );
      } else {
        console.log("Nenhum arquivo recebido no registro");
      }

      // Criar e salvar aluno
      const aluno = new Aluno(alunoData);
      await aluno.save();

      console.log("Aluno registrado com sucesso:", aluno._id);

      res.status(201).json({
        msg: "Aluno registrado com sucesso!",
        aluno: {
          id: aluno._id,
          nome: aluno.nome,
          ra: aluno.ra,
          email: aluno.email,
          tipo: "aluno", // MUDANÇA: Incluir tipo
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
      console.error("Erro no registro:", err);
      res.status(500).json({
        error: err.message,
        stack: process.env.NODE_ENV === "development" ? err.stack : undefined,
      });
    }
  }
);

// LOGIN ALUNO - ROTA PRINCIPAL
router.post("/login", async (req, res) => {
  try {
    console.log("=== 🔐 TENTATIVA DE LOGIN ALUNO ===");
    console.log("📦 Body recebido:", req.body);
    
    const { ra, senha } = req.body;

    if (!ra || !senha) {
      console.log("❌ Dados incompletos:", { ra: !!ra, senha: !!senha });
      return res.status(400).json({ 
        success: false,
        msg: "RA e senha são obrigatórios" 
      });
    }

    console.log("🔍 Buscando aluno com RA:", ra);
    const aluno = await Aluno.findOne({ ra });
    
    console.log("📊 Aluno encontrado:", {
      encontrado: !!aluno,
      id: aluno?._id,
      ra: aluno?.ra,
      nome: aluno?.nome
    });

    if (!aluno) {
      console.log("❌ Aluno não encontrado com RA:", ra);
      return res.status(400).json({ 
        success: false,
        msg: "Aluno não encontrado" 
      });
    }

    const isMatch = await bcrypt.compare(senha, aluno.senha);
    console.log("🔑 Senha confere?", isMatch);

    if (!isMatch) {
      console.log("❌ Senha incorreta");
      return res.status(400).json({ 
        success: false,
        msg: "Senha incorreta" 
      });
    }

    const token = jwt.sign(
      { id: aluno._id, role: "aluno" },
      process.env.JWT_SECRET,
      { expiresIn: "24h" }
    );

    console.log("✅ Login aluno bem-sucedido");

    res.json({
      success: true,
      token,
      aluno: {
        id: aluno._id,
        nome: aluno.nome,
        ra: aluno.ra,
        email: aluno.email,
        tipo: "aluno",
        hasImage: !!aluno.imagem,
      }
    });

  } catch (err) {
    console.error("💥 Erro no login:", err);
    res.status(500).json({ 
      success: false,
      error: err.message 
    });
  }
});

// Update Aluno (self-update)
router.put(
  "/update",
  auth("aluno"),
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
      const { nome, email, senha } = req.body;
      const aluno = await Aluno.findById(req.user.id);

      if (!aluno) {
        return res.status(404).json({ msg: "Aluno não encontrado" });
      }

      // Atualizar campos
      if (nome) aluno.nome = nome;
      if (email) aluno.email = email;
      if (senha) {
        aluno.senha = await bcrypt.hash(senha, 10);
      }

      // Atualizar imagem se foi enviada
      if (req.file) {
        console.log("Atualizando imagem do aluno...");
        aluno.imagem = {
          data: req.file.buffer.toString("base64"),
          contentType: req.file.mimetype,
          filename: req.file.originalname,
          size: req.file.size,
        };
        console.log("Imagem atualizada com sucesso");
      } else {
        console.log("Nenhuma nova imagem no update");
      }

      await aluno.save();

      const alunoResponse = {
        id: aluno._id,
        nome: aluno.nome,
        ra: aluno.ra,
        email: aluno.email,
        tipo: "aluno", // MUDANÇA: Incluir tipo
        hasImage: !!aluno.imagem,
      };

      res.json({
        msg: "Aluno atualizado com sucesso",
        aluno: alunoResponse,
      });
    } catch (err) {
      console.error("Erro no update:", err);
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

// Rota para upload de imagem via base64
router.put("/update-image-base64", auth("aluno"), async (req, res) => {
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

    const aluno = await Aluno.findById(req.user.id);
    if (!aluno) return res.status(404).json({ msg: "Aluno não encontrado" });

    // Extrair dados da string base64
    const matches = imagem.match(/^data:([A-Za-z-+\/]+);base64,(.+)$/);
    if (!matches || matches.length !== 3) {
      return res.status(400).json({ msg: "String base64 inválida" });
    }

    const imageBuffer = Buffer.from(matches[2], "base64");

    aluno.imagem = {
      data: matches[2], // Apenas a parte base64 sem o prefixo
      contentType: matches[1] || contentType || "image/jpeg",
      filename: filename || "imagem.jpg",
      size: imageBuffer.length,
    };

    await aluno.save();

    console.log("Imagem atualizada via base64 com sucesso");

    res.json({
      msg: "Imagem atualizada com sucesso",
      imagem: {
        contentType: aluno.imagem.contentType,
        filename: aluno.imagem.filename,
        size: aluno.imagem.size,
      },
    });
  } catch (err) {
    console.error("Erro no upload base64:", err);
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
        tipo: "aluno", // MUDANÇA: Incluir tipo
        hasImage: !!aluno.imagem,
      },
    });
  } catch (err) {
    console.log("Erro na rota GET /:", err);
    res.status(500).json({ error: err.message });
  }
});

// GET: Buscar alunos por RA
router.get("/buscar", auth(["admin", "professor"]), async (req, res) => {
  try {
    const { ra } = req.query;
    
    if (!ra) {
      return res.status(400).json({ 
        success: false, 
        error: "Parâmetro 'ra' é obrigatório" 
      });
    }

    const alunos = await Aluno.find({
      ra: { $regex: ra, $options: 'i' }
    }).select('_id nome ra email').limit(10);

    res.json(alunos);
  } catch (err) {
    console.error("Erro ao buscar alunos:", err);
    res.status(500).json({ 
      success: false, 
      error: "Erro interno do servidor ao buscar alunos" 
    });
  }
});

// Listar todos os alunos (GET /list) - Permite admin e professor
router.get("/list", auth(["admin", "professor"]), async (req, res) => {
  try {
    console.log("=== ROTA LIST ALUNOS CHAMADA ==="); // Log para debug
    console.log("User role:", req.user.role);
    console.log("User ID:", req.user.id);

    const alunos = await Aluno.find({}, { senha: 0, imagem: { data: 0 } });
    const host = getHost(req); // MUDANÇA: Usar host correto
    const formattedAlunos = alunos.map((aluno) => ({
      id: aluno._id.toString(),
      nome: aluno.nome,
      email: aluno.email,
      ra: aluno.ra,
      tipo: "aluno", // MUDANÇA: Incluir tipo
      fotoUrl: aluno.imagem
        ? `${req.protocol}://${host}/api/alunos/image/${aluno._id}`
        : null,
    }));
    console.log(`Encontrados ${formattedAlunos.length} alunos`); // Log para debug
    res.json(formattedAlunos);
  } catch (err) {
    console.error("Erro ao listar alunos:", err); // Log para debug
    res.status(500).json({ error: err.message });
  }
});

// Atualizar aluno por ID (PUT /:id) - Permite admin e professor
router.put("/:id", auth(["admin", "professor"]), async (req, res) => {
  try {
    console.log("=== ROTA UPDATE ALUNO POR ID CHAMADA ==="); // Log para debug
    console.log("User role:", req.user.role);
    const { id } = req.params;
    const { nome, email, ra } = req.body;
    const aluno = await Aluno.findById(id);
    if (!aluno) {
      return res.status(404).json({ msg: "Aluno não encontrado" });
    }
    if (nome) aluno.nome = nome.trim();
    if (email) aluno.email = email.trim();
    if (ra) aluno.ra = ra.trim();
    await aluno.save();
    const host = getHost(req); // MUDANÇA: Usar host correto
    const formatted = {
      id: aluno._id.toString(),
      nome: aluno.nome,
      email: aluno.email,
      ra: aluno.ra,
      tipo: "aluno", // MUDANÇA: Incluir tipo
      fotoUrl: aluno.imagem
        ? `${req.protocol}://${host}/api/alunos/image/${aluno._id}`
        : null,
    };
    res.json({ msg: "Aluno atualizado com sucesso", aluno: formatted });
  } catch (err) {
    console.error("Erro ao atualizar aluno:", err); // Log para debug
    res.status(500).json({ error: err.message });
  }
});

// Deletar aluno por ID (DELETE /:id) - Permite admin e professor
router.delete("/:id", auth(["admin", "professor"]), async (req, res) => {
  try {
    console.log("=== ROTA DELETE ALUNO POR ID CHAMADA ==="); // Log para debug
    console.log("User role:", req.user.role);
    const { id } = req.params;
    const aluno = await Aluno.findByIdAndDelete(id);
    if (!aluno) {
      return res.status(404).json({ msg: "Aluno não encontrado" });
    }
    res.json({ msg: "Aluno deletado com sucesso" });
  } catch (err) {
    console.error("Erro ao deletar aluno:", err); // Log para debug
    res.status(500).json({ error: err.message });
  }
});

router.use(handleMulterError);

module.exports = router;
