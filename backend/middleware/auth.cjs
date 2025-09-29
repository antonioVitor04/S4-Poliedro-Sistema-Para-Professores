const jwt = require("jsonwebtoken");

function auth(role = null) {
  return (req, res, next) => {
    const token = req.header("Authorization")?.replace("Bearer ", "");
    if (!token) return res.status(401).json({ msg: "Acesso negado. Token ausente." });

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      req.user = decoded;

      // Se foi passada role, verifica
      if (role && decoded.role !== role) {
        return res.status(403).json({ msg: "Acesso negado. Permissão insuficiente." });
      }

      next();
    } catch (err) {
      res.status(400).json({ msg: "Token inválido" });
    }
  };
}

module.exports = auth;
