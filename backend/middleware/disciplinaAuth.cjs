const CardDisciplina = require("../models/cardDisciplina.cjs");

const verificarAcessoDisciplina = async (req, res, next) => {
  try {
    const { slug } = req.params;
    const userId = req.user.id;
    const userRole = req.user.role;

    console.log(`=== VERIFICANDO ACESSO: User ${userId} (${userRole}) na disciplina ${slug} ===`);

    // Buscar disciplina pelo slug
    const disciplina = await CardDisciplina.findOne({ slug })
      .populate('professores', '_id nome email')
      .populate('alunos', '_id nome ra')
      .populate('criadoPor', '_id nome email');

    if (!disciplina) {
      console.log('❌ Disciplina não encontrada:', slug);
      return res.status(404).json({
        success: false,
        error: "Disciplina não encontrada",
      });
    }

    // ADMIN tem acesso a tudo
    if (userRole === "admin") {
      console.log('✅ Acesso concedido: ADMIN');
      req.disciplina = disciplina;
      return next();
    }

    // Verificar se o usuário está na lista de professores
    const isProfessor = disciplina.professores.some(
      prof => prof._id.toString() === userId
    );

    // Verificar se o usuário está na lista de alunos
    const isAluno = disciplina.alunos.some(
      aluno => aluno._id.toString() === userId
    );

    console.log(`📊 Verificação: Professor=${isProfessor}, Aluno=${isAluno}`);

    // PERMITIR ACESSO se for professor OU aluno da disciplina
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

// Middleware para ações de edição (apenas professores e admin)
const verificarProfessorDisciplina = async (req, res, next) => {
  try {
    const disciplinaId = req.params.id || req.params.disciplinaId;
    const userId = req.user.id;
    const userRole = req.user.role;

    console.log(`=== VERIFICANDO EDIÇÃO: User ${userId} (${userRole}) na disciplina ${disciplinaId} ===`);

    // ADMIN pode editar tudo
    if (userRole === "admin") {
      console.log('✅ Permissão de edição: ADMIN');
      return next();
    }

    // Buscar disciplina
    const disciplina = await CardDisciplina.findById(disciplinaId)
      .populate('professores', '_id');

    if (!disciplina) {
      return res.status(404).json({
        success: false,
        error: "Disciplina não encontrada",
      });
    }

    // Verificar se o usuário é professor da disciplina
    const isProfessor = disciplina.professores.some(
      prof => prof._id.toString() === userId
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