// models/cardDisciplina.cjs
const mongoose = require("mongoose");

// Função para gerar slug
const generateSlug = (titulo) => {
  return titulo
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9 -]/g, "")
    .replace(/\s+/g, "-")
    .replace(/-+/g, "-")
    .trim();
};

const materialSchema = new mongoose.Schema({
  tipo: {
    type: String,
    enum: ['pdf', 'imagem', 'link', 'atividade'],
    required: true
  },
  titulo: {
    type: String,
    required: true,
    trim: true
  },
  descricao: {
    type: String,
    trim: true
  },
  url: {
    type: String,
    trim: true
  },
  arquivo: {
    data: Buffer,
    contentType: String,
    nomeOriginal: String
  },
  peso: {
    type: Number,
    default: 0,
    min: 0,
    max: 100
  },
  prazo: Date,
  dataCriacao: {
    type: Date,
    default: Date.now
  },
  ordem: {
    type: Number,
    default: 0
  }
});

const topicoSchema = new mongoose.Schema({
  titulo: {
    type: String,
    required: true,
    trim: true
  },
  descricao: {
    type: String,
    trim: true
  },
  ordem: {
    type: Number,
    required: true
  },
  materiais: [materialSchema],
  dataCriacao: {
    type: Date,
    default: Date.now
  }
});

const cardDisciplinaSchema = new mongoose.Schema(
  {
    imagem: {
      data: { type: Buffer, required: true },
      contentType: { type: String, required: true }
    },
    icone: {
      data: { type: Buffer, required: true },
      contentType: { type: String, required: true }
    },
    titulo: {
      type: String,
      required: true,
      trim: true,
    },
    slug: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },
    topicos: [topicoSchema],
    professores: [{ 
      type: mongoose.Schema.Types.ObjectId, 
      ref: "Professor" 
    }],
    alunos: [{ 
      type: mongoose.Schema.Types.ObjectId, 
      ref: "Aluno" 
    }],
    criadoPor: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Professor",
      required: true
    }
  },
  { timestamps: true }
);

// Middleware para gerar slug automaticamente antes de salvar
cardDisciplinaSchema.pre("save", function (next) {
  if (this.isModified("titulo") || !this.slug) {
    this.slug = generateSlug(this.titulo);
  }
  next();
});

module.exports = mongoose.model("CardDisciplina", cardDisciplinaSchema);