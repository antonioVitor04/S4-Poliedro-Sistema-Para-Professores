const mongoose = require("mongoose");

const notaDetalheSchema = new mongoose.Schema({
  tipo: { 
    type: String, 
    required: true,
    enum: ['prova', 'atividade'] // Tipos predefinidos
  },
  descricao: { 
    type: String, 
    required: true 
  }, // Ex: "Prova 1", "Atividade Laboratório"
  nota: { 
    type: Number, 
    required: true,
    min: 0,
    max: 10 // Ajuste conforme seu sistema de notas
  },
  peso: { 
    type: Number, 
    required: true,
    min: 0.1,
    max: 1.0
  },
});

const disciplinaNotasSchema = new mongoose.Schema({
  nome: { 
    type: String, 
    required: true 
  },
  detalhes: [notaDetalheSchema], // Lista de todas as notas
  mediaProvas: { 
    type: Number, 
    default: 0 
  },
  mediaAtividades: { 
    type: Number, 
    default: 0 
  },
  mediaFinal: { 
    type: Number, 
    default: 0 
  },
  alunoId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Aluno', 
    required: true 
  }, // Relacionamento com aluno
  periodo: { 
    type: String, 
    required: true 
  } // Ex: "2024.1", "2023.2"
}, {
  timestamps: true // Cria created_at e updated_at automaticamente
});

module.exports = mongoose.model("Disciplina", disciplinaNotasSchema);