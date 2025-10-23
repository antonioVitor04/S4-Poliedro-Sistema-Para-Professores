import 'package:flutter/material.dart';
import '../styles/cores.dart';
import '../styles/fontes.dart';

class EditarPerfilDialog extends StatefulWidget {
  final String emailAtual;
  final Function(String? email, String? senha) onConfirm;

  const EditarPerfilDialog({
    super.key,
    required this.emailAtual,
    required this.onConfirm,
  });

  @override
  State<EditarPerfilDialog> createState() => _EditarPerfilDialogState();
}

class _EditarPerfilDialogState extends State<EditarPerfilDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _senhaVisivel = false;
  bool _confirmarSenhaVisivel = false;

  // Variáveis para validação de senha
  bool get hasUpperCase => _senhaController.text.contains(RegExp(r'[A-Z]'));
  bool get hasNumber => _senhaController.text.contains(RegExp(r'[0-9]'));
  bool get hasSymbol =>
      _senhaController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  bool get hasMinLength => _senhaController.text.length >= 8;
  bool get senhasIguais =>
      _senhaController.text.isNotEmpty &&
      _senhaController.text == _confirmarSenhaController.text;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.emailAtual;

    // Adicionar listeners para validação em tempo real
    _senhaController.addListener(_atualizarValidacao);
    _confirmarSenhaController.addListener(_atualizarValidacao);
  }

  void _atualizarValidacao() {
    setState(() {});
  }

  @override
  void dispose() {
    _senhaController.removeListener(_atualizarValidacao);
    _confirmarSenhaController.removeListener(_atualizarValidacao);
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Widget _buildRequisitoSenha(String texto, bool atendido) {
    return Row(
      children: [
        Icon(
          atendido ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: atendido ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(
          texto,
          style: TextStyle(
            fontSize: 12,
            color: atendido ? Colors.green : Colors.grey,
            fontWeight: atendido ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  bool get _senhaValida {
    if (_senhaController.text.isEmpty) return true; // Senha é opcional
    return hasUpperCase &&
        hasNumber &&
        hasSymbol &&
        hasMinLength &&
        senhasIguais;
  }

  @override
  Widget build(BuildContext context) {
    final senhaPreenchida = _senhaController.text.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
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
                            'Editar Perfil',
                            style: AppTextStyles.fonteUbuntu.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Atualize suas informações',
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
                      controller: _emailController,
                      cursorColor: AppColors.azulClaro,
                      style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Email',
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
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, insira um email';
                        }
                        if (!value.contains('@')) {
                          return 'Por favor, insira um email válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campo Nova Senha
                    TextFormField(
                      controller: _senhaController,
                      cursorColor: AppColors.azulClaro,
                      style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
                      obscureText: !_senhaVisivel,
                      decoration: InputDecoration(
                        labelText: 'Nova Senha (opcional)',
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
                          Icons.lock,
                          color: AppColors.azulClaro,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _senhaVisivel
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: AppColors.azulClaro,
                          ),
                          onPressed: () {
                            setState(() {
                              _senhaVisivel = !_senhaVisivel;
                            });
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Campo Confirmar Senha (apenas aparece se senha for preenchida)
                    if (senhaPreenchida) ...[
                      TextFormField(
                        controller: _confirmarSenhaController,
                        cursorColor: AppColors.azulClaro,
                        style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
                        obscureText: !_confirmarSenhaVisivel,
                        decoration: InputDecoration(
                          labelText: 'Confirmar Nova Senha',
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
                            Icons.lock_outline,
                            color: AppColors.azulClaro,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _confirmarSenhaVisivel
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: AppColors.azulClaro,
                            ),
                            onPressed: () {
                              setState(() {
                                _confirmarSenhaVisivel =
                                    !_confirmarSenhaVisivel;
                              });
                            },
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                      ),

                      // Validações de senha (apenas aparece se senha for preenchida)
                      if (senhaPreenchida) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Requisitos da senha:',
                                style: AppTextStyles.fonteUbuntu.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildRequisitoSenha(
                                "Pelo menos 8 caracteres",
                                hasMinLength,
                              ),
                              const SizedBox(height: 8),
                              _buildRequisitoSenha(
                                "Pelo menos uma letra maiúscula",
                                hasUpperCase,
                              ),
                              const SizedBox(height: 8),
                              _buildRequisitoSenha(
                                "Pelo menos um número",
                                hasNumber,
                              ),
                              const SizedBox(height: 8),
                              _buildRequisitoSenha(
                                "Pelo menos um símbolo (!@#\$% etc.)",
                                hasSymbol,
                              ),
                              const SizedBox(height: 8),
                              _buildRequisitoSenha(
                                "As senhas devem ser iguais",
                                senhasIguais,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],

                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            _senhaController.clear();
                            _confirmarSenhaController.clear();
                            Navigator.pop(context);
                          },
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
                          onPressed: _senhaValida ? _salvar : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _senhaValida
                                ? AppColors.azulClaro
                                : Colors.grey,
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

  void _salvar() {
    if (_formKey.currentState!.validate() && _senhaValida) {
      final novoEmail = _emailController.text.trim() != widget.emailAtual
          ? _emailController.text.trim()
          : null;

      final novaSenha = _senhaController.text.trim().isNotEmpty
          ? _senhaController.text.trim()
          : null;

      widget.onConfirm(novoEmail, novaSenha);
      //fechar o modal
      Navigator.pop(context);
    }
  }
}
