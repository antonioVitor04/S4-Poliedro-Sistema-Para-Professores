const jwt = require("jsonwebtoken");

function auth(allowedRoles = []) {
  return (req, res, next) => {
    try {
      console.log("=== MIDDLEWARE AUTH INICIADO ===");
      console.log("Headers:", req.headers);
      
      const authHeader = req.header("Authorization");
      console.log("Authorization Header:", authHeader);
      
      const token = authHeader?.replace("Bearer ", "");
      console.log("Token extraído:", token ? `${token.substring(0, 20)}...` : "Nenhum");
      
      if (!token) {
        console.log("❌ Token ausente");
        return res.status(401).json({ msg: "Acesso negado. Token ausente." });
      }

      // Verificar JWT_SECRET
      if (!process.env.JWT_SECRET) {
        console.log("❌ JWT_SECRET não definido");
        return res.status(500).json({ msg: "Erro de configuração do servidor" });
      }

      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      console.log("✅ Token decodificado:", decoded);
      
      req.user = decoded;

      // Verificar roles se especificadas
      if (allowedRoles && allowedRoles.length > 0) {
        console.log("Verificando roles:", {
          userRole: decoded.role,
          allowedRoles: allowedRoles
        });
        
        if (!allowedRoles.includes(decoded.role)) {
          console.log("❌ Role não permitida");
          return res.status(403).json({ 
            msg: "Acesso negado. Permissão insuficiente.",
            required: allowedRoles,
            userRole: decoded.role
          });
        }
      }

      console.log("✅ Auth middleware passou");
      next();
    } catch (err) {
      console.error("❌ Erro no middleware auth:", {
        name: err.name,
        message: err.message,
        stack: err.stack
      });
      
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

module.exports = auth;