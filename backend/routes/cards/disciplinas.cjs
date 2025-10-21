const express = require("express");
const multer = require("multer");
const path = require("path");
const routerCards = express.Router();
const CardDisciplina = require("../../models/cardDisciplina.cjs");
const Professor = require("../../models/professor.cjs");
const Aluno = require("../../models/aluno.cjs");
const auth = require("../../middleware/auth.cjs");
const { verificarProfessorDisciplina, verificarAcessoDisciplina } = require("../../middleware/disciplinaAuth.cjs");

// Configurações
const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB

// Configuração do Multer para armazenar na memória
const storage = multer.memoryStorage();

// Função para obter mimetype baseado na extensão
function getMimeTypeFromExtension(filename) {
  const ext = path.extname(filename).toLowerCase();
  switch (ext) {
    case ".jpg":
    case ".jpeg":
      return "image/jpeg";
    case ".png":
      return "image/png";
    case ".gif":
      return "image/gif";
    case ".bmp":
      return "image/bmp";
    case ".webp":
      return "image/webp";
    case ".svg":
      return "image/svg+xml";
    default:
      return "application/octet-stream";
  }
}

// Função para gerar slug a partir do título
function generateSlug(title) {
  return title
    .toLowerCase()
    .trim()
    .replace(/[^\w\s-]/g, "")
    .replace(/[\s_-]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

// Filtro para validar tipos de arquivo
const fileFilter = (req, file, cb) => {
  const allowedExtensions = /jpeg|jpg|png|gif|bmp|webp|svg/;
  const extname = allowedExtensions.test(
    path.extname(file.originalname).toLowerCase()
  );
  const allowedMimeTypes = /^image\/(jpeg|png|gif|bmp|webp|svg\+xml)$/;
  const mimetype = allowedMimeTypes.test(file.mimetype);

  if (extname) {
    return cb(null, true);
  } else {
    cb(
      new Error(
        `Apenas arquivos de imagem são permitidos. Enviado: ${file.originalname} (mimetype: ${file.mimetype})`
      )
    );
  }
};

const upload = multer({
  storage: storage,
  limits: {
    fileSize: MAX_FILE_SIZE,
  },
  fileFilter: fileFilter,
});

// Middleware para processar uploads múltiplos
const handleUpload = upload.fields([
  { name: "imagem", maxCount: 1 },
  { name: "icone", maxCount: 1 },
]);

// Middleware para processar arquivos uploadados
const processUploadedFiles = (req, res, next) => {
  if (req.files) {
    if (req.files.imagem) {
      let contentType = req.files.imagem[0].mimetype;
      if (contentType === "application/octet-stream") {
        contentType = getMimeTypeFromExtension(req.files.imagem[0].originalname);
      }
      req.body.imagem = {
        data: req.files.imagem[0].buffer,
        contentType: contentType,
      };
    }
    if (req.files.icone) {
      let contentType = req.files.icone[0].mimetype;
      if (contentType === "application/octet-stream") {
        contentType = getMimeTypeFromExtension(req.files.icone[0].originalname);
      }
      req.body.icone = {
        data: req.files.icone[0].buffer,
        contentType: contentType,
      };
    }
  }
  next();
};

// Middleware de validação
const validateRequiredFields = (req, res, next) => {
  const { imagem, icone, titulo } = req.body;

  if (req.method === "POST") {
    if (!imagem || !icone || !titulo) {
      return res.status(400).json({
        success: false,
        error: "Todos os campos (imagem, icone, titulo) são obrigatórios",
      });
    }
  }

  if (titulo && (typeof titulo !== "string" || titulo.trim().length === 0)) {
    return res.status(400).json({
      success: false,
      error: "Título deve ser uma string não vazia",
    });
  }

  next();
};

// ✅ CORREÇÃO: Rota para servir imagens do MongoDB - EVITAR CACHE
routerCards.get("/imagem/:id/:tipo", async (req, res) => {
  try {
    const { id, tipo } = req.params;

    if (!["imagem", "icone"].includes(tipo)) {
      return res.status(400).json({
        success: false,
        error: "Tipo inválido. Use 'imagem' ou 'icone'",
      });
    }

    const card = await CardDisciplina.findById(id);

    if (!card || !card[tipo]) {
      return res.status(404).json({
        success: false,
        error: "Imagem não encontrada",
      });
    }

    // ✅ CORREÇÃO: Headers para evitar cache
    res.set("Content-Type", card[tipo].contentType);
    res.set("Cache-Control", "no-cache, no-store, must-revalidate");
    res.set("Pragma", "no-cache");
    res.set("Expires", "0");
    
    // ✅ CORREÇÃO: Usar timestamp como ETag para cache busting
    const timestamp = req.query.t || Date.now();
    res.set("ETag", `"${timestamp}"`);

    res.send(card[tipo].data);
  } catch (err) {
    console.error("Erro ao buscar imagem:", err);
    res.status(500).json({
      success: false,
      error: "Erro interno do servidor ao buscar a imagem",
    });
  }
});

// ✅ CORREÇÃO: GET: Buscar card por slug (com timestamp para cache busting)
routerCards.get("/disciplina/:slug", auth(), verificarAcessoDisciplina, async (req, res) => {
  try {
    if (!req.disciplina) {
      return res.status(404).json({
        success: false,
        error: "Disciplina não encontrada",
      });
    }

    const card = await CardDisciplina.findById(req.disciplina._id)
      .populate('criadoPor', 'nome email')
      .populate('professores', 'nome email')
      .populate('alunos', 'nome email ra');

    if (!card) {
      return res.status(404).json({
        success: false,
        error: "Disciplina não encontrada",
      });
    }

    // ✅ CORREÇÃO: Adicionar timestamp único para evitar cache
    const timestamp = Date.now();

    const cardResponse = {
      _id: card._id,
      titulo: card.titulo,
      slug: card.slug,
      topicos: card.topicos || [],
      professores: card.professores,
      alunos: card.alunos,
      criadoPor: card.criadoPor,
      createdAt: card.createdAt,
      updatedAt: card.updatedAt,
      // ✅ CORREÇÃO: Adicionar timestamp às URLs
      imagem: `${req.protocol}://${req.get("host")}/api/cardsDisciplinas/imagem/${card._id}/imagem?t=${timestamp}`,
      icone: `${req.protocol}://${req.get("host")}/api/cardsDisciplinas/imagem/${card._id}/icone?t=${timestamp}`,
      url: `${req.protocol}://${req.get("host")}/api/cardsDisciplinas/disciplina/${card.slug}`,
    };

    res.json({
      success: true,
      data: cardResponse,
    });
  } catch (err) {
    console.error("Erro ao buscar disciplina:", err);
    res.status(500).json({
      success: false,
      error: "Erro interno do servidor ao buscar a disciplina",
    });
  }
});

// ✅ CORREÇÃO: GET: Buscar todos os cards (com timestamp para cache busting)
routerCards.get("/", auth(), async (req, res) => {
  try {
    const userId = req.user.id;
    const userRole = req.user.role;

    let query = {};
    if (userRole === "professor") {
      query = { professores: userId };
    } else if (userRole === "aluno") {
      query = { alunos: userId };
    }

    const cards = await CardDisciplina.find(query)
      .populate('criadoPor', 'nome email')
      .populate('professores', 'nome email')
      .populate('alunos', 'nome email ra')
      .sort({ createdAt: -1 });

    // ✅ CORREÇÃO: Adicionar timestamp único para evitar cache
    const timestamp = Date.now();

    const cardsWithUrls = cards.map((card) => ({
      _id: card._id,
      titulo: card.titulo,
      slug: card.slug,
      topicos: card.topicos || [],
      professores: card.professores,
      alunos: card.alunos,
      criadoPor: card.criadoPor,
      createdAt: card.createdAt,
      updatedAt: card.updatedAt,
      // ✅ CORREÇÃO: Adicionar timestamp às URLs
      imagem: `${req.protocol}://${req.get("host")}/api/cardsDisciplinas/imagem/${card._id}/imagem?t=${timestamp}`,
      icone: `${req.protocol}://${req.get("host")}/api/cardsDisciplinas/imagem/${card._id}/icone?t=${timestamp}`,
      url: `${req.protocol}://${req.get("host")}/api/cardsDisciplinas/disciplina/${card.slug}`,
    }));

    res.json({
      success: true,
      count: cards.length,
      data: cardsWithUrls,
    });
  } catch (err) {
    console.error("Erro ao buscar cards:", err);
    res.status(500).json({
      success: false,
      error: "Erro interno do servidor ao buscar os cards",
    });
  }
});

// ✅ CORREÇÃO: GET: Listar disciplinas do usuário logado (com timestamp para cache busting)
routerCards.get("/minhas-disciplinas", auth(), async (req, res) => {
  try {
    const userId = req.user.id;
    const userRole = req.user.role;

    let query = {};
    if (userRole === "professor") {
      query = { professores: userId };
    } else if (userRole === "aluno") {
      query = { alunos: userId };
    }

    const cards = await CardDisciplina.find(query).sort({ createdAt: -1 });

    // ✅ CORREÇÃO: Adicionar timestamp único para evitar cache
    const timestamp = Date.now();

    const cardsWithUrls = cards.map((card) => ({
      _id: card._id,
      titulo: card.titulo,
      slug: card.slug,
      topicos: card.topicos || [],
      professores: card.professores,
      alunos: card.alunos,
      criadoPor: card.criadoPor,
      createdAt: card.createdAt,
      updatedAt: card.updatedAt,
      // ✅ CORREÇÃO: Adicionar timestamp às URLs
      imagem: `${req.protocol}://${req.get("host")}/api/cardsDisciplinas/imagem/${card._id}/imagem?t=${timestamp}`,
      icone: `${req.protocol}://${req.get("host")}/api/cardsDisciplinas/imagem/${card._id}/icone?t=${timestamp}`,
      url: `${req.protocol}://${req.get("host")}/api/cardsDisciplinas/disciplina/${card.slug}`,
    }));

    res.json({
      success: true,
      count: cards.length,
      data: cardsWithUrls,
    });
  } catch (err) {
    console.error("Erro ao buscar disciplinas:", err);
    res.status(500).json({
      success: false,
      error: "Erro interno do servidor ao buscar as disciplinas",
    });
  }
});

// POST: Criar um novo card
routerCards.post(
  "/",
  auth(["professor", "admin"]),
  handleUpload,
  processUploadedFiles,
  validateRequiredFields,
  async (req, res) => {
    try {
      const { imagem, icone, titulo, professores, alunos } = req.body;
      const userId = req.user.id;

      const slug = generateSlug(titulo.trim());

      const existingCard = await CardDisciplina.findOne({ slug });
      if (existingCard) {
        return res.status(400).json({
          success: false,
          error: "Já existe uma disciplina com este título",
        });
      }

      // Processar lista de professores
      let professoresIds = [];
      if (professores && Array.isArray(professores)) {
        const professoresExistentes = await Professor.find({ 
          _id: { $in: professores } 
        });
        
        if (professoresExistentes.length !== professores.length) {
          return res.status(400).json({
            success: false,
            error: "Um ou mais professores não foram encontrados",
          });
        }
        professoresIds = professores;
      }

      // Adicionar o criador automaticamente como professor
      if (!professoresIds.includes(userId)) {
        professoresIds.push(userId);
      }

      // Processar lista de alunos
      let alunosIds = [];
      if (alunos && Array.isArray(alunos)) {
        const alunosExistentes = await Aluno.find({ 
          _id: { $in: alunos } 
        });
        
        if (alunosExistentes.length !== alunos.length) {
          return res.status(400).json({
            success: false,
            error: "Um ou mais alunos não foram encontrados",
          });
        }
        alunosIds = alunos;
      }

      const novoCard = new CardDisciplina({
        imagem: {
          data: imagem.data,
          contentType: imagem.contentType,
        },
        icone: {
          data: icone.data,
          contentType: icone.contentType,
        },
        titulo: titulo.trim(),
        slug: slug,
        professores: professoresIds,
        alunos: alunosIds,
        criadoPor: userId
      });

      await novoCard.save();

      // Atualizar as disciplinas dos professores
      await Professor.updateMany(
        { _id: { $in: professoresIds } },
        { $addToSet: { disciplinas: novoCard._id } }
      );

      // Atualizar as disciplinas dos alunos
      if (alunosIds.length > 0) {
        await Aluno.updateMany(
          { _id: { $in: alunosIds } },
          { $addToSet: { disciplinas: novoCard._id } }
        );
      }

      // ✅ CORREÇÃO: Adicionar timestamp único para evitar cache
      const timestamp = Date.now();

      const cardResponse = {
        _id: novoCard._id,
        titulo: novoCard.titulo,
        slug: novoCard.slug,
        professores: novoCard.professores,
        alunos: novoCard.alunos,
        criadoPor: novoCard.criadoPor,
        createdAt: novoCard.createdAt,
        updatedAt: novoCard.updatedAt,
        // ✅ CORREÇÃO: Adicionar timestamp às URLs
        imagem: `${req.protocol}://${req.get("host")}/api/cardsDisciplinas/imagem/${novoCard._id}/imagem?t=${timestamp}`,
        icone: `${req.protocol}://${req.get("host")}/api/cardsDisciplinas/imagem/${novoCard._id}/icone?t=${timestamp}`,
        url: `${req.protocol}://${req.get("host")}/api/cardsDisciplinas/disciplina/${novoCard.slug}`,
      };

      res.status(201).json({
        success: true,
        message: "Disciplina criada com sucesso",
        data: cardResponse,
      });
    } catch (err) {
      console.error("Erro ao criar card:", err);

      if (err.name === "ValidationError") {
        return res.status(400).json({
          success: false,
          error: "Dados de entrada inválidos",
          details: err.errors,
        });
      }

      if (err.code === 11000) {
        return res.status(400).json({
          success: false,
          error: "Já existe uma disciplina com este título",
        });
      }

      res.status(500).json({
        success: false,
        error: "Erro interno do servidor ao criar o card",
      });
    }
  }
);

// ✅ CORREÇÃO: PUT: Atualizar um card (com timestamp para cache busting)
routerCards.put(
  "/:id",
  auth(["professor", "admin"]),
  verificarProfessorDisciplina,
  handleUpload,
  processUploadedFiles,
  async (req, res) => {
    const { id } = req.params;
    const { imagem, icone, titulo, professores, alunos } = req.body;

    if (!id || id.length !== 24) {
      return res.status(400).json({
        success: false,
        error: "ID inválido",
      });
    }

    const updates = {};
    if (imagem !== undefined) {
      updates.imagem = {
        data: imagem.data,
        contentType: imagem.contentType,
      };
    }
    if (icone !== undefined) {
      updates.icone = {
        data: icone.data,
        contentType: icone.contentType,
      };
    }
    if (titulo !== undefined) {
      if (typeof titulo !== "string" || titulo.trim().length === 0) {
        return res.status(400).json({
          success: false,
          error: "Título deve ser uma string não vazia",
        });
      }
      const newSlug = generateSlug(titulo.trim());
      updates.titulo = titulo.trim();
      updates.slug = newSlug;

      const existingCard = await CardDisciplina.findOne({
        slug: newSlug,
        _id: { $ne: id },
      });
      if (existingCard) {
        return res.status(400).json({
          success: false,
          error: "Já existe uma disciplina com este título",
        });
      }
    }

    // Atualizar professores se fornecido
    if (professores !== undefined) {
      if (Array.isArray(professores)) {
        const professoresExistentes = await Professor.find({ 
          _id: { $in: professores } 
        });
        
        if (professoresExistentes.length !== professores.length) {
          return res.status(400).json({
            success: false,
            error: "Um ou mais professores não foram encontrados",
          });
        }
        updates.professores = professores;
      } else {
        return res.status(400).json({
          success: false,
          error: "Professores deve ser um array",
        });
      }
    }

    // Atualizar alunos se fornecido
    if (alunos !== undefined) {
      if (Array.isArray(alunos)) {
        const alunosExistentes = await Aluno.find({ 
          _id: { $in: alunos } 
        });
        
        if (alunosExistentes.length !== alunos.length) {
          return res.status(400).json({
            success: false,
            error: "Um ou mais alunos não foram encontrados",
          });
        }
        updates.alunos = alunos;
      } else {
        return res.status(400).json({
          success: false,
          error: "Alunos deve ser um array",
        });
      }
    }

    if (Object.keys(updates).length === 0) {
      return res.status(400).json({
        success: false,
        error: "Nenhum campo válido para atualização fornecido",
      });
    }

    try {
      const cardAtualizado = await CardDisciplina.findByIdAndUpdate(
        id,
        updates,
        {
          new: true,
          runValidators: true,
        }
      );

      if (!cardAtualizado) {
        return res.status(404).json({
          success: false,
          error: "Card não encontrado",
        });
      }

      // Atualizar relações nos modelos de Professor e Aluno
      if (professores !== undefined) {
        const professoresAntigos = await Professor.find({ disciplinas: id });
        const professoresAntigosIds = professoresAntigos.map(p => p._id.toString());
        
        const professoresRemovidos = professoresAntigosIds.filter(
          profId => !updates.professores.includes(profId)
        );
        
        if (professoresRemovidos.length > 0) {
          await Professor.updateMany(
            { _id: { $in: professoresRemovidos } },
            { $pull: { disciplinas: id } }
          );
        }

        await Professor.updateMany(
          { _id: { $in: updates.professores } },
          { $addToSet: { disciplinas: id } }
        );
      }

      if (alunos !== undefined) {
        const alunosAntigos = await Aluno.find({ disciplinas: id });
        const alunosAntigosIds = alunosAntigos.map(a => a._id.toString());
        
        const alunosRemovidos = alunosAntigosIds.filter(
          alunoId => !updates.alunos.includes(alunoId)
        );
        
        if (alunosRemovidos.length > 0) {
          await Aluno.updateMany(
            { _id: { $in: alunosRemovidos } },
            { $pull: { disciplinas: id } }
          );
        }

        await Aluno.updateMany(
          { _id: { $in: updates.alunos } },
          { $addToSet: { disciplinas: id } }
        );
      }

      // ✅ CORREÇÃO: Adicionar timestamp único para evitar cache
      const timestamp = Date.now();

      const cardResponse = {
        _id: cardAtualizado._id,
        titulo: cardAtualizado.titulo,
        slug: cardAtualizado.slug,
        professores: cardAtualizado.professores,
        alunos: cardAtualizado.alunos,
        criadoPor: cardAtualizado.criadoPor,
        createdAt: cardAtualizado.createdAt,
        updatedAt: cardAtualizado.updatedAt,
        // ✅ CORREÇÃO: Adicionar timestamp às URLs
        imagem: `${req.protocol}://${req.get("host")}/api/cardsDisciplinas/imagem/${cardAtualizado._id}/imagem?t=${timestamp}`,
        icone: `${req.protocol}://${req.get("host")}/api/cardsDisciplinas/imagem/${cardAtualizado._id}/icone?t=${timestamp}`,
        url: `${req.protocol}://${req.get("host")}/api/cardsDisciplinas/disciplina/${cardAtualizado.slug}`,
      };

      res.json({
        success: true,
        message: "Card atualizado com sucesso",
        data: cardResponse,
      });
    } catch (err) {
      console.error("Erro ao atualizar card:", err);

      if (err.name === "CastError") {
        return res.status(400).json({
          success: false,
          error: "ID inválido",
        });
      }

      if (err.name === "ValidationError") {
        return res.status(400).json({
          success: false,
          error: "Dados de entrada inválidos",
          details: err.errors,
        });
      }

      if (err.code === 11000) {
        return res.status(400).json({
          success: false,
          error: "Já existe uma disciplina com este título",
        });
      }

      res.status(500).json({
        success: false,
        error: "Erro interno do servidor ao atualizar o card",
      });
    }
  }
);

// DELETE: Deletar um card (apenas professores da disciplina ou admin)
routerCards.delete(
  "/:id",
  auth(["professor", "admin"]),
  verificarProfessorDisciplina,
  async (req, res) => {
    const { id } = req.params;

    if (!id || id.length !== 24) {
      return res.status(400).json({
        success: false,
        error: "ID inválido",
      });
    }

    try {
      const card = await CardDisciplina.findByIdAndDelete(id);

      if (!card) {
        return res.status(404).json({
          success: false,
          error: "Card não encontrado",
        });
      }

      // Remover a disciplina dos professores e alunos
      await Professor.updateMany(
        { disciplinas: id },
        { $pull: { disciplinas: id } }
      );

      await Aluno.updateMany(
        { disciplinas: id },
        { $pull: { disciplinas: id } }
      );

      res.json({
        success: true,
        message: "Card deletado com sucesso",
        data: {
          _id: card._id,
          titulo: card.titulo,
          slug: card.slug,
        },
      });
    } catch (err) {
      console.error("Erro ao deletar card:", err);

      if (err.name === "CastError") {
        return res.status(400).json({
          success: false,
          error: "ID inválido",
        });
      }

      res.status(500).json({
        success: false,
        error: "Erro interno do servidor ao deletar o card",
      });
    }
  }
);

// ✅ ADICIONE: Rota de debug para verificar imagens (REMOVA DEPOIS DE TESTAR)
routerCards.get("/debug-imagem/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const card = await CardDisciplina.findById(id);
    
    if (!card) {
      return res.status(404).json({ error: "Card não encontrado" });
    }

    res.json({
      id: card._id,
      titulo: card.titulo,
      temImagem: !!card.imagem,
      temIcone: !!card.icone,
      tamanhoImagem: card.imagem?.data?.length || 0,
      tamanhoIcone: card.icone?.data?.length || 0,
      contentTypeImagem: card.imagem?.contentType,
      contentTypeIcone: card.icone?.contentType,
      updatedAt: card.updatedAt
    });

  } catch (err) {
    console.error("Erro no debug:", err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = routerCards;