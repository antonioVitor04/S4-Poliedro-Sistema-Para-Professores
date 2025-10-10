import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // Verificar e solicitar permissões de armazenamento
  static Future<bool> requestStoragePermissions() async {
    try {
      // Para Android 13+ (API 33+)
      if (await Permission.manageExternalStorage.isRestricted) {
        // Dispositivos com armazenamento restrito - usar DocumentsUI
        return await _requestDocumentPermissions();
      }

      // Para Android 11+ (API 30+)
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }

      // Solicitar permissão de gerenciamento de armazenamento
      final manageStorageStatus = await Permission.manageExternalStorage.request();
      
      if (manageStorageStatus.isGranted) {
        return true;
      }

      // Fallback para permissões tradicionais (Android < 11)
      final storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) {
        return true;
      }

      // Se as permissões forem negadas permanentemente
      if (storageStatus.isPermanentlyDenied || manageStorageStatus.isPermanentlyDenied) {
        return await _showPermissionDialog();
      }

      return false;
    } catch (e) {
      print('=== DEBUG ERRO PermissionService: $e ===');
      return false;
    }
  }

  // Método alternativo usando Documentos (menos permissões invasivas)
  static Future<bool> _requestDocumentPermissions() async {
    try {
      // Solicitar permissão para acessar documentos
      final status = await Permission.storage.request();
      
      if (status.isGranted) {
        return true;
      }
      
      if (status.isPermanentlyDenied) {
        return await _showPermissionDialog();
      }
      
      return false;
    } catch (e) {
      print('=== DEBUG ERRO Document Permissions: $e ===');
      return false;
    }
  }

  // Diálogo para quando a permissão é negada permanentemente
  static Future<bool> _showPermissionDialog() async {
    // Este método será implementado no contexto da UI
    // Por enquanto, retorna false
    return false;
  }

  // Verificar se temos permissões suficientes
  static Future<bool> hasStoragePermissions() async {
    try {
      // Verificar permissão de gerenciamento (Android 11+)
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }

      // Verificar permissão de armazenamento tradicional
      if (await Permission.storage.isGranted) {
        return true;
      }

      return false;
    } catch (e) {
      print('=== DEBUG ERRO hasStoragePermissions: $e ===');
      return false;
    }
  }

  // Abrir configurações do app
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}