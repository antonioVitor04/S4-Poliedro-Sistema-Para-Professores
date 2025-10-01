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
      required: true,
      unique: true,
      trim: true,
    },
    descricao: {
      type: String,
      default: "",
    },
  },
  {
    timestamps: true,
  }
);

// Middleware para gerar slug antes de salvar
cardDisciplinaSchema.pre("save", function (next) {
  if (this.isModified("titulo") || !this.slug) {
    let baseSlug = generateSlug(this.titulo);
    let slug = baseSlug;
    let counter = 1;

    // Verifica se o slug já existe (usaremos uma função externa para isso)
    const checkSlug = async () => {
      const existingDoc = await mongoose.model("CardDisciplina").findOne({
        slug,
        _id: { $ne: this._id },
      });

      if (existingDoc) {
        slug = `${baseSlug}-${counter}`;
        counter++;
        await checkSlug();
      } else {
        this.slug = slug;
        next();
      }
    };

    checkSlug().catch(next);
  } else {
    next();
  }
});

module.exports = mongoose.model("CardDisciplina", cardDisciplinaSchema);
