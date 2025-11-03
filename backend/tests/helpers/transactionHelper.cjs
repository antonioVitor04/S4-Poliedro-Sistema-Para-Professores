// Helper para executar operações que podem usar transações em ambiente de teste
const executeWithTestFallback = async (operation, fallbackOperation = null) => {
  try {
    // Tenta executar com transação
    const session = await mongoose.startSession();
    
    try {
      session.startTransaction();
      const result = await operation(session);
      await session.commitTransaction();
      return result;
    } catch (error) {
      await session.abortTransaction();
      throw error;
    } finally {
      session.endSession();
    }
  } catch (error) {
    // Se falhar por causa de transações, executa sem transação
    if (error.message.includes('Transaction numbers') || 
        error.message.includes('replica set') ||
        error.code === 20) {
      console.log('⚠️  Transações não suportadas, executando sem transação...');
      return fallbackOperation ? await fallbackOperation() : await operation();
    }
    throw error;
  }
};

module.exports = { executeWithTestFallback };