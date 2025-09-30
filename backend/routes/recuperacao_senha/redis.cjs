const redis = require("redis");
require("dotenv").config();

// Força IPv4 para evitar problemas no Windows (::1)
const REDIS_URL = process.env.REDIS_URL || "redis://127.0.0.1:6379";

const redisClient = redis.createClient({
  url: REDIS_URL,
});

// Log de erros
redisClient.on("error", (err) => console.error("Redis Client Error:", err));

// Log de conexão bem-sucedida
redisClient.on("connect", () => console.log("✅ Redis conectado"));

// Conectar ao Redis de forma assíncrona
(async () => {
  try {
    await redisClient.connect();
  } catch (err) {
    console.error("❌ Erro ao conectar no Redis:", err);
  }
})();

module.exports = redisClient;
