const mongoose = require("mongoose");

const comentarioSchema = new mongoose.Schema(
  {
    materialId: {
      type: mongoose.Schema.Types.ObjectId,
      required: true
    },
    topicoId: {
      type: mongoose.Schema.Types.ObjectId,
      required: true
    },
    disciplinaId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "CardDisciplina",
      required: true
    },
    disciplinaSlug: {
      type: String,
      required: true
    },
    autor: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
      refPath: 'autorModel'
    },
    autorModel: {
      type: String,
      required: true,
      enum: ['Aluno', 'Professor']
    },
    texto: {
      type: String,
      required: true,
      trim: true,
      maxlength: 1000
    },
    respostas: [{
      autor: {
        type: mongoose.Schema.Types.ObjectId,
        required: true,
        refPath: 'respostas.autorModel'
      },
      autorModel: {
        type: String,
        required: true,
        enum: ['Aluno', 'Professor']
      },
      texto: {
        type: String,
        required: true,
        trim: true,
        maxlength: 500
      },
      dataCriacao: {
        type: Date,
        default: Date.now
      }
    }],
    dataCriacao: {
      type: Date,
      default: Date.now
    },
    dataEdicao: {
      type: Date
    },
    editado: {
      type: Boolean,
      default: false
    }
  },
  { timestamps: true }
);

// Índices para melhor performance
comentarioSchema.index({ materialId: 1, dataCriacao: -1 });
comentarioSchema.index({ topicoId: 1 });
comentarioSchema.index({ disciplinaId: 1 });
comentarioSchema.index({ disciplinaSlug: 1 }); // Novo índice para slug

// Método para adicionar resposta
comentarioSchema.methods.adicionarResposta = function(respostaData) {
  this.respostas.push(respostaData);
  return this.save();
};

// Método estático para buscar comentários por material
comentarioSchema.statics.buscarPorMaterial = function(materialId, pagina = 1, limite = 20) {
  const skip = (pagina - 1) * limite;
  
  return this.find({ materialId })
    .populate('autor', 'nome email')
    .populate('respostas.autor', 'nome email')
    .populate('disciplinaId', 'titulo slug')
    .sort({ dataCriacao: -1 })
    .skip(skip)
    .limit(limite)
    .exec();
};

// Método estático para buscar comentários por slug da disciplina
comentarioSchema.statics.buscarPorSlugDisciplina = function(disciplinaSlug, pagina = 1, limite = 20) {
  const skip = (pagina - 1) * limite;
  
  return this.find({ disciplinaSlug })
    .populate('autor', 'nome email')
    .populate('respostas.autor', 'nome email')
    .populate('disciplinaId', 'titulo slug')
    .sort({ dataCriacao: -1 })
    .skip(skip)
    .limit(limite)
    .exec();
};

// Middleware para atualizar data de edição
comentarioSchema.pre('save', function(next) {
  if (this.isModified('texto') && !this.isNew) {
    this.dataEdicao = new Date();
    this.editado = true;
  }
  next();
});

module.exports = mongoose.model("Comentario", comentarioSchema);