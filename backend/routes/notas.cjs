const express = require("express");
const routerNotas = express.Router();
const Nota = require("../models/nota.cjs");
const CardDisciplina = require("../models/cardDisciplina.cjs");
const Aluno = require("../models/aluno.cjs");
const auth = require("../middleware/auth.cjs");
const {
  verificarProfessorDisciplina,
  verificarPermissaoNota,  // NOVO
} = require("../middleware/disciplinaAuth.cjs");

// GET: Listar notas de uma disciplina (populada com aluno)
routerNotas.get(
  "/:disciplinaId",
  auth(["professor", "admin"]),
  verificarProfessorDisciplina,  // Garante permissão
  async (req, res) => {
    try {
      console.log("=== ROTA GET NOTAS EXECUTADA ===");
      const { disciplinaId } = req.params;

      const notas = await Nota.find({ disciplina: disciplinaId })
        .populate("aluno", "nome ra email")  // Fix: populate correto
        .populate("disciplina", "titulo");

      const notasWithDetails = notas.map((nota) => ({
        _id: nota._id,
        disciplina: nota.disciplina._id,
        aluno: nota.aluno._id,
        alunoNome: nota.aluno ? nota.aluno.nome : null,  // Fix: check null
        alunoRa: nota.aluno ? nota.aluno.ra : null,
        avaliacoes: nota.avaliacoes,
        createdAt: nota.createdAt,
        updatedAt: nota.updatedAt,
      }));

      res.json({
        success: true,
        count: notas.length,
        data: notasWithDetails,
      });
    } catch (err) {
      console.error("Erro ao buscar notas:", err);
      res.status(500).json({
        success: false,
        error: "Erro interno do servidor ao buscar notas",
      });
    }
  }
);

// POST: Criar nova nota para aluno em disciplina
routerNotas.post(
  "/", 
  auth(["professor", "admin"]),
  async (req, res) => {
    try {
      console.log("=== ROTA POST NOTAS ===");
      console.log("Body:", req.body);
      
      const { disciplina, aluno, avaliacoes } = req.body;

      // NOVO: Check de permissão para professor (admin bypassa)
      if (req.user.role !== "admin") {
        const disciplinaDoc = await CardDisciplina.findById(disciplina);
        if (!disciplinaDoc) {
          return res.status(404).json({ success: false, error: "Disciplina não encontrada" });
        }
        const isProfessor = disciplinaDoc.professores.some(p => p.toString() === req.user.id);
        if (!isProfessor) {
          return res.status(403).json({ success: false, error: "Apenas professores desta disciplina podem criar notas" });
        }
      }

      // Validar existência
      const disciplinaExists = await CardDisciplina.findById(disciplina);
      const alunoExists = await Aluno.findById(aluno);
      if (!disciplinaExists || !alunoExists) {
        return res.status(404).json({
          success: false,
          error: "Disciplina ou aluno não encontrado",
        });
      }

      // Verificar se já existe nota para este aluno/disciplina
      const existingNota = await Nota.findOne({ disciplina, aluno });
      if (existingNota) {
        return res.status(400).json({
          success: false,
          error: "Nota já existe para este aluno na disciplina",
        });
      }

      const novaNota = new Nota({
        disciplina,
        aluno,
        avaliacoes: avaliacoes || [],
      });

      await novaNota.save();

      const populatedNota = await Nota.findById(novaNota._id).populate(
        "aluno",
        "nome ra"
      );

      const notaResponse = {
        _id: populatedNota._id,
        disciplina: populatedNota.disciplina,
        aluno: populatedNota.aluno._id,
        alunoNome: populatedNota.aluno.nome,
        alunoRa: populatedNota.aluno.ra,
        avaliacoes: populatedNota.avaliacoes,
        createdAt: populatedNota.createdAt,
        updatedAt: populatedNota.updatedAt,
      };

      res.status(201).json({
        success: true,
        message: "Nota criada com sucesso",
        data: notaResponse,
      });
    } catch (err) {
      console.error("Erro ao criar nota:", err);
      if (err.name === "ValidationError") {
        return res.status(400).json({
          success: false,
          error: "Dados inválidos",
          details: err.errors,
        });
      }
      res.status(500).json({
        success: false,
        error: "Erro interno do servidor ao criar nota",
      });
    }
  }
);

// PUT: Atualizar nota
routerNotas.put(
  "/:id", 
  auth(["professor", "admin"]),
  verificarPermissaoNota,  // NOVO: Verifica permissão via nota
  async (req, res) => {
    try {
      const { id } = req.params;
      const { avaliacoes } = req.body;

      const notaAtualizada = await Nota.findByIdAndUpdate(
        id,
        { avaliacoes, updatedAt: new Date() },
        { new: true, runValidators: true }
      ).populate("aluno", "nome ra");  // Fix: populate após update

      if (!notaAtualizada) {
        return res.status(404).json({
          success: false,
          error: "Nota não encontrada",
        });
      }

      const notaResponse = {
        _id: notaAtualizada._id,
        disciplina: notaAtualizada.disciplina,
        aluno: notaAtualizada.aluno._id,
        alunoNome: notaAtualizada.aluno ? notaAtualizada.aluno.nome : null,  // Fix: check null
        alunoRa: notaAtualizada.aluno ? notaAtualizada.aluno.ra : null,
        avaliacoes: notaAtualizada.avaliacoes,
        createdAt: notaAtualizada.createdAt,
        updatedAt: notaAtualizada.updatedAt,
      };

      res.json({
        success: true,
        message: "Nota atualizada com sucesso",
        data: notaResponse,
      });
    } catch (err) {
      console.error("Erro ao atualizar nota:", err);
      if (err.name === "ValidationError") {
        return res.status(400).json({
          success: false,
          error: "Dados inválidos",
          details: err.errors,
        });
      }
      res.status(500).json({
        success: false,
        error: "Erro interno do servidor ao atualizar nota",
      });
    }
  }
);

// DELETE: Deletar nota
routerNotas.delete(
  "/:id", 
  auth(["professor", "admin"]),
  verificarPermissaoNota,  // NOVO: Verifica permissão via nota
  async (req, res) => {
    try {
      const { id } = req.params;

      const notaDeletada = await Nota.findByIdAndDelete(id);

      if (!notaDeletada) {
        return res.status(404).json({
          success: false,
          error: "Nota não encontrada",
        });
      }

      res.json({
        success: true,
        message: "Nota deletada com sucesso",
        data: { _id: notaDeletada._id },
      });
    } catch (err) {
      console.error("Erro ao deletar nota:", err);
      res.status(500).json({
        success: false,
        error: "Erro interno do servidor ao deletar nota",
      });
    }
  }
);


// GET: Listar notas do aluno logado
routerNotas.get(
  "/aluno/minhas-notas",
  auth(["aluno", "professor", "admin"]),
  async (req, res) => {
    try {
      const alunoId = req.user.id; // ID do aluno logado

      const notas = await Nota.find({ aluno: alunoId })
        .populate("disciplina", "titulo descricao")
        .populate("aluno", "nome ra email");

      const notasFormatadas = notas.map((nota) => ({
        _id: nota._id,
        disciplina: nota.disciplina.titulo,
        disciplinaId: nota.disciplina._id,
        aluno: nota.aluno.nome,
        alunoRa: nota.aluno.ra,
        detalhes: nota.avaliacoes.map((av) => ({
          tipo: av.tipo,
          nota: av.nota,
          peso: av.peso,
        })),
        media: calcularMedia(nota.avaliacoes),
        createdAt: nota.createdAt,
        updatedAt: nota.updatedAt,
      }));

      res.json({
        success: true,
        count: notas.length,
        data: notasFormatadas,
      });
    } catch (err) {
      console.error("Erro ao buscar notas do aluno:", err);
      res.status(500).json({
        success: false,
        error: "Erro interno do servidor ao buscar notas",
      });
    }
  }
);

// Função auxiliar para calcular média
function calcularMedia(avaliacoes) {
  if (!avaliacoes || avaliacoes.length === 0) return 0;

  let somaPonderada = 0;
  let totalPesos = 0;

  avaliacoes.forEach((av) => {
    somaPonderada += av.nota * av.peso;
    totalPesos += av.peso;
  });

  return totalPesos > 0 ? somaPonderada / totalPesos : 0;
}

module.exports = routerNotas;

