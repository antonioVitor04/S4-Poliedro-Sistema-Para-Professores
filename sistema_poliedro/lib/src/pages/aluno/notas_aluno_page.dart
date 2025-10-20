import 'package:flutter/material.dart';
import 'package:sistema_poliedro/src/components/lista_disciplinas.dart';
import 'package:sistema_poliedro/src/services/calculadora_medias.dart';
import 'package:sistema_poliedro/src/styles/cores.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // Adicione esta dependência no pubspec.yaml se não tiver

class NotasPage extends StatefulWidget {
  const NotasPage({super.key});

  @override
  State<NotasPage> createState() => _NotasPageState();
}

class _NotasPageState extends State<NotasPage> {
  final TextEditingController _searchController = TextEditingController();
  String searchText = "";
  List<Map<String, dynamic>> disciplinas = [];
  List<String> periodosDisponiveis = [];
  String? periodoSelecionado;
  List<dynamic> allDisciplinasRaw = [];
  bool isLoading = false;
  String? errorMessage;
  String? token;

  // Base URL da API
  static const String baseUrl = 'http://localhost:5000/api/notas';

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    print('DEBUG: Iniciando _loadToken...');
    final prefs = await SharedPreferences.getInstance();
    final String? loadedToken = prefs.getString(
      'token',
    ); // Corrigido para 'token' conforme AuthService
    setState(() {
      token = loadedToken;
    });
    final bool hasValidToken = token != null && token!.isNotEmpty;
    print(
      'DEBUG: Token carregado: ${hasValidToken ? "SIM (primeiros 10 chars: ${token!.substring(0, token!.length > 10 ? 10 : token!.length)}...)" : "NÃO (valor: '${token ?? 'null'}')"}',
    );
    if (hasValidToken) {
      _carregarPeriodos();
    } else {
      // Redirecione para login ou trate o erro de não autenticado
      setState(() {
        errorMessage = 'Usuário não autenticado. Faça login novamente.';
      });
      print(
        'DEBUG: Token inválido (null ou vazio), definindo errorMessage para não autenticado.',
      );
    }
  }

  String _computePeriod(dynamic disciplina) {
    final String? createdAtStr = disciplina['createdAt'];
    if (createdAtStr == null || createdAtStr.isEmpty) return '';
    try {
      final DateTime date = DateTime.parse(createdAtStr);
      final int year = date.year;
      final int quarter = ((date.month - 1) ~/ 3) + 1;
      return '$year - ${quarter}º Trimestre';
    } catch (e) {
      print('DEBUG: Erro ao computar período para disciplina $disciplina: $e');
      return '';
    }
  }

  Future<void> _carregarPeriodos() async {
    final bool hasValidToken = token != null && token!.isNotEmpty;
    if (!hasValidToken) {
      print('DEBUG: Token inválido em _carregarPeriodos, retornando.');
      setState(() {
        errorMessage = 'Token inválido. Faça login novamente.';
        isLoading = false;
      });
      return;
    }

    print('DEBUG: Iniciando _carregarPeriodos...');
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      print('DEBUG: Fazendo GET para $baseUrl/disciplinas');
      print(
        'DEBUG: Headers: Content-Type: application/json, Authorization: Bearer $token (mascarado como válido)',
      );
      final response = await http.get(
        Uri.parse('$baseUrl/disciplinas'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('DEBUG: Status Code recebido: ${response.statusCode}');
      print('DEBUG: Response Headers: ${response.headers}');
      print(
        'DEBUG: Response Body (primeiros 200 chars): ${response.body.length > 200 ? response.body.substring(0, 200) + '...' : response.body}',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('DEBUG: Dados decodificados: ${data.length} disciplinas');
        allDisciplinasRaw = data;

        final Set<String> periodosSet = <String>{};
        for (var d in data) {
          final String p = _computePeriod(d);
          if (p.isNotEmpty) {
            periodosSet.add(p);
          }
        }
        print('DEBUG: Períodos computados: $periodosSet');

        setState(() {
          periodosDisponiveis = periodosSet.toList()
            ..sort((a, b) => b.compareTo(a));
          print('DEBUG: Períodos ordenados: $periodosDisponiveis');
          if (periodosDisponiveis.isNotEmpty) {
            periodoSelecionado = periodosDisponiveis
                .first; // Seleciona o mais recente (primeiro após sort descending)
            print('DEBUG: Período selecionado: $periodoSelecionado');
          }
          isLoading = false;
          if (periodoSelecionado != null) {
            _carregarDisciplinas(); // Carrega inicial para o periodo selecionado
          }
        });
      } else if (response.statusCode == 401) {
        print('DEBUG: Status 401 detectado - tratando como sessão expirada.');
        setState(() {
          errorMessage = 'Sessão expirada. Faça login novamente.';
          isLoading = false;
        });
        // Limpe o token
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token'); // Corrigido para 'token'
        setState(() {
          token = null;
        });
        print('DEBUG: Token removido do SharedPreferences.');
      } else {
        print(
          'DEBUG: Status Code não é 200 nem 401: ${response.statusCode} - lançando exceção.',
        );
        throw Exception(
          'Erro ao carregar períodos: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('DEBUG: Exceção em _carregarPeriodos: $e');
      setState(() {
        errorMessage = 'Erro ao carregar períodos: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _carregarDisciplinas() async {
    final bool hasValidToken = token != null && token!.isNotEmpty;
    if (periodoSelecionado == null ||
        allDisciplinasRaw.isEmpty ||
        !hasValidToken) {
      print(
        'DEBUG: Condições não atendidas em _carregarDisciplinas: periodo=$periodoSelecionado, allDisciplinas=${allDisciplinasRaw.length}, hasValidToken=$hasValidToken',
      );
      return;
    }

    print('DEBUG: Iniciando _carregarDisciplinas para $periodoSelecionado...');
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Filtra no front usando o período computado
      final List<dynamic> disciplinasFiltradas = allDisciplinasRaw
          .where((d) => _computePeriod(d) == periodoSelecionado)
          .toList();
      print('DEBUG: Disciplinas filtradas: ${disciplinasFiltradas.length}');

      // Mapeia para o formato esperado pela ListaDisciplinas
      final List<Map<String, dynamic>>
      dadosProcessados = disciplinasFiltradas.map((d) {
        return {
          "disciplina": d['nome'],
          "detalhes": (d['detalhes'] as List<dynamic>)
              .map(
                (det) => {
                  "tipo": det['tipo']
                      .toLowerCase(), // Padroniza para 'prova' ou 'atividade'
                  "nota": det['nota'] as double,
                  "peso": det['peso'] as double,
                  // Nota: descricao não é usada no front atual, mas pode ser adicionada se necessário
                },
              )
              .toList(),
          // Adiciona medias já calculadas pelo backend
          "mediaProvas": d['mediaProvas'],
          "mediaAtividades": d['mediaAtividades'],
          "mediaFinal": d['mediaFinal'],
        };
      }).toList();
      print('DEBUG: Dados processados: ${dadosProcessados.length} itens');

      setState(() {
        // Usa processarDisciplinas se necessário para computações adicionais, senão usa direto
        disciplinas = CalculadoraMedias.processarDisciplinas(dadosProcessados);
        print(
          'DEBUG: Disciplinas processadas pela CalculadoraMedias: ${disciplinas.length}',
        );
        isLoading = false;
      });
    } catch (e) {
      print('DEBUG: Exceção em _carregarDisciplinas: $e');
      setState(() {
        errorMessage = 'Erro ao carregar disciplinas: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasValidToken = token != null && token!.isNotEmpty;
    print(
      'DEBUG: Build chamado. Token válido: ${hasValidToken ? "SIM" : "NÃO"}, Loading: $isLoading, Error: ${errorMessage ?? "NENHUM"}',
    );
    return Scaffold(
      backgroundColor: AppColors.branco,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isMobile = constraints.maxWidth < 600;
            final double padding = isMobile ? 12.0 : 24.0;

            return Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// CABEÇALHO RESPONSIVO
                  _buildHeader(isMobile),
                  SizedBox(height: isMobile ? 12 : 20),

                  /// SELETOR DE PERÍODO (TRIMESTRE)
                  _buildPeriodoSelector(isMobile),
                  if (errorMessage != null) ...[
                    SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red[800], size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: TextStyle(color: Colors.red[800]),
                            ),
                          ),
                          if (errorMessage!.contains('login') ||
                              errorMessage!.contains('autenticado') ||
                              errorMessage!.contains('expirada')) ...[
                            TextButton(
                              onPressed: () {
                                print(
                                  'DEBUG: Botão "Fazer Login" pressionado.',
                                );
                                // Navegue para tela de login
                                // Navigator.pushNamed(context, '/login');
                              },
                              child: const Text('Fazer Login'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: isMobile ? 12 : 16),

                  /// BARRA DE PESQUISA RESPONSIVA
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 600,
                      minWidth: 300,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() => searchText = value.toLowerCase());
                        print('DEBUG: Search text alterado para: $searchText');
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: "Pesquisar disciplina...",
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  /// LEGENDA RESPONSIVA
                  _buildLegend(isMobile),
                  SizedBox(height: isMobile ? 12 : 16),

                  /// LISTA DE DISCIPLINAS OU MENSAGEM DE VAZIO
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildListaOuVazio(isMobile),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPeriodoSelector(bool isMobile) {
    print(
      'DEBUG: _buildPeriodoSelector chamado. Períodos disponíveis: ${periodosDisponiveis.length}',
    );
    if (periodosDisponiveis.isEmpty) {
      return const SizedBox.shrink(); // Não mostra se não há períodos
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Período:",
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 4),
        Container(
          width: isMobile ? double.infinity : 300,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: periodoSelecionado,
              isExpanded: true,
              hint: const Text("Selecione um período"),
              items: periodosDisponiveis.map((String periodo) {
                return DropdownMenuItem<String>(
                  value: periodo,
                  child: Text(periodo),
                );
              }).toList(),
              onChanged: (String? newValue) {
                print('DEBUG: Período alterado para: $newValue');
                setState(() {
                  periodoSelecionado = newValue;
                });
                _carregarDisciplinas();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListaOuVazio(bool isMobile) {
    print(
      'DEBUG: _buildListaOuVazio chamado. Disciplinas totais: ${disciplinas.length}, searchText: $searchText',
    );
    final List<Map<String, dynamic>> disciplinasFiltradas = disciplinas
        .where((d) => d['disciplina'].toLowerCase().contains(searchText))
        .toList();
    print(
      'DEBUG: Disciplinas filtradas por search: ${disciplinasFiltradas.length}',
    );

    if (disciplinasFiltradas.isEmpty) {
      print('DEBUG: Lista vazia, mostrando mensagem.');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: isMobile ? 48 : 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              periodoSelecionado != null
                  ? "Nenhuma nota cadastrada para este trimestre."
                  : "Selecione um período para visualizar as notas.",
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (periodoSelecionado != null) ...[
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  print('DEBUG: Botão "Recarregar" pressionado.');
                  _carregarPeriodos(); // Recarrega para verificar atualizações
                },
                child: const Text("Recarregar"),
              ),
            ],
          ],
        ),
      );
    }

    print(
      'DEBUG: Renderizando ListaDisciplinas com ${disciplinasFiltradas.length} itens.',
    );
    return ListaDisciplinas(
      disciplinas: disciplinasFiltradas,
      searchText: "", // A filtragem já foi feita no pai
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Notas",
          style: TextStyle(
            fontSize: isMobile ? 22 : 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        if (!isMobile) const SizedBox(height: 4),
        if (!isMobile)
          Text(
            "Acompanhe seu desempenho acadêmico",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
      ],
    );
  }

  Widget _buildLegend(bool isMobile) {
    return Wrap(
      spacing: isMobile ? 12 : 20,
      runSpacing: isMobile ? 8 : 0,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: isMobile ? 4 : 6, backgroundColor: Colors.red),
            SizedBox(width: isMobile ? 4 : 6),
            Text(
              "Abaixo da média",
              style: TextStyle(fontSize: isMobile ? 12 : 14),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: isMobile ? 4 : 6,
              backgroundColor: Colors.teal,
            ),
            SizedBox(width: isMobile ? 4 : 6),
            Text(
              "Acima da média",
              style: TextStyle(fontSize: isMobile ? 12 : 14),
            ),
          ],
        ),
      ],
    );
  }
}
