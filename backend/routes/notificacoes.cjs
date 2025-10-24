const express = require("express");
const router = express.Router();
const Notificacoes = require("../models/nota.cjs");
const Professor = require("../models/professor.cjs");
const Disciplina = require("../models/cardDisciplina.cjs"); // Certifique-se de ter este model
const authMiddleware = require("../middleware/auth.cjs"); // Assumindo que você tem um middleware de autenticação

// Criar nova notificação
router.post("/criar", authMiddleware, async (req, res) => {
  try {
    const { mensagem, disciplinaId } = req.body;
    const professorId = req.user.id; // Obtido do middleware de autenticação

    // Validar entrada
    if (!mensagem || !disciplinaId) {
      return res.status(400).json({
        success: false,
        message: "Mensagem e disciplina são obrigatórios"
      });
    }

    // Verificar se a disciplina existe
    const disciplina = await Disciplina.findById(disciplinaId);
    if (!disciplina) {
      return res.status(404).json({
        success: false,
        message: "Disciplina não encontrada"
      });
    }

    // Verificar se o professor está autorizado para a disciplina
    const professor = await Professor.findById(professorId);
    if (!professor.disciplinas.includes(disciplinaId)) {
      return res.status(403).json({
        success: false,
        message: "Professor não autorizado para esta disciplina"
      });
    }

    const notificacao = new Notificacoes({
      mensagem,
      disciplina: disciplinaId,
      professor: professorId
    });

    await notificacao.save();

    res.status(201).json({
      success: true,
      message: "Notificação criada com sucesso",
      notificacao
    });
  } catch (error) {
    console.error("Erro ao criar notificação:", error);
    res.status(500).json({
      success: false,
      message: "Erro ao criar notificação",
      error: error.message
    });
  }
});

// Listar notificações por disciplina
router.get("/disciplina/:disciplinaId", authMiddleware, async (req, res) => {
  try {
    const { disciplinaId } = req.params;

    // Verificar se a disciplina existe
    const disciplina = await Disciplina.findById(disciplinaId);
    if (!disciplina) {
      return res.status(404).json({
        success: false,
        message: "Disciplina não encontrada"
      });
    }

    const notificacoes = await Notificacoes.find({ disciplina: disciplinaId })
      .populate("professor", "nome")
      .sort({ dataCriacao: -1 });

    res.json({
      success: true,
      notificacoes
    });
  } catch (error) {
    console.error("Erro ao listar notificações:", error);
    res.status(500).json({
      success: false,
      message: "Erro ao listar notificações",
      error: error.message
    });
  }
});

// Listar todas as notificações
router.get("/todas", authMiddleware, async (req, res) => {
    try {
      // Verificar se o usuário é admin (opcional, dependendo dos requisitos)
      const professor = await Professor.findById(req.user.id);
      if (professor.tipo !== "admin") {
        return res.status(403).json({
          success: false,
          message: "Apenas administradores podem acessar todas as notificações"
        });
      }
  
      const notificacoes = await Notificacoes.find({})
        .populate("professor", "nome")
        .populate("disciplina", "nome") // Assumindo que o model Disciplina tem um campo 'nome'
        .sort({ dataCriacao: -1 });
  
      res.json({
        success: true,
        notificacoes
      });
    } catch (error) {
      console.error("Erro ao listar todas as notificações:", error);
      res.status(500).json({
        success: false,
        message: "Erro ao listar todas as notificações",
        error: error.message
      });
    }
  });

  // Listar disciplinas do aluno
router.get("/disciplinas-aluno", authMiddleware, async (req, res) => {
    try {
      const userId = req.user.id;
  
      // Buscar disciplinas onde o aluno está matriculado
      const disciplinas = await Disciplina.find({ alunos: userId }).select("titulo _id slug");
  
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
module.exports = router;