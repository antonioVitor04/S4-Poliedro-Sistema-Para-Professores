// routes/cards/disciplinas.cjs
const express = require("express");
const multer = require("multer");
const path = require("path");
const routerCards = express.Router();
const CardDisciplina = require("../../models/cardDisciplina.cjs");

// Configurações
const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB

// Configuração do Multer para armazenar na memória
const storage = multer.memoryStorage();

// Filtro para validar tipos de arquivo
const fileFilter = (req, file, cb) => {
  const allowedTypes = /jpeg|jpg|png|gif|bmp|webp|svg/;
  const extname = allowedTypes.test(
    path.extname(file.originalname).toLowerCase()
  );
  const mimetype = allowedTypes.test(file.mimetype);

  if (mimetype && extname) {
    return cb(null, true);
  } else {
    cb(new Error("Apenas arquivos de imagem são permitidos"));
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
    // Prepara os dados para salvar no MongoDB
    if (req.files.imagem) {
      req.body.imagem = {
        data: req.files.imagem[0].buffer,
        contentType: req.files.imagem[0].mimetype
      };
    }
    if (req.files.icone) {
      req.body.icone = {
        data: req.files.icone[0].buffer,
        contentType: req.files.icone[0].mimetype
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

// Rota para servir imagens do MongoDB
routerCards.get("/imagem/:id/:tipo", async (req, res) => {
  try {
    const { id, tipo } = req.params;
    
    if (!['imagem', 'icone'].includes(tipo)) {
      return res.status(400).json({
        success: false,
        error: "Tipo inválido. Use 'imagem' ou 'icone'"
      });
    }

    const card = await CardDisciplina.findById(id);
    
    if (!card || !card[tipo]) {
      return res.status(404).json({
        success: false,
        error: "Imagem não encontrada"
      });
    }

    // Configurar headers para imagem
    res.set('Content-Type', card[tipo].contentType);
    res.set('Cache-Control', 'public, max-age=86400'); // Cache de 1 dia
    
    // Enviar dados da imagem
    res.send(card[tipo].data);
  } catch (err) {
    console.error("Erro ao buscar imagem:", err);
    res.status(500).json({
      success: false,
      error: "Erro interno do servidor ao buscar a imagem",
    });
  }
});

// GET: Buscar card por slug
routerCards.get("/disciplina/:slug", async (req, res) => {
  try {
    const { slug } = req.params;

    const card = await CardDisciplina.findOne({ slug });

    if (!card) {
      return res.status(404).json({
        success: false,
        error: "Disciplina não encontrada",
      });
    }

    // URLs para as imagens no MongoDB
    const cardResponse = {
      _id: card._id,
      titulo: card.titulo,
      slug: card.slug,
      createdAt: card.createdAt,
      updatedAt: card.updatedAt,
      imagem: `${req.protocol}://${req.get("host")}/api/cardsDisciplinas/imagem/${card._id}/imagem`,
      icone: `${req.protocol}://${req.get("host")}/api/cardsDisciplinas/imagem/${card._id}/icone`,
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

// GET: Buscar todos os cards
routerCards.get("/", async (req, res) => {
  try {
    const cards = await CardDisciplina.find().sort({ createdAt: -1 });

    // Adiciona URLs para as imagens no MongoDB
    const cardsWithUrls = cards.map((card) => ({
      _id: card._id,
      titulo: card.titulo,
      slug: card.slug,
      createdAt: card.createdAt,
      updatedAt: card.updatedAt,
      imagem: `${req.protocol}://${req.get("host")}/api/cardsDisciplinas/imagem/${card._id}/imagem`,
      icone: `${req.protocol}://${req.get("host")}/api/cardsDisciplinas/imagem/${card._id}/icone`,
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

// POST: Criar um novo card
routerCards.post(
  "/",
  handleUpload,
  processUploadedFiles,
  validateRequiredFields,
  async (req, res) => {
    try {
      const { imagem, icone, titulo } = req.body;

      const novoCard = new CardDisciplina({
        imagem: {
          data: imagem.data,
          contentType: imagem.contentType
        },
        icone: {
          data: icone.data,
          contentType: icone.contentType
        },
        titulo: titulo.trim(),
      });

      await novoCard.save();

      // Resposta com URLs para as imagens
      const cardResponse = {
        _id: novoCard._id,
        titulo: novoCard.titulo,
        slug: novoCard.slug,
        createdAt: novoCard.createdAt,
        updatedAt: novoCard.updatedAt,
        imagem: `${req.protocol}://${req.get("host")}/api/cardsDisciplinas/imagem/${novoCard._id}/imagem`,
        icone: `${req.protocol}://${req.get("host")}/api/cardsDisciplinas/imagem/${novoCard._id}/icone`,
        url: `${req.protocol}://${req.get("host")}/api/cardsDisciplinas/disciplina/${novoCard.slug}`,
      };

      res.status(201).json({
        success: true,
        message: "Card criado com sucesso",
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

// PUT: Atualizar um card
routerCards.put(
  "/:id",
  handleUpload,
  processUploadedFiles,
  async (req, res) => {
    const { id } = req.params;
    const { imagem, icone, titulo } = req.body;

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
        contentType: imagem.contentType
      };
    }
    if (icone !== undefined) {
      updates.icone = {
        data: icone.data,
        contentType: icone.contentType
      };
    }
    if (titulo !== undefined) {
      if (typeof titulo !== "string" || titulo.trim().length === 0) {
        return res.status(400).json({
          success: false,
          error: "Título deve ser uma string não vazia",
        });
      }
      updates.titulo = titulo.trim();
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

      const cardResponse = {
        _id: cardAtualizado._id,
        titulo: cardAtualizado.titulo,
        slug: cardAtualizado.slug,
        createdAt: cardAtualizado.createdAt,
        updatedAt: cardAtualizado.updatedAt,
        imagem: `${req.protocol}://${req.get("host")}/api/cardsDisciplinas/imagem/${cardAtualizado._id}/imagem`,
        icone: `${req.protocol}://${req.get("host")}/api/cardsDisciplinas/imagem/${cardAtualizado._id}/icone`,
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

// DELETE: Deletar um card
routerCards.delete("/:id", async (req, res) => {
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

    res.json({
      success: true,
      message: "Card deletado com sucesso",
      data: {
        _id: card._id,
        titulo: card.titulo,
        slug: card.slug
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
});

module.exports = routerCards;