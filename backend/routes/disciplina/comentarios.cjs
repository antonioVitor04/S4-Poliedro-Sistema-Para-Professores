const express = require("express");
const router = express.Router();
const Comentario = require("../../models/comentario.cjs");
const CardDisciplina = require("../../models/cardDisciplina.cjs");
const auth = require("../../middleware/auth.cjs");
const mongoose = require("mongoose");

// GET /comentarios/material/:materialId - Buscar comentários de um material
router.get("/material/:materialId", auth(), async (req, res) => {
  try {
    const { materialId } = req.params;
    const pagina = parseInt(req.query.pagina) || 1;
    const limite = parseInt(req.query.limite) || 20;

    console.log(`=== BUSCANDO COMENTÁRIOS: materialId=${materialId} ===`);

    // Buscar comentários diretamente
    const comentarios = await Comentario.buscarPorMaterial(materialId, pagina, limite);
    
    res.json({
      success: true,
      data: comentarios,
      paginacao: {
        pagina,
        limite,
        total: comentarios.length
      }
    });
  } catch (error) {
    console.error("Erro ao buscar comentários:", error);
    res.status(500).json({
      success: false,
      message: "Erro interno do servidor ao buscar comentários",
      error: error.message
    });
  }
});

// routes/comentarios.cjs - CORREÇÃO NO MÉTODO POST
router.post("/", auth(), async (req, res) => {
  try {
    const { materialId, topicoId, disciplinaId, texto } = req.body;
    const userId = req.user.id;
    const userRole = req.user.role;

    console.log(`=== CRIANDO COMENTÁRIO ===`);
    console.log("Dados recebidos:", { materialId, topicoId, disciplinaId, texto, userId, userRole });

    // Validações básicas
    if (!materialId || !topicoId || !disciplinaId || !texto) {
      return res.status(400).json({
        success: false,
        message: "Dados incompletos. materialId, topicoId, disciplinaId e texto são obrigatórios."
      });
    }

    if (texto.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: "O texto do comentário não pode estar vazio."
      });
    }

    let disciplinaObjectId = disciplinaId;
    let disciplinaSlug = disciplinaId;

    // VERIFICAÇÃO: Se disciplinaId NÃO é um ObjectId válido, buscar pelo slug
    if (!mongoose.Types.ObjectId.isValid(disciplinaId)) {
      console.log(`🔍 Buscando disciplina por slug: ${disciplinaId}`);
      
      const disciplina = await CardDisciplina.findOne({ slug: disciplinaId });
      if (!disciplina) {
        return res.status(404).json({
          success: false,
          message: "Disciplina não encontrada"
        });
      }
      
      disciplinaObjectId = disciplina._id;
      disciplinaSlug = disciplina.slug;
      
      console.log(`✅ Disciplina encontrada: ${disciplina.titulo}, ID: ${disciplinaObjectId}, Slug: ${disciplinaSlug}`);
    } else {
      // Se é um ObjectId válido, buscar a disciplina para obter o slug
      const disciplina = await CardDisciplina.findById(disciplinaId);
      if (disciplina) {
        disciplinaSlug = disciplina.slug;
      }
    }

    // VERIFICAÇÃO DE ACESSO CORRIGIDA - USANDO O MÉTODO DIRETO
    console.log(`🔍 Verificando acesso do usuário à disciplina...`);
    
    let disciplinaAcesso;
    if (mongoose.Types.ObjectId.isValid(disciplinaObjectId)) {
      disciplinaAcesso = await CardDisciplina.findById(disciplinaObjectId);
    } else {
      disciplinaAcesso = await CardDisciplina.findOne({ slug: disciplinaObjectId });
    }

    if (!disciplinaAcesso) {
      return res.status(404).json({
        success: false,
        message: "Disciplina não encontrada"
      });
    }

    // Verificar acesso manualmente (substituindo o método que não existe)
    const isAdmin = userRole === 'admin';
    const isProfessor = disciplinaAcesso.professores.some(prof => 
      prof.toString() === userId.toString()
    );
    const isAluno = disciplinaAcesso.alunos.some(aluno => 
      aluno.toString() === userId.toString()
    );

    if (!isAdmin && !isProfessor && !isAluno) {
      return res.status(403).json({
        success: false,
        message: "Acesso negado à disciplina"
      });
    }

    console.log(`✅ Acesso permitido: ${userRole} na disciplina ${disciplinaAcesso.titulo}`);

    // Determinar o modelo do autor baseado na role
    const autorModel = userRole === "professor" || userRole === "admin" ? "Professor" : "Aluno";

    console.log(`👤 Autor model: ${autorModel}, Disciplina ID: ${disciplinaObjectId}, Slug: ${disciplinaSlug}`);

    // Criar o comentário
    const novoComentario = new Comentario({
      materialId,
      topicoId,
      disciplinaId: disciplinaObjectId,
      disciplinaSlug: disciplinaSlug,
      texto: texto.trim(),
      autor: userId,
      autorModel
    });

    await novoComentario.save();
    
    // Popular os dados para retorno
    await novoComentario.populate('autor', 'nome email');
    await novoComentario.populate('disciplinaId', 'titulo slug');

    res.status(201).json({
      success: true,
      message: "Comentário criado com sucesso",
      data: novoComentario
    });

  } catch (error) {
    console.error("❌ Erro ao criar comentário:", error);
    res.status(500).json({
      success: false,
      message: "Erro interno do servidor ao criar comentário",
      error: error.message
    });
  }
});

// POST /comentarios/:id/respostas - Adicionar resposta a um comentário
router.post("/:id/respostas", auth(), async (req, res) => {
  try {
    const { id } = req.params;
    const { texto } = req.body;
    const userId = req.user.id;
    const userRole = req.user.role;

    if (!texto || texto.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: "O texto da resposta é obrigatório."
      });
    }

    const comentario = await Comentario.findById(id);
    
    if (!comentario) {
      return res.status(404).json({
        success: false,
        message: "Comentário não encontrado"
      });
    }

    // Verificar acesso à disciplina do comentário
    const temAcesso = await CardDisciplina.verificarAcessoUsuario(
      comentario.disciplinaId, 
      userId, 
      userRole
    );
    
    if (!temAcesso) {
      return res.status(403).json({
        success: false,
        message: "Acesso negado à disciplina"
      });
    }

    const autorModel = userRole === "professor" || userRole === "admin" ? "Professor" : "Aluno";

    const respostaData = {
      autor: userId,
      autorModel,
      texto: texto.trim(),
      dataCriacao: new Date()
    };

    await comentario.adicionarResposta(respostaData);
    
    // Popular dados atualizados
    await comentario.populate('autor', 'nome email');
    await comentario.populate('respostas.autor', 'nome email');
    await comentario.populate('disciplinaId', 'titulo slug');

    res.json({
      success: true,
      message: "Resposta adicionada com sucesso",
      data: comentario
    });
  } catch (error) {
    console.error("Erro ao adicionar resposta:", error);
    res.status(500).json({
      success: false,
      message: "Erro interno do servidor ao adicionar resposta",
      error: error.message
    });
  }
});

// PUT /comentarios/:id - Editar comentário
router.put("/:id", auth(), async (req, res) => {
  try {
    const { id } = req.params;
    const { texto } = req.body;
    const userId = req.user.id;
    const userRole = req.user.role;

    if (!texto || texto.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: "O texto do comentário é obrigatório."
      });
    }

    const comentario = await Comentario.findById(id);

    if (!comentario) {
      return res.status(404).json({
        success: false,
        message: "Comentário não encontrado"
      });
    }

    // Verificar permissões
    const isAutor = comentario.autor.toString() === userId;
    const isProfessorOrAdmin = userRole === "professor" || userRole === "admin";

    if (!isAutor && !isProfessorOrAdmin) {
      return res.status(403).json({
        success: false,
        message: "Apenas o autor, professores ou administradores podem editar comentários"
      });
    }

    const comentarioAtualizado = await Comentario.findByIdAndUpdate(
      id,
      { 
        texto: texto.trim(),
        dataEdicao: new Date(),
        editado: true
      },
      { new: true, runValidators: true }
    ).populate('autor', 'nome email')
     .populate('respostas.autor', 'nome email')
     .populate('disciplinaId', 'titulo slug');

    res.json({
      success: true,
      message: "Comentário atualizado com sucesso",
      data: comentarioAtualizado
    });
  } catch (error) {
    console.error("Erro ao atualizar comentário:", error);
    res.status(500).json({
      success: false,
      message: "Erro interno do servidor ao atualizar comentário",
      error: error.message
    });
  }
});

// DELETE /comentarios/:id - Excluir comentário
router.delete("/:id", auth(), async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const userRole = req.user.role;

    const comentario = await Comentario.findById(id);

    if (!comentario) {
      return res.status(404).json({
        success: false,
        message: "Comentário não encontrado"
      });
    }

    // Verificar permissões
    const isAutor = comentario.autor.toString() === userId;
    const isProfessorOrAdmin = userRole === "professor" || userRole === "admin";

    if (!isAutor && !isProfessorOrAdmin) {
      return res.status(403).json({
        success: false,
        message: "Apenas o autor, professores ou administradores podem excluir comentários"
      });
    }

    await Comentario.findByIdAndDelete(id);

    res.json({
      success: true,
      message: "Comentário excluído com sucesso"
    });
  } catch (error) {
    console.error("Erro ao excluir comentário:", error);
    res.status(500).json({
      success: false,
      message: "Erro interno do servidor ao excluir comentário",
      error: error.message
    });
  }
});

module.exports = router;