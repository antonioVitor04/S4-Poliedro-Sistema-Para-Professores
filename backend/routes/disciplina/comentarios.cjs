const express = require("express");
const router = express.Router();
const Comentario = require("../models/comentario.gs");
const CardDisciplina = require("../models/cardDisciplina.gs");

// GET /comentarios/material/:materialId - Buscar comentários de um material
router.get("/material/:materialId", async (req, res) => {
  try {
    const { materialId } = req.params;
    const pagina = parseInt(req.query.pagina) || 1;
    const limite = parseInt(req.query.limite) || 20;

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
    res.status(500).json({
      success: false,
      message: "Erro ao buscar comentários",
      error: error.message
    });
  }
});

// POST /comentarios - Criar novo comentário
router.post("/", async (req, res) => {
  try {
    const { materialId, topicoId, disciplinaId, autor, autorModel, texto } = req.body;

    // Verificar se o material existe
    const disciplina = await CardDisciplina.findOne({
      _id: disciplinaId,
      "topicos._id": topicoId,
      "topicos.materiais._id": materialId
    });

    if (!disciplina) {
      return res.status(404).json({
        success: false,
        message: "Material não encontrado"
      });
    }

    const novoComentario = new Comentario({
      materialId,
      topicoId,
      disciplinaId,
      autor,
      autorModel,
      texto
    });

    await novoComentario.save();
    
    // Popular os dados do autor para retorno
    await novoComentario.populate('autor', 'nome email');
    await novoComentario.populate('disciplinaId', 'titulo slug');

    res.status(201).json({
      success: true,
      message: "Comentário criado com sucesso",
      data: novoComentario
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Erro ao criar comentário",
      error: error.message
    });
  }
});

// POST /comentarios/:id/respostas - Adicionar resposta a um comentário
router.post("/:id/respostas", async (req, res) => {
  try {
    const { id } = req.params;
    const { autor, autorModel, texto } = req.body;

    const comentario = await Comentario.findById(id);
    
    if (!comentario) {
      return res.status(404).json({
        success: false,
        message: "Comentário não encontrado"
      });
    }

    const respostaData = {
      autor,
      autorModel,
      texto,
      dataCriacao: new Date()
    };

    await comentario.adicionarResposta(respostaData);
    
    // Popular dados da resposta
    await comentario.populate('respostas.autor', 'nome email');

    res.json({
      success: true,
      message: "Resposta adicionada com sucesso",
      data: comentario
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Erro ao adicionar resposta",
      error: error.message
    });
  }
});

// PUT /comentarios/:id - Editar comentário
router.put("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { texto } = req.body;

    const comentario = await Comentario.findByIdAndUpdate(
      id,
      { 
        texto,
        dataEdicao: new Date(),
        editado: true
      },
      { new: true, runValidators: true }
    ).populate('autor', 'nome email');

    if (!comentario) {
      return res.status(404).json({
        success: false,
        message: "Comentário não encontrado"
      });
    }

    res.json({
      success: true,
      message: "Comentário atualizado com sucesso",
      data: comentario
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Erro ao atualizar comentário",
      error: error.message
    });
  }
});

// DELETE /comentarios/:id - Excluir comentário
router.delete("/:id", async (req, res) => {
  try {
    const { id } = req.params;

    const comentario = await Comentario.findByIdAndDelete(id);

    if (!comentario) {
      return res.status(404).json({
        success: false,
        message: "Comentário não encontrado"
      });
    }

    res.json({
      success: true,
      message: "Comentário excluído com sucesso"
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Erro ao excluir comentário",
      error: error.message
    });
  }
});

module.exports = router;