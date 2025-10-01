// routes/cards/materiais.cjs
const express = require("express");
const multer = require("multer");
const routerMateriais = express.Router();
const CardDisciplina = require("../../models/cardDisciplina.cjs");

// Configuração do Multer para arquivos
const storage = multer.memoryStorage();
const upload = multer({
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB
  },
});

// POST: Adicionar material a um tópico
routerMateriais.post("/:slug/topicos/:topicoId/materiais", upload.single('arquivo'), async (req, res) => {
  try {
    const { slug, topicoId } = req.params;
    const { tipo, titulo, descricao, url, peso, prazo } = req.body;

    if (!tipo || !titulo || titulo.trim().length === 0) {
      return res.status(400).json({
        success: false,
        error: "Tipo e título são obrigatórios",
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

    const novoMaterial = {
      tipo,
      titulo: titulo.trim(),
      descricao: descricao ? descricao.trim() : "",
      url: url || "",
      peso: peso ? parseFloat(peso) : 0,
      prazo: prazo ? new Date(prazo) : null,
      ordem: topico.materiais.length
    };

    // Se há arquivo uploadado
    if (req.file) {
      novoMaterial.arquivo = {
        data: req.file.buffer,
        contentType: req.file.mimetype,
        nomeOriginal: req.file.originalname
      };
    }

    topico.materiais.push(novoMaterial);
    await card.save();

    const materialSalvo = topico.materiais[topico.materiais.length - 1];

    res.status(201).json({
      success: true,
      message: "Material criado com sucesso",
      data: materialSalvo,
    });
  } catch (err) {
    console.error("Erro ao criar material:", err);
    res.status(500).json({
      success: false,
      error: "Erro interno do servidor ao criar material",
    });
  }
});

// PUT: Atualizar material
routerMateriais.put("/:slug/topicos/:topicoId/materiais/:materialId", upload.single('arquivo'), async (req, res) => {
  try {
    const { slug, topicoId, materialId } = req.params;
    const { tipo, titulo, descricao, url, peso, prazo } = req.body;

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

    const material = topico.materiais.id(materialId);
    if (!material) {
      return res.status(404).json({
        success: false,
        error: "Material não encontrado",
      });
    }

    if (tipo !== undefined) material.tipo = tipo;
    if (titulo !== undefined) material.titulo = titulo.trim();
    if (descricao !== undefined) material.descricao = descricao ? descricao.trim() : "";
    if (url !== undefined) material.url = url;
    if (peso !== undefined) material.peso = parseFloat(peso);
    if (prazo !== undefined) material.prazo = prazo ? new Date(prazo) : null;

    // Se há novo arquivo uploadado
    if (req.file) {
      material.arquivo = {
        data: req.file.buffer,
        contentType: req.file.mimetype,
        nomeOriginal: req.file.originalname
      };
    }

    await card.save();

    res.json({
      success: true,
      message: "Material atualizado com sucesso",
      data: material,
    });
  } catch (err) {
    console.error("Erro ao atualizar material:", err);
    res.status(500).json({
      success: false,
      error: "Erro interno do servidor ao atualizar material",
    });
  }
});

// DELETE: Deletar material
routerMateriais.delete("/:slug/topicos/:topicoId/materiais/:materialId", async (req, res) => {
  try {
    const { slug, topicoId, materialId } = req.params;

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

    const material = topico.materiais.id(materialId);
    if (!material) {
      return res.status(404).json({
        success: false,
        error: "Material não encontrado",
      });
    }

    material.deleteOne();
    await card.save();

    res.json({
      success: true,
      message: "Material deletado com sucesso",
      data: { _id: materialId },
    });
  } catch (err) {
    console.error("Erro ao deletar material:", err);
    res.status(500).json({
      success: false,
      error: "Erro interno do servidor ao deletar material",
    });
  }
});

// GET: Download de arquivo
routerMateriais.get("/:slug/topicos/:topicoId/materiais/:materialId/download", async (req, res) => {
  try {
    const { slug, topicoId, materialId } = req.params;

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

    const material = topico.materiais.id(materialId);
    if (!material || !material.arquivo || !material.arquivo.data) {
      return res.status(404).json({
        success: false,
        error: "Arquivo não encontrado",
      });
    }

    res.setHeader('Content-Type', material.arquivo.contentType);
    res.setHeader('Content-Disposition', `attachment; filename="${material.arquivo.nomeOriginal || 'download'}"`);
    
    res.send(material.arquivo.data);
  } catch (err) {
    console.error("Erro ao baixar arquivo:", err);
    res.status(500).json({
      success: false,
      error: "Erro interno do servidor ao baixar arquivo",
    });
  }
});

module.exports = routerMateriais;