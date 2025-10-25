const express = require("express");
const router = express.Router();
const Notificacoes = require("../models/notificacoes.cjs");
const Professor = require("../models/professor.cjs");
const Disciplina = require("../models/cardDisciplina.cjs");
const auth = require("../middleware/auth.cjs");

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

// POST /api/notificacoes/professor - Enviar mensagem para múltiplas disciplinas
// POST /api/notificacoes/professor - Adicione mais debug
router.post("/professor", auth(), async (req, res) => {
  try {
    console.log("=== 📨 RECEBENDO MENSAGEM ===");
    console.log("📝 Body recebido:", req.body);
    console.log("👤 User:", req.user);

    const { mensagem, disciplinas } = req.body;
    const professorId = req.user.id;
    const userType = req.user.role;

    // Validar entrada
    if (!mensagem || !disciplinas || !Array.isArray(disciplinas)) {
      console.log(" Validação falhou:", { mensagem, disciplinas });
      return res.status(400).json({
        success: false,
        message: "Mensagem e lista de disciplinas são obrigatórios",
      });
    }

    console.log(" Validação passou");

    // Para professores não-admin, verificar se tem permissão nas disciplinas
    if (userType === "professor") {
      console.log(" Verificando permissões do professor...");
      const professor = await Professor.findById(professorId);

      if (!professor) {
        console.log(" Professor não encontrado:", professorId);
        return res.status(404).json({
          success: false,
          message: "Professor não encontrado",
        });
      }

      const disciplinasNaoAutorizadas = disciplinas.filter(
        (disciplinaId) => !professor.disciplinas.includes(disciplinaId)
      );

      if (disciplinasNaoAutorizadas.length > 0) {
        console.log(" Disciplinas não autorizadas:", disciplinasNaoAutorizadas);
        return res.status(403).json({
          success: false,
          message: "Professor não autorizado para algumas disciplinas",
          disciplinasNaoAutorizadas,
        });
      }
    }

    console.log(" Permissões validadas");

    // Criar notificação para cada disciplina
    const notificacoes = [];
    for (const disciplinaId of disciplinas) {
      console.log(`📚 Processando disciplina: ${disciplinaId}`);

      // Verificar se a disciplina existe
      const disciplina = await Disciplina.findById(disciplinaId);
      if (!disciplina) {
        console.log(` Disciplina ${disciplinaId} não encontrada, pulando...`);
        continue;
      }

      console.log(` Disciplina encontrada: ${disciplina.titulo}`);

      const notificacao = new Notificacoes({
        mensagem: mensagem,
        disciplina: disciplinaId,
        professor: professorId,
      });

      await notificacao.save();
      notificacoes.push(notificacao);
      console.log(` Notificação criada para disciplina ${disciplina.titulo}`);
    }

    console.log(` Todas notificações criadas: ${notificacoes.length}`);

    res.status(201).json({
      success: true,
      message: "Notificações criadas com sucesso",
      notificacoesCriadas: notificacoes.length,
      notificacoes,
    });
  } catch (error) {
    console.error(" Erro ao criar notificações:", error);
    res.status(500).json({
      success: false,
      message: "Erro interno ao criar notificações",
      error: error.message,
      stack: process.env.NODE_ENV === "development" ? error.stack : undefined,
    });
  }
});
// GET /api/professores/:id/disciplinas - Listar disciplinas do professor
router.get("/professores/:id/disciplinas", auth(), async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const userType = req.user.role;

    // Verificar permissões
    if (userType === "professor" && userId !== id) {
      return res.status(403).json({
        success: false,
        message: "Acesso não autorizado",
      });
    }

    const professor = await Professor.findById(id).populate(
      "disciplinas",
      "titulo nome _id"
    );

    if (!professor) {
      return res.status(404).json({
        success: false,
        message: "Professor não encontrado",
      });
    }

    res.json({
      success: true,
      disciplinas: professor.disciplinas,
    });
  } catch (error) {
    console.error("Erro ao listar disciplinas do professor:", error);
    res.status(500).json({
      success: false,
      message: "Erro ao listar disciplinas",
      error: error.message,
    });
  }
});

// GET /api/disciplinas - Listar todas as disciplinas (admin) ou do professor
router.get("/disciplinas", auth(), async (req, res) => {
  try {
    const userType = req.user.role;
    const userId = req.user.id;

    console.log("🔐 User info:", { userType, userId }); // ← ADD DEBUG

    let disciplinas;

    if (userType === "admin") {
      // Admin vê todas as disciplinas
      disciplinas = await Disciplina.find({}).select("titulo nome _id");
      console.log("👑 Admin - Todas disciplinas:", disciplinas.length);
    } else if (userType === "professor") {
      // Professor vê apenas suas disciplinas
      const professor = await Professor.findById(userId).populate(
        "disciplinas",
        "titulo nome _id"
      );
      disciplinas = professor?.disciplinas || [];
      console.log("👨‍🏫 Professor - Disciplinas:", disciplinas.length);
    } else {
      console.log("❌ Acesso negado - Tipo de usuário:", userType);
      return res.status(403).json({
        success: false,
        message:
          "Acesso não autorizado. Apenas admin e professores podem acessar.",
        userType: userType, // ← Mostra qual tipo foi recebido
      });
    }

    res.json({
      success: true,
      disciplinas,
    });
  } catch (error) {
    console.error("Erro ao listar disciplinas:", error);
    res.status(500).json({
      success: false,
      message: "Erro ao listar disciplinas",
      error: error.message,
    });
  }
});

// GET /api/notificacoes/professor - Versão corrigida
router.get("/professor", auth(), async (req, res) => {
  try {
    const { professorId } = req.query;
    const userId = req.user.id;
    const userType = req.user.role;

    let query = {};

    if (userType === "professor") {
      query.professor = userId;
    } else if (userType === "admin" && professorId) {
      query.professor = professorId;
    }

    // Buscar apenas os dados básicos primeiro
    const notificacoes = await Notificacoes.find(query).sort({
      dataCriacao: -1,
    });

    console.log("📨 Notificações encontradas:", notificacoes.length);

    // Se não há notificações, retornar array vazio
    if (notificacoes.length === 0) {
      return res.json({
        success: true,
        mensagens: [],
      });
    }

    // Agrupar por mensagem e data (para mensagens enviadas para múltiplas disciplinas)
    const mensagensAgrupadas = {};

    for (const notificacao of notificacoes) {
      // CORREÇÃO: Usar data segura
      const dataSegura =
        notificacao.dataCriacao || notificacao.createdAt || new Date();
      const dataFormatada = dataSegura.toISOString().split("T")[0];

      const chave = `${notificacao.mensagem}_${notificacao.professor}_${dataFormatada}`;

      if (!mensagensAgrupadas[chave]) {
        // Buscar nome do professor uma vez por grupo
        let professorNome = "Professor";
        try {
          const professor = await Professor.findById(
            notificacao.professor
          ).select("nome");
          if (professor) professorNome = professor.nome;
        } catch (e) {
          console.log("Erro ao buscar professor:", e);
        }

        mensagensAgrupadas[chave] = {
          _id: notificacao._id,
          mensagem: notificacao.mensagem,
          dataCriacao: dataSegura,
          professorNome: professorNome,
          disciplinas: [],
        };
      }

      // Buscar nome da disciplina para esta notificação
      let disciplinaNome = "Disciplina";
      try {
        const disciplina = await Disciplina.findById(
          notificacao.disciplina
        ).select("titulo nome");
        if (disciplina) disciplinaNome = disciplina.titulo || disciplina.nome;
      } catch (e) {
        console.log("Erro ao buscar disciplina:", e);
      }

      mensagensAgrupadas[chave].disciplinas.push({
        _id: notificacao.disciplina,
        titulo: disciplinaNome,
      });
    }

    const resultado = Object.values(mensagensAgrupadas);

    res.json({
      success: true,
      mensagens: resultado,
    });
  } catch (error) {
    console.error("Erro ao listar mensagens do professor:", error);
    res.status(500).json({
      success: false,
      message: "Erro ao listar mensagens",
      error: error.message,
    });
  }
});

// GET /api/professores/:id - Obter informações do professor
router.get("/professores/:id", auth(), async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const userType = req.user.role;

    // Verificar permissões
    if (userType === "professor" && userId !== id) {
      return res.status(403).json({
        success: false,
        message: "Acesso não autorizado",
      });
    }

    const professor = await Professor.findById(id).select("nome email tipo");

    if (!professor) {
      return res.status(404).json({
        success: false,
        message: "Professor não encontrado",
      });
    }

    res.json({
      success: true,
      professor,
    });
  } catch (error) {
    console.error("Erro ao obter informações do professor:", error);
    res.status(500).json({
      success: false,
      message: "Erro ao obter informações",
      error: error.message,
    });
  }
});

module.exports = router;
