// middleware/comentarioAuth.cjs
const Comentario = require("../models/comentario.cjs");
const CardDisciplina = require("../models/cardDisciplina.cjs");
const mongoose = require("mongoose"); // ADICIONAR ESTA LINHA

// Verificar acesso ao material/comentários (CORRIGIDO)
const verificarAcessoComentarios = async (req, res, next) => {
  try {
    const { materialId, topicoId, disciplinaId } = req.body;
    const usuario = req.user;

    console.log(`=== VERIFICANDO ACESSO COMENTÁRIOS: User ${usuario.id} (${usuario.role}) ===`);
    console.log('📋 Dados recebidos:', { materialId, topicoId, disciplinaId });

    // CORREÇÃO: Buscar disciplina de forma flexível
    let disciplina;
    
    // Primeiro tentar buscar por slug (caso mais comum)
    disciplina = await CardDisciplina.findOne({ slug: disciplinaId })
      .select('professores alunos titulo _id');

    // Se não encontrou por slug, tentar por ObjectId
    if (!disciplina && mongoose.Types.ObjectId.isValid(disciplinaId)) {
      disciplina = await CardDisciplina.findById(disciplinaId)
        .select('professores alunos titulo _id');
    }

    if (!disciplina) {
      console.log('❌ Disciplina não encontrada:', disciplinaId);
      return res.status(404).json({
        success: false,
        message: "Disciplina não encontrada"
      });
    }

    console.log('✅ Disciplina encontrada:', disciplina.titulo);

    // Admin tem acesso total
    if (usuario.role === "admin") {
      console.log('✅ Acesso comentários: ADMIN');
      req.disciplina = disciplina;
      return next();
    }

    // Verificar se professor está na disciplina
    if (usuario.role === "professor") {
      const isProfessor = disciplina.professores.some(
        prof => prof.toString() === usuario.id
      );
      
      if (isProfessor) {
        console.log('✅ Acesso comentários: PROFESSOR da disciplina');
        req.disciplina = disciplina;
        return next();
      }
    }

    // Verificar se aluno está matriculado
    if (usuario.role === "aluno") {
      const isAluno = disciplina.alunos.some(
        aluno => aluno.toString() === usuario.id
      );
      
      if (isAluno) {
        console.log('✅ Acesso comentários: ALUNO matriculado');
        req.disciplina = disciplina;
        return next();
      }
    }

    console.log('❌ Acesso comentários negado');
    return res.status(403).json({
      success: false,
      message: "Acesso negado. Você não tem permissão para acessar estes comentários."
    });

  } catch (error) {
    console.error("💥 Erro na verificação de acesso:", error);
    res.status(500).json({
      success: false,
      message: "Erro interno do servidor"
    });
  }
};

module.exports = {
  verificarPermissaoComentario,
  verificarProfessorOuAdmin,
  verificarAcessoComentarios
};