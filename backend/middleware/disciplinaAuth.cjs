const CardDisciplina = require("../models/cardDisciplina.cjs");
const Nota = require("../models/nota.cjs");

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
        message: "Disciplina não encontrada",
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
      message: "Acesso negado. Você não está matriculado nesta disciplina.",
    });

  } catch (err) {
    console.error("💥 Erro no middleware de acesso:", err);
    return res.status(500).json({
      success: false,
      message: "Erro interno do servidor ao verificar acesso",
    });
  }
};

const verificarPermissaoNota = async (req, res, next) => {
  try {
    const { id } = req.params; // id da nota
    const userId = req.user.id;
    const userRole = req.user.role;

    console.log(`=== VERIFICANDO PERMISSÃO NOTA: User ${userId} (${userRole}) na nota ${id} ===`);

    if (userRole === "admin") {
      console.log('✅ Permissão nota: ADMIN');
      const nota = await Nota.findById(id).populate('aluno', 'nome ra').populate({ path: 'disciplina', select: 'titulo professores' });
      if (!nota) {
        return res.status(404).json({ success: false, message: "Nota não encontrada" });
      }
      if (!nota.disciplina) {
        console.log('⚠️ Populate falhou para disciplina da nota');
        return res.status(404).json({ success: false, message: "Disciplina da nota não encontrada" });
      }
      req.nota = nota;
      return next();
    }

    console.log('🔍 Buscando nota por ID:', id);
    const nota = await Nota.findById(id).populate({ path: 'disciplina', select: 'titulo professores' });
    if (!nota) {
      console.log('❌ Nota não encontrada:', id);
      return res.status(404).json({
        success: false,
        message: "Nota não encontrada",
      });
    }

    if (!nota.disciplina) {
      console.log('⚠️ Populate falhou para disciplina da nota');
      return res.status(404).json({ success: false, message: "Disciplina da nota não encontrada" });
    }

    console.log('✅ Nota encontrada. Disciplina:', nota.disciplina.titulo);

    const isProfessor = nota.disciplina.professores.some(
      prof => prof.toString() === userId
    );

    if (isProfessor) {
      console.log('✅ Permissão nota: PROFESSOR da disciplina');
      req.nota = nota;
      return next();
    }

    console.log('❌ Permissão nota negada');
    return res.status(403).json({
      success: false,
      message: "Apenas professores desta disciplina podem realizar esta ação.",
    });

  } catch (err) {
    console.error("💥 Erro no middleware de permissão nota:", err);
    return res.status(500).json({
      success: false,
      message: "Erro interno do servidor ao verificar permissões",
    });
  }
};

const verificarProfessorDisciplina = async (req, res, next) => {
  try {
    const { slug, id, disciplinaId } = req.params;
    const userId = req.user.id;
    const userRole = req.user.role;

    console.log(`=== VERIFICANDO EDIÇÃO: User ${userId} (${userRole}) ===`);
    console.log('📋 Parâmetros:', { slug, id, disciplinaId });

    if (userRole === "admin") {
      console.log('✅ Permissão de edição: ADMIN');
      let disciplina;
      if (disciplinaId) {
        console.log('🔍 Buscando disciplina por disciplinaId:', disciplinaId);
        disciplina = await CardDisciplina.findById(disciplinaId);
      } else if (slug) {
        console.log('🔍 Buscando disciplina por slug:', slug);
        disciplina = await CardDisciplina.findOne({ slug });
      } else if (id) {
        console.log('🔍 Buscando disciplina por ID:', id);
        disciplina = await CardDisciplina.findById(id);
      }
      if (!disciplina) {
        console.log('❌ Disciplina não encontrada para admin');
        return res.status(404).json({ success: false, message: "Disciplina não encontrada" });
      }
      req.disciplina = disciplina;
      return next();
    }

    let disciplina;
    
    if (disciplinaId) {
      console.log('🔍 Buscando disciplina por disciplinaId:', disciplinaId);
      disciplina = await CardDisciplina.findById(disciplinaId);
    } else if (slug) {
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
        message: "Disciplina não encontrada",
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
      req.disciplina = disciplina;
      return next();
    }

    console.log('❌ Permissão de edição negada');
    return res.status(403).json({
      success: false,
      message: "Apenas professores desta disciplina podem realizar esta ação.",
    });

  } catch (err) {
    console.error("💥 Erro no middleware de edição:", err);
    return res.status(500).json({
      success: false,
      message: "Erro interno do servidor ao verificar permissões",
    });
  }
};

module.exports = {
  verificarAcessoDisciplina,
  verificarProfessorDisciplina,
  verificarPermissaoNota
};