const mongoose = require("mongoose");
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

// Função auxiliar para host correto (para dev com IP)
const getHost = (req) => {
  return process.env.NODE_ENV === "development"
    ? "192.168.15.123:5000"
    : req.get("host");
};

// Registrar professor (SOMENTE professor ou admin pode registrar outro professor)
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
      const { nome, email, tipo = "professor" } = req.body;

      // DEPURAÇÃO: Log completo do body
      console.log("Body recebido:", {
        nome: nome,
        email: email,
        tipo: tipo,
        bodyKeys: Object.keys(req.body),
      });

      // Validações
      if (!email) {
        return res.status(400).json({
          msg: "Email é obrigatório",
          received: { nome, email, tipo },
        });
      }

      // VALIDAÇÃO DO EMAIL ANTES DO MONGOOSE - ADICIONAR DEPURAÇÃO
      console.log("Validando email:", email);
      const emailRegex = /^[\w.-]+@sistemapoliedro\.br$/;
      const isEmailValid = emailRegex.test(email.trim());
      console.log("Resultado validação email:", isEmailValid);

      if (!isEmailValid) {
        return res.status(400).json({
          msg: "Email inválido! O formato deve conter @sistemapoliedro.br",
          received: email,
        });
      }

      // Verificar se já existe professor com esse email
      console.log("Verificando email duplicado...");
      const existing = await Professor.findOne({ email });
      if (existing) {
        return res.status(400).json({
          msg: "Esse email já está em uso",
          received: email,
        });
      }

      // Validar tipo (enum)
      console.log("Validando tipo:", tipo);
      if (!["admin", "professor"].includes(tipo)) {
        return res.status(400).json({
          msg: "Tipo inválido. Deve ser 'admin' ou 'professor'.",
          received: tipo,
        });
      }

      // Opcional: Só permitir criar admin se o usuário atual for admin
      console.log(
        "Validando permissões - User role:",
        req.user.role,
        "Tipo solicitado:",
        tipo
      );
      if (tipo === "admin" && req.user.role !== "admin") {
        return res.status(403).json({
          msg: "Apenas administradores podem criar outros administradores.",
        });
      }

      // Gerar senha automática
      const senhaGerada = crypto.randomBytes(4).toString("hex");
      console.log("Senha gerada:", senhaGerada);

      // Hashear senha
      const hashedPassword = await bcrypt.hash(senhaGerada, 10);
      console.log("Senha hash gerada");

      // Preparar dados do professor
      const professorData = {
        nome: nome ? nome.trim() : "",
        email: email.trim(),
        tipo: tipo,
        senha: hashedPassword,
      };

      console.log("Dados do professor preparados:", {
        nome: professorData.nome,
        email: professorData.email,
        tipo: professorData.tipo,
        hasPassword: !!professorData.senha,
      });

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

      // Criar professor COM TRY-CATCH ESPECÍFICO PARA VALIDAÇÃO
      console.log("Criando instância do Professor...");
      const novoProfessor = new Professor(professorData);

      // VALIDAR ANTES DE SALVAR
      console.log("Validando dados do professor...");
      try {
        await novoProfessor.validate();
        console.log("Validação do mongoose passou");
      } catch (validationError) {
        console.error("ERRO NA VALIDAÇÃO DO MONGOOSE:", validationError);
        return res.status(400).json({
          msg: "Dados inválidos",
          error: validationError.message,
          errors: validationError.errors
            ? Object.keys(validationError.errors)
            : [],
        });
      }

      console.log("Salvando professor no banco...");
      await novoProfessor.save();
      console.log("Professor salvo com ID:", novoProfessor._id);

      // Não enviar dados Base64 na resposta (pode ser muito grande)
      const professorResponse = {
        id: novoProfessor._id,
        nome: novoProfessor.nome,
        email: novoProfessor.email,
        tipo: novoProfessor.tipo,
        hasImage: !!novoProfessor.imagem,
      };

      console.log("Professor registrado com sucesso:", professorResponse);

      res.status(201).json({
        msg: "Professor cadastrado com sucesso",
        professor: professorResponse,
        senhaProvisoria: senhaGerada,
      });
    } catch (err) {
      console.error("ERRO GERAL NO REGISTRO:", err);
      console.error("Nome do erro:", err.name);
      console.error("Mensagem do erro:", err.message);
      console.error("Stack do erro:", err.stack);

      // TRATAMENTO ESPECÍFICO DE ERROS
      if (err.name === "ValidationError") {
        const errors = Object.values(err.errors).map((error) => ({
          field: error.path,
          message: error.message,
        }));
        return res.status(400).json({
          msg: "Erro de validação nos dados",
          errors: errors,
        });
      }

      if (err.code === 11000) {
        return res.status(400).json({
          msg: "Este email já está em uso por outro professor",
        });
      }

      if (err.name === "CastError") {
        return res.status(400).json({
          msg: "Formato de dados inválido",
        });
      }

      res.status(500).json({
        msg: "Erro interno no servidor",
        error:
          process.env.NODE_ENV === "development" ? err.message : "Erro interno",
        ...(process.env.NODE_ENV === "development" && { stack: err.stack }),
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
      { id: prof._id, role: prof.tipo }, // MUDANÇA: Use prof.tipo em vez de hardcoded "professor"
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

// Update Professor (self-update)
router.put(
  "/update",
  auth(["professor", "admin"]), // MUDANÇA: Permite admin também
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
        tipo: prof.tipo, // MUDANÇA: Incluir tipo
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
router.get("/image", auth(["professor", "admin"]), async (req, res) => {
  // MUDANÇA: Permite admin
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

// Rota para upload de imagem via base64 - PROFESSOR (COM DEPURAÇÃO)
router.put(
  "/update-image-base64",
  auth(["professor", "admin"]),
  async (req, res) => {
    try {
      console.log("=== UPLOAD VIA BASE64 - PROFESSOR ===");
      console.log("Headers:", req.headers);
      console.log("Content-Type:", req.headers["content-type"]);
      console.log("Content-Length:", req.headers["content-length"]);

      const { imagem, filename, contentType } = req.body;

      // DEPURAÇÃO
      console.log("Dados recebidos:", {
        hasImagem: !!imagem,
        imagemLength: imagem ? imagem.length : 0,
        filename: filename,
        contentType: contentType,
      });

      if (!imagem) {
        console.log("ERRO: Nenhuma imagem enviada");
        return res.status(400).json({ msg: "Nenhuma imagem enviada" });
      }

      // Validar tamanho
      const base64Size = Math.ceil((imagem.length * 3) / 4);
      console.log("Tamanho estimado da imagem:", base64Size, "bytes");

      if (base64Size > 5 * 1024 * 1024) {
        console.log("ERRO: Imagem muito grande:", base64Size, "bytes");
        return res.status(400).json({
          msg: "Imagem muito grande. Tamanho máximo: 5MB",
        });
      }

      if (!imagem.startsWith("data:image/")) {
        console.log("ERRO: Formato inválido");
        return res.status(400).json({ msg: "Formato de imagem inválido" });
      }

      const prof = await Professor.findById(req.user.id);
      if (!prof) {
        console.log("ERRO: Professor não encontrado - ID:", req.user.id);
        return res.status(404).json({ msg: "Professor não encontrado" });
      }

      const matches = imagem.match(/^data:([A-Za-z-+\/]+);base64,(.+)$/);
      if (!matches || matches.length !== 3) {
        console.log("ERRO: String base64 inválida");
        return res.status(400).json({ msg: "String base64 inválida" });
      }

      try {
        const imageBuffer = Buffer.from(matches[2], "base64");
        console.log("Buffer criado. Tamanho:", imageBuffer.length, "bytes");

        prof.imagem = {
          data: matches[2],
          contentType: matches[1] || contentType || "image/jpeg",
          filename: filename || "imagem.jpg",
          size: imageBuffer.length,
        };

        await prof.save();
        console.log("Imagem salva no banco com sucesso");

        res.json({
          msg: "Imagem atualizada com sucesso",
          imagem: {
            contentType: prof.imagem.contentType,
            filename: prof.imagem.filename,
            size: prof.imagem.size,
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

      if (err.name === "PayloadTooLargeError") {
        return res.status(413).json({
          msg: "Arquivo muito grande. Tamanho máximo: 5MB",
        });
      }

      res.status(500).json({
        msg: "Erro interno no servidor",
        error:
          process.env.NODE_ENV === "development" ? err.message : "Erro interno",
      });
    }
  }
);

// Remover imagem do perfil
router.delete(
  "/remove-image",
  auth(["professor", "admin"]),
  async (req, res) => {
    // MUDANÇA: Permite admin
    try {
      const prof = await Professor.findById(req.user.id);
      if (!prof)
        return res.status(404).json({ msg: "Professor não encontrado" });

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
  }
);

// ADICIONE ESTA ROTA - Perfil do professor (GET /)
router.get("/", auth(["professor", "admin"]), async (req, res) => {
  // MUDANÇA: Permite admin
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
        tipo: professor.tipo, // MUDANÇA: Incluir tipo
        hasImage: !!professor.imagem,
      },
    });
  } catch (err) {
    console.log("Erro na rota GET / professor:", err);
    res.status(500).json({ error: err.message });
  }
});

// GET: Buscar professores por email
router.get("/buscar", auth(["admin", "professor"]), async (req, res) => {
  try {
    const { email } = req.query;

    if (!email) {
      return res.status(400).json({
        success: false,
        error: "Parâmetro 'email' é obrigatório",
      });
    }

    const professores = await Professor.find({
      email: { $regex: email, $options: "i" },
    })
      .select("_id nome email")
      .limit(10);

    res.json(professores);
  } catch (err) {
    console.error("Erro ao buscar professores:", err);
    res.status(500).json({
      success: false,
      error: "Erro interno do servidor ao buscar professores",
    });
  }
});

// Listar todos os professores (GET /list)
router.get("/list", auth(["professor", "admin"]), async (req, res) => {
  // MUDANÇA: Permite admin e adiciona log
  try {
    console.log("=== ROTA LIST PROFESSORES CHAMADA ==="); // Log para debug
    console.log("User role:", req.user.role); // Log do role do usuário logado
    console.log("User ID:", req.user.id);

    const professores = await Professor.find(
      {},
      { senha: 0, imagem: { data: 0 } }
    );
    const host = getHost(req); // MUDANÇA: Usar host correto
    const formattedProfessores = professores.map((prof) => ({
      id: prof._id.toString(),
      nome: prof.nome,
      email: prof.email,
      ra: null,
      tipo: prof.tipo, // MUDANÇA: Usar o tipo real do banco (admin ou professor)
      fotoUrl: prof.imagem
        ? `${req.protocol}://${host}/api/professores/image/${prof._id}`
        : null,
    }));
    console.log(`Encontrados ${formattedProfessores.length} professores`); // Log para debug
    res.json(formattedProfessores);
  } catch (err) {
    console.error("Erro ao listar professores:", err); // Log para debug
    res.status(500).json({ error: err.message });
  }
});

// Atualizar professor por ID (PUT /:id)
router.put("/:id", auth(["professor", "admin"]), async (req, res) => {
  try {
    console.log("=== ROTA UPDATE PROFESSOR POR ID CHAMADA ===");
    console.log("User role:", req.user.role);
    const { id } = req.params;
    const { nome, email, tipo } = req.body;

    // VALIDAÇÃO: Verificar se o ID é válido
    if (!id || !mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ msg: "ID do professor inválido" });
    }

    const prof = await Professor.findById(id);
    if (!prof) {
      return res.status(404).json({ msg: "Professor não encontrado" });
    }

    // VALIDAÇÃO: Campos obrigatórios
    if (!nome && !email && !tipo) {
      return res
        .status(400)
        .json({ msg: "Nenhum dado fornecido para atualização" });
    }

    // VALIDAÇÃO: Nome
    if (nome && (typeof nome !== "string" || nome.trim().length === 0)) {
      return res.status(400).json({ msg: "Nome inválido" });
    }

    // VALIDAÇÃO: Email - VALIDAÇÃO ANTES DO MONGOOSE
    if (email) {
      if (typeof email !== "string" || email.trim().length === 0) {
        return res.status(400).json({ msg: "Email inválido" });
      }

      // VALIDAÇÃO DO DOMÍNIO DO EMAIL - MESMA REGRA DO MONGOOSE
      const emailRegex = /^[\w.-]+@sistemapoliedro\.br$/;
      if (!emailRegex.test(email.trim())) {
        return res.status(400).json({
          msg: "Email inválido! O formato deve conter @sistemapoliedro.br",
        });
      }

      // VERIFICAR SE EMAIL JÁ EXISTE EM OUTRO USUÁRIO
      const existingProfessor = await Professor.findOne({
        email: email.trim().toLowerCase(),
        _id: { $ne: id },
      });

      if (existingProfessor) {
        return res
          .status(400)
          .json({ msg: "Este email já está em uso por outro professor" });
      }
    }

    // VALIDAÇÃO: Tipo
    if (tipo && !["admin", "professor"].includes(tipo)) {
      return res
        .status(400)
        .json({ msg: "Tipo inválido. Use 'admin' ou 'professor'" });
    }

    // VALIDAÇÃO: Permissão para promover para admin
    if (tipo === "admin" && req.user.role !== "admin") {
      return res.status(403).json({
        msg: "Apenas administradores podem promover para admin.",
      });
    }

    // VALIDAÇÃO: Impedir que não-admins alterem o tipo de outros professores
    if (
      tipo &&
      req.user.role !== "admin" &&
      prof._id.toString() !== req.user.id
    ) {
      return res.status(403).json({
        msg: "Você só pode alterar seu próprio tipo de usuário",
      });
    }

    // ATUALIZAR CAMPOS
    if (nome) prof.nome = nome.trim();
    if (email) prof.email = email.trim().toLowerCase();
    if (tipo) prof.tipo = tipo;

    // TENTAR SALVAR E CAPTURAR ERROS DE VALIDAÇÃO DO MONGOOSE
    try {
      await prof.save();
    } catch (saveError) {
      // CAPTURAR ERROS DE VALIDAÇÃO DO MONGOOSE ESPECIFICAMENTE
      if (saveError.name === "ValidationError") {
        const errors = Object.values(saveError.errors).map(
          (err) => err.message
        );
        return res.status(400).json({
          msg: "Dados inválidos",
          errors: errors,
        });
      }

      // CAPTURAR ERRO DE EMAIL DUPLICADO
      if (saveError.code === 11000) {
        return res.status(400).json({ msg: "Este email já está em uso" });
      }

      throw saveError; // Re-lançar outros erros para o catch externo
    }

    const host = getHost(req);
    const formatted = {
      id: prof._id.toString(),
      nome: prof.nome,
      email: prof.email,
      ra: null,
      tipo: prof.tipo,
      fotoUrl: prof.imagem
        ? `${req.protocol}://${host}/api/professores/image/${prof._id}`
        : null,
    };

    res.json({ msg: "Professor atualizado com sucesso", professor: formatted });
  } catch (err) {
    console.error("Erro ao atualizar professor:", err);

    // TRATAMENTO ESPECÍFICO DE ERROS
    if (err.name === "CastError") {
      return res.status(400).json({ msg: "ID do professor inválido" });
    }

    res.status(500).json({
      msg: "Erro interno do servidor ao atualizar professor",
      error:
        process.env.NODE_ENV === "development" ? err.message : "Erro interno",
    });
  }
});

// Deletar professor por ID (DELETE /:id)
router.delete("/:id", auth(["professor", "admin"]), async (req, res) => {
  // MUDANÇA: Permite admin
  try {
    console.log("=== ROTA DELETE PROFESSOR POR ID CHAMADA ==="); // Log para debug
    console.log("User role:", req.user.role);
    const { id } = req.params;
    const prof = await Professor.findByIdAndDelete(id);
    if (!prof) {
      return res.status(404).json({ msg: "Professor não encontrado" });
    }
    res.json({ msg: "Professor deletado com sucesso" });
  } catch (err) {
    console.error("Erro ao deletar professor:", err); // Log para debug
    res.status(500).json({ error: err.message });
  }
});

router.use(handleMulterError);

module.exports = router;
