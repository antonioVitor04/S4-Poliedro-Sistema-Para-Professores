const express = require("express");
const router = express.Router();
const Notificacoes = require("../models/nota.cjs");
const Professor = require("../models/professor.cjs");
const Disciplina = require("../models/cardDisciplina.cjs"); // Certifique-se de ter este model
const auth = require("../middleware/auth.cjs"); // Assumindo que você tem um middleware de autenticação

// Criar nova notificação
router.post("/criar", auth(), async (req, res) => {
  try {
    const { mensagem, disciplinaId } = req.body;
    const professorId = req.user.id; // Obtido do middleware de autenticação

    // Validar entrada
    if (!mensagem || !disciplinaId) {
      return res.status(400).json({
        success: false,
        message: "Mensagem e disciplina são obrigatórios",
      });
    }

    // Verificar se a disciplina existe
    const disciplina = await Disciplina.findById(disciplinaId);
    if (!disciplina) {
      return res.status(404).json({
        success: false,
        message: "Disciplina não encontrada",
      });
    }

    // Verificar se o professor está autorizado para a disciplina
    const professor = await Professor.findById(professorId);
    if (!professor.disciplinas.includes(disciplinaId)) {
      return res.status(403).json({
        success: false,
        message: "Professor não autorizado para esta disciplina",
      });
    }

    const notificacao = new Notificacoes({
      mensagem,
      disciplina: disciplinaId,
      professor: professorId,
    });

    await notificacao.save();

    res.status(201).json({
      success: true,
      message: "Notificação criada com sucesso",
      notificacao,
    });
  } catch (error) {
    console.error("Erro ao criar notificação:", error);
    res.status(500).json({
      success: false,
      message: "Erro ao criar notificação",
      error: error.message,
    });
  }
});

// Listar notificações por disciplina (com verificação de matrícula)
router.get("/disciplina/:disciplinaId", auth(), async (req, res) => {
  try {
    const { disciplinaId } = req.params;
    const userId = req.user.id;

    console.log(
      "🔍 Buscando notificações da disciplina:",
      disciplinaId,
      "para user:",
      userId
    );

    // Verificar se a disciplina existe E se o aluno está matriculado
    const disciplina = await Disciplina.findOne({
      _id: disciplinaId,
      alunos: userId,
    });

    if (!disciplina) {
      console.log("❌ Disciplina não encontrada ou aluno não matriculado");
      return res.status(404).json({
        success: false,
        message: "Disciplina não encontrada ou você não está matriculado",
      });
    }

    // Buscar notificações SEM populate por enquanto
    const notificacoes = await Notificacoes.find({ disciplina: disciplinaId })
      // .populate("professor", "nome") // ⚠️ REMOVIDO TEMPORARIAMENTE
      .sort({ dataCriacao: -1 });

    console.log("✅ Notificações encontradas:", notificacoes.length);

    res.json({
      success: true,
      notificacoes,
    });
  } catch (error) {
    console.error("❌ Erro ao listar notificações:", error);
    res.status(500).json({
      success: false,
      message: "Erro ao listar notificações",
      error: error.message,
    });
  }
});
// Listar notificações do aluno - SEM POPULATE TEMPORARIAMENTE
router.get("/todas", auth(), async (req, res) => {
  try {
    console.log("🔍 Buscando notificações para aluno:", req.user.id);

    // Buscar disciplinas onde o aluno está matriculado
    const disciplinasAluno = await Disciplina.find({
      alunos: req.user.id,
    }).select("_id");

    const disciplinasIds = disciplinasAluno.map((disciplina) => disciplina._id);

    console.log("📚 Disciplinas do aluno:", disciplinasIds);

    if (disciplinasIds.length === 0) {
      return res.json({
        success: true,
        notificacoes: [],
        message: "Aluno não está matriculado em nenhuma disciplina",
      });
    }

    // Buscar notificações SEM populate por enquanto
    const notificacoes = await Notificacoes.find({
      disciplina: { $in: disciplinasIds },
    })
      // .populate("professor", "nome") // ⚠️ COMENTADO TEMPORARIAMENTE
      // .populate("disciplina", "nome") // ⚠️ COMENTADO TEMPORARIAMENTE
      .sort({ dataCriacao: -1 });

    console.log("✅ Notificações encontradas:", notificacoes.length);

    res.json({
      success: true,
      notificacoes,
    });
  } catch (error) {
    console.error("❌ Erro ao listar notificações do aluno:", error);
    res.status(500).json({
      success: false,
      message: "Erro ao listar notificações",
      error: error.message,
    });
  }
});
// Listar disciplinas do aluno
router.get("/disciplinas-aluno", auth(), async (req, res) => {
  try {
    const userId = req.user.id;

    // Buscar disciplinas onde o aluno está matriculado
    const disciplinas = await Disciplina.find({ alunos: userId }).select(
      "titulo _id slug"
    );

    console.log("📚 Disciplinas do aluno:", disciplinas.length);

    res.json({
      success: true,
      disciplinas,
    });
  } catch (error) {
    console.error("Erro ao listar disciplinas do aluno:", error);
    res.status(500).json({
      success: false,
      message: "Erro ao listar disciplinas",
      error: error.message,
    });
  }
});

// Marcar notificação como lida
router.patch("/:id/lida", auth(), async (req, res) => {
  try {
    const { id } = req.params;

    const notificacao = await Notificacoes.findByIdAndUpdate(
      id,
      { lida: true },
      { new: true }
    );

    if (!notificacao) {
      return res.status(404).json({
        success: false,
        message: "Notificação não encontrada",
      });
    }

    res.json({
      success: true,
      message: "Notificação marcada como lida",
      notificacao,
    });
  } catch (error) {
    console.error("Erro ao marcar notificação como lida:", error);
    res.status(500).json({
      success: false,
      message: "Erro ao marcar notificação como lida",
      error: error.message,
    });
  }
});

// Toggle favorita
router.patch("/:id/favorita", auth(), async (req, res) => {
  try {
    const { id } = req.params;
    const { isFavorita } = req.body;

    const notificacao = await Notificacoes.findByIdAndUpdate(
      id,
      { favorita: isFavorita },
      { new: true }
    );

    if (!notificacao) {
      return res.status(404).json({
        success: false,
        message: "Notificação não encontrada",
      });
    }

    res.json({
      success: true,
      message: `Notificação ${
        isFavorita ? "marcada" : "desmarcada"
      } como favorita`,
      notificacao,
    });
  } catch (error) {
    console.error("Erro ao atualizar favorita:", error);
    res.status(500).json({
      success: false,
      message: "Erro ao atualizar favorita",
      error: error.message,
    });
  }
});

module.exports = router;
