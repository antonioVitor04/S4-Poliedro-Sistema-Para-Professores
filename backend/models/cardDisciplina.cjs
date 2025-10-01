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

const cardDisciplinaSchema = new mongoose.Schema(
  {
    imagem: {
      data: {
        type: Buffer,
        required: true
      },
      contentType: {
        type: String,
        required: true
      }
    },
    icone: {
      data: {
        type: Buffer,
        required: true
      },
      contentType: {
        type: String,
        required: true
      }
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