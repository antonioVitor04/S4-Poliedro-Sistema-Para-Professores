import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../styles/cores.dart';
import '../styles/fontes.dart';
import '../models/modelo_usuario.dart';
import '../models/modelo_disciplina.dart';
import '../models/modelo_avaliacao.dart';
import '../models/modelo_nota.dart';
import '../pages/professor/administracao_page.dart';
import 'package:collection/collection.dart';

// Diálogo para adicionar/editar usuário - RESPONSIVO
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
      _nomeController.text = widget.usuario!.nome;
      _emailController.text = widget.usuario!.email;
      _raController.text = widget.usuario!.ra ?? '';
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

  Map<String, String> _getImageHeaders() {
    if (widget.token == null) return {};
    return {'Authorization': 'Bearer ${widget.token}'};
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 900;
    final dialogWidth = isMobile
        ? screenWidth * 0.95
        : (isTablet ? 500.0 : 550.0);
    final primaryColor = AppColors.azulClaro;
    final Map<String, String> imageHeaders = _getImageHeaders();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 24,
      insetPadding: isMobile
          ? const EdgeInsets.all(16)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height * (isMobile ? 0.85 : 0.8),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.branco, AppColors.cinzaClaro],
          ),
        ),
        child: Column(
          children: [
            // Header do Dialog
            Container(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 20 : 24,
                isMobile ? 24 : 32,
                isMobile ? 20 : 24,
                isMobile ? 20 : 24,
              ),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.branco.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.isAluno ? Icons.school : Icons.school_outlined,
                      color: AppColors.branco,
                      size: isMobile ? 24 : 28,
                    ),
                  ),
                  SizedBox(width: isMobile ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.isEdit ? 'Editar' : 'Adicionar'} ${widget.isAluno ? 'Aluno' : 'Professor'}',
                          style: AppTextStyles.fonteUbuntu.copyWith(
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.branco,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (widget.isEdit)
                          Text(
                            widget.usuario!.nome,
                            style: AppTextStyles.fonteUbuntuSans.copyWith(
                              fontSize: isMobile ? 12 : 14,
                              color: AppColors.branco.withOpacity(0.9),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: isMobile ? 20 : 24,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Body do Form
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.isEdit &&
                            widget.usuario!.fotoUrl != null) ...[
                          Center(
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: widget.usuario!.fotoUrl!,
                                httpHeaders: imageHeaders,
                                width: isMobile ? 60 : 80,
                                height: isMobile ? 60 : 80,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    CircularProgressIndicator(strokeWidth: 2),
                                errorWidget: (context, url, error) {
                                  return CircleAvatar(
                                    backgroundColor: Colors.grey[200],
                                    radius: isMobile ? 30 : 40,
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.grey[400],
                                      size: isMobile ? 24 : 32,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: isMobile ? 12 : 16),
                          Text(
                            'Foto atual',
                            style: AppTextStyles.fonteUbuntuSans.copyWith(
                              fontSize: isMobile ? 12 : 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: isMobile ? 16 : 24),
                        ],
                        TextFormField(
                          controller: _nomeController,
                          style: AppTextStyles.fonteUbuntuSans.copyWith(
                            fontSize: isMobile ? 14 : 16,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Nome completo',
                            labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                              color: Colors.grey[600],
                              fontSize: isMobile ? 14 : 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.person,
                              color: Colors.grey[500],
                              size: isMobile ? 20 : 24,
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 16 : 20,
                              vertical: isMobile ? 14 : 16,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira o nome';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: isMobile ? 16 : 20),
                        TextFormField(
                          controller: _emailController,
                          style: AppTextStyles.fonteUbuntuSans.copyWith(
                            fontSize: isMobile ? 14 : 16,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                              color: Colors.grey[600],
                              fontSize: isMobile ? 14 : 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.email,
                              color: Colors.grey[500],
                              size: isMobile ? 20 : 24,
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 16 : 20,
                              vertical: isMobile ? 14 : 16,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira o email';
                            }
                            if (!value.contains('@')) {
                              return 'Por favor, insira um email válido';
                            }
                            return null;
                          },
                        ),
                        if (widget.isAluno) ...[
                          SizedBox(height: isMobile ? 16 : 20),
                          TextFormField(
                            controller: _raController,
                            style: AppTextStyles.fonteUbuntuSans.copyWith(
                              fontSize: isMobile ? 14 : 16,
                            ),
                            decoration: InputDecoration(
                              labelText: 'RA',
                              labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                                color: Colors.grey[600],
                                fontSize: isMobile ? 14 : 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: primaryColor,
                                  width: 2,
                                ),
                              ),
                              prefixIcon: Icon(
                                Icons.badge,
                                color: Colors.grey[500],
                                size: isMobile ? 20 : 24,
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 16 : 20,
                                vertical: isMobile ? 14 : 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, insira o RA';
                              }
                              return null;
                            },
                          ),
                        ],
                        if (!widget.isAluno) ...[
                          SizedBox(height: isMobile ? 16 : 20),
                          SwitchListTile(
                            title: Text(
                              'É Administrador?',
                              style: AppTextStyles.fonteUbuntu.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: isMobile ? 14 : 16,
                              ),
                            ),
                            subtitle: Text(
                              'Administradores podem criar outros professores.',
                              style: AppTextStyles.fonteUbuntuSans.copyWith(
                                fontSize: isMobile ? 12 : 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            value: _isAdmin,
                            onChanged: (value) {
                              setState(() {
                                _isAdmin = value;
                              });
                            },
                            activeColor: primaryColor,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Footer com botões
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              decoration: BoxDecoration(
                color: AppColors.branco,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.preto.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: isMobile
                  ? Column(
                      children: [
                        ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: AppColors.branco,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: Text(
                            widget.isEdit ? 'Salvar Alterações' : 'Adicionar',
                            style: AppTextStyles.fonteUbuntu.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey[300]!),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: Text(
                            'Cancelar',
                            style: AppTextStyles.fonteUbuntu.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              'Cancelar',
                              style: AppTextStyles.fonteUbuntu.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: AppColors.branco,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              widget.isEdit ? 'Salvar Alterações' : 'Adicionar',
                              style: AppTextStyles.fonteUbuntu.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Diálogo de confirmação de exclusão - RESPONSIVO
class DeleteDialog extends StatelessWidget {
  final Usuario usuario;

  const DeleteDialog({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final dialogWidth = isMobile ? screenWidth * 0.9 : 400.0;
    final primaryColor = AppColors.azulClaro;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 24,
      insetPadding: isMobile
          ? const EdgeInsets.all(20)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Container(
        width: dialogWidth,
        padding: EdgeInsets.all(isMobile ? 24 : 32),
        decoration: BoxDecoration(
          color: AppColors.branco,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.preto.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.vermelho.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                size: isMobile ? 48 : 56,
                color: AppColors.vermelho,
              ),
            ),
            SizedBox(height: isMobile ? 16 : 24),
            Text(
              'Confirmar Exclusão',
              style: AppTextStyles.fonteUbuntu.copyWith(
                fontSize: isMobile ? 20 : 24,
                fontWeight: FontWeight.w700,
                color: AppColors.preto,
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              'Tem certeza que deseja excluir ${usuario.nome}?',
              textAlign: TextAlign.center,
              style: AppTextStyles.fonteUbuntuSans.copyWith(
                fontSize: isMobile ? 16 : 18,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            SizedBox(height: isMobile ? 8 : 8),
            Text(
              'Esta ação não pode ser desfeita.',
              textAlign: TextAlign.center,
              style: AppTextStyles.fonteUbuntu.copyWith(
                fontSize: isMobile ? 12 : 14,
                color: AppColors.vermelhoErro,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: isMobile ? 24 : 32),
            isMobile
                ? Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.vermelhoErro,
                          foregroundColor: AppColors.branco,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(
                          'Excluir',
                          style: AppTextStyles.fonteUbuntu.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[300]!),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(
                          'Cancelar',
                          style: AppTextStyles.fonteUbuntu.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            'Cancelar',
                            style: AppTextStyles.fonteUbuntu.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.vermelhoErro,
                            foregroundColor: AppColors.branco,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            'Excluir',
                            style: AppTextStyles.fonteUbuntu.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

// Diálogo para adicionar avaliação global - RESPONSIVO
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final primaryColor = AppColors.azulClaro;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 20,
      backgroundColor: AppColors.branco,
      insetPadding: isMobile
          ? const EdgeInsets.all(16)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Container(
        constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 500),
        padding: EdgeInsets.all(isMobile ? 20 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.assignment_add,
                    color: primaryColor,
                    size: isMobile ? 24 : 28,
                  ),
                ),
                SizedBox(width: isMobile ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nova Avaliação',
                        style: AppTextStyles.fonteUbuntu.copyWith(
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.preto,
                        ),
                      ),
                      Text(
                        'Disciplina: ${widget.disciplina.titulo}',
                        style: AppTextStyles.fonteUbuntuSans.copyWith(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 24 : 32),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nomeController,
                    style: AppTextStyles.fonteUbuntuSans.copyWith(
                      fontSize: isMobile ? 14 : 16,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Nome da Avaliação',
                      labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 14 : 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[400]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      prefixIcon: Icon(
                        Icons.title,
                        color: primaryColor,
                        size: isMobile ? 20 : 24,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 20,
                        vertical: isMobile ? 14 : 16,
                      ),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Nome obrigatório' : null,
                  ),
                  SizedBox(height: isMobile ? 16 : 20),
                  DropdownButtonFormField<String>(
                    value: _tipo,
                    style: AppTextStyles.fonteUbuntuSans.copyWith(
                      fontSize: isMobile ? 14 : 16,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Tipo de Avaliação',
                      labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 14 : 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[400]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      prefixIcon: Icon(
                        Icons.category,
                        color: primaryColor,
                        size: isMobile ? 20 : 24,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 20,
                        vertical: isMobile ? 14 : 16,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'prova',
                        child: Row(
                          children: [
                            Icon(
                              Icons.quiz,
                              color: primaryColor,
                              size: isMobile ? 18 : 20,
                            ),
                            SizedBox(width: isMobile ? 6 : 8),
                            Text(
                              'Prova',
                              style: AppTextStyles.fonteUbuntu.copyWith(
                                fontSize: isMobile ? 14 : 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'atividade',
                        child: Row(
                          children: [
                            Icon(
                              Icons.assignment,
                              color: Colors.green,
                              size: isMobile ? 18 : 20,
                            ),
                            SizedBox(width: isMobile ? 6 : 8),
                            Text(
                              'Atividade',
                              style: AppTextStyles.fonteUbuntu.copyWith(
                                fontSize: isMobile ? 14 : 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _tipo = value ?? 'prova'),
                  ),
                  SizedBox(height: isMobile ? 16 : 20),
                  TextFormField(
                    controller: _pesoController,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.fonteUbuntuSans.copyWith(
                      fontSize: isMobile ? 14 : 16,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Peso da Avaliação',
                      labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 14 : 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[400]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      prefixIcon: Icon(
                        Icons.balance,
                        color: primaryColor,
                        size: isMobile ? 20 : 24,
                      ),
                      suffixText: 'pontos',
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 20,
                        vertical: isMobile ? 14 : 16,
                      ),
                    ),
                    validator: (value) {
                      final num = double.tryParse(value ?? '');
                      if (num == null || num <= 0)
                        return 'Peso positivo obrigatório';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 24 : 32),
            isMobile
                ? Column(
                    children: [
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
                          backgroundColor: primaryColor,
                          foregroundColor: AppColors.branco,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              size: isMobile ? 18 : 20,
                            ),
                            SizedBox(width: isMobile ? 6 : 8),
                            Text(
                              'Criar para Todos',
                              style: AppTextStyles.fonteUbuntu.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: isMobile ? 14 : 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[400]!),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(
                          'Cancelar',
                          style: AppTextStyles.fonteUbuntu.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey[400]!),
                          ),
                          child: Text(
                            'Cancelar',
                            style: AppTextStyles.fonteUbuntu.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
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
                            backgroundColor: primaryColor,
                            foregroundColor: AppColors.branco,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle_outline, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Criar para Todos os Alunos',
                                style: AppTextStyles.fonteUbuntu.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

// Diálogo para editar avaliação global - RESPONSIVO
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final primaryColor = AppColors.azulClaro;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 20,
      backgroundColor: Colors.white,
      insetPadding: isMobile
          ? const EdgeInsets.all(16)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Container(
        constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 500),
        padding: EdgeInsets.all(isMobile ? 20 : 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.edit,
                    color: primaryColor,
                    size: isMobile ? 24 : 28,
                  ),
                ),
                SizedBox(width: isMobile ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Editar Avaliação',
                        style: AppTextStyles.fonteUbuntu.copyWith(
                          fontSize: isMobile ? 20 : 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Atualize os dados da avaliação',
                        style: AppTextStyles.fonteUbuntuSans.copyWith(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 20 : 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nomeController,
                    style: AppTextStyles.fonteUbuntuSans.copyWith(
                      fontSize: isMobile ? 14 : 16,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Nome da Avaliação',
                      labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 14 : 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[400]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      prefixIcon: Icon(
                        Icons.title,
                        color: primaryColor,
                        size: isMobile ? 20 : 24,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 20,
                        vertical: isMobile ? 14 : 16,
                      ),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Nome obrigatório' : null,
                  ),
                  SizedBox(height: isMobile ? 16 : 20),
                  DropdownButtonFormField<String>(
                    value: _tipo,
                    style: AppTextStyles.fonteUbuntuSans.copyWith(
                      fontSize: isMobile ? 14 : 16,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Tipo de Avaliação',
                      labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 14 : 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[400]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      prefixIcon: Icon(
                        Icons.category,
                        color: primaryColor,
                        size: isMobile ? 20 : 24,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 20,
                        vertical: isMobile ? 14 : 16,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'prova',
                        child: Row(
                          children: [
                            Icon(
                              Icons.quiz,
                              color: primaryColor,
                              size: isMobile ? 18 : 20,
                            ),
                            SizedBox(width: isMobile ? 6 : 8),
                            Text(
                              'Prova',
                              style: AppTextStyles.fonteUbuntu.copyWith(
                                fontSize: isMobile ? 14 : 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'atividade',
                        child: Row(
                          children: [
                            Icon(
                              Icons.assignment,
                              color: Colors.green,
                              size: isMobile ? 18 : 20,
                            ),
                            SizedBox(width: isMobile ? 6 : 8),
                            Text(
                              'Atividade',
                              style: AppTextStyles.fonteUbuntu.copyWith(
                                fontSize: isMobile ? 14 : 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _tipo = value ?? 'prova'),
                  ),
                  SizedBox(height: isMobile ? 16 : 20),
                  TextFormField(
                    controller: _pesoController,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.fonteUbuntuSans.copyWith(
                      fontSize: isMobile ? 14 : 16,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Peso da Avaliação',
                      labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 14 : 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[400]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      prefixIcon: Icon(
                        Icons.balance,
                        color: primaryColor,
                        size: isMobile ? 20 : 24,
                      ),
                      suffixText: 'pontos',
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 20,
                        vertical: isMobile ? 14 : 16,
                      ),
                    ),
                    validator: (value) {
                      final num = double.tryParse(value ?? '');
                      if (num == null || num <= 0)
                        return 'Peso positivo obrigatório';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 24 : 32),
            isMobile
                ? Column(
                    children: [
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
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save, size: isMobile ? 18 : 20),
                            SizedBox(width: isMobile ? 6 : 8),
                            Text(
                              'Salvar Alterações',
                              style: AppTextStyles.fonteUbuntu.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: isMobile ? 14 : 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[400]!),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(
                          'Cancelar',
                          style: AppTextStyles.fonteUbuntu.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey[400]!),
                          ),
                          child: Text(
                            'Cancelar',
                            style: AppTextStyles.fonteUbuntu.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
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
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Salvar Alterações',
                                style: AppTextStyles.fonteUbuntu.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

// Diálogo para adicionar/editar nota - RESPONSIVO
class NotaDialog extends StatefulWidget {
  final Disciplina disciplina;
  final Nota? nota;
  final Usuario? selectedAluno;

  const NotaDialog({
    super.key,
    required this.disciplina,
    this.nota,
    this.selectedAluno,
  });

  @override
  State<NotaDialog> createState() => _NotaDialogState();
}

class _NotaDialogState extends State<NotaDialog> {
  final _formKey = GlobalKey<FormState>();
  late Usuario _selectedAluno;
  List<Avaliacao> _avaliacoes = [];
  final _nomeController = TextEditingController();
  final _tipoController = TextEditingController();
  final _notaController = TextEditingController();
  final _pesoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final isEdit = widget.nota != null;
    if (isEdit) {
      final nota = widget.nota!;
      final aluno = widget.disciplina.alunos.firstWhereOrNull(
        (a) => a.id == nota.alunoId,
      );
      _selectedAluno =
          aluno ??
          Usuario(
            id: nota.alunoId,
            nome: nota.alunoNome,
            email: '',
            tipo: 'aluno',
            ra: nota.alunoRa,
          );
      _avaliacoes = List<Avaliacao>.from(nota.avaliacoes);
    } else {
      if (widget.selectedAluno == null) {
        throw ArgumentError('selectedAluno é obrigatório para criação');
      }
      _selectedAluno = widget.selectedAluno!;
      _avaliacoes = [];
    }
    _tipoController.text = 'prova';
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _tipoController.dispose();
    _notaController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  void _addAvaliacao() {
    if (_formKey.currentState!.validate()) {
      final novaAvaliacao = Avaliacao(
        id: '',
        nome: _nomeController.text,
        tipo: _tipoController.text,
        nota: double.tryParse(_notaController.text),
        peso: double.tryParse(_pesoController.text) ?? 1.0,
        data: DateTime.now(),
      );
      setState(() {
        _avaliacoes.add(novaAvaliacao);
      });
      _nomeController.clear();
      _notaController.clear();
      _pesoController.clear();
    }
  }

  void _removeAvaliacao(int index) {
    setState(() {
      _avaliacoes.removeAt(index);
    });
  }

  Nota? _buildNota() {
    return Nota(
      id: widget.nota?.id ?? '',
      disciplinaId: widget.disciplina.id,
      alunoId: _selectedAluno.id,
      alunoNome: _selectedAluno.nome,
      alunoRa: _selectedAluno.ra,
      avaliacoes: _avaliacoes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.nota != null;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 900;
    final dialogWidth = isMobile
        ? screenWidth * 0.98
        : (isTablet ? 550.0 : 600.0);
    final primaryColor = AppColors.azulClaro;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 24,
      insetPadding: isMobile
          ? const EdgeInsets.all(8)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height * (isMobile ? 0.9 : 0.8),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.branco, AppColors.cinzaClaro],
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                isMobile ? 20 : 32,
                isMobile ? 16 : 24,
                isMobile ? 16 : 24,
              ),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.branco.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.grade,
                      color: AppColors.branco,
                      size: isMobile ? 24 : 28,
                    ),
                  ),
                  SizedBox(width: isMobile ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${isEdit ? 'Editar' : 'Adicionar'} Nota',
                          style: AppTextStyles.fonteUbuntu.copyWith(
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.branco,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '${widget.disciplina.titulo} - ${_selectedAluno.nome}',
                          style: AppTextStyles.fonteUbuntuSans.copyWith(
                            fontSize: isMobile ? 12 : 14,
                            color: AppColors.branco.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: AppColors.branco,
                      size: isMobile ? 20 : 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Form para nova avaliação
                        Text(
                          'Adicionar Nova Avaliação',
                          style: AppTextStyles.fonteUbuntu.copyWith(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        TextFormField(
                          controller: _nomeController,
                          style: AppTextStyles.fonteUbuntuSans.copyWith(
                            fontSize: isMobile ? 14 : 16,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Nome da Avaliação',
                            labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                              color: Colors.grey[600],
                              fontSize: isMobile ? 14 : 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.assignment,
                              color: Colors.grey[500],
                              size: isMobile ? 20 : 24,
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 16 : 20,
                              vertical: isMobile ? 14 : 16,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira o nome da avaliação';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: isMobile ? 16 : 20),
                        DropdownButtonFormField<String>(
                          value: _tipoController.text.isEmpty
                              ? 'prova'
                              : _tipoController.text,
                          style: AppTextStyles.fonteUbuntuSans.copyWith(
                            fontSize: isMobile ? 14 : 16,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Tipo',
                            labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                              color: Colors.grey[600],
                              fontSize: isMobile ? 14 : 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.category,
                              color: Colors.grey[500],
                              size: isMobile ? 20 : 24,
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 16 : 20,
                              vertical: isMobile ? 14 : 16,
                            ),
                          ),
                          items: ['prova', 'atividade'].map((tipo) {
                            return DropdownMenuItem(
                              value: tipo,
                              child: Text(
                                tipo.toUpperCase(),
                                style: TextStyle(fontSize: isMobile ? 14 : 16),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) _tipoController.text = value;
                          },
                        ),
                        SizedBox(height: isMobile ? 16 : 20),
                        TextFormField(
                          controller: _notaController,
                          style: AppTextStyles.fonteUbuntuSans.copyWith(
                            fontSize: isMobile ? 14 : 16,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Nota (0-10)',
                            labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                              color: Colors.grey[600],
                              fontSize: isMobile ? 14 : 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.star,
                              color: Colors.grey[500],
                              size: isMobile ? 20 : 24,
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 16 : 20,
                              vertical: isMobile ? 14 : 16,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            final num = double.tryParse(value ?? '');
                            if (num == null || num < 0 || num > 10)
                              return 'Nota deve estar entre 0 e 10';
                            return null;
                          },
                        ),
                        SizedBox(height: isMobile ? 16 : 20),
                        TextFormField(
                          controller: _pesoController,
                          style: AppTextStyles.fonteUbuntuSans.copyWith(
                            fontSize: isMobile ? 14 : 16,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Peso (padrão 1)',
                            labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                              color: Colors.grey[600],
                              fontSize: isMobile ? 14 : 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.balance,
                              color: Colors.grey[500],
                              size: isMobile ? 20 : 24,
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 16 : 20,
                              vertical: isMobile ? 14 : 16,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            final num = double.tryParse(value ?? '');
                            if (num == null || num <= 0)
                              return 'Peso deve ser positivo';
                            return null;
                          },
                        ),
                        SizedBox(height: isMobile ? 20 : 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _addAvaliacao,
                            icon: Icon(Icons.add, size: isMobile ? 18 : 20),
                            label: Text(
                              'Adicionar Avaliação',
                              style: AppTextStyles.fonteUbuntu.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: isMobile ? 14 : 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: AppColors.branco,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 24 : 32),
                        // Lista de avaliações atuais
                        Text(
                          'Avaliações Adicionadas (${_avaliacoes.length})',
                          style: AppTextStyles.fonteUbuntu.copyWith(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        if (_avaliacoes.isEmpty)
                          Container(
                            padding: EdgeInsets.all(isMobile ? 24 : 32),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.assignment_outlined,
                                  size: isMobile ? 48 : 64,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: isMobile ? 12 : 16),
                                Text(
                                  'Nenhuma avaliação adicionada',
                                  style: AppTextStyles.fonteUbuntu.copyWith(
                                    fontSize: isMobile ? 14 : 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._avaliacoes.asMap().entries.map((entry) {
                            final index = entry.key;
                            final av = entry.value;
                            return Card(
                              margin: EdgeInsets.only(
                                bottom: isMobile ? 8 : 12,
                              ),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(
                                  isMobile ? 12 : 16,
                                ),
                                title: Text(
                                  av.nome,
                                  style: AppTextStyles.fonteUbuntu.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: isMobile ? 14 : 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${av.tipo.toUpperCase()}: ${av.nota ?? 'Não definida'}',
                                      style: TextStyle(
                                        fontSize: isMobile ? 12 : 14,
                                      ),
                                    ),
                                    Text(
                                      'Peso: ${av.peso ?? 1.0}',
                                      style: TextStyle(
                                        fontSize: isMobile ? 12 : 14,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: AppColors.vermelho,
                                    size: isMobile ? 20 : 24,
                                  ),
                                  onPressed: () => _removeAvaliacao(index),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Footer
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              decoration: BoxDecoration(
                color: AppColors.branco,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.preto.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: isMobile
                  ? Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            final novaNota = _buildNota();
                            if (novaNota != null &&
                                (_avaliacoes.isNotEmpty || isEdit)) {
                              Navigator.pop(context, novaNota);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Adicione pelo menos uma avaliação',
                                  ),
                                  backgroundColor: AppColors.vermelhoErro,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: AppColors.branco,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: Text(
                            isEdit ? 'Salvar Alterações' : 'Criar Nota',
                            style: AppTextStyles.fonteUbuntu.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey[300]!),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: Text(
                            'Cancelar',
                            style: AppTextStyles.fonteUbuntu.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              'Cancelar',
                              style: AppTextStyles.fonteUbuntu.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              final novaNota = _buildNota();
                              if (novaNota != null &&
                                  (_avaliacoes.isNotEmpty || isEdit)) {
                                Navigator.pop(context, novaNota);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Adicione pelo menos uma avaliação',
                                    ),
                                    backgroundColor: AppColors.vermelhoErro,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: AppColors.branco,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              isEdit ? 'Salvar Alterações' : 'Criar Nota',
                              style: AppTextStyles.fonteUbuntu.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Diálogo para gerenciar avaliações - RESPONSIVO
class ManageAvaliacoesDialog extends StatelessWidget {
  final Disciplina disciplina;
  final List<Avaliacao> uniqueAvaliacoes;
  final Future<void> Function(String, String, Avaliacao) onEdit;
  final Future<void> Function(String, String) onDelete;

  const ManageAvaliacoesDialog({
    super.key,
    required this.disciplina,
    required this.uniqueAvaliacoes,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 20,
      backgroundColor: Colors.white,
      insetPadding: isMobile
          ? const EdgeInsets.all(16)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: EdgeInsets.all(isMobile ? 20 : 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
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
                      Icons.settings,
                      size: isMobile ? 28 : 32,
                      color: AppColors.azulClaro,
                    ),
                  ),
                  SizedBox(height: isMobile ? 12 : 16),
                  Text(
                    'Gerenciar Avaliações',
                    style: AppTextStyles.fonteUbuntu.copyWith(
                      fontSize: isMobile ? 20 : 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(height: isMobile ? 4 : 8),
                  Text(
                    'Disciplina: ${disciplina.titulo}',
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 20 : 24),
            if (uniqueAvaliacoes.isEmpty)
              Container(
                padding: EdgeInsets.all(isMobile ? 24 : 32),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: isMobile ? 48 : 64,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    Text(
                      'Nenhuma avaliação encontrada',
                      style: AppTextStyles.fonteUbuntu.copyWith(
                        fontSize: isMobile ? 14 : 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: isMobile ? 8 : 8),
                    Text(
                      'Adicione avaliações para gerenciá-las aqui',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 14,
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: uniqueAvaliacoes.length,
                  itemBuilder: (context, index) {
                    final av = uniqueAvaliacoes[index];
                    final color = av.tipo == 'atividade'
                        ? Colors.green
                        : AppColors.azulClaro;
                    return Card(
                      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.white,
                      child: ListTile(
                        contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            av.tipo == 'atividade'
                                ? Icons.assignment
                                : Icons.quiz,
                            color: color,
                            size: isMobile ? 20 : 24,
                          ),
                        ),
                        title: Text(
                          av.nome,
                          style: AppTextStyles.fonteUbuntu.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: isMobile ? 2 : 4),
                            Wrap(
                              spacing: isMobile ? 4 : 8,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: color.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    av.tipo.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: isMobile ? 9 : 10,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.orange.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    'Peso: ${av.peso?.toStringAsFixed(1) ?? '1.0'}',
                                    style: TextStyle(
                                      fontSize: isMobile ? 9 : 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: isMobile
                            ? PopupMenuButton(
                                icon: Icon(Icons.more_vert, size: 20),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit,
                                          color: AppColors.azulClaro,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Editar',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete,
                                          color: AppColors.vermelho,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Excluir',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    final newAv = await showDialog<Avaliacao?>(
                                      context: context,
                                      builder: (c) => EditAvaliacaoGlobalDialog(
                                        initialAv: av,
                                      ),
                                    );
                                    if (newAv != null) {
                                      await onEdit(av.nome, av.tipo, newAv);
                                      if (context.mounted)
                                        Navigator.pop(context);
                                    }
                                  } else if (value == 'delete') {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (dialogContext) =>
                                          _buildConfirmDeleteDialog(
                                            dialogContext,
                                            av.nome,
                                          ),
                                    );
                                    if (confirm == true) {
                                      await onDelete(av.nome, av.tipo);
                                      if (context.mounted)
                                        Navigator.pop(context);
                                    }
                                  }
                                },
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      color: AppColors.azulClaro,
                                      size: isMobile ? 18 : 20,
                                    ),
                                    onPressed: () async {
                                      final newAv =
                                          await showDialog<Avaliacao?>(
                                            context: context,
                                            builder: (c) =>
                                                EditAvaliacaoGlobalDialog(
                                                  initialAv: av,
                                                ),
                                          );
                                      if (newAv != null) {
                                        await onEdit(av.nome, av.tipo, newAv);
                                        if (context.mounted)
                                          Navigator.pop(context);
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: AppColors.vermelho,
                                      size: isMobile ? 18 : 20,
                                    ),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (dialogContext) =>
                                            _buildConfirmDeleteDialog(
                                              dialogContext,
                                              av.nome,
                                            ),
                                      );
                                      if (confirm == true) {
                                        await onDelete(av.nome, av.tipo);
                                        if (context.mounted)
                                          Navigator.pop(context);
                                      }
                                    },
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ),
            SizedBox(height: isMobile ? 20 : 24),
            Center(
              child: SizedBox(
                width: isMobile ? double.infinity : null,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.azulClaro,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 24 : 32,
                      vertical: isMobile ? 12 : 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: isMobile
                        ? const Size(double.infinity, 50)
                        : null,
                  ),
                  child: Text(
                    'Fechar',
                    style: AppTextStyles.fonteUbuntu.copyWith(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Diálogo de confirmação de exclusão interno - RESPONSIVO
  Widget _buildConfirmDeleteDialog(
    BuildContext dialogContext,
    String nomeAvaliacao,
  ) {
    final screenWidth = MediaQuery.of(dialogContext).size.width;
    final isMobile = screenWidth < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 20,
      backgroundColor: Colors.white,
      insetPadding: isMobile
          ? const EdgeInsets.all(20)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Container(
        constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 400),
        padding: EdgeInsets.all(isMobile ? 20 : 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
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
                      size: isMobile ? 28 : 32,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: isMobile ? 12 : 16),
                  Text(
                    'Confirmar Remoção',
                    style: AppTextStyles.fonteUbuntu.copyWith(
                      fontSize: isMobile ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(height: isMobile ? 8 : 8),
                  Text(
                    'Deseja remover a avaliação "$nomeAvaliacao" de TODOS os alunos?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 16 : 24),
            Text(
              'Esta ação não pode ser desfeita.',
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                color: Colors.red.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: isMobile ? 20 : 30),
            isMobile
                ? Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text('Remover', style: TextStyle(fontSize: 16)),
                      ),
                      SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[400]!),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          side: BorderSide(color: Colors.grey[400]!),
                        ),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        child: Text('Remover', style: TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

// Extension para capitalize
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
