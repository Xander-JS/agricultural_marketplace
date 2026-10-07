import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/crop_model.dart';
import '../services/crop_service.dart';
import '../widgets/crop_card.dart';
import 'publish_crop_screen.dart';
import 'crop_detail_screen.dart';
import '../../../core/widgets/avatars/user_avatar.dart';
import '../../profile/services/profile_service.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _cropService = CropService();
  final _profileService = ProfileService();
  
  List<CropModel> _crops = [];
  String? _profileImageUrl;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // Cargar cosechas
      final crops = await _cropService.getCropsByFarmerId(user.id);
      
      // Cargar info del perfil para el avatar
      try {
        final profileData = await _profileService.getFarmerProfileData(user.id);
        if (profileData.profilePath != null && profileData.profilePath!.isNotEmpty) {
          _profileImageUrl = _profileService.getPublicProfileImageUrl(profileData.profilePath!);
        }
      } catch (_) {
        // Ignorar si falla la carga del perfil
      }

      setState(() {
        _crops = crops;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCrops() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final crops = await _cropService.getCropsByFarmerId(user.id);
        
        // Recargar perfil por si cambió la imagen
        try {
          final profileData = await _profileService.getFarmerProfileData(user.id);
          if (profileData.profilePath != null && profileData.profilePath!.isNotEmpty) {
            _profileImageUrl = _profileService.getPublicProfileImageUrl(profileData.profilePath!);
          }
        } catch (_) {}

        setState(() {
          _crops = crops;
        });
      }
    } catch (_) {}
  }

  void _navigateToPublish() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PublishCropScreen()),
    );

    // Si retorna true, significa que se publicó/guardó y hay que recargar
    if (result == true) {
      _loadCrops();
    }
  }

  void _showPublishOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '¿Cómo deseas publicar?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: Icon(Icons.edit_document, color: Theme.of(context).primaryColor),
                ),
                title: const Text('Publicación Manual'),
                subtitle: const Text('Llena el formulario paso a paso'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToPublish();
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: Icon(Icons.mic, color: Theme.of(context).primaryColor),
                ),
                title: const Text('Publicación por Nota de Voz'),
                subtitle: const Text('Cuéntanos qué quieres publicar (Con IA)'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Función de IA próximamente...')),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _navigateToDetail(CropModel crop) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CropDetailScreen(crop: crop),
      ),
    );

    if (result == true) {
      _loadCrops();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Mercado'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: UserAvatar(
                imageUrl: _profileImageUrl,
                onTap: () {
                  // Opcional: Navegar al perfil o abrir un diálogo
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Este es tu perfil')),
                  );
                },
              ),
            ),
          )
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPublishOptions,
        icon: const Icon(Icons.add),
        label: const Text('Publicar'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ocurrió un error: $_errorMessage', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCrops,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_crops.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadCrops,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0).copyWith(bottom: 80), // Espacio para el FAB
        itemCount: _crops.length,
        itemBuilder: (context, index) {
          final crop = _crops[index];
          return CropCard(
            crop: crop,
            onTap: () => _navigateToDetail(crop),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Aún no tienes cosechas publicadas',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Comienza a ofrecer tus productos en el mercado agrícola creando tu primera publicación.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToPublish,
              icon: const Icon(Icons.add),
              label: const Text('Publicar mi primera cosecha'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
