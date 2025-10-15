const jwt = require("jsonwebtoken");

function auth(allowedRoles = null) {
  // MUDANÇA: Renomeado para allowedRoles para clareza, aceita string ou array
  return (req, res, next) => {
    const token = req.header("Authorization")?.replace("Bearer ", "");
    if (!token)
      return res.status(401).json({ msg: "Acesso negado. Token ausente." });

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      req.user = decoded;

      // Se foram passadas roles permitidas, verifica
      if (allowedRoles) {
        const userRole = decoded.role;
        let rolesArray = allowedRoles;
        if (typeof allowedRoles === "string") {
          rolesArray = [allowedRoles]; // Converte string para array se necessário
        }
        if (!rolesArray.includes(userRole)) {
          console.log(
            `Acesso negado: role '${userRole}' não está em [${rolesArray.join(
              ", "
            )}]`
          ); // Log para debug
          return res
            .status(403)
            .json({ msg: "Acesso negado. Permissão insuficiente." });
        }
      }

      next();
    } catch (err) {
      console.error("Erro na verificação do token:", err.message); // Log para debug (ajuda a ver se é JWT_SECRET ou expiração)
      res.status(400).json({ msg: "Token inválido" });
    }
  };
}

module.exports = auth;
