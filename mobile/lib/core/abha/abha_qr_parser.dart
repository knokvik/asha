import 'dart:convert';

/// Demographic information extracted offline from an ABDM ABHA QR code.
class AbhaDemographics {
  const AbhaDemographics({
    required this.abhaNumber,
    required this.name,
    required this.gender,
    this.abhaAddress,
    this.dob,
    this.ageYears,
    this.ageMonths,
    this.mobile,
    this.address,
    this.village,
    this.district,
    this.state,
    this.pincode,
    this.rawPayload,
  });

  final String abhaNumber;
  final String? abhaAddress;
  final String name;
  final String gender; // 'M', 'F', 'O'
  final String? dob; // YYYY-MM-DD
  final int? ageYears;
  final int? ageMonths;
  final String? mobile;
  final String? address;
  final String? village;
  final String? district;
  final String? state;
  final String? pincode;
  final String? rawPayload;

  Map<String, dynamic> toJson() => {
    'abhaNumber': abhaNumber,
    'abhaAddress': abhaAddress,
    'name': name,
    'gender': gender,
    'dob': dob,
    'ageYears': ageYears,
    'ageMonths': ageMonths,
    'mobile': mobile,
    'address': address,
    'village': village,
    'district': district,
    'state': state,
    'pincode': pincode,
  };
}

/// Offline parser for ABDM ABHA Card QR codes.
///
/// Operates with ZERO network calls, zero external API dependencies.
/// Decodes JSON, XML-like, delimited, or URL query formats commonly
/// found on national ABHA cards and Ayushman Bharat health accounts.
class AbhaQrParser {
  const AbhaQrParser();

  /// Parse raw string scanned from an ABHA QR code into [AbhaDemographics].
  /// Throws [FormatException] if payload is invalid or cannot be decoded.
  static AbhaDemographics parse(String rawQr) {
    final trimmed = rawQr.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Empty ABHA QR payload');
    }

    // Try JSON format (Official ABDM QR standard)
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      return _parseJson(trimmed);
    }

    // Try URL or URI parameter format (e.g. phr.abdm.gov.in/share?...)
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://') || trimmed.contains('?')) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null && uri.queryParameters.isNotEmpty) {
        return _parseQueryParams(uri.queryParameters, trimmed);
      }
    }

    // Try delimited format (pipe | or comma separated key-value pairs)
    if (trimmed.contains('|') || (trimmed.contains(':') && trimmed.contains(','))) {
      return _parseDelimited(trimmed);
    }

    // Fallback: check if the string itself is a 14-digit ABHA number
    final sanitizedNumber = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (sanitizedNumber.length == 14) {
      return AbhaDemographics(
        abhaNumber: _formatAbhaNumber(sanitizedNumber),
        name: 'Beneficiary',
        gender: 'O',
        rawPayload: trimmed,
      );
    }

    throw FormatException('Unrecognized ABHA QR payload format: $trimmed');
  }

  static AbhaDemographics _parseJson(String jsonStr) {
    final dynamic decoded = jsonDecode(jsonStr);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('ABHA QR JSON must be an object');
    }

    // Extract ABHA number (support keys: hidn, healthIdNumber, abhaNumber, abhaId)
    final abhaNumRaw = decoded['hidn'] ??
        decoded['healthIdNumber'] ??
        decoded['abhaNumber'] ??
        decoded['abhaId'] ??
        decoded['hid_number'] ??
        '';

    final abhaNumber = _formatAbhaNumber(abhaNumRaw.toString());
    if (abhaNumber.isEmpty) {
      throw const FormatException('ABHA QR payload missing valid ABHA number');
    }

    final abhaAddress = decoded['hid'] ?? decoded['healthId'] ?? decoded['abhaAddress'];
    final name = (decoded['name'] ?? decoded['fullName'] ?? decoded['first_name'] ?? 'Beneficiary').toString();
    
    // Gender normalization: 'M', 'F', 'O'
    final rawGender = (decoded['gender'] ?? decoded['sex'] ?? 'O').toString().toUpperCase();
    final gender = rawGender.startsWith('M')
        ? 'M'
        : (rawGender.startsWith('F') ? 'F' : 'O');

    // DOB and Age calculation
    String? dobStr;
    int? ageYears;
    int? ageMonths;

    if (decoded['dob'] != null && decoded['dob'].toString().isNotEmpty) {
      dobStr = decoded['dob'].toString();
      final parsedDate = _tryParseDate(dobStr);
      if (parsedDate != null) {
        final now = DateTime.now();
        var years = now.year - parsedDate.year;
        var months = now.month - parsedDate.month;
        if (now.day < parsedDate.day) {
          months--;
        }
        if (months < 0) {
          years--;
          months += 12;
        }
        ageYears = years >= 0 ? years : 0;
        ageMonths = (ageYears * 12) + (months >= 0 ? months : 0);
      }
    } else if (decoded['yearOfBirth'] != null) {
      final yob = int.tryParse(decoded['yearOfBirth'].toString());
      if (yob != null) {
        final mob = int.tryParse(decoded['monthOfBirth']?.toString() ?? '1') ?? 1;
        final dobDay = int.tryParse(decoded['dayOfBirth']?.toString() ?? '1') ?? 1;
        dobStr = '$yob-${mob.toString().padLeft(2, '0')}-${dobDay.toString().padLeft(2, '0')}';
        final now = DateTime.now();
        ageYears = now.year - yob;
        ageMonths = (ageYears * 12) + (now.month - mob);
      }
    }

    if (ageMonths == null && decoded['age'] != null) {
      final a = int.tryParse(decoded['age'].toString());
      if (a != null) {
        ageYears = a;
        ageMonths = a * 12;
      }
    }

    // Address & village
    final address = decoded['address']?.toString();
    final village = decoded['village'] ?? decoded['subdistrict_name'] ?? _extractVillage(address);
    final district = decoded['dist_name'] ?? decoded['district'] ?? decoded['district_name'];
    final state = decoded['state_name'] ?? decoded['state'];
    final pincode = decoded['pincode'] ?? decoded['pin'];
    final mobile = decoded['mobile'] ?? decoded['phone'];

    return AbhaDemographics(
      abhaNumber: abhaNumber,
      abhaAddress: abhaAddress?.toString(),
      name: name,
      gender: gender,
      dob: dobStr,
      ageYears: ageYears,
      ageMonths: ageMonths,
      mobile: mobile?.toString(),
      address: address,
      village: village?.toString(),
      district: district?.toString(),
      state: state?.toString(),
      pincode: pincode?.toString(),
      rawPayload: jsonStr,
    );
  }

  static AbhaDemographics _parseQueryParams(Map<String, String> params, String raw) {
    final abhaNumRaw = params['hidn'] ?? params['abha'] ?? params['healthIdNumber'] ?? '';
    final abhaNumber = _formatAbhaNumber(abhaNumRaw);
    final name = params['name'] ?? 'Beneficiary';
    final gender = params['gender']?.toUpperCase().startsWith('F') == true ? 'F' : 'M';
    final dob = params['dob'];
    final village = params['village'] ?? params['address'];

    return AbhaDemographics(
      abhaNumber: abhaNumber.isNotEmpty ? abhaNumber : '91-0000-0000-0000',
      abhaAddress: params['hid'],
      name: name,
      gender: gender,
      dob: dob,
      village: village,
      rawPayload: raw,
    );
  }

  static AbhaDemographics _parseDelimited(String text) {
    final pairs = text.split(RegExp(r'[,|]'));
    final map = <String, String>{};
    for (final pair in pairs) {
      final idx = pair.indexOf(':');
      if (idx > 0) {
        final k = pair.substring(0, idx).trim().toLowerCase();
        final v = pair.substring(idx + 1).trim();
        map[k] = v;
      }
    }

    final abhaNumRaw = map['abha'] ?? map['hidn'] ?? map['hid'] ?? '';
    final abhaNumber = _formatAbhaNumber(abhaNumRaw);
    final name = map['name'] ?? 'Beneficiary';
    final gender = (map['gender'] ?? map['sex'] ?? 'O').toUpperCase().startsWith('F') ? 'F' : 'M';
    final dob = map['dob'];
    final village = map['village'] ?? map['address'] ?? map['dist'];

    return AbhaDemographics(
      abhaNumber: abhaNumber.isNotEmpty ? abhaNumber : '91-0000-0000-0000',
      abhaAddress: map['hid'],
      name: name,
      gender: gender,
      dob: dob,
      village: village,
      rawPayload: text,
    );
  }

  static String _formatAbhaNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 14) {
      return '${digits.substring(0, 2)}-${digits.substring(2, 6)}-${digits.substring(6, 10)}-${digits.substring(10, 14)}';
    }
    return raw.trim();
  }

  static DateTime? _tryParseDate(String dateStr) {
    try {
      if (dateStr.contains('-')) {
        return DateTime.parse(dateStr);
      }
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          // DD/MM/YYYY
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static String? _extractVillage(String? address) {
    if (address == null) return null;
    final match = RegExp(r'\b(?:Village|Vill|Gram)\s*[:\s-]?\s*([A-Za-z\u0900-\u097F]+)', caseSensitive: false)
        .firstMatch(address);
    if (match != null) {
      return match.group(1);
    }
    return null;
  }
}
