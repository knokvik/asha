/// Canonical capability tags used by offline referral routing.
///
/// Source importers should emit these tags in `services_json`. They are
/// deliberately small and stable so a new government source can be joined to
/// the same offline directory without changing the APK.
abstract final class FacilityCapability {
  static const bloodBank = 'blood_bank';
  static const deliveryRoom = 'delivery_room';
  static const nrc = 'nrc';
  static const antivenom = 'antivenom';
  static const abHwc = 'ab_hwc';
  static const cho = 'cho';
  static const ncdClinic = 'ncd_clinic';
  static const pmJay = 'pmjay';
  static const janaushadhi = 'janaushadhi';
  static const vhsnd = 'vhsnd';
  static const eyeBank = 'eye_bank';
  static const ambulance108 = 'ambulance_108';
  static const ambulance102 = 'ambulance_102';
  static const emergency112 = 'emergency_112';

  /// Set only when the source has actually supplied route metadata.
  static const routeFerryCrossing = 'route_ferry_crossing';
  static const routeFerrySafe = 'route_ferry_safe';
  static const routeNetworkV1 = 'route_network_v1';
}

/// Converts source-specific service labels into stable routing capabilities.
///
/// The matcher accepts both the legacy list format and importer labels such as
/// `blood_bank:yes`, `delivery room`, or `AB-HWC`. Unknown values are retained
/// as normalised tags so future capabilities remain visible without becoming
/// clinical routing rules accidentally.
abstract final class FacilityCapabilityParser {
  static Set<String> normalise(Iterable<String> services) {
    final output = <String>{};
    for (final raw in services) {
      final value = raw.trim().toLowerCase();
      if (value.isEmpty || _isFalseValue(value)) continue;

      final parts = value.split(RegExp(r'[:=]'));
      final key = _slug(parts.first);
      if (parts.length > 1 && _isFalseValue(parts.last)) continue;

      final canonical = _aliases[key] ?? key;
      if (canonical.isNotEmpty) output.add(canonical);
    }
    return output;
  }

  static bool has(Iterable<String> services, String capability) =>
      normalise(services).contains(capability);

  static String _slug(String value) => value
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  static bool _isFalseValue(String value) => const {
    'no',
    'false',
    '0',
    'unavailable',
    'not_available',
    'closed',
  }.contains(value.trim().toLowerCase());

  static const _aliases = <String, String>{
    'blood': FacilityCapability.bloodBank,
    'blood_bank': FacilityCapability.bloodBank,
    'blood_centre': FacilityCapability.bloodBank,
    'blood_center': FacilityCapability.bloodBank,
    'blood_storage': FacilityCapability.bloodBank,
    'delivery': FacilityCapability.deliveryRoom,
    'delivery_room': FacilityCapability.deliveryRoom,
    'labour_room': FacilityCapability.deliveryRoom,
    'labour_delivery_room': FacilityCapability.deliveryRoom,
    'lr': FacilityCapability.deliveryRoom,
    'nrc': FacilityCapability.nrc,
    'nutrition_rehabilitation_centre': FacilityCapability.nrc,
    'nutrition_rehabilitation_center': FacilityCapability.nrc,
    'sam_care': FacilityCapability.nrc,
    'antivenin': FacilityCapability.antivenom,
    'anti_venom': FacilityCapability.antivenom,
    'antivenom': FacilityCapability.antivenom,
    'snakebite_treatment': FacilityCapability.antivenom,
    'ab_hwc': FacilityCapability.abHwc,
    'abpmj_ayushman_arogya_mandir': FacilityCapability.abHwc,
    'ayushman_arogya_mandir': FacilityCapability.abHwc,
    'health_and_wellness_centre': FacilityCapability.abHwc,
    'health_wellness_centre': FacilityCapability.abHwc,
    'cho': FacilityCapability.cho,
    'community_health_officer': FacilityCapability.cho,
    'ncd': FacilityCapability.ncdClinic,
    'ncd_clinic': FacilityCapability.ncdClinic,
    'cbac': FacilityCapability.ncdClinic,
    'pm_jay': FacilityCapability.pmJay,
    'pmjay': FacilityCapability.pmJay,
    'ayushman_bharat': FacilityCapability.pmJay,
    'jan_aushadhi': FacilityCapability.janaushadhi,
    'janaushadhi': FacilityCapability.janaushadhi,
    'pmbjp': FacilityCapability.janaushadhi,
    'vhsnd_site': FacilityCapability.vhsnd,
    'vhsnd': FacilityCapability.vhsnd,
    'eye_bank': FacilityCapability.eyeBank,
    'eye_bank_service': FacilityCapability.eyeBank,
    '108': FacilityCapability.ambulance108,
    'ambulance_108': FacilityCapability.ambulance108,
    '102': FacilityCapability.ambulance102,
    'ambulance_102': FacilityCapability.ambulance102,
    '112': FacilityCapability.emergency112,
    'erss_112': FacilityCapability.emergency112,
    'emergency_112': FacilityCapability.emergency112,
    'ferry_crossing': FacilityCapability.routeFerryCrossing,
    'route_ferry_crossing': FacilityCapability.routeFerryCrossing,
    'ferry_safe': FacilityCapability.routeFerrySafe,
    'route_ferry_safe': FacilityCapability.routeFerrySafe,
    'route_network_v1': FacilityCapability.routeNetworkV1,
  };
}
