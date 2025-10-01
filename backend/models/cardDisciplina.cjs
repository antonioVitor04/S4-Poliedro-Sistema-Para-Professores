// models/cardDisciplina.cjs
const mongoose = require("mongoose");

// Função para gerar slug
const generateSlug = (titulo) => {
  return titulo
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "") // Remove acentos
    .replace(/[^a-z0-9 -]/g, "") // Remove caracteres especiais
    .replace(/\s+/g, "-") // Substitui espaços por hífens
    .replace(/-+/g, "-") // Remove hífens múltiplos
    .trim();
};

const cardDisciplinaSchema = new mongoose.Schema(
  {
    imagem: {
      type: String,
      required: true,
    },
    icone: {
      type: String,
      required: true,
    },
    titulo: {
      type: String,
      required: true,
      trim: true,
    },
    slug: {
      type: String,
      required: false,
      unique: true,
      trim: true,
    },
  },
  {
    timestamps: true,
  }
);

// Middleware para gerar slug automaticamente antes de salvar
cardDisciplinaSchema.pre("save", function (next) {
  if (this.isModified("titulo") || !this.slug) {
    this.slug = generateSlug(this.titulo);
  }
  next();
});

module.exports = mongoose.model("CardDisciplina", cardDisciplinaSchema);
