const express = require("express");
const router = express.Router();
const Disciplina = require("../../models/disciplinaNota.cjs"); // CORREÇÃO: Usar modelo específico para notas
const Aluno = require("../../models/aluno.cjs"); // Assumindo que existe um modelo Aluno
const auth = require("../../middleware/auth.cjs"); // Ajuste o caminho para o seu arquivo de auth (ex: ./middleware/auth.js)

// Função auxiliar para calcular médias
const calcularMedias = (detalhes) => {
  let provas = detalhes.filter((d) => d.tipo === "prova");
  let atividades = detalhes.filter((d) => d.tipo === "atividade");

  let somaProvas = 0,
    pesoProvas = 0;
  provas.forEach((p) => {
    somaProvas += p.nota * p.peso;
    pesoProvas += p.peso;
  });
  let mediaProvas = pesoProvas > 0 ? somaProvas / pesoProvas : 0;

  let somaAtividades = 0,
    pesoAtividades = 0;
  atividades.forEach((a) => {
    somaAtividades += a.nota * a.peso;
    pesoAtividades += a.peso;
  });
  let mediaAtividades =
    pesoAtividades > 0 ? somaAtividades / pesoAtividades : 0;

  // Assumindo média final como média simples das duas (ajuste se necessário)
  let mediaFinal = (mediaProvas + mediaAtividades) / 2;

  return { mediaProvas, mediaAtividades, mediaFinal };
};

// GET /disciplinas - Listar disciplinas/notas
router.get("/disciplinas", auth(), async (req, res) => {
  // auth() para autenticação geral
  try {
    let query = {};

    const userRole = req.user.role;
    if (userRole === "aluno") {
      query.alunoId = req.user._id; // Filtra apenas pelas notas do aluno logado
    } else if (userRole === "professor") {
      // Filtro por mês para professores (opcional via query params)
      const { mes, ano } = req.query;
      if (mes && ano) {
        const inicioMes = new Date(parseInt(ano), parseInt(mes) - 1, 1);
        const fimMes = new Date(parseInt(ano), parseInt(mes), 1);
        query.createdAt = { $gte: inicioMes, $lt: fimMes };
      }
      // Para professores, popula dados do aluno em todas as disciplinas
      // (mas só popula se for professor, para evitar exposição desnecessária)
    } // CORREÇÃO: Para admin, cai no else abaixo com populate

    let disciplinas;
    if (userRole === "aluno") {
      // Para aluno: sem populate
      disciplinas = await Disciplina.find(query).sort({ createdAt: -1 });
    } else {
      // Para professor ou admin: com populate e filtro opcional para professor
      if (userRole === "professor") {
        const { mes, ano } = req.query;
        if (mes && ano) {
          const inicioMes = new Date(parseInt(ano), parseInt(mes) - 1, 1);
          const fimMes = new Date(parseInt(ano), parseInt(mes), 1);
          query.createdAt = { $gte: inicioMes, $lt: fimMes };
        }
      }
      // Query vazia para admin (todas as disciplinas)
      disciplinas = await Disciplina.find(query)
        .populate("alunoId", "nome email")
        .sort({ createdAt: -1 });
    }

    res.json(disciplinas);
  } catch (error) {
    console.error("DEBUG Backend: Erro no GET /disciplinas:", error); // Adicione log para debug
    res.status(500).json({ error: "Erro ao buscar disciplinas" });
  }
});

// POST /disciplinas - Criar nova disciplina (apenas professores e admins - ajuste auth se necessário)
router.post("/disciplinas", auth("professor"), async (req, res) => {
  // CORREÇÃO: Assumir que auth permite admin
  try {
    const { nome, alunoId } = req.body;
    if (!nome || !alunoId) {
      return res.status(400).json({ error: "Nome e alunoId são obrigatórios" });
    }

    // Verifica se aluno existe
    const aluno = await Aluno.findById(alunoId);
    if (!aluno) {
      return res.status(404).json({ error: "Aluno não encontrado" });
    }

    const novaDisciplina = new Disciplina({
      nome,
      detalhes: [], // Inicia vazia
      alunoId,
    });

    // Calcula médias iniciais (0)
    const medias = calcularMedias(novaDisciplina.detalhes);
    novaDisciplina.mediaProvas = medias.mediaProvas;
    novaDisciplina.mediaAtividades = medias.mediaAtividades;
    novaDisciplina.mediaFinal = medias.mediaFinal;

    await novaDisciplina.save();
    await novaDisciplina.populate("alunoId", "nome email");
    res.status(201).json(novaDisciplina);
  } catch (error) {
    console.error("DEBUG Backend: Erro no POST /disciplinas:", error); // Adicione log para debug
    res.status(500).json({ error: "Erro ao criar disciplina" });
  }
});

// PUT /disciplinas/:id/adicionar-nota - Adicionar nota (apenas professores e admins)
router.put(
  "/disciplinas/:id/adicionar-nota",
  auth("professor"),
  async (req, res) => {
    try {
      const { id } = req.params;
      const { tipo, descricao, nota, peso } = req.body;
      if (!tipo || !descricao || nota === undefined || peso === undefined) {
        return res
          .status(400)
          .json({ error: "Tipo, descricao, nota e peso são obrigatórios" });
      }

      const disciplina = await Disciplina.findById(id);
      if (!disciplina) {
        return res.status(404).json({ error: "Disciplina não encontrada" });
      }

      // Adiciona a nova nota
      disciplina.detalhes.push({ tipo, descricao, nota, peso });

      // Recalcula médias
      const medias = calcularMedias(disciplina.detalhes);
      disciplina.mediaProvas = medias.mediaProvas;
      disciplina.mediaAtividades = medias.mediaAtividades;
      disciplina.mediaFinal = medias.mediaFinal;

      await disciplina.save();
      await disciplina.populate("alunoId", "nome email");
      res.json(disciplina);
    } catch (error) {
      console.error(
        "DEBUG Backend: Erro no PUT /disciplinas/:id/adicionar-nota:",
        error
      ); // Adicione log para debug
      res.status(500).json({ error: "Erro ao adicionar nota" });
    }
  }
);

// DELETE /disciplinas/:id/remover-nota/:notaId - Remover nota específica (apenas professores e admins)
router.delete(
  "/disciplinas/:id/remover-nota/:notaId",
  auth("professor"),
  async (req, res) => {
    try {
      const { id, notaId } = req.params;

      const disciplina = await Disciplina.findById(id);
      if (!disciplina) {
        return res.status(404).json({ error: "Disciplina não encontrada" });
      }

      // Remove a nota pelo _id
      const notaIndex = disciplina.detalhes.findIndex(
        (d) => d._id.toString() === notaId
      );
      if (notaIndex === -1) {
        return res.status(404).json({ error: "Nota não encontrada" });
      }

      disciplina.detalhes.splice(notaIndex, 1);

      // Recalcula médias
      const medias = calcularMedias(disciplina.detalhes);
      disciplina.mediaProvas = medias.mediaProvas;
      disciplina.mediaAtividades = medias.mediaAtividades;
      disciplina.mediaFinal = medias.mediaFinal;

      await disciplina.save();
      await disciplina.populate("alunoId", "nome email");
      res.json(disciplina);
    } catch (error) {
      console.error(
        "DEBUG Backend: Erro no DELETE /disciplinas/:id/remover-nota/:notaId:",
        error
      ); // Adicione log para debug
      res.status(500).json({ error: "Erro ao remover nota" });
    }
  }
);

// DELETE /disciplinas/:id - Deletar disciplina inteira (apenas professores e admins)
router.delete("/disciplinas/:id", auth("professor"), async (req, res) => {
  try {
    const { id } = req.params;
    const disciplina = await Disciplina.findByIdAndDelete(id);
    if (!disciplina) {
      return res.status(404).json({ error: "Disciplina não encontrada" });
    }
    res.json({ message: "Disciplina deletada com sucesso" });
  } catch (error) {
    console.error("DEBUG Backend: Erro no DELETE /disciplinas/:id:", error); // Adicione log para debug
    res.status(500).json({ error: "Erro ao deletar disciplina" });
  }
});

module.exports = router;
