const express = require("express");
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const routerCards = express.Router();
const CardDisciplina = require("../../models/cardDisciplina.cjs");

// Configurações
const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB
const UPLOADS_DIR = path.join(__dirname, "../uploads");

// Criar diretório de uploads se não existir
if (!fs.existsSync(UPLOADS_DIR)) {
  fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

// Configuração do Multer para upload de arquivos
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, UPLOADS_DIR);
  },
  filename: (req, file, cb) => {
    // Gera nome único para o arquivo
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    const ext = path.extname(file.originalname);
    cb(null, "card-" + uniqueSuffix + ext);
  },
});

// Filtro para validar tipos de arquivo
const fileFilter = (req, file, cb) => {
  const allowedTypes = /jpeg|jpg|png|gif|bmp|webp|svg|ico/;
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

// Middleware para converter arquivos uploadados em URLs
const processUploadedFiles = (req, res, next) => {
  if (req.files) {
    // Converte os arquivos uploadados em URLs acessíveis
    if (req.files.imagem) {
      req.body.imagem = `/uploads/${req.files.imagem[0].filename}`;
    }
    if (req.files.icone) {
      req.body.icone = `/uploads/${req.files.icone[0].filename}`;
    }
  }
  next();
};

// Middleware de validação de campos obrigatórios
const validateRequiredFields = (req, res, next) => {
  const { imagem, icone, titulo } = req.body;

  // Para criação, todos os campos são obrigatórios
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

// Função para deletar arquivo antigo se necessário
const deleteOldFile = async (cardId, fieldName) => {
  try {
    const card = await CardDisciplina.findById(cardId);
    if (card && card[fieldName]) {
      const oldFilePath = path.join(__dirname, "..", card[fieldName]);
      if (fs.existsSync(oldFilePath)) {
        fs.unlinkSync(oldFilePath);
      }
    }
  } catch (error) {
    console.error(`Erro ao deletar arquivo antigo ${fieldName}:`, error);
  }
};

// GET: Buscar card por slug (para a página individual da disciplina)
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

    // Adiciona URLs completas
    const cardResponse = {
      ...card._doc,
      imagem: req.protocol + "://" + req.get("host") + card.imagem,
      icone: req.protocol + "://" + req.get("host") + card.icone,
      url: `${req.protocol}://${req.get("host")}/cards/disciplina/${card.slug}`,
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

// GET: Buscar todos os cards (inclui a URL da disciplina)
routerCards.get("/", async (req, res) => {
  try {
    const cards = await CardDisciplina.find().sort({ createdAt: -1 });

    // Converte caminhos relativos em URLs completas e adiciona URL da disciplina
    const cardsWithFullUrls = cards.map((card) => ({
      ...card._doc,
      imagem: req.protocol + "://" + req.get("host") + card.imagem,
      icone: req.protocol + "://" + req.get("host") + card.icone,
      url: `${req.protocol}://${req.get("host")}/cards/disciplina/${card.slug}`,
    }));

    res.json({
      success: true,
      count: cards.length,
      data: cardsWithFullUrls,
    });
  } catch (err) {
    console.error("Erro ao buscar cards:", err);
    res.status(500).json({
      success: false,
      error: "Erro interno do servidor ao buscar os cards",
    });
  }
});

// POST: Criar um novo card com upload de arquivos
routerCards.post(
  "/",
  (req, res, next) => {
    handleUpload(req, res, (err) => {
      if (err) {
        if (err instanceof multer.MulterError) {
          if (err.code === "LIMIT_FILE_SIZE") {
            return res.status(400).json({
              success: false,
              error: "Arquivo muito grande. Tamanho máximo permitido: 5MB",
            });
          }
        }
        return res.status(400).json({
          success: false,
          error: err.message,
        });
      }
      next();
    });
  },
  processUploadedFiles,
  validateRequiredFields,
  async (req, res) => {
    try {
      const { imagem, icone, titulo } = req.body;

      const novoCard = new CardDisciplina({
        imagem: imagem,
        icone: icone,
        titulo: titulo.trim(),
      });

      await novoCard.save();

      // Adiciona URLs completas na resposta
      const cardResponse = {
        ...novoCard._doc,
        imagem: req.protocol + "://" + req.get("host") + novoCard.imagem,
        icone: req.protocol + "://" + req.get("host") + novoCard.icone,
        url: `${req.protocol}://${req.get("host")}/cards/disciplina/${
          novoCard.slug
        }`,
      };

      res.status(201).json({
        success: true,
        message: "Card criado com sucesso",
        data: cardResponse,
      });
    } catch (err) {
      // Deleta arquivos uploadados se houve erro
      if (req.files) {
        Object.values(req.files).forEach((files) => {
          files.forEach((file) => {
            if (fs.existsSync(file.path)) {
              fs.unlinkSync(file.path);
            }
          });
        });
      }

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

// PUT: Atualizar um card pelo ID com upload de arquivos
routerCards.put(
  "/:id",
  (req, res, next) => {
    handleUpload(req, res, (err) => {
      if (err) {
        if (err instanceof multer.MulterError) {
          if (err.code === "LIMIT_FILE_SIZE") {
            return res.status(400).json({
              success: false,
              error: "Arquivo muito grande. Tamanho máximo permitido: 5MB",
            });
          }
        }
        return res.status(400).json({
          success: false,
          error: err.message,
        });
      }
      next();
    });
  },
  processUploadedFiles,
  async (req, res) => {
    const { id } = req.params;
    const { imagem, icone, titulo } = req.body;

    // Validação do ID
    if (!id || id.length !== 24) {
      // Deleta arquivos uploadados se ID é inválido
      if (req.files) {
        Object.values(req.files).forEach((files) => {
          files.forEach((file) => {
            if (fs.existsSync(file.path)) {
              fs.unlinkSync(file.path);
            }
          });
        });
      }
      return res.status(400).json({
        success: false,
        error: "ID inválido",
      });
    }

    // Prepara updates
    const updates = {};
    if (imagem !== undefined) updates.imagem = imagem;
    if (icone !== undefined) updates.icone = icone;
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
      const cardAtual = await CardDisciplina.findById(id);
      if (!cardAtual) {
        return res.status(404).json({
          success: false,
          error: "Card não encontrado",
        });
      }

      // Deleta arquivos antigos se novos arquivos foram uploadados
      if (req.files && req.files.imagem) {
        await deleteOldFile(id, "imagem");
      }
      if (req.files && req.files.icone) {
        await deleteOldFile(id, "icone");
      }

      const cardAtualizado = await CardDisciplina.findByIdAndUpdate(
        id,
        updates,
        {
          new: true,
          runValidators: true,
        }
      );

      // Adiciona URLs completas na resposta
      const cardResponse = {
        ...cardAtualizado._doc,
        imagem: req.protocol + "://" + req.get("host") + cardAtualizado.imagem,
        icone: req.protocol + "://" + req.get("host") + cardAtualizado.icone,
        url: `${req.protocol}://${req.get("host")}/cards/disciplina/${
          cardAtualizado.slug
        }`,
      };

      res.json({
        success: true,
        message: "Card atualizado com sucesso",
        data: cardResponse,
      });
    } catch (err) {
      // Deleta arquivos uploadados se houve erro
      if (req.files) {
        Object.values(req.files).forEach((files) => {
          files.forEach((file) => {
            if (fs.existsSync(file.path)) {
              fs.unlinkSync(file.path);
            }
          });
        });
      }

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

// DELETE: Deletar um card pelo ID
routerCards.delete("/:id", async (req, res) => {
  const { id } = req.params;

  // Validação do ID
  if (!id || id.length !== 24) {
    return res.status(400).json({
      success: false,
      error: "ID inválido",
    });
  }

  try {
    const card = await CardDisciplina.findById(id);

    if (!card) {
      return res.status(404).json({
        success: false,
        error: "Card não encontrado",
      });
    }

    // Deleta os arquivos associados
    if (card.imagem) {
      const imagemPath = path.join(__dirname, "..", card.imagem);
      if (fs.existsSync(imagemPath)) {
        fs.unlinkSync(imagemPath);
      }
    }

    if (card.icone) {
      const iconePath = path.join(__dirname, "..", card.icone);
      if (fs.existsSync(iconePath)) {
        fs.unlinkSync(iconePath);
      }
    }

    // Deleta o card do banco de dados
    await CardDisciplina.findByIdAndDelete(id);

    res.json({
      success: true,
      message: "Card e arquivos associados deletados com sucesso",
      data: card,
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
