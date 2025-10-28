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

cardDisciplinaSchema.statics.verificarAcessoUsuario = async function(disciplinaId, userId, userRole) {
  try {
    console.log(`🔍 Verificando acesso: disciplina=${disciplinaId}, user=${userId}, role=${userRole}`);
    
    let disciplina;
    
    // Buscar por ObjectId primeiro
    if (mongoose.Types.ObjectId.isValid(disciplinaId)) {
      disciplina = await this.findById(disciplinaId);
    }
    
    // Se não encontrou, buscar por slug
    if (!disciplina) {
      disciplina = await this.findOne({ slug: disciplinaId });
    }
    
    if (!disciplina) {
      console.log('❌ Disciplina não encontrada');
      return false;
    }

    // Admin tem acesso total
    if (userRole === 'admin') {
      console.log('✅ Acesso permitido: ADMIN');
      return true;
    }

    // Verificar se é professor da disciplina
    const isProfessor = disciplina.professores.some(prof => 
      prof.toString() === userId.toString()
    );
    
    if (isProfessor) {
      console.log('✅ Acesso permitido: PROFESSOR da disciplina');
      return true;
    }

    // Verificar se é aluno da disciplina
    const isAluno = disciplina.alunos.some(aluno => 
      aluno.toString() === userId.toString()
    );
    
    if (isAluno) {
      console.log('✅ Acesso permitido: ALUNO matriculado');
      return true;
    }

    console.log('❌ Acesso negado: usuário não tem permissão');
    return false;
    
  } catch (error) {
    console.error('💥 Erro ao verificar acesso do usuário:', error);
    return false;
  }
};

module.exports = mongoose.model("CardDisciplina", cardDisciplinaSchema);