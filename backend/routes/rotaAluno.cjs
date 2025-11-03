const express = require("express");
const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const Aluno = require("../models/aluno.cjs");
const auth = require("../middleware/auth.cjs");
const multer = require("multer");
const Nota = require("../models/nota.cjs");
const CardDisciplina = require("../models/cardDisciplina.cjs");
const path = require("path");
const router = express.Router();

// Configuração do Multer para memória (não salva arquivo)
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
    if (err.code === "LIMIT_FILE_COUNT") {
      return res
        .status(400)
        .json({ msg: "Número máximo de arquivos excedido" });
    }
    if (err.code === "LIMIT_PART_COUNT") {
      return res.status(400).json({ msg: "Muitas partes no formulário" });
    }
    return res.status(400).json({ msg: `Erro no upload: ${err.message}` });
  } else if (err) {
    // Erro de tipo de arquivo personalizado
    if (err.message === "Tipo de arquivo não permitido") {
      return res.status(400).json({
        msg: "Tipo de arquivo não suportado. Use apenas: JPG, JPEG, PNG, GIF, WEBP",
      });
    }
    return res.status(400).json({ msg: err.message });
  }
  next();
};

// Configuração do Multer com validação de tipos de arquivo CORRIGIDA
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB
  },
  fileFilter: (req, file, cb) => {
    console.log("🔍 Validando arquivo (modo estrito):", {
      originalname: file.originalname,
      mimetype: file.mimetype,
    });

    // Apenas imagens são permitidas - validação mais rigorosa
    if (!file.mimetype.startsWith("image/")) {
      console.log("❌ Rejeitado - Não é uma imagem");
      return cb(new Error("Tipo de arquivo não permitido"), false);
    }

    // Lista explícita de tipos permitidos
    const allowedImageTypes = [
      "image/jpeg",
      "image/jpg",
      "image/png",
      "image/gif",
      "image/webp",
    ];

    if (!allowedImageTypes.includes(file.mimetype)) {
      console.log("❌ Rejeitado - Tipo de imagem não suportado");
      return cb(new Error("Tipo de arquivo não permitido"), false);
    }

    // Verificar extensão também
    const fileExtension = path.extname(file.originalname).toLowerCase();
    const allowedExtensions = [".jpg", ".jpeg", ".png", ".gif", ".webp"];

    if (!allowedExtensions.includes(fileExtension)) {
      console.log("❌ Rejeitado - Extensão não permitida");
      return cb(new Error("Tipo de arquivo não permitido"), false);
    }

    console.log("✅ Arquivo aceito - É uma imagem válida");
    cb(null, true);
  },
});

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
        msg: "RA e senha são obrigatórios",
      });
    }

    console.log("🔍 Buscando aluno com RA:", ra);
    const aluno = await Aluno.findOne({ ra });

    console.log("📊 Aluno encontrado:", {
      encontrado: !!aluno,
      id: aluno?._id,
      ra: aluno?.ra,
      nome: aluno?.nome,
    });

    if (!aluno) {
      console.log("❌ Aluno não encontrado com RA:", ra);
      return res.status(400).json({
        success: false,
        msg: "Aluno não encontrado",
      });
    }

    const isMatch = await bcrypt.compare(senha, aluno.senha);
    console.log("🔑 Senha confere?", isMatch);

    if (!isMatch) {
      console.log("❌ Senha incorreta");
      return res.status(400).json({
        success: false,
        msg: "Senha incorreta",
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
      },
    });
  } catch (err) {
    console.error("💥 Erro no login:", err);
    res.status(500).json({
      success: false,
      error: err.message,
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

const validarImagemBase64 = (base64String, filename) => {
  console.log("🔍 Validando imagem Base64...");

  // Validar formato data URL - DEVE começar com data:image/
  if (!base64String.startsWith("data:image/")) {
    console.log("❌ Não é uma data URL de imagem válida");
    return { isValid: false, error: "Formato de imagem inválido" };
  }

  // Extrair MIME type
  const matches = base64String.match(/^data:([A-Za-z-+\/]+);base64,(.+)$/);
  if (!matches || matches.length !== 3) {
    console.log("❌ String base64 inválida");
    return { isValid: false, error: "String base64 inválida" };
  }

  const mimeType = matches[1];
  console.log("📄 MIME Type detectado:", mimeType);

  // Lista de tipos MIME permitidos - APENAS IMAGENS
  const allowedMimeTypes = [
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/gif",
    "image/webp",
  ];

  // VALIDAÇÃO CRÍTICA: Verificar se é realmente uma imagem
  if (!mimeType.startsWith("image/")) {
    console.log("❌ MIME type não é uma imagem:", mimeType);
    return {
      isValid: false,
      error:
        "Tipo de arquivo não suportado. Use apenas: JPG, JPEG, PNG, GIF, WEBP",
    };
  }

  // VALIDAÇÃO CRÍTICA: Verificar se está na lista permitida
  if (!allowedMimeTypes.includes(mimeType)) {
    console.log("❌ MIME type não permitido:", mimeType);
    return {
      isValid: false,
      error:
        "Tipo de arquivo não suportado. Use apenas: JPG, JPEG, PNG, GIF, WEBP",
    };
  }

  // Validar extensão do arquivo se fornecida
  if (filename) {
    const fileExtension = path.extname(filename).toLowerCase();
    const allowedExtensions = [".jpg", ".jpeg", ".png", ".gif", ".webp"];

    // BLOQUEAR ESPECIFICAMENTE PDF E OUTROS ARQUIVOS
    const blockedExtensions = [".pdf", ".doc", ".docx", ".txt", ".zip", ".rar"];
    if (blockedExtensions.includes(fileExtension)) {
      console.log("❌ Extensão bloqueada:", fileExtension);
      return {
        isValid: false,
        error:
          "Extensão de arquivo não permitida. Use apenas imagens: .jpg, .jpeg, .png, .gif, .webp",
      };
    }

    if (!allowedExtensions.includes(fileExtension)) {
      console.log("❌ Extensão não permitida:", fileExtension);
      return {
        isValid: false,
        error:
          "Extensão de arquivo não suportada. Use apenas: .jpg, .jpeg, .png, .gif, .webp",
      };
    }
  }

  // Validar tamanho (estimativa)
  const base64Data = matches[2];
  const estimatedSize = Math.ceil((base64Data.length * 3) / 4);
  console.log("📏 Tamanho estimado:", estimatedSize, "bytes");

  if (estimatedSize > 5 * 1024 * 1024) {
    console.log("❌ Imagem muito grande:", estimatedSize, "bytes");
    return {
      isValid: false,
      error: "Imagem muito grande. Tamanho máximo: 5MB",
    };
  }

  // VALIDAÇÃO EXTRA: Tentar decodificar para verificar se é realmente uma imagem
  try {
    const buffer = Buffer.from(base64Data, "base64");

    // Verificar se o buffer tem tamanho mínimo para ser uma imagem
    if (buffer.length < 100) {
      console.log("❌ Arquivo muito pequeno para ser uma imagem válida");
      return {
        isValid: false,
        error: "Arquivo muito pequeno para ser uma imagem válida",
      };
    }

    // Verificar assinatura de arquivo (magic numbers)
    const fileSignature = buffer.slice(0, 8).toString("hex").toUpperCase();
    console.log("🔍 Assinatura do arquivo:", fileSignature);

    // Assinaturas conhecidas de imagens
    const imageSignatures = {
      FFD8FF: "JPEG",
      "89504E470D0A1A0A": "PNG",
      474946383761: "GIF87a",
      474946383961: "GIF89a",
      52494646: "WEBP", // RIFF header
    };

    let isValidSignature = false;
    for (const signature in imageSignatures) {
      if (fileSignature.startsWith(signature)) {
        console.log("✅ Assinatura válida:", imageSignatures[signature]);
        isValidSignature = true;
        break;
      }
    }

    if (!isValidSignature) {
      console.log("❌ Assinatura de arquivo não reconhecida como imagem");
      return {
        isValid: false,
        error: "Arquivo não é uma imagem válida",
      };
    }
  } catch (bufferError) {
    console.log("❌ Erro ao decodificar Base64:", bufferError);
    return {
      isValid: false,
      error: "Dados Base64 inválidos",
    };
  }

  console.log("✅ Imagem Base64 validada com sucesso");
  return {
    isValid: true,
    mimeType: mimeType,
    base64Data: base64Data,
    size: estimatedSize,
  };
};

// Rota para upload de imagem via base64
router.put("/update-image-base64", auth("aluno"), async (req, res) => {
  try {
    const { imagem, filename, contentType } = req.body;

    if (!imagem) {
      return res.status(400).json({ msg: "Nenhuma imagem enviada" });
    }

    // ✅ VALIDAÇÃO CRÍTICA: Validar a imagem Base64
    const validacao = validarImagemBase64(imagem, filename);
    if (!validacao.isValid) {
      return res.status(400).json({ msg: validacao.error });
    }

    const aluno = await Aluno.findById(req.user.id);
    if (!aluno) {
      return res.status(404).json({ msg: "Aluno não encontrado" });
    }

    try {
      // Usar os dados validados
      const imageBuffer = Buffer.from(validacao.base64Data, "base64");

      aluno.imagem = {
        data: validacao.base64Data,
        contentType: validacao.mimeType,
        filename: filename || `imagem.${validacao.mimeType.split("/")[1]}`,
        size: imageBuffer.length,
      };

      await aluno.save();
      console.log("Imagem salva no banco com sucesso");

      res.json({
        msg: "Imagem atualizada com sucesso",
        imagem: {
          contentType: aluno.imagem.contentType,
          filename: aluno.imagem.filename,
          size: aluno.imagem.size,
        },
      });
    } catch (bufferError) {
      console.error("ERRO ao criar buffer:", bufferError);
      return res.status(400).json({
        msg: "Erro ao processar imagem: dados base64 inválidos",
      });
    }
  } catch (err) {
    console.error("ERRO GERAL no upload base64:", err);
    console.error("Stack:", err.stack);

    // Tratamento específico de erros
    if (err.name === "PayloadTooLargeError") {
      return res.status(413).json({
        msg: "Arquivo muito grande. Tamanho máximo: 5MB",
      });
    }

    if (err.name === "ValidationError") {
      return res.status(400).json({
        msg: "Dados de imagem inválidos",
        error: err.message,
      });
    }

    res.status(500).json({
      msg: "Erro interno no servidor",
      error:
        process.env.NODE_ENV === "development" ? err.message : "Erro interno",
    });
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
        error: "Parâmetro 'ra' é obrigatório",
      });
    }

    const alunos = await Aluno.find({
      ra: { $regex: ra, $options: "i" },
    })
      .select("_id nome ra email")
      .limit(10);

    res.json(alunos);
  } catch (err) {
    console.error("Erro ao buscar alunos:", err);
    res.status(500).json({
      success: false,
      error: "Erro interno do servidor ao buscar alunos",
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
  if (process.env.NODE_ENV === 'test') {
    console.log('🔧 TEST: Executando DELETE aluno sem transação');
    try {
      const { id } = req.params;

      console.log("=== ROTA DELETE ALUNO POR ID CHAMADA ===");
      console.log("User role:", req.user.role);
      console.log("User ID:", req.user.id);
      console.log("Aluno ID a ser deletado:", id);

      // Verificar se o aluno existe
      const aluno = await Aluno.findById(id);
      if (!aluno) {
        return res.status(404).json({
          success: false,
          error: "Aluno não encontrado",
        });
      }

      // 1. Deletar todas as notas do aluno (sem session)
      const resultadoNotas = await Nota.deleteMany({ aluno: id });
      console.log(`Notas deletadas: ${resultadoNotas.deletedCount}`);

      // 2. Remover o aluno de todas as disciplinas (sem session)
      const resultadoDisciplinas = await CardDisciplina.updateMany(
        { alunos: id },
        { $pull: { alunos: id } }
      );
      console.log(`Disciplinas atualizadas: ${resultadoDisciplinas.modifiedCount}`);

      // 3. Deletar o aluno (sem session)
      await Aluno.findByIdAndDelete(id);

      console.log(`Aluno "${aluno.nome}" deletado com sucesso`);

      res.json({
        success: true,
        message: "Aluno e todos os dados associados foram deletados com sucesso",
        data: {
          _id: aluno._id,
          nome: aluno.nome,
          email: aluno.email,
          estatisticas: {
            notasDeletadas: resultadoNotas.deletedCount,
            disciplinasAtualizadas: resultadoDisciplinas.modifiedCount,
          },
        },
      });
    } catch (err) {
      console.error("Erro ao deletar aluno:", err);

      if (err.name === "CastError") {
        return res.status(400).json({
          success: false,
          error: "ID inválido",
        });
      }

      res.status(500).json({
        success: false,
        error: "Erro interno do servidor ao deletar o aluno",
        details: process.env.NODE_ENV === "development" ? err.message : undefined,
      });
    }
  } else {
    let session;
    try {
      console.log("=== ROTA DELETE ALUNO POR ID CHAMADA ===");
      console.log("User role:", req.user.role);
      console.log("User ID:", req.user.id);
      console.log("Aluno ID a ser deletado:", req.params.id);

      const { id } = req.params;

      // Verificar se o aluno existe
      const aluno = await Aluno.findById(id);
      if (!aluno) {
        return res.status(404).json({
          success: false,
          error: "Aluno não encontrado",
        });
      }

      // Iniciar transação para operação atômica
      session = await mongoose.startSession();
      session.startTransaction();

      // 1. Deletar todas as notas do aluno
      const resultadoNotas = await Nota.deleteMany({ aluno: id }).session(
        session
      );
      console.log(`Notas deletadas: ${resultadoNotas.deletedCount}`);

      // 2. Remover o aluno de todas as disciplinas
      const resultadoDisciplinas = await CardDisciplina.updateMany(
        { alunos: id },
        { $pull: { alunos: id } },
        { session }
      );
      console.log(
        `Disciplinas atualizadas: ${resultadoDisciplinas.modifiedCount}`
      );

      // 3. Deletar o aluno
      await Aluno.findByIdAndDelete(id).session(session);

      // Confirmar a transação
      await session.commitTransaction();
      session.endSession();

      console.log(`Aluno "${aluno.nome}" deletado com sucesso`);

      res.json({
        success: true,
        message: "Aluno e todos os dados associados foram deletados com sucesso",
        data: {
          _id: aluno._id,
          nome: aluno.nome,
          email: aluno.email,
          estatisticas: {
            notasDeletadas: resultadoNotas.deletedCount,
            disciplinasAtualizadas: resultadoDisciplinas.modifiedCount,
          },
        },
      });
    } catch (err) {
      // Reverter a transação em caso de erro
      if (session) {
        await session.abortTransaction();
        session.endSession();
      }

      console.error("Erro ao deletar aluno:", err);

      if (err.name === "CastError") {
        return res.status(400).json({
          success: false,
          error: "ID inválido",
        });
      }

      res.status(500).json({
        success: false,
        error: "Erro interno do servidor ao deletar o aluno",
        details: process.env.NODE_ENV === "development" ? err.message : undefined,
      });
    }
  }
});

router.use(handleMulterError);

module.exports = router;
