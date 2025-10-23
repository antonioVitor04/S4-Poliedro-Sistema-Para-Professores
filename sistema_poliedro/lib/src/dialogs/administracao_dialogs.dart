import 'package:flutter/material.dart';
import '../styles/cores.dart';
import '../styles/fontes.dart';
import '../models/modelo_usuario.dart';
import '../models/modelo_card_disciplina.dart';
import '../models/modelo_usuario.dart';
import '../models/modelo_disciplina.dart';
import '../models/modelo_avaliacao.dart';

// Diálogo para adicionar/editar usuário (PADRONIZADO)
class UserDialog extends StatefulWidget {
  final Usuario? usuario;
  final bool isEdit;
  final bool isAluno;
  final String? token;

  const UserDialog({
    super.key,
    this.usuario,
    required this.isEdit,
    required this.isAluno,
    this.token,
  });

  @override
  State<UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<UserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _raController = TextEditingController();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.usuario != null) {
      _nomeController.text = widget.usuario!.nome; // nome não pode ser nulo
      _emailController.text = widget.usuario!.email; // email não pode ser nulo
      _raController.text =
          widget.usuario!.ra ?? ''; // ra pode ser nulo, então usa fallback
      if (!widget.isAluno && widget.usuario!.tipo == 'admin') {
        _isAdmin = true;
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _raController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final userData = <String, String>{
        'nome': _nomeController.text,
        'email': _emailController.text,
        'ra': _raController.text,
      };
      if (!widget.isAluno) {
        userData['tipo'] = _isAdmin ? 'admin' : 'professor';
      }
      Navigator.of(context).pop(userData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
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
              child: Form(
                key: _formKey,
                child: Column(
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
                              widget.isAluno
                                  ? Icons.school
                                  : Icons.school_outlined,
                              size: 32,
                              color: AppColors.azulClaro,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${widget.isEdit ? 'Editar' : 'Adicionar'} ${widget.isAluno ? 'Aluno' : 'Professor'}',
                            style: AppTextStyles.fonteUbuntu.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.isEdit
                                ? 'Atualize as informações do ${widget.isAluno ? 'aluno' : 'professor'}'
                                : 'Adicione um novo ${widget.isAluno ? 'aluno' : 'professor'} ao sistema',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nomeController,
                      cursorColor: AppColors.azulClaro,
                      style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Nome completo*',
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
                        prefixIcon: Icon(
                          Icons.person,
                          color: AppColors.azulClaro,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, insira o nome';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      cursorColor: AppColors.azulClaro,
                      style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Email*',
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
                        prefixIcon: Icon(
                          Icons.email,
                          color: AppColors.azulClaro,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, insira o email';
                        }
                        if (!value.contains('@')) {
                          return 'Por favor, insira um email válido';
                        }
                        return null;
                      },
                    ),
                    if (widget.isAluno) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _raController,
                        cursorColor: AppColors.azulClaro,
                        style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'RA*',
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
                          prefixIcon: Icon(
                            Icons.badge,
                            color: AppColors.azulClaro,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, insira o RA';
                          }
                          return null;
                        },
                      ),
                    ],
                    if (!widget.isAluno) ...[
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'É Administrador?',
                          style: AppTextStyles.fonteUbuntu.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Administradores podem criar outros professores',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        value: _isAdmin,
                        onChanged: (value) {
                          setState(() {
                            _isAdmin = value;
                          });
                        },
                        activeColor: AppColors.azulClaro,
                      ),
                    ],
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.azulClaro,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                          child: Text(
                            widget.isEdit ? 'Salvar' : 'Adicionar',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Diálogo de confirmação de exclusão (PADRONIZADO)
class DeleteDialog extends StatelessWidget {
  final Usuario usuario;

  const DeleteDialog({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          size: 32,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Confirmar Exclusão',
                        style: AppTextStyles.fonteUbuntu.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tem certeza que deseja excluir este usuário?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.grey.shade600, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              usuario.nome,
                              style: AppTextStyles.fonteUbuntu.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              usuario.email,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Esta ação não pode ser desfeita.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      child: const Text(
                        'Excluir',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Diálogo para adicionar avaliação global (PADRONIZADO)
class AddGlobalAvaliacaoDialog extends StatefulWidget {
  final Disciplina disciplina;

  const AddGlobalAvaliacaoDialog({super.key, required this.disciplina});

  @override
  State<AddGlobalAvaliacaoDialog> createState() =>
      _AddGlobalAvaliacaoDialogState();
}

class _AddGlobalAvaliacaoDialogState extends State<AddGlobalAvaliacaoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _pesoController = TextEditingController(text: '1.0');
  String _tipo = 'prova';

  @override
  void dispose() {
    _nomeController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
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
              child: Form(
                key: _formKey,
                child: Column(
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
                              Icons.assignment_add,
                              size: 32,
                              color: AppColors.azulClaro,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nova Avaliação',
                            style: AppTextStyles.fonteUbuntu.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Disciplina: ${widget.disciplina.titulo}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nomeController,
                      cursorColor: AppColors.azulClaro,
                      style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Nome da Avaliação*',
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
                        prefixIcon: Icon(
                          Icons.title,
                          color: AppColors.azulClaro,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, insira o nome da avaliação';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _tipo,
                      decoration: InputDecoration(
                        labelText: 'Tipo de Avaliação*',
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
                        prefixIcon: Icon(
                          Icons.category,
                          color: AppColors.azulClaro,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'prova',
                          child: Text(
                            'Prova',
                            style: AppTextStyles.fonteUbuntu,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'atividade',
                          child: Text(
                            'Atividade',
                            style: AppTextStyles.fonteUbuntu,
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _tipo = value ?? 'prova'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pesoController,
                      cursorColor: AppColors.azulClaro,
                      style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Peso da Avaliação*',
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
                        prefixIcon: Icon(
                          Icons.balance,
                          color: AppColors.azulClaro,
                        ),
                        suffixText: 'pontos',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      validator: (value) {
                        final num = double.tryParse(value ?? '');
                        if (num == null || num <= 0) {
                          return 'Peso positivo obrigatório';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              final newAv = Avaliacao(
                                id: '',
                                nome: _nomeController.text,
                                tipo: _tipo,
                                peso: double.parse(_pesoController.text),
                                data: DateTime.now(),
                              );
                              Navigator.pop(context, newAv);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.azulClaro,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                          child: const Text(
                            'Criar Avaliação',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Diálogo para editar avaliação global (PADRONIZADO)
class EditAvaliacaoGlobalDialog extends StatefulWidget {
  final Avaliacao initialAv;

  const EditAvaliacaoGlobalDialog({super.key, required this.initialAv});

  @override
  State<EditAvaliacaoGlobalDialog> createState() =>
      _EditAvaliacaoGlobalDialogState();
}

class _EditAvaliacaoGlobalDialogState extends State<EditAvaliacaoGlobalDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _pesoController;
  late String _tipo;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.initialAv.nome);
    _pesoController = TextEditingController(
      text: widget.initialAv.peso?.toString() ?? '1.0',
    );
    _tipo = widget.initialAv.tipo;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
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
              child: Form(
                key: _formKey,
                child: Column(
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
                              Icons.edit,
                              size: 32,
                              color: AppColors.azulClaro,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Editar Avaliação',
                            style: AppTextStyles.fonteUbuntu.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Atualize as informações da avaliação',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nomeController,
                      cursorColor: AppColors.azulClaro,
                      style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Nome da Avaliação*',
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
                        prefixIcon: Icon(
                          Icons.title,
                          color: AppColors.azulClaro,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, insira o nome da avaliação';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _tipo,
                      decoration: InputDecoration(
                        labelText: 'Tipo de Avaliação*',
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
                        prefixIcon: Icon(
                          Icons.category,
                          color: AppColors.azulClaro,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'prova',
                          child: Text(
                            'Prova',
                            style: AppTextStyles.fonteUbuntu,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'atividade',
                          child: Text(
                            'Atividade',
                            style: AppTextStyles.fonteUbuntu,
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _tipo = value ?? 'prova'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pesoController,
                      cursorColor: AppColors.azulClaro,
                      style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Peso da Avaliação*',
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
                        prefixIcon: Icon(
                          Icons.balance,
                          color: AppColors.azulClaro,
                        ),
                        suffixText: 'pontos',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      validator: (value) {
                        final num = double.tryParse(value ?? '');
                        if (num == null || num <= 0) {
                          return 'Peso positivo obrigatório';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              final newAv = Avaliacao(
                                id: '',
                                nome: _nomeController.text,
                                tipo: _tipo,
                                peso: double.parse(_pesoController.text),
                                data: widget.initialAv.data,
                              );
                              Navigator.pop(context, newAv);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.azulClaro,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                          child: const Text(
                            'Salvar',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
