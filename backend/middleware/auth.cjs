const jwt = require("jsonwebtoken");

function auth(allowedRoles = []) {
  return (req, res, next) => {
    try {
      const authHeader = req.header("Authorization");

      const token = authHeader?.replace("Bearer ", "");

      if (!token) {
        return res.status(401).json({ msg: "Acesso negado. Token ausente." });
      }

      // Verificar JWT_SECRET
      if (!process.env.JWT_SECRET) {
        return res
          .status(500)
          .json({ msg: "Erro de configuração do servidor" });
      }

      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      req.user = decoded;

      // Verificar roles se especificadas
      if (allowedRoles && allowedRoles.length > 0) {
        if (!allowedRoles.includes(decoded.role)) {
          return res.status(403).json({
            msg: "Acesso negado. Permissão insuficiente.",
            required: allowedRoles,
            userRole: decoded.role,
          });
        }
      }

      next();
    } catch (err) {
      if (err.name === "TokenExpiredError") {
        return res.status(401).json({ msg: "Token expirado" });
      }

      if (err.name === "JsonWebTokenError") {
        return res.status(401).json({ msg: "Token inválido" });
      }

      res.status(500).json({ msg: "Erro na autenticação" });
    }
  };
}

// ADIÇÃO: Função auxiliar para verificar se o usuário é admin
auth.isAdmin = (req, res, next) => {
  if (req.user && req.user.role === "admin") {
    return next();
  }
  return res
    .status(403)
    .json({ msg: "Acesso negado. Apenas administradores." });
};

// ADIÇÃO: Função auxiliar para verificar se o usuário é professor
auth.isProfessor = (req, res, next) => {
  if (
    req.user &&
    (req.user.role === "professor" || req.user.role === "admin")
  ) {
    return next();
  }
  return res
    .status(403)
    .json({ msg: "Acesso negado. Apenas professores ou administradores." });
};

// ADIÇÃO: Função auxiliar para verificar se o usuário é aluno
auth.isAluno = (req, res, next) => {
  if (
    req.user &&
    (req.user.role === "aluno" ||
      req.user.role === "professor" ||
      req.user.role === "admin")
  ) {
    return next();
  }
  return res.status(403).json({
    msg: "Acesso negado. Apenas alunos, professores ou administradores.",
  });
};

// ADIÇÃO: Middleware para verificar se o usuário é o próprio ou admin
auth.isSelfOrAdmin = (req, res, next) => {
  const userId = req.params.id || req.body.userId;
  if (req.user && (req.user.id === userId || req.user.role === "admin")) {
    return next();
  }
  return res
    .status(403)
    .json({ msg: "Acesso negado. Apenas o próprio usuário ou administrador." });
};

module.exports = auth;
