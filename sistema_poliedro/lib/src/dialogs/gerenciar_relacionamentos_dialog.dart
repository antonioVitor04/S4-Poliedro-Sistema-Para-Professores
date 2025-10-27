import 'package:flutter/material.dart';
import '../models/modelo_card_disciplina.dart';
import '../services/card_disciplina_service.dart';
import '../styles/cores.dart';
import '../styles/fontes.dart';

class GerenciarRelacionamentosDialog extends StatefulWidget {
  final CardDisciplina card;
  final VoidCallback onUpdated;

  const GerenciarRelacionamentosDialog({
    super.key,
    required this.card,
    required this.onUpdated,
  });

  @override
  State<GerenciarRelacionamentosDialog> createState() =>
      _GerenciarRelacionamentosDialogState();
}

class _GerenciarRelacionamentosDialogState
    extends State<GerenciarRelacionamentosDialog> {
  final List<Map<String, dynamic>> _professoresSelecionados = [];
  final List<Map<String, dynamic>> _alunosSelecionados = [];
  bool _isLoading = false;
  bool _carregandoDadosIniciais = true;
  final TextEditingController _professorController = TextEditingController();
  final TextEditingController _alunoController = TextEditingController();
  List<Map<String, dynamic>> _sugestoesProfessores = [];
  List<Map<String, dynamic>> _sugestoesAlunos = [];
  bool _buscandoProfessores = false;
  bool _buscandoAlunos = false;

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    try {
      setState(() {
        _carregandoDadosIniciais = true;
      });

      // Buscar dados completos da disciplina
      final disciplinaCompleta = await CardDisciplinaService.getCardBySlug(
        widget.card.slug,
      );

      // Carregar professores com dados reais
      if (disciplinaCompleta.professores.isNotEmpty) {
        for (var prof in disciplinaCompleta.professores) {
          if (prof is Map) {
            _professoresSelecionados.add({
              '_id': prof['_id'] ?? prof['id'],
              'nome': prof['nome'] ?? 'Professor',
              'email': prof['email'] ?? '',
            });
          } else if (prof is String) {
            // Se for apenas ID, buscar dados completos
            final professorCompleto = await _buscarProfessorPorId(prof);
            if (professorCompleto != null) {
              _professoresSelecionados.add(professorCompleto);
            }
          }
        }
      }

      // Carregar alunos com dados reais
      if (disciplinaCompleta.alunos.isNotEmpty) {
        for (var aluno in disciplinaCompleta.alunos) {
          if (aluno is Map) {
            _alunosSelecionados.add({
              '_id': aluno['_id'] ?? aluno['id'],
              'nome': aluno['nome'] ?? 'Aluno',
              'ra': aluno['ra'] ?? '',
            });
          } else if (aluno is String) {
            // Se for apenas ID, buscar dados completos
            final alunoCompleto = await _buscarAlunoPorId(aluno);
            if (alunoCompleto != null) {
              _alunosSelecionados.add(alunoCompleto);
            }
          }
        }
      }
    } catch (e) {
      print('Erro ao carregar dados iniciais: $e');
      // Fallback: usar dados básicos se a busca falhar
      _carregarDadosBasicos();
    } finally {
      setState(() {
        _carregandoDadosIniciais = false;
      });
    }
  }

  // Fallback para carregar dados básicos
  void _carregarDadosBasicos() {
    if (widget.card.professores.isNotEmpty) {
      _professoresSelecionados.addAll(
        widget.card.professores.map((prof) {
          if (prof is Map) {
            return {
              '_id': prof['_id'] ?? prof['id'],
              'nome': prof['nome'] ?? 'Professor',
              'email': prof['email'] ?? '',
            };
          }
          return {'_id': prof.toString(), 'nome': 'Professor', 'email': ''};
        }).toList(),
      );
    }

    if (widget.card.alunos.isNotEmpty) {
      _alunosSelecionados.addAll(
        widget.card.alunos.map((aluno) {
          if (aluno is Map) {
            return {
              '_id': aluno['_id'] ?? aluno['id'],
              'nome': aluno['nome'] ?? 'Aluno',
              'ra': aluno['ra'] ?? '',
            };
          }
          return {'_id': aluno.toString(), 'nome': 'Aluno', 'ra': ''};
        }).toList(),
      );
    }
  }

  // Buscar dados completos do professor por ID
  Future<Map<String, dynamic>?> _buscarProfessorPorId(String id) async {
    try {
      // Implementar busca de professor por ID
      // Por enquanto, retornar null para usar dados básicos
      return null;
    } catch (e) {
      print('Erro ao buscar professor $id: $e');
      return null;
    }
  }

  // Buscar dados completos do aluno por ID
  Future<Map<String, dynamic>?> _buscarAlunoPorId(String id) async {
    try {
      // Implementar busca de aluno por ID
      // Por enquanto, retornar null para usar dados básicos
      return null;
    } catch (e) {
      print('Erro ao buscar aluno $id: $e');
      return null;
    }
  }

  Future<void> _buscarProfessores(String email) async {
    if (email.isEmpty) {
      setState(() {
        _sugestoesProfessores = [];
      });
      return;
    }

    setState(() {
      _buscandoProfessores = true;
    });

    try {
      final professores = await CardDisciplinaService.buscarProfessoresPorEmail(
        email,
      );

      // FILTRAR: Remover professores já selecionados
      final professoresFiltrados = professores
          .where(
            (prof) =>
                !_professoresSelecionados.any((p) => p['_id'] == prof['_id']),
          )
          .toList();

      setState(() {
        _sugestoesProfessores = professoresFiltrados;
      });
    } catch (e) {
      print('Erro ao buscar professores: $e');
      setState(() {
        _sugestoesProfessores = [];
      });
    } finally {
      setState(() {
        _buscandoProfessores = false;
      });
    }
  }

  Future<void> _buscarAlunos(String ra) async {
    if (ra.isEmpty) {
      setState(() {
        _sugestoesAlunos = [];
      });
      return;
    }

    setState(() {
      _buscandoAlunos = true;
    });

    try {
      final alunos = await CardDisciplinaService.buscarAlunosPorRA(ra);

      // FILTRAR: Remover alunos já selecionados
      final alunosFiltrados = alunos
          .where(
            (aluno) =>
                !_alunosSelecionados.any((a) => a['_id'] == aluno['_id']),
          )
          .toList();

      setState(() {
        _sugestoesAlunos = alunosFiltrados;
      });
    } catch (e) {
      print('Erro ao buscar alunos: $e');
      setState(() {
        _sugestoesAlunos = [];
      });
    } finally {
      setState(() {
        _buscandoAlunos = false;
      });
    }
  }

  void _adicionarProfessor(Map<String, dynamic> professor) {
    if (!_professoresSelecionados.any((p) => p['_id'] == professor['_id'])) {
      setState(() {
        _professoresSelecionados.add(professor);
        _professorController.clear();
        _sugestoesProfessores = [];
      });
    }
  }

  void _adicionarAluno(Map<String, dynamic> aluno) {
    if (!_alunosSelecionados.any((a) => a['_id'] == aluno['_id'])) {
      setState(() {
        _alunosSelecionados.add(aluno);
        _alunoController.clear();
        _sugestoesAlunos = [];
      });
    }
  }

  void _removerProfessor(String professorId) {
    setState(() {
      _professoresSelecionados.removeWhere((p) => p['_id'] == professorId);
    });
  }

  void _removerAluno(String alunoId) {
    setState(() {
      _alunosSelecionados.removeWhere((a) => a['_id'] == alunoId);
    });
  }

  Future<void> _salvarAlteracoes() async {
    setState(() => _isLoading = true);

    try {
      final professoresIds = _professoresSelecionados
          .map((p) => p['_id'].toString())
          .toList();
      final alunosIds = _alunosSelecionados
          .map((a) => a['_id'].toString())
          .toList();

      // CORREÇÃO: Passar os argumentos obrigatórios corretamente
      await CardDisciplinaService.atualizarCard(
        widget.card.id, // id (String)
        widget.card.titulo, // titulo (String)
        null, // imagemFile (PlatformFile?) - opcional
        null, // iconeFile (PlatformFile?) - opcional
        professores: professoresIds, // professores (List<String>?) - opcional
        alunos: alunosIds, // alunos (List<String>?) - opcional
      );

      widget.onUpdated();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Acessos atualizados com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar acessos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(maxWidth: isMobile ? 400 : 500),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _carregandoDadosIniciais
                  ? _buildLoadingIndicator()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.group,
                                  size: 32,
                                  color: AppColors.azulClaro,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Gerenciar Acessos',
                                style: AppTextStyles.fonteUbuntu.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Disciplina: ${widget.card.titulo}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Informações do Criador
                        _buildInfoCriador(),

                        const SizedBox(height: 16),

                        // Seção de Professores
                        _buildSelecaoProfessores(),

                        const SizedBox(height: 16),

                        // Seção de Alunos
                        _buildSelecaoAlunos(),

                        const SizedBox(height: 24),

                        // Botões
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text('Cancelar'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _salvarAlteracoes,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.azulClaro,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text('Salvar'),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.azulClaro),
          ),
          const SizedBox(height: 16),
          Text(
            'Carregando dados...',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCriador() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, size: 20, color: AppColors.azulClaro),
              const SizedBox(width: 8),
              Text(
                'Criador da Disciplina',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.azulClaro,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (widget.card.criadoPor is Map)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nome: ${widget.card.nomeCriador}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                ),
                if (widget.card.emailCriador.isNotEmpty)
                  Text(
                    'Email: ${widget.card.emailCriador}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
              ],
            )
          else
            Text(
              'Professor',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelecaoProfessores() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Professores',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.azulClaro,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.azulClaro.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_professoresSelecionados.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.azulClaro,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Campo de busca de professores
              // Campo Professor
              TextFormField(
                controller: _professorController,
                cursorColor: AppColors.azulClaro,
                style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Digite o email do professor...',
                  labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                    color: Colors.black,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.preto.withOpacity(0.1),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.azulClaro,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  prefixIcon: Icon(Icons.email, color: AppColors.azulClaro),
                  suffixIcon: _buscandoProfessores
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
                onChanged: _buscarProfessores,
              ),

              // Sugestões de professores (FILTRADAS - não mostram já adicionados)
              if (_sugestoesProfessores.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: _sugestoesProfessores
                        .map(
                          (professor) => ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.azulClaro,
                              child: Text(
                                professor['nome'] != null &&
                                        professor['nome'].isNotEmpty
                                    ? professor['nome']
                                          .substring(0, 1)
                                          .toUpperCase()
                                    : 'P',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            title: Text(professor['nome'] ?? 'Professor'),
                            subtitle: Text(professor['email'] ?? ''),
                            trailing: IconButton(
                              onPressed: () => _adicionarProfessor(professor),
                              icon: const Icon(Icons.add, color: Colors.green),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),

              const SizedBox(height: 12),

              // Lista de professores selecionados (COM DADOS REAIS)
              if (_professoresSelecionados.isNotEmpty)
                Column(
                  children: _professoresSelecionados
                      .map(
                        (professor) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.azulClaro,
                            child: Text(
                              professor['nome'] != null &&
                                      professor['nome'].isNotEmpty
                                  ? professor['nome']
                                        .substring(0, 1)
                                        .toUpperCase()
                                  : 'P',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          title: Text(
                            professor['nome'] ?? 'Professor',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            professor['email']?.isNotEmpty == true
                                ? professor['email']!
                                : 'Email não disponível',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          trailing: IconButton(
                            onPressed: () =>
                                _removerProfessor(professor['_id']),
                            icon: const Icon(
                              Icons.remove_circle,
                              color: Colors.red,
                            ),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                      .toList(),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Nenhum professor adicionado',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelecaoAlunos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Alunos',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_alunosSelecionados.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Campo de busca de alunos
              // Campo Aluno
              TextFormField(
                controller: _alunoController,
                cursorColor: AppColors.azulClaro,
                style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Digite o RA do aluno...',
                  labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                    color: Colors.black,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.preto.withOpacity(0.1),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.azulClaro,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  prefixIcon: Icon(Icons.person, color: AppColors.azulClaro),
                  suffixIcon: _buscandoAlunos
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
                onChanged: _buscarAlunos,
              ),

              // Sugestões de alunos (FILTRADAS - não mostram já adicionados)
              if (_sugestoesAlunos.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: _sugestoesAlunos
                        .map(
                          (aluno) => ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Text(
                                aluno['nome'] != null &&
                                        aluno['nome'].isNotEmpty
                                    ? aluno['nome']
                                          .substring(0, 1)
                                          .toUpperCase()
                                    : 'A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            title: Text(aluno['nome'] ?? 'Aluno'),
                            subtitle: Text('RA: ${aluno['ra'] ?? ''}'),
                            trailing: IconButton(
                              onPressed: () => _adicionarAluno(aluno),
                              icon: const Icon(Icons.add, color: Colors.green),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),

              const SizedBox(height: 12),

              // Lista de alunos selecionados (COM DADOS REAIS)
              if (_alunosSelecionados.isNotEmpty)
                Column(
                  children: _alunosSelecionados
                      .map(
                        (aluno) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Text(
                              aluno['nome'] != null && aluno['nome'].isNotEmpty
                                  ? aluno['nome'].substring(0, 1).toUpperCase()
                                  : 'A',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          title: Text(
                            aluno['nome'] ?? 'Aluno',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            aluno['ra']?.isNotEmpty == true
                                ? 'RA: ${aluno['ra']!}'
                                : 'RA não disponível',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          trailing: IconButton(
                            onPressed: () => _removerAluno(aluno['_id']),
                            icon: const Icon(
                              Icons.remove_circle,
                              color: Colors.red,
                            ),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                      .toList(),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Nenhum aluno adicionado',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
