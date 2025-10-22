// routes/relacionamentos.cjs - CORREÇÃO COMPLETA
const express = require("express");
const routerRelacionamentos = express.Router();
const CardDisciplina = require("../../models/cardDisciplina.cjs");
const Professor = require("../../models/professor.cjs");
const Aluno = require("../../models/aluno.cjs");
const auth = require("../../middleware/auth.cjs");

// Adicionar professor à disciplina - CORREÇÃO
routerRelacionamentos.post("/:disciplinaId/professores/:professorId", 
  auth(["admin", "professor"]), 
  async (req, res) => {
    try {
      const { disciplinaId, professorId } = req.params;
      const userId = req.user.id;
      const userRole = req.user.role;

      console.log('=== ADD PROFESSOR ===');
      console.log('Disciplina ID:', disciplinaId);
      console.log('Professor ID:', professorId);
      console.log('User ID:', userId);

      const disciplina = await CardDisciplina.findById(disciplinaId);
      if (!disciplina) {
        console.log('❌ Disciplina não encontrada');
        return res.status(404).json({
          success: false,
          error: "Disciplina não encontrada",
        });
      }

      // Verificar permissão
      if (userRole !== "admin") {
        const isProfessor = disciplina.professores.some(
          prof => prof.toString() === userId
        );
        
        if (!isProfessor) {
          console.log('❌ Usuário não é professor da disciplina');
          return res.status(403).json({
            success: false,
            error: "Apenas professores desta disciplina podem adicionar outros professores",
          });
        }
      }

      const professor = await Professor.findById(professorId);
      if (!professor) {
        console.log('❌ Professor não encontrado');
        return res.status(404).json({
          success: false,
          error: "Professor não encontrado",
        });
      }

      if (disciplina.professores.includes(professorId)) {
        console.log('❌ Professor já está na disciplina');
        return res.status(400).json({
          success: false,
          error: "Professor já está associado a esta disciplina",
        });
      }

      disciplina.professores.push(professorId);
      professor.disciplinas.push(disciplinaId);

      await Promise.all([disciplina.save(), professor.save()]);

      console.log('✅ Professor adicionado com sucesso');
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
  }
);

// Remover professor da disciplina - CORREÇÃO
routerRelacionamentos.delete("/:disciplinaId/professores/:professorId", 
  auth(["admin", "professor"]), 
  async (req, res) => {
    try {
      const { disciplinaId, professorId } = req.params;
      const userId = req.user.id;
      const userRole = req.user.role;

      console.log('=== REMOVE PROFESSOR ===');
      console.log('Disciplina ID:', disciplinaId);
      console.log('Professor ID:', professorId);

      const disciplina = await CardDisciplina.findById(disciplinaId);
      if (!disciplina) {
        return res.status(404).json({
          success: false,
          error: "Disciplina não encontrada",
        });
      }

      if (disciplina.criadoPor.toString() === professorId) {
        return res.status(400).json({
          success: false,
          error: "Não é possível remover o criador da disciplina",
        });
      }

      // Verificar permissão
      if (userRole !== "admin") {
        const isProfessor = disciplina.professores.some(
          prof => prof.toString() === userId
        );
        
        if (!isProfessor) {
          return res.status(403).json({
            success: false,
            error: "Apenas professores desta disciplina podem remover outros professores",
          });
        }
      }

      const professor = await Professor.findById(professorId);
      if (!professor) {
        return res.status(404).json({
          success: false,
          error: "Professor não encontrado",
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
  }
);

// Adicionar aluno à disciplina - CORREÇÃO
routerRelacionamentos.post("/:disciplinaId/alunos/:alunoId", 
  auth(["admin", "professor"]), 
  async (req, res) => {
    try {
      const { disciplinaId, alunoId } = req.params;
      const userId = req.user.id;
      const userRole = req.user.role;

      console.log('=== ADD ALUNO ===');
      console.log('Disciplina ID:', disciplinaId);
      console.log('Aluno ID:', alunoId);

      const disciplina = await CardDisciplina.findById(disciplinaId);
      if (!disciplina) {
        return res.status(404).json({
          success: false,
          error: "Disciplina não encontrada",
        });
      }

      // Verificar permissão
      if (userRole !== "admin") {
        const isProfessor = disciplina.professores.some(
          prof => prof.toString() === userId
        );
        
        if (!isProfessor) {
          return res.status(403).json({
            success: false,
            error: "Apenas professores desta disciplina podem adicionar alunos",
          });
        }
      }

      const aluno = await Aluno.findById(alunoId);
      if (!aluno) {
        return res.status(404).json({
          success: false,
          error: "Aluno não encontrado",
        });
      }

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
  }
);

// Remover aluno da disciplina - CORREÇÃO
routerRelacionamentos.delete("/:disciplinaId/alunos/:alunoId", 
  auth(["admin", "professor"]), 
  async (req, res) => {
    try {
      const { disciplinaId, alunoId } = req.params;
      const userId = req.user.id;
      const userRole = req.user.role;

      console.log('=== REMOVE ALUNO ===');
      console.log('Disciplina ID:', disciplinaId);
      console.log('Aluno ID:', alunoId);

      const disciplina = await CardDisciplina.findById(disciplinaId);
      if (!disciplina) {
        return res.status(404).json({
          success: false,
          error: "Disciplina não encontrada",
        });
      }

      // Verificar permissão
      if (userRole !== "admin") {
        const isProfessor = disciplina.professores.some(
          prof => prof.toString() === userId
        );
        
        if (!isProfessor) {
          return res.status(403).json({
            success: false,
            error: "Apenas professores desta disciplina podem remover alunos",
          });
        }
      }

      const aluno = await Aluno.findById(alunoId);
      if (!aluno) {
        return res.status(404).json({
          success: false,
          error: "Aluno não encontrado",
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
  }
);

module.exports = routerRelacionamentos;