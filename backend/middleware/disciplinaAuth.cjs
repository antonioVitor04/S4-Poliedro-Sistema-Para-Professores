// middleware/disciplinaAuth.cjs - CORREÇÃO COMPLETA
const CardDisciplina = require("../models/cardDisciplina.cjs");

const verificarAcessoDisciplina = async (req, res, next) => {
  try {
    const { slug } = req.params;
    const userId = req.user.id;
    const userRole = req.user.role;

    console.log(`=== VERIFICANDO ACESSO: User ${userId} (${userRole}) na disciplina ${slug} ===`);

    const disciplina = await CardDisciplina.findOne({ slug });

    if (!disciplina) {
      console.log('❌ Disciplina não encontrada:', slug);
      return res.status(404).json({
        success: false,
        error: "Disciplina não encontrada",
      });
    }

    console.log('✅ Disciplina encontrada:', disciplina.titulo);

    if (userRole === "admin") {
      console.log('✅ Acesso concedido: ADMIN');
      req.disciplina = disciplina;
      return next();
    }

    const isProfessor = disciplina.professores.some(
      prof => prof.toString() === userId
    );

    const isAluno = disciplina.alunos.some(
      aluno => aluno.toString() === userId
    );

    console.log(`📊 Verificação: Professor=${isProfessor}, Aluno=${isAluno}`);

    if (isProfessor || isAluno) {
      console.log('✅ Acesso concedido: Usuário está na disciplina');
      req.disciplina = disciplina;
      return next();
    }

    console.log('❌ Acesso negado: Usuário não está na disciplina');
    return res.status(403).json({
      success: false,
      error: "Acesso negado. Você não está matriculado nesta disciplina.",
    });

  } catch (err) {
    console.error("💥 Erro no middleware de acesso:", err);
    return res.status(500).json({
      success: false,
      error: "Erro interno do servidor ao verificar acesso",
    });
  }
};

const verificarProfessorDisciplina = async (req, res, next) => {
  try {
    const { slug, id } = req.params;
    const userId = req.user.id;
    const userRole = req.user.role;

    console.log(`=== VERIFICANDO EDIÇÃO: User ${userId} (${userRole}) ===`);
    console.log('📋 Parâmetros:', { slug, id });

    if (userRole === "admin") {
      console.log('✅ Permissão de edição: ADMIN');
      return next();
    }

    let disciplina;
    if (slug) {
      console.log('🔍 Buscando disciplina por slug:', slug);
      disciplina = await CardDisciplina.findOne({ slug });
    } else if (id) {
      console.log('🔍 Buscando disciplina por ID:', id);
      disciplina = await CardDisciplina.findById(id);
    }

    if (!disciplina) {
      console.log('❌ Disciplina não encontrada');
      return res.status(404).json({
        success: false,
        error: "Disciplina não encontrada",
      });
    }

    console.log('✅ Disciplina encontrada:', disciplina.titulo);
    console.log('👥 Professores da disciplina:', disciplina.professores.map(p => p.toString()));
    console.log('👤 ID do usuário:', userId);

    const isProfessor = disciplina.professores.some(
      prof => prof.toString() === userId
    );

    if (isProfessor) {
      console.log('✅ Permissão de edição: PROFESSOR da disciplina');
      return next();
    }

    console.log('❌ Permissão de edição negada');
    return res.status(403).json({
      success: false,
      error: "Apenas professores desta disciplina podem realizar esta ação.",
    });

  } catch (err) {
    console.error("💥 Erro no middleware de edição:", err);
    return res.status(500).json({
      success: false,
      error: "Erro interno do servidor ao verificar permissões",
    });
  }
};

module.exports = {
  verificarAcessoDisciplina,
  verificarProfessorDisciplina
};