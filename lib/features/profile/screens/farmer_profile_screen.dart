import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/farmer_profile_data.dart';
import '../services/profile_service.dart';

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = true;
  bool _isSaving = false;
  FarmerProfileData? _profileData;

  // Controladores para la edición de campos
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _loadProfileData();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final data = await _profileService.getFarmerProfileData(userId);
      setState(() {
        _profileData = data;
        _emailController.text = data.email;
        _phoneController.text = data.phone;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar el perfil: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _updateProfileInfo() async {
    if (_profileData == null) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);
    try {
      await _profileService.updateProfileData(
        _profileData!.id,
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos actualizados correctamente'), backgroundColor: AppColors.success),
        );
      }
      await _loadProfileData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar datos: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _updateSettings(FarmerSettingsData newSettings) async {
    if (_profileData == null) return;
    
    // Optimistic UI update
    setState(() {
      _profileData = FarmerProfileData(
        id: _profileData!.id,
        fullName: _profileData!.fullName,
        role: _profileData!.role,
        email: _profileData!.email,
        phone: _profileData!.phone,
        profilePath: _profileData!.profilePath,
        stats: _profileData!.stats,
        settings: newSettings,
      );
    });

    try {
      await _profileService.updateFarmerSettings(_profileData!.id, newSettings);
    } catch (e) {
      // Revertir en caso de error
      await _loadProfileData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar configuración: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (_profileData == null) return;
    
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() => _isSaving = true);
    try {
      final file = File(image.path);
      await _profileService.uploadProfilePicture(_profileData!.id, file);
      await _loadProfileData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil actualizada'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir imagen: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Mi finca', style: TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.lightTertiary))
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              color: AppColors.lightTertiary,
              child: _profileData == null
                  ? ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text('No se pudieron cargar los datos.', style: TextStyle(color: AppColors.lightTextSecondary))),
                      ],
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildProfileHeader(),
                          const SizedBox(height: 32),
                          _buildEditableDataSection(),
                          const SizedBox(height: 32),
                          _buildStatisticsSection(),
                          const SizedBox(height: 32),
                          _buildSettingsSection(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    String? imageUrl;
    if (_profileData!.profilePath != null && _profileData!.profilePath!.isNotEmpty) {
      imageUrl = _profileService.getPublicProfileImageUrl(_profileData!.profilePath!);
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.lightBorder,
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
              child: imageUrl == null
                  ? const Icon(Icons.person, size: 50, color: AppColors.lightTextDisabled)
                  : null,
            ),
            GestureDetector(
              onTap: _isSaving ? null : _pickAndUploadImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.lightTertiary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.lightSecondary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            (_profileData!.role).toUpperCase(),
            style: const TextStyle(
              color: AppColors.lightTertiary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _profileData!.fullName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEditableDataSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información de contacto',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Correo electrónico',
            controller: _emailController,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Número de teléfono',
            controller: _phoneController,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _updateProfileInfo,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightTertiary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Guardar cambios', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: AppColors.lightTextPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.lightTextDisabled),
            filled: true,
            fillColor: AppColors.lightBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightTertiary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estadísticas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard('Publicados', _profileData!.stats.published.toString(), Icons.grass_outlined, AppColors.info)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Negociando', _profileData!.stats.negotiating.toString(), Icons.handshake_outlined, AppColors.warning)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Cerradas', _profileData!.stats.closed.toString(), Icons.check_circle_outline, AppColors.success)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    final settings = _profileData!.settings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Opciones de negociación',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 16),
        
        // Habilitar precompra
        _buildSwitchTile(
          title: 'Habilitar precompra',
          subtitle: 'Permitir que los compradores oferten antes de la cosecha.',
          value: settings.enableEarlySale,
          onChanged: (val) {
            _updateSettings(FarmerSettingsData(
              enableEarlySale: val,
              sharePhone: settings.sharePhone,
              shareLocation: settings.shareLocation,
              shareWhatsapp: settings.shareWhatsapp,
            ));
          },
          icon: Icons.calendar_month_outlined,
        ),
        
        const SizedBox(height: 24),
        
        const Text(
          'Datos visibles durante la negociación',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Elige qué información de contacto estará disponible para el comprador.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          decoration: BoxDecoration(
            color: AppColors.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightBorder),
          ),
          child: Column(
            children: [
              _buildSwitchListTileInside(
                title: 'Teléfono',
                value: settings.sharePhone,
                onChanged: (val) {
                  _updateSettings(FarmerSettingsData(
                    enableEarlySale: settings.enableEarlySale,
                    sharePhone: val,
                    shareLocation: settings.shareLocation,
                    shareWhatsapp: settings.shareWhatsapp,
                  ));
                },
              ),
              const Divider(height: 1, color: AppColors.lightBorder),
              _buildSwitchListTileInside(
                title: 'Ubicación',
                value: settings.shareLocation,
                onChanged: (val) {
                  _updateSettings(FarmerSettingsData(
                    enableEarlySale: settings.enableEarlySale,
                    sharePhone: settings.sharePhone,
                    shareLocation: val,
                    shareWhatsapp: settings.shareWhatsapp,
                  ));
                },
              ),
              const Divider(height: 1, color: AppColors.lightBorder),
              _buildSwitchListTileInside(
                title: 'WhatsApp',
                value: settings.shareWhatsapp,
                onChanged: (val) {
                  _updateSettings(FarmerSettingsData(
                    enableEarlySale: settings.enableEarlySale,
                    sharePhone: settings.sharePhone,
                    shareLocation: settings.shareLocation,
                    shareWhatsapp: val,
                  ));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: AppColors.lightTextSecondary),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.lightSecondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.lightTertiary),
        ),
        value: value,
        onChanged: _isSaving ? null : onChanged,
        activeColor: AppColors.lightSurface,
        activeTrackColor: AppColors.lightTertiary,
        inactiveThumbColor: AppColors.lightTextDisabled,
        inactiveTrackColor: AppColors.lightBorder,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildSwitchListTileInside({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.lightTextPrimary),
      ),
      value: value,
      onChanged: _isSaving ? null : onChanged,
      activeColor: AppColors.lightSurface,
      activeTrackColor: AppColors.lightTertiary,
      inactiveThumbColor: AppColors.lightTextDisabled,
      inactiveTrackColor: AppColors.lightBorder,
    );
  }
}
