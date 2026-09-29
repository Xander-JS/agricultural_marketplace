import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Verificar conexión con Supabase usando credenciales .env', () async {
    // 1. Leer manualmente el archivo .env de la raíz
    final envFile = File('.env');
    expect(envFile.existsSync(), isTrue, reason: 'El archivo .env no existe en la raíz');

    final lines = envFile.readAsLinesSync();
    final envVars = <String, String>{};

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final parts = trimmed.split('=');
      if (parts.length >= 2) {
        final key = parts[0].trim();
        var value = parts.sublist(1).join('=').trim();
        // Quitar comillas simples o dobles si las contiene
        if ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'"))) {
          value = value.substring(1, value.length - 1).trim();
        }
        envVars[key] = value;
      }
    }

    final url = envVars['SUPABASE_URL'];
    final key = envVars['SUPABASE_ANON_KEY'] ?? envVars['SUPABASE_PUBLISHABLE_KEY'];

    expect(url, isNotNull, reason: 'Falta SUPABASE_URL en el archivo .env');
    expect(key, isNotNull, reason: 'Falta SUPABASE_ANON_KEY o SUPABASE_PUBLISHABLE_KEY en el archivo .env');
    expect(url!.isNotEmpty, isTrue, reason: 'SUPABASE_URL está vacío en .env');
    expect(key!.isNotEmpty, isTrue, reason: 'SUPABASE_ANON_KEY está vacío en .env');

    // 2. Instanciar cliente de Supabase
    final client = SupabaseClient(
      url,
      key,
      authOptions: const AuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    );

    // 3. Probar respuesta del servidor
    try {
      await client.from('_test_health').select().limit(1);
    } on PostgrestException catch (_) {
      // Si el servidor PostgREST de Supabase responde con un PostgrestException
      // (por ejemplo, tabla inexistente, falta de permisos RLS, etc.), la conexión con Supabase es exitosa.
      return;
    } catch (e) {
      final msg = e.toString();
      // Si responde con cualquier error característico de PostgreSQL o Supabase HTTP
      final servidorRespondio = msg.contains('does not exist') ||
          msg.contains('PGRST') ||
          msg.contains('401') ||
          msg.contains('404') ||
          msg.contains('Unauthorized') ||
          msg.contains('PostgrestException');
      expect(servidorRespondio, isTrue, reason: 'Error de red o credenciales/servidor inaccesible: $msg');
    }
  });
}