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

  /// Calcula a média final baseada nos pesos totais das provas e atividades
  static double calcularMediaFinal(List<dynamic> detalhes) {
    final provas = _filtrarPorTipo(detalhes, "prova");
    final atividades = _filtrarPorTipo(detalhes, "atividade");

    final mediaProvas = _calcularMediaPonderada(provas);
    final mediaAtividades = _calcularMediaPonderada(atividades);

    // Calcula os pesos totais
    final pesoTotalProvas = _calcularPesoTotal(provas);
    final pesoTotalAtividades = _calcularPesoTotal(atividades);
    final pesoTotalGeral = pesoTotalProvas + pesoTotalAtividades;

    // Se não há itens, retorna 0
    if (pesoTotalGeral == 0.0) return 0.0;

    // Se só há provas, retorna média das provas
    if (pesoTotalAtividades == 0.0) return mediaProvas;

    // Se só há atividades, retorna média das atividades
    if (pesoTotalProvas == 0.0) return mediaAtividades;

    // Calcula a média final ponderada pelos pesos totais
    final double pesoRelativoProvas = pesoTotalProvas / pesoTotalGeral;
    final double pesoRelativoAtividades = pesoTotalAtividades / pesoTotalGeral;

    return (mediaProvas * pesoRelativoProvas) + (mediaAtividades * pesoRelativoAtividades);
  }

  /// Calcula o peso total de uma lista de itens
  static double _calcularPesoTotal(List<dynamic> itens) {
    double pesoTotal = 0.0;
    
    for (final item in itens) {
      final peso = _converterParaDouble(item["peso"]);
      pesoTotal += peso;
    }
    
    return pesoTotal;
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