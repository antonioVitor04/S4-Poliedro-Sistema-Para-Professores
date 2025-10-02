class CalculadoraMedias {
  /// Calcula a média das provas (considera itens que contenham "prova" no tipo)
  static double calcularMediaProvas(List<dynamic> detalhes) {
    final provas = _filtrarPorTipo(detalhes, "prova");
    return _calcularMediaPonderada(provas);
  }

  /// Calcula a média das atividades (considera itens que contenham "atividade" no tipo)
  static double calcularMediaAtividades(List<dynamic> detalhes) {
    final atividades = _filtrarPorTipo(detalhes, "atividade");
    return _calcularMediaPonderada(atividades);
  }

  /// Calcula a média final (70% provas + 30% atividades)
  static double calcularMediaFinal(List<dynamic> detalhes) {
    final mediaProvas = calcularMediaProvas(detalhes);
    final mediaAtividades = calcularMediaAtividades(detalhes);

    // Se não há provas, retorna apenas atividades
    if (mediaProvas == 0.0) return mediaAtividades;
    
    // Se não há atividades, retorna apenas provas
    if (mediaAtividades == 0.0) return mediaProvas;

    // Aplica pesos: 70% provas + 30% atividades
    return (mediaProvas * 0.7) + (mediaAtividades * 0.3);
  }

  /// Filtra os detalhes por tipo (case insensitive)
  static List<dynamic> _filtrarPorTipo(List<dynamic> detalhes, String tipo) {
    return detalhes.where((detalhe) {
      final tipoItem = detalhe["tipo"].toString().toLowerCase();
      return tipoItem.contains(tipo.toLowerCase());
    }).toList();
  }

  /// Calcula média ponderada
  static double _calcularMediaPonderada(List<dynamic> itens) {
    if (itens.isEmpty) return 0.0;

    double somaNotasPesos = 0.0;
    double somaPesos = 0.0;

    for (final item in itens) {
      final nota = _converterParaDouble(item["nota"]);
      final peso = _converterParaDouble(item["peso"]);
      
      somaNotasPesos += nota * peso;
      somaPesos += peso;
    }

    // Evita divisão por zero
    if (somaPesos == 0.0) return 0.0;

    return somaNotasPesos / somaPesos;
  }

  /// Converte valor para double (tratamento seguro)
  static double _converterParaDouble(dynamic valor) {
    if (valor is double) return valor;
    if (valor is int) return valor.toDouble();
    if (valor is String) return double.tryParse(valor) ?? 0.0;
    return 0.0;
  }

  /// Processa todas as disciplinas e calcula as médias automaticamente
  static List<Map<String, dynamic>> processarDisciplinas(List<Map<String, dynamic>> disciplinas) {
    return disciplinas.map((disciplina) {
      final detalhes = disciplina["detalhes"] as List<dynamic>;
      
      return {
        ...disciplina,
        "mediaProvas": calcularMediaProvas(detalhes),
        "mediaAtividades": calcularMediaAtividades(detalhes),
        "mediaFinal": calcularMediaFinal(detalhes),
      };
    }).toList();
  }

  /// Atualiza uma disciplina específica com os cálculos
  static Map<String, dynamic> processarDisciplina(Map<String, dynamic> disciplina) {
    final detalhes = disciplina["detalhes"] as List<dynamic>;
    
    return {
      ...disciplina,
      "mediaProvas": calcularMediaProvas(detalhes),
      "mediaAtividades": calcularMediaAtividades(detalhes),
      "mediaFinal": calcularMediaFinal(detalhes),
    };
  }
}