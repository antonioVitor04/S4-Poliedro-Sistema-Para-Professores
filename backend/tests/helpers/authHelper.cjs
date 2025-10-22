// tests/helpers/authHelper.cjs
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const Professor = require('../../models/professor.cjs');
const Aluno = require('../../models/aluno.cjs');

class AuthHelper {
  static async createProfessorAndLogin() {
    const hashedPassword = await bcrypt.hash("senha123", 10);
    const professor = new Professor({
      nome: "Professor Teste",
      email: `professor${Date.now()}@sistemapoliedro.br`,
      senha: hashedPassword,
      tipo: "professor"
    });
    await professor.save();
    
    const token = jwt.sign(
      { id: professor._id.toString(), role: "professor" },
      process.env.JWT_SECRET
    );

    return { professor, token };
  }

  static async createAdminAndLogin() {
    const hashedPassword = await bcrypt.hash("admin123", 10);
    const admin = new Professor({
      nome: "Admin Teste",
      email: `admin${Date.now()}@sistemapoliedro.br`,
      senha: hashedPassword,
      tipo: "admin"
    });
    await admin.save();
    
    const token = jwt.sign(
      { id: admin._id.toString(), role: "admin" },
      process.env.JWT_SECRET
    );

    return { professor: admin, token };
  }

  static async createAlunoAndLogin() {
    const ra = `RA${Date.now()}`;
    const hashedPassword = await bcrypt.hash(ra, 10);
    const aluno = new Aluno({
      nome: "Aluno Teste",
      ra: ra,
      email: `aluno${Date.now()}@teste.com`,
      senha: hashedPassword
    });
    await aluno.save();
    
    const token = jwt.sign(
      { id: aluno._id.toString(), role: "aluno" },
      process.env.JWT_SECRET
    );

    return { aluno, token };
  }

  static async cleanup() {
    await Professor.deleteMany({});
    await Aluno.deleteMany({});
  }
}

module.exports = AuthHelper;