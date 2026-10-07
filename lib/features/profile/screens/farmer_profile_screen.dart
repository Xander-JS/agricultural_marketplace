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

  late FocusNode _emailFocusNode;
  late FocusNode _phoneFocusNode;
  bool _emailSaved = false;
  bool _phoneSaved = false;
  StateSetter? _modalSetState;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _emailFocusNode = FocusNode();
    _phoneFocusNode = FocusNode();

    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        _checkAndSaveField('email', _emailController.text.trim());
      } else {
        _emailSaved = false;
        _modalSetState?.call(() {});
      }
    });

    _phoneFocusNode.addListener(() {
      if (!_phoneFocusNode.hasFocus) {
        _checkAndSaveField('phone', _phoneController.text.trim());
      } else {
        _phoneSaved = false;
        _modalSetState?.call(() {});
      }
    });

    _loadProfileData();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No hay usuario autenticado. (Modo prueba activo sin sesión)');
      }
      final userId = currentUser.id;      final data = await _profileService.getFarmerProfileData(userId);
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

  Future<void> _checkAndSaveField(String field, String value) async {
    if (_profileData == null) return;
    
    // Verificar si realmente cambió
    if (field == 'email' && value == _profileData!.email) return;
    if (field == 'phone' && value == _profileData!.phone) return;

    setState(() => _isSaving = true);
    _modalSetState?.call(() {});

    try {
      if (field == 'email') {
        await _profileService.updateProfileData(_profileData!.id, email: value);
        _profileData = FarmerProfileData(
          id: _profileData!.id,
          fullName: _profileData!.fullName,
          role: _profileData!.role,
          email: value,
          phone: _profileData!.phone,
          profilePath: _profileData!.profilePath,
          stats: _profileData!.stats,
          settings: _profileData!.settings,
        );
        _emailSaved = true;
      } else if (field == 'phone') {
        await _profileService.updateProfileData(_profileData!.id, phone: value);
        _profileData = FarmerProfileData(
          id: _profileData!.id,
          fullName: _profileData!.fullName,
          role: _profileData!.role,
          email: _profileData!.email,
          phone: value,
          profilePath: _profileData!.profilePath,
          stats: _profileData!.stats,
          settings: _profileData!.settings,
        );
        _phoneSaved = true;
      }
      
      setState(() => _isSaving = false);
      _modalSetState?.call(() {});
      
    } catch (e) {
      setState(() => _isSaving = false);
      _modalSetState?.call(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar dato: $e'), backgroundColor: AppColors.error),
        );
      }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _isSaving || _profileData == null ? null : _showSettingsBottomSheet,
          ),
        ],
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
                          _buildStatisticsSection(),
                          const SizedBox(height: 40),

                        ],
                      ),
                    ),
            ),
    );
  }

  void _showSettingsBottomSheet() {
    // Reset status al abrir
    _emailSaved = false;
    _phoneSaved = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          _modalSetState = setModalState;
          final settings = _profileData!.settings;

          
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.lightBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 24,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: AppColors.lightBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Información de contacto',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Correo electrónico',
                    controller: _emailController,
                    originalValue: _profileData!.email,
                    icon: Icons.email_outlined,
                    focusNode: _emailFocusNode,
                    isSaved: _emailSaved,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Número de teléfono',
                    controller: _phoneController,
                    originalValue: _profileData!.phone,
                    icon: Icons.phone_outlined,
                    focusNode: _phoneFocusNode,
                    isSaved: _phoneSaved,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  
                  const Text(
                    'Opciones de negociación',

                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Habilitar precompra
                _buildSwitchTile(
                  title: 'Habilitar precompra',
                  value: settings.enableEarlySale,
                  icon: Icons.calendar_month_outlined,
                  onChanged: (val) {
                    setModalState(() {
                      _updateSettings(FarmerSettingsData(
                        enableEarlySale: val,
                        sharePhone: settings.sharePhone,
                        shareLocation: settings.shareLocation,
                        shareWhatsapp: settings.shareWhatsapp,
                      ));
                    });
                  },
                ),
                
                const SizedBox(height: 24),
                
                const Text(
                  'Visibilidad durante una negociación',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightTextPrimary,
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
                          setModalState(() {
                            _updateSettings(FarmerSettingsData(
                              enableEarlySale: settings.enableEarlySale,
                              sharePhone: val,
                              shareLocation: settings.shareLocation,
                              shareWhatsapp: settings.shareWhatsapp,
                            ));
                          });
                        },
                      ),
                      const Divider(height: 1, color: AppColors.lightBorder),
                      _buildSwitchListTileInside(
                        title: 'Ubicación',
                        value: settings.shareLocation,
                        onChanged: (val) {
                          setModalState(() {
                            _updateSettings(FarmerSettingsData(
                              enableEarlySale: settings.enableEarlySale,
                              sharePhone: settings.sharePhone,
                              shareLocation: val,
                              shareWhatsapp: settings.shareWhatsapp,
                            ));
                          });
                        },
                      ),
                      const Divider(height: 1, color: AppColors.lightBorder),
                      _buildSwitchListTileInside(
                        title: 'WhatsApp',
                        value: settings.shareWhatsapp,
                        onChanged: (val) {
                          setModalState(() {
                            _updateSettings(FarmerSettingsData(
                              enableEarlySale: settings.enableEarlySale,
                              sharePhone: settings.sharePhone,
                              shareLocation: settings.shareLocation,
                              shareWhatsapp: val,
                            ));
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ),
            ),
          );


        },
      ),
    );
  }

  // Se modifican los headers y el editable data... (se deja igual)
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String originalValue,
    required IconData icon,
    required FocusNode focusNode,
    required bool isSaved,
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
          focusNode: focusNode,
          style: const TextStyle(color: AppColors.lightTextPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.lightTextDisabled),
            suffixIcon: isSaved
                ? const Icon(Icons.check_circle, color: AppColors.success)
                : null,
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

  Widget _buildSwitchTile({
    required String title,
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
