const express = require("express");
const router = express.Router();
const Comentario = require("../../models/comentario.cjs");
const CardDisciplina = require("../../models/cardDisciplina.cjs");
const auth = require("../../middleware/auth.cjs");
const mongoose = require("mongoose");

// Função auxiliar para host correto (para dev com IP) - REUTILIZADA DAS ROTAS ANTERIORES
const getHost = (req) => {
  return process.env.NODE_ENV === "development"
    ? "192.168.15.123:5000"  // Ajuste para o seu IP/host de dev se necessário
    : req.get("host");
};

// GET /comentarios/material/:materialId - Buscar comentários de um material (VERSÃO CORRIGIDA)
router.get("/material/:materialId", auth(), async (req, res) => {
  try {
    const { materialId } = req.params;
    const pagina = parseInt(req.query.pagina) || 1;
    const limite = parseInt(req.query.limite) || 20;
    const skip = (pagina - 1) * limite;

    console.log(`=== BUSCANDO COMENTÁRIOS: materialId=${materialId}, pagina=${pagina}, limite=${limite} ===`);

    // Buscar comentários com população CORRIGIDA - INCLUINDO 'ra' e 'tipo' para detecção de avatar
    const comentarios = await Comentario.find({ materialId })
      .sort({ dataCriacao: -1 })  // Mais recentes primeiro
      .skip(skip)
      .limit(limite)
      .populate({
        path: 'autor',
        select: 'nome email ra imagem tipo'  // KEY FIX: Incluir 'ra' (para alunos) e 'tipo' (para ambos)
      })
      .populate({
        path: 'respostas.autor',
        select: 'nome email ra imagem tipo'  // Mesma correção para respostas
      })
      .populate('disciplinaId', 'titulo slug');  // Manter população da disciplina

    // Contar total para paginação real
    const total = await Comentario.countDocuments({ materialId });

    // Transformar para adicionar 'tipo' explicitamente se ausente e gerar 'fotoUrl'
    const formattedComentarios = comentarios.map(comentario => {
      const base = comentario.toObject();

      // Setar 'tipo' baseado no autorModel se não estiver presente
      if (base.autorModel === 'Aluno' && !base.autor.tipo) {
        base.autor.tipo = 'aluno';
      } else if (base.autorModel === 'Professor' && !base.autor.tipo) {
        base.autor.tipo = base.autor.tipo || 'professor';  // Default para professor/admin
      }

      // Gerar fotoUrl para autor principal
      if (base.autor && base.autor.imagem && base.autor._id) {
        const endpoint = base.autor.tipo === 'aluno' ? 'alunos' : 'professores';
        base.autor.fotoUrl = `${req.protocol}://${getHost(req)}/api/${endpoint}/image/${base.autor._id}`;
      }

      // Gerar fotoUrl para respostas (se houver)
      if (base.respostas && base.respostas.length > 0) {
        base.respostas = base.respostas.map(resposta => {
          if (resposta.autor && resposta.autor.imagem && resposta.autor._id) {
            const endpointResposta = resposta.autor.tipo === 'aluno' ? 'alunos' : 'professores';
            resposta.autor.fotoUrl = `${req.protocol}://${getHost(req)}/api/${endpointResposta}/image/${resposta.autor._id}`;
          }
          return resposta;
        });
      }

      return base;
    });

    console.log(`✅ Encontrados ${formattedComentarios.length} comentários (total: ${total})`);

    res.json({
      success: true,
      data: formattedComentarios,
      paginacao: {
        pagina,
        limite,
        total,
        totalPaginas: Math.ceil(total / limite)
      }
    });
  } catch (error) {
    console.error("❌ Erro ao buscar comentários:", error);
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
    
    // Popular os dados para retorno - CORRIGIDO PARA INCLUIR 'ra' E 'TIPO'
    await novoComentario.populate({
      path: 'autor',
      select: 'nome email ra imagem tipo'  // Incluir 'ra' e 'tipo'
    });
    await novoComentario.populate('disciplinaId', 'titulo slug');

    // Gerar fotoUrl para o autor no novo comentário
    if (novoComentario.autor && novoComentario.autor.imagem && novoComentario.autor._id) {
      const autorTipo = novoComentario.autor.tipo || (novoComentario.autorModel === 'Aluno' ? 'aluno' : 'professor');
      const endpoint = autorTipo === 'aluno' ? 'alunos' : 'professores';
      novoComentario.autor.fotoUrl = `${req.protocol}://${getHost(req)}/api/${endpoint}/image/${novoComentario.autor._id}`;
    }

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

// POST /comentarios/:id/respostas - Adicionar resposta a um comentário (CORRIGIDO)
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
    
    // Popular dados atualizados - CORRIGIDO PARA INCLUIR 'ra' E 'TIPO'
    await comentario.populate({
      path: 'autor',
      select: 'nome email ra imagem tipo'
    });
    await comentario.populate({
      path: 'respostas.autor',
      select: 'nome email ra imagem tipo'
    });
    await comentario.populate('disciplinaId', 'titulo slug');

    // Gerar fotoUrl para autores nas respostas
    if (comentario.respostas && comentario.respostas.length > 0) {
      comentario.respostas = comentario.respostas.map(resposta => {
        if (resposta.autor && resposta.autor.imagem && resposta.autor._id) {
          const autorTipoResposta = resposta.autor.tipo || (resposta.autorModel === 'Aluno' ? 'aluno' : 'professor');
          const endpointResposta = autorTipoResposta === 'aluno' ? 'alunos' : 'professores';
          resposta.autor.fotoUrl = `${req.protocol}://${getHost(req)}/api/${endpointResposta}/image/${resposta.autor._id}`;
        }
        return resposta;
      });
    }

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

// PUT /comentarios/:id - Editar comentário (CORRIGIDO)
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
    ).populate({
      path: 'autor',
      select: 'nome email ra imagem tipo'  // Incluir 'ra' e 'tipo'
    })
     .populate({
       path: 'respostas.autor',
       select: 'nome email ra imagem tipo'  // Incluir para respostas
     })
     .populate('disciplinaId', 'titulo slug');

    // Gerar fotoUrl após update
    if (comentarioAtualizado.autor && comentarioAtualizado.autor.imagem && comentarioAtualizado.autor._id) {
      const autorTipo = comentarioAtualizado.autor.tipo || (comentarioAtualizado.autorModel === 'Aluno' ? 'aluno' : 'professor');
      const endpoint = autorTipo === 'aluno' ? 'alunos' : 'professores';
      comentarioAtualizado.autor.fotoUrl = `${req.protocol}://${getHost(req)}/api/${endpoint}/image/${comentarioAtualizado.autor._id}`;
    }

    if (comentarioAtualizado.respostas && comentarioAtualizado.respostas.length > 0) {
      comentarioAtualizado.respostas = comentarioAtualizado.respostas.map(resposta => {
        if (resposta.autor && resposta.autor.imagem && resposta.autor._id) {
          const autorTipoResposta = resposta.autor.tipo || (resposta.autorModel === 'Aluno' ? 'aluno' : 'professor');
          const endpointResposta = autorTipoResposta === 'aluno' ? 'alunos' : 'professores';
          resposta.autor.fotoUrl = `${req.protocol}://${getHost(req)}/api/${endpointResposta}/image/${resposta.autor._id}`;
        }
        return resposta;
      });
    }

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