// routes/cardsDisciplinas.cjs
const mongoose = require("mongoose");
const Nota = require("../../models/nota.cjs");
const express = require("express");
const multer = require("multer");
const path = require("path");
const routerCards = express.Router();
const CardDisciplina = require("../../models/cardDisciplina.cjs");
const Professor = require("../../models/professor.cjs");
const Aluno = require("../../models/aluno.cjs");
const auth = require("../../middleware/auth.cjs");
const {
  verificarProfessorDisciplina,
  verificarAcessoDisciplina,
} = require("../../middleware/disciplinaAuth.cjs");

// Configurações
const MAX_FILE_SIZE = 5 * 1024 * 1024;

// routes/cardsDisciplinas.cjs - CORREÇÃO DO MULTER

// Configuração do Multer CORRIGIDA
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

// Filtro CORRIGIDO para validar tipos de arquivo
const fileFilter = (req, file, cb) => {
  const allowedExtensions = /jpeg|jpg|png|gif|bmp|webp|svg/;
  const extname = allowedExtensions.test(
    path.extname(file.originalname).toLowerCase()
  );

  if (extname) {
    return cb(null, true);
  } else {
    cb(
      new Error(
        `Apenas arquivos de imagem são permitidos. Enviado: ${file.originalname}`
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

// Middleware para processar arquivos uploadados CORRIGIDO
const processUploadedFiles = (req, res, next) => {
  try {
    console.log("=== PROCESSANDO ARQUIVOS UPLOADADOS ===");
    console.log("Files recebidos:", req.files);

    if (req.files) {
      if (req.files.imagem) {
        let contentType = req.files.imagem[0].mimetype;
        // Se o mimetype for application/octet-stream, tentar determinar pelo nome do arquivo
        if (contentType === "application/octet-stream") {
          contentType = getMimeTypeFromExtension(
            req.files.imagem[0].originalname
          );
        }
        req.body.imagem = {
          data: req.files.imagem[0].buffer,
          contentType: contentType,
        };
        console.log("✅ Imagem processada:", {
          tamanho: req.files.imagem[0].buffer.length,
          contentType: contentType,
          nome: req.files.imagem[0].originalname,
        });
      }

      if (req.files.icone) {
        let contentType = req.files.icone[0].mimetype;
        // Se o mimetype for application/octet-stream, tentar determinar pelo nome do arquivo
        if (contentType === "application/octet-stream") {
          contentType = getMimeTypeFromExtension(
            req.files.icone[0].originalname
          );
        }
        req.body.icone = {
          data: req.files.icone[0].buffer,
          contentType: contentType,
        };
        console.log("✅ Ícone processado:", {
          tamanho: req.files.icone[0].buffer.length,
          contentType: contentType,
          nome: req.files.icone[0].originalname,
        });
      }
    } else {
      console.log("⚠️ Nenhum arquivo recebido");
    }

    next();
  } catch (error) {
    console.error("❌ Erro ao processar arquivos:", error);
    return res.status(400).json({
      success: false,
      error: "Erro ao processar arquivos enviados",
    });
  }
};

// Validação de campos
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

// Gerar slug
function generateSlug(title) {
  return title
    .toLowerCase()
    .trim()
    .replace(/[^\w\s-]/g, "")
    .replace(/[\s_-]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

// GET: Imagem
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

    res.set("Content-Type", card[tipo].contentType);
    res.set("Cache-Control", "no-cache, no-store, must-revalidate");
    res.set("Pragma", "no-cache");
    res.set("Expires", "0");

    res.send(card[tipo].data);
  } catch (err) {
    console.error("Erro ao buscar imagem:", err);
    res.status(500).json({
      success: false,
      error: "Erro interno do servidor ao buscar a imagem",
    });
  }
});

// GET: Disciplina por slug
routerCards.get(
  "/disciplina/:slug",
  auth(),
  verificarAcessoDisciplina,
  async (req, res) => {
    try {
      if (!req.disciplina) {
        return res.status(404).json({
          success: false,
          error: "Disciplina não encontrada",
        });
      }

      const card = await CardDisciplina.findById(req.disciplina._id)
        .populate("criadoPor", "nome email")
        .populate("professores", "nome email")
        .populate("alunos", "nome email ra");

      if (!card) {
        return res.status(404).json({
          success: false,
          error: "Disciplina não encontrada",
        });
      }

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
        imagem: `${req.protocol}://${req.get(
          "host"
        )}/api/cardsDisciplinas/imagem/${card._id}/imagem?t=${timestamp}`,
        icone: `${req.protocol}://${req.get(
          "host"
        )}/api/cardsDisciplinas/imagem/${card._id}/icone?t=${timestamp}`,
        url: `${req.protocol}://${req.get(
          "host"
        )}/api/cardsDisciplinas/disciplina/${card.slug}`,
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
  }
);

// GET: Todas as disciplinas
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
      .populate("criadoPor", "nome email")
      .populate("professores", "nome email")
      .populate("alunos", "nome email ra")
      .sort({ createdAt: -1 });

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
      imagem: `${req.protocol}://${req.get(
        "host"
      )}/api/cardsDisciplinas/imagem/${card._id}/imagem?t=${timestamp}`,
      icone: `${req.protocol}://${req.get(
        "host"
      )}/api/cardsDisciplinas/imagem/${card._id}/icone?t=${timestamp}`,
      url: `${req.protocol}://${req.get(
        "host"
      )}/api/cardsDisciplinas/disciplina/${card.slug}`,
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

// GET: Minhas disciplinas
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
      imagem: `${req.protocol}://${req.get(
        "host"
      )}/api/cardsDisciplinas/imagem/${card._id}/imagem?t=${timestamp}`,
      icone: `${req.protocol}://${req.get(
        "host"
      )}/api/cardsDisciplinas/imagem/${card._id}/icone?t=${timestamp}`,
      url: `${req.protocol}://${req.get(
        "host"
      )}/api/cardsDisciplinas/disciplina/${card.slug}`,
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

// POST: Criar disciplina
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

      // BUSCAR TODOS OS ADMINS PARA ADICIONAR AUTOMATICAMENTE
      const todosAdmins = await Professor.find({ tipo: "admin" }).select("_id");
      const adminIds = todosAdmins.map((admin) => admin._id.toString());

      console.log("=== ADMINS ENCONTRADOS:", adminIds);

      let professoresIds = [];
      if (professores && Array.isArray(professores)) {
        const professoresExistentes = await Professor.find({
          _id: { $in: professores },
        });

        if (professoresExistentes.length !== professores.length) {
          return res.status(400).json({
            success: false,
            error: "Um ou mais professores não foram encontrados",
          });
        }
        professoresIds = professores;
      }

      // ADICIONAR O USUÁRIO ATUAL SE NÃO ESTIVER NA LISTA
      if (!professoresIds.includes(userId)) {
        professoresIds.push(userId);
      }

      // ADICIONAR TODOS OS ADMINS AUTOMATICAMENTE
      adminIds.forEach((adminId) => {
        if (!professoresIds.includes(adminId)) {
          professoresIds.push(adminId);
        }
      });

      console.log("=== LISTA FINAL DE PROFESSORES:", professoresIds);

      let alunosIds = [];
      if (alunos && Array.isArray(alunos)) {
        const alunosExistentes = await Aluno.find({
          _id: { $in: alunos },
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
        criadoPor: userId,
      });

      await novoCard.save();

      // ATUALIZAR TODOS OS PROFESSORES (INCLUINDO ADMINS) COM A NOVA DISCIPLINA
      await Professor.updateMany(
        { _id: { $in: professoresIds } },
        { $addToSet: { disciplinas: novoCard._id } }
      );

      if (alunosIds.length > 0) {
        await Aluno.updateMany(
          { _id: { $in: alunosIds } },
          { $addToSet: { disciplinas: novoCard._id } }
        );
      }

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
        imagem: `${req.protocol}://${req.get(
          "host"
        )}/api/cardsDisciplinas/imagem/${novoCard._id}/imagem?t=${timestamp}`,
        icone: `${req.protocol}://${req.get(
          "host"
        )}/api/cardsDisciplinas/imagem/${novoCard._id}/icone?t=${timestamp}`,
        url: `${req.protocol}://${req.get(
          "host"
        )}/api/cardsDisciplinas/disciplina/${novoCard.slug}`,
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

// PUT: Atualizar disciplina
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

    if (professores !== undefined) {
      if (Array.isArray(professores)) {
        const professoresExistentes = await Professor.find({
          _id: { $in: professores },
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

    if (alunos !== undefined) {
      if (Array.isArray(alunos)) {
        const alunosExistentes = await Aluno.find({
          _id: { $in: alunos },
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

      if (professores !== undefined) {
        const professoresAntigos = await Professor.find({ disciplinas: id });
        const professoresAntigosIds = professoresAntigos.map((p) =>
          p._id.toString()
        );

        const professoresRemovidos = professoresAntigosIds.filter(
          (profId) => !updates.professores.includes(profId)
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
        const alunosAntigosIds = alunosAntigos.map((a) => a._id.toString());

        const alunosRemovidos = alunosAntigosIds.filter(
          (alunoId) => !updates.alunos.includes(alunoId)
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
        imagem: `${req.protocol}://${req.get(
          "host"
        )}/api/cardsDisciplinas/imagem/${
          cardAtualizado._id
        }/imagem?t=${timestamp}`,
        icone: `${req.protocol}://${req.get(
          "host"
        )}/api/cardsDisciplinas/imagem/${
          cardAtualizado._id
        }/icone?t=${timestamp}`,
        url: `${req.protocol}://${req.get(
          "host"
        )}/api/cardsDisciplinas/disciplina/${cardAtualizado.slug}`,
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

// DELETE: Deletar disciplina
routerCards.delete(
  "/:id",
  auth(["professor", "admin"]),
  verificarProfessorDisciplina,
  async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
      const { id } = req.params;

      if (!id || id.length !== 24) {
        await session.abortTransaction();
        return res.status(400).json({
          success: false,
          error: "ID inválido",
        });
      }

      // Verificar se a disciplina existe
      const card = await CardDisciplina.findById(id).session(session);
      if (!card) {
        await session.abortTransaction();
        return res.status(404).json({
          success: false,
          error: "Card não encontrado",
        });
      }

      // 1. Deletar todas as notas associadas a esta disciplina

      const resultadoNotas = await Nota.deleteMany({ disciplina: id }).session(
        session
      );
      console.log(`Notas deletadas: ${resultadoNotas.deletedCount}`);

      // 2. Deletar a disciplina
      await CardDisciplina.findByIdAndDelete(id).session(session);

      // 3. Remover referências dos professores
      const resultadoProfessores = await Professor.updateMany(
        { disciplinas: id },
        { $pull: { disciplinas: id } },
        { session }
      );

      // 4. Remover referências dos alunos
      const resultadoAlunos = await Aluno.updateMany(
        { disciplinas: id },
        { $pull: { disciplinas: id } },
        { session }
      );

      // Confirmar a transação
      await session.commitTransaction();

      console.log(
        `Disciplina "${card.titulo}" e dados associados deletados com sucesso`
      );

      res.json({
        success: true,
        message:
          "Disciplina e todos os dados associados foram deletados com sucesso",
        data: {
          _id: card._id,
          titulo: card.titulo,
          slug: card.slug,
          estatisticas: {
            notasDeletadas: resultadoNotas.deletedCount,
            professoresAtualizados: resultadoProfessores.modifiedCount,
            alunosAtualizados: resultadoAlunos.modifiedCount,
          },
        },
      });
    } catch (err) {
      // Reverter a transação em caso de erro
      await session.abortTransaction();

      console.error("Erro ao deletar disciplina:", err);

      if (err.name === "CastError") {
        return res.status(400).json({
          success: false,
          error: "ID inválido",
        });
      }

      res.status(500).json({
        success: false,
        error: "Erro interno do servidor ao deletar a disciplina",
        details:
          process.env.NODE_ENV === "development" ? err.message : undefined,
      });
    } finally {
      session.endSession();
    }
  }
);
module.exports = routerCards;
