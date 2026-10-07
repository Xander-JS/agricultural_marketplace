class FarmerSettingsData {
  final bool enableEarlySale;
  final bool sharePhone;
  final bool shareLocation;
  final bool shareWhatsapp;

  FarmerSettingsData({
    required this.enableEarlySale,
    required this.sharePhone,
    required this.shareLocation,
    required this.shareWhatsapp,
  });

  factory FarmerSettingsData.fromMap(Map<String, dynamic> map) {
    return FarmerSettingsData(
      enableEarlySale: map['enable_early_sale'] ?? false,
      sharePhone: map['share_phone'] ?? false,
      shareLocation: map['share_location'] ?? false,
      shareWhatsapp: map['share_whatsapp'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enable_early_sale': enableEarlySale,
      'share_phone': sharePhone,
      'share_location': shareLocation,
      'share_whatsapp': shareWhatsapp,
    };
  }
}

class FarmerStatsData {
  final int published;
  final int negotiating;
  final int closed;

  FarmerStatsData({
    required this.published,
    required this.negotiating,
    required this.closed,
  });
}

class FarmerProfileData {
  final String id;
  final String fullName;
  final String role;
  final String email;
  final String phone;
  final String? profilePath;
  final FarmerSettingsData settings;
  final FarmerStatsData stats;

  FarmerProfileData({
    required this.id,
    required this.fullName,
    required this.role,
    required this.email,
    required this.phone,
    this.profilePath,
    required this.settings,
    required this.stats,
  });

  factory FarmerProfileData.fromMap({
    required Map<String, dynamic> profileMap,
    required Map<String, dynamic> settingsMap,
    required FarmerStatsData stats,
  }) {
    return FarmerProfileData(
      id: profileMap['id'],
      fullName: profileMap['full_name'] ?? '',
      role: profileMap['role'] ?? '',
      email: profileMap['email'] ?? '',
      phone: profileMap['phone'] ?? '',
      profilePath: profileMap['profile_path'],
      settings: FarmerSettingsData.fromMap(settingsMap),
      stats: stats,
    );
  }
}
