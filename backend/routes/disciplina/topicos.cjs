// routes/cards/topicos.cjs
const express = require("express");
const routerTopicos = express.Router();
const CardDisciplina = require("../../models/cardDisciplina.cjs");

// GET: Buscar todos os tópicos de uma disciplina
routerTopicos.get("/:slug/topicos", async (req, res) => {
  try {
    const { slug } = req.params;

    const card = await CardDisciplina.findOne({ slug });

    if (!card) {
      return res.status(404).json({
        success: false,
        error: "Disciplina não encontrada",
      });
    }

    res.json({
      success: true,
      data: card.topicos,
    });
  } catch (err) {
    console.error("Erro ao buscar tópicos:", err);
    res.status(500).json({
      success: false,
      error: "Erro interno do servidor ao buscar tópicos",
    });
  }
});

// POST: Adicionar novo tópico
routerTopicos.post("/:slug/topicos", async (req, res) => {
  try {
    const { slug } = req.params;
    const { titulo, descricao } = req.body;

    if (!titulo || titulo.trim().length === 0) {
      return res.status(400).json({
        success: false,
        error: "Título do tópico é obrigatório",
      });
    }

    const card = await CardDisciplina.findOne({ slug });

    if (!card) {
      return res.status(404).json({
        success: false,
        error: "Disciplina não encontrada",
      });
    }

    // Determinar a próxima ordem
    const proximaOrdem = card.topicos.length > 0 
      ? Math.max(...card.topicos.map(t => t.ordem)) + 1 
      : 0;

    const novoTopico = {
      titulo: titulo.trim(),
      descricao: descricao ? descricao.trim() : "",
      ordem: proximaOrdem,
      materiais: []
    };

    card.topicos.push(novoTopico);
    await card.save();

    const topicoSalvo = card.topicos[card.topicos.length - 1];

    res.status(201).json({
      success: true,
      message: "Tópico criado com sucesso",
      data: topicoSalvo,
    });
  } catch (err) {
    console.error("Erro ao criar tópico:", err);
    res.status(500).json({
      success: false,
      error: "Erro interno do servidor ao criar tópico",
    });
  }
});

// PUT: Atualizar tópico
routerTopicos.put("/:slug/topicos/:topicoId", async (req, res) => {
  try {
    const { slug, topicoId } = req.params;
    const { titulo, descricao, ordem } = req.body;

    const card = await CardDisciplina.findOne({ slug });

    if (!card) {
      return res.status(404).json({
        success: false,
        error: "Disciplina não encontrada",
      });
    }

    const topico = card.topicos.id(topicoId);
    if (!topico) {
      return res.status(404).json({
        success: false,
        error: "Tópico não encontrado",
      });
    }

    if (titulo !== undefined) {
      if (typeof titulo !== "string" || titulo.trim().length === 0) {
        return res.status(400).json({
          success: false,
          error: "Título deve ser uma string não vazia",
        });
      }
      topico.titulo = titulo.trim();
    }

    if (descricao !== undefined) {
      topico.descricao = descricao ? descricao.trim() : "";
    }

    if (ordem !== undefined) {
      topico.ordem = ordem;
    }

    await card.save();

    res.json({
      success: true,
      message: "Tópico atualizado com sucesso",
      data: topico,
    });
  } catch (err) {
    console.error("Erro ao atualizar tópico:", err);
    res.status(500).json({
      success: false,
      error: "Erro interno do servidor ao atualizar tópico",
    });
  }
});

// DELETE: Deletar tópico
routerTopicos.delete("/:slug/topicos/:topicoId", async (req, res) => {
  try {
    const { slug, topicoId } = req.params;

    const card = await CardDisciplina.findOne({ slug });

    if (!card) {
      return res.status(404).json({
        success: false,
        error: "Disciplina não encontrada",
      });
    }

    const topico = card.topicos.id(topicoId);
    if (!topico) {
      return res.status(404).json({
        success: false,
        error: "Tópico não encontrado",
      });
    }

    topico.deleteOne();
    await card.save();

    res.json({
      success: true,
      message: "Tópico deletado com sucesso",
      data: { _id: topicoId },
    });
  } catch (err) {
    console.error("Erro ao deletar tópico:", err);
    res.status(500).json({
      success: false,
      error: "Erro interno do servidor ao deletar tópico",
    });
  }
});

// PUT: Reordenar tópicos
routerTopicos.put("/:slug/topicos/:topicoId/reordenar", async (req, res) => {
  try {
    const { slug, topicoId } = req.params;
    const { novaOrdem } = req.body;

    if (novaOrdem === undefined || novaOrdem < 0) {
      return res.status(400).json({
        success: false,
        error: "Nova ordem é obrigatória e deve ser um número positivo",
      });
    }

    const card = await CardDisciplina.findOne({ slug });

    if (!card) {
      return res.status(404).json({
        success: false,
        error: "Disciplina não encontrada",
      });
    }

    const topico = card.topicos.id(topicoId);
    if (!topico) {
      return res.status(404).json({
        success: false,
        error: "Tópico não encontrado",
      });
    }

    // Reordenar todos os tópicos
    const topicosOrdenados = card.topicos.sort((a, b) => a.ordem - b.ordem);
    
    // Remover o tópico que está sendo movido
    const topicoMovido = topicosOrdenados.splice(topicosOrdenados.findIndex(t => t._id.toString() === topicoId), 1)[0];
    
    // Inserir na nova posição
    topicosOrdenados.splice(novaOrdem, 0, topicoMovido);
    
    // Atualizar as ordens
    topicosOrdenados.forEach((topico, index) => {
      topico.ordem = index;
    });

    card.topicos = topicosOrdenados;
    await card.save();

    res.json({
      success: true,
      message: "Tópicos reordenados com sucesso",
      data: card.topicos,
    });
  } catch (err) {
    console.error("Erro ao reordenar tópicos:", err);
    res.status(500).json({
      success: false,
      error: "Erro interno do servidor ao reordenar tópicos",
    });
  }
});

module.exports = routerTopicos;