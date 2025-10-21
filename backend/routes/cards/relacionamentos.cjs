const express = require("express");
const routerRelacionamentos = express.Router();
const CardDisciplina = require("../../models/cardDisciplina.cjs");
const Professor = require("../../models/professor.cjs");
const Aluno = require("../../models/aluno.cjs");
const auth = require("../../middleware/auth.cjs");
const { verificarProfessorDisciplina } = require("../../middleware/disciplinaAuth.cjs");

// Adicionar professor à disciplina
routerRelacionamentos.post("/:disciplinaId/professores/:professorId", auth(["admin", "professor"]), verificarProfessorDisciplina, async (req, res) => {
  try {
    const { disciplinaId, professorId } = req.params;

    const disciplina = await CardDisciplina.findById(disciplinaId);
    const professor = await Professor.findById(professorId);

    if (!disciplina || !professor) {
      return res.status(404).json({
        success: false,
        error: "Disciplina ou professor não encontrado",
      });
    }

    // Verificar se já não está associado
    if (disciplina.professores.includes(professorId)) {
      return res.status(400).json({
        success: false,
        error: "Professor já está associado a esta disciplina",
      });
    }

    disciplina.professores.push(professorId);
    professor.disciplinas.push(disciplinaId);

    await Promise.all([disciplina.save(), professor.save()]);

    res.json({
      success: true,
      message: "Professor adicionado à disciplina com sucesso",
    });
  } catch (err) {
    console.error("Erro ao adicionar professor:", err);
    res.status(500).json({
      success: false,
      error: "Erro interno do servidor",
    });
  }
});

// Remover professor da disciplina
routerRelacionamentos.delete("/:disciplinaId/professores/:professorId", auth(["admin", "professor"]), verificarProfessorDisciplina, async (req, res) => {
  try {
    const { disciplinaId, professorId } = req.params;

    // Não permitir remover o criador da disciplina
    const disciplina = await CardDisciplina.findById(disciplinaId);
    if (disciplina.criadoPor.toString() === professorId) {
      return res.status(400).json({
        success: false,
        error: "Não é possível remover o criador da disciplina",
      });
    }

    const professor = await Professor.findById(professorId);

    if (!disciplina || !professor) {
      return res.status(404).json({
        success: false,
        error: "Disciplina ou professor não encontrado",
      });
    }

    disciplina.professores.pull(professorId);
    professor.disciplinas.pull(disciplinaId);

    await Promise.all([disciplina.save(), professor.save()]);

    res.json({
      success: true,
      message: "Professor removido da disciplina com sucesso",
    });
  } catch (err) {
    console.error("Erro ao remover professor:", err);
    res.status(500).json({
      success: false,
      error: "Erro interno do servidor",
    });
  }
});

// Adicionar aluno à disciplina
routerRelacionamentos.post("/:disciplinaId/alunos/:alunoId", auth(["admin", "professor"]), verificarProfessorDisciplina, async (req, res) => {
  try {
    const { disciplinaId, alunoId } = req.params;

    const disciplina = await CardDisciplina.findById(disciplinaId);
    const aluno = await Aluno.findById(alunoId);

    if (!disciplina || !aluno) {
      return res.status(404).json({
        success: false,
        error: "Disciplina ou aluno não encontrado",
      });
    }

    // Verificar se já não está associado
    if (disciplina.alunos.includes(alunoId)) {
      return res.status(400).json({
        success: false,
        error: "Aluno já está matriculado nesta disciplina",
      });
    }

    disciplina.alunos.push(alunoId);
    aluno.disciplinas.push(disciplinaId);

    await Promise.all([disciplina.save(), aluno.save()]);

    res.json({
      success: true,
      message: "Aluno matriculado na disciplina com sucesso",
    });
  } catch (err) {
    console.error("Erro ao matricular aluno:", err);
    res.status(500).json({
      success: false,
      error: "Erro interno do servidor",
    });
  }
});

// Remover aluno da disciplina
routerRelacionamentos.delete("/:disciplinaId/alunos/:alunoId", auth(["admin", "professor"]), verificarProfessorDisciplina, async (req, res) => {
  try {
    const { disciplinaId, alunoId } = req.params;

    const disciplina = await CardDisciplina.findById(disciplinaId);
    const aluno = await Aluno.findById(alunoId);

    if (!disciplina || !aluno) {
      return res.status(404).json({
        success: false,
        error: "Disciplina ou aluno não encontrado",
      });
    }

    disciplina.alunos.pull(alunoId);
    aluno.disciplinas.pull(disciplinaId);

    await Promise.all([disciplina.save(), aluno.save()]);

    res.json({
      success: true,
      message: "Aluno removido da disciplina com sucesso",
    });
  } catch (err) {
    console.error("Erro ao remover aluno:", err);
    res.status(500).json({
      success: false,
      error: "Erro interno do servidor",
    });
  }
});

module.exports = routerRelacionamentos;