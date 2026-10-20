import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../app/theme/app_theme.dart';

/// Reusable SVG and vector illustrations matching the exact Asha Platform UI design.
class AshaSvgIllustrations {
  AshaSvgIllustrations._();

  static const String logoSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 60" width="200" height="60">
  <g fill="none" fill-rule="evenodd">
    <text x="4" y="46" font-family="-apple-system, 'SF Pro Display', BlinkMacSystemFont, sans-serif" font-size="52" font-weight="900" fill="#1E4231" letter-spacing="-2">asha</text>
  </g>
</svg>
''';

  static const String fieldWorkerSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 280 160" width="280" height="160">
  <defs>
    <linearGradient id="skyGrad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#EBF7F0" />
      <stop offset="100%" stop-color="#D6EFE1" />
    </linearGradient>
    <linearGradient id="hillGrad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#A7D7BC" />
      <stop offset="100%" stop-color="#80BE9D" />
    </linearGradient>
  </defs>
  <path d="M0 90 Q 60 70, 140 85 T 280 80 L 280 160 L 0 160 Z" fill="url(#hillGrad)" opacity="0.6" />
  <path d="M0 110 Q 70 95, 160 110 T 280 100 L 280 160 L 0 160 Z" fill="#9BCDAF" opacity="0.8" />
  <rect y="125" width="280" height="35" fill="#C4E4D3" />
  <g transform="translate(25, 92)">
    <polygon points="0,20 22,4 44,20" fill="#E67E48" />
    <rect x="5" y="20" width="34" height="24" rx="2" fill="#FDF3E7" />
    <rect x="18" y="28" width="8" height="16" rx="2" fill="#9A5B32" />
    <circle cx="50" cy="18" r="10" fill="#489F6E" />
    <circle cx="56" cy="14" r="7" fill="#60B785" />
    <rect x="51" y="25" width="4" height="15" fill="#755038" />
  </g>
  <g transform="translate(85, 96)">
    <polygon points="0,16 18,3 36,16" fill="#D36B3B" />
    <rect x="4" y="16" width="28" height="20" rx="1.5" fill="#F5E8D8" />
    <rect x="15" y="23" width="7" height="13" rx="1.5" fill="#7D4624" />
    <circle cx="-5" cy="28" r="8" fill="#58AC7B" />
  </g>
  <g transform="translate(180, 20)">
    <circle cx="48" cy="36" r="16" fill="#1C1B1F" />
    <circle cx="60" cy="38" r="7" fill="#1C1B1F" />
    <ellipse cx="48" cy="40" rx="13" ry="15" fill="#E8A87C" />
    <rect x="44" y="52" width="8" height="12" fill="#D9966A" />
    <path d="M35 34 C 42 26, 56 26, 61 36 C 58 32, 48 30, 35 34 Z" fill="#1C1B1F" />
    <circle cx="48" cy="37" r="1.5" fill="#C23B22" />
    <path d="M43 42 Q 45 44, 47 42" stroke="#683B20" stroke-width="1.2" fill="none" stroke-linecap="round" />
    <path d="M49 42 Q 51 44, 53 42" stroke="#683B20" stroke-width="1.2" fill="none" stroke-linecap="round" />
    <path d="M46 47 Q 48 50, 50 47" stroke="#BA4A3A" stroke-width="1.2" fill="none" stroke-linecap="round" />
    <path d="M32 64 C 36 60, 60 60, 64 64 L 66 85 L 30 85 Z" fill="#D95C38" />
    <path d="M30 65 Q 48 68, 62 88 L 68 140 L 24 140 L 26 82 Z" fill="#2D5F47" />
    <path d="M30 65 Q 44 80, 55 110 L 40 125 Q 32 85, 30 65 Z" fill="#3D7D5E" />
    <path d="M30 65 Q 44 80, 55 110" stroke="#F5B041" stroke-width="2.5" fill="none" />
    <path d="M30 68 Q 20 82, 26 98 L 35 96 Q 28 82, 36 72 Z" fill="#E8A87C" />
    <path d="M62 68 Q 72 82, 60 98 L 54 94 Q 64 80, 58 70 Z" fill="#E8A87C" />
    <circle cx="58" cy="94" r="3" fill="#19D96B" />
    <g transform="translate(18, 90) rotate(-10)">
      <rect x="0" y="0" width="34" height="42" rx="4" fill="#263238" />
      <rect x="2" y="2" width="30" height="38" rx="3" fill="#E0F2FE" />
      <rect x="5" y="6" width="16" height="4" rx="1" fill="#0284C7" />
      <rect x="5" y="13" width="24" height="2" fill="#94A3B8" />
      <rect x="5" y="18" width="20" height="2" fill="#94A3B8" />
      <rect x="5" y="23" width="22" height="2" fill="#94A3B8" />
      <polyline points="5,32 10,32 12,28 15,35 18,30 20,32 25,32" stroke="#16A34A" stroke-width="1.5" fill="none" stroke-linecap="round" />
    </g>
  </g>
</svg>
''';

  static const String triageHeadacheSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 200" width="240" height="200">
  <defs>
    <radialGradient id="auraGrad" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="#FEE2E2" stop-opacity="0.8" />
      <stop offset="80%" stop-color="#FEF2F2" stop-opacity="0.3" />
      <stop offset="100%" stop-color="#FFFFFF" stop-opacity="0" />
    </radialGradient>
    <linearGradient id="painSparks" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#EF4444" />
      <stop offset="100%" stop-color="#DC2626" />
    </linearGradient>
  </defs>
  <circle cx="120" cy="100" r="85" fill="#F0FDF4" />
  <circle cx="140" cy="70" r="45" fill="url(#auraGrad)" />
  <g stroke="url(#painSparks)" stroke-width="2.5" stroke-linecap="round" fill="none">
    <path d="M148 38 L154 32 L150 44 L158 40" />
    <path d="M162 48 L170 44 L165 54 L174 50" />
    <path d="M164 64 L174 62 L168 70" />
    <path d="M152 24 A 12 12 0 0 1 166 32" stroke-width="1.8" stroke="#F87171" stroke-dasharray="2 3" />
    <path d="M164 18 A 22 22 0 0 1 180 32" stroke-width="1.8" stroke="#FCA5A5" stroke-dasharray="3 3" />
  </g>
  <g transform="translate(45, 20)">
    <ellipse cx="65" cy="48" rx="20" ry="22" fill="#18181B" />
    <circle cx="48" cy="46" r="10" fill="#18181B" />
    <rect x="76" y="58" width="12" height="18" rx="4" fill="#D9966A" />
    <ellipse cx="88" cy="46" rx="16" ry="18" fill="#E8A87C" />
    <path d="M72 40 C 76 30, 94 28, 102 40 C 96 35, 82 35, 72 40 Z" fill="#18181B" />
    <path d="M84 43 Q 87 40, 91 44" stroke="#5C3317" stroke-width="1.8" fill="none" stroke-linecap="round" />
    <path d="M96 44 Q 99 41, 102 45" stroke="#5C3317" stroke-width="1.8" fill="none" stroke-linecap="round" />
    <path d="M92 39 Q 94 37, 95 39" stroke="#B45309" stroke-width="1.2" fill="none" />
    <circle cx="93" cy="38" r="1.5" fill="#DC2626" />
    <path d="M88 56 Q 93 53, 98 56" stroke="#991B1B" stroke-width="1.8" fill="none" stroke-linecap="round" />
    <path d="M102 75 Q 120 70, 126 50" stroke="#E8A87C" stroke-width="12" stroke-linecap="round" fill="none" />
    <path d="M126 50 Q 120 38, 104 38" stroke="#E8A87C" stroke-width="10" stroke-linecap="round" fill="none" />
    <circle cx="103" cy="37" r="4" fill="#E8A87C" />
    <ellipse cx="118" cy="44" rx="4" ry="7" fill="none" stroke="#F59E0B" stroke-width="2.5" />
    <ellipse cx="116" cy="46" rx="4" ry="7" fill="none" stroke="#EF4444" stroke-width="2" />
    <path d="M68 76 C 75 70, 105 70, 110 76 L 112 105 L 64 105 Z" fill="#EA580C" />
    <path d="M60 102 C 60 102, 50 120, 52 145 C 54 165, 80 178, 115 178 C 145 178, 150 155, 148 135 C 146 115, 130 102, 110 102 Z" fill="#15803D" />
    <path d="M75 110 Q 85 145, 95 178" stroke="#166534" stroke-width="2" fill="none" opacity="0.6" />
    <path d="M92 110 Q 105 145, 115 178" stroke="#166534" stroke-width="2" fill="none" opacity="0.6" />
    <path d="M68 76 Q 88 95, 100 135 L 75 155 Q 65 110, 68 76 Z" fill="#166534" />
    <path d="M68 76 Q 88 95, 100 135" stroke="#FBBF24" stroke-width="3" fill="none" />
    <path d="M68 80 Q 52 105, 58 130 L 78 142 Q 62 120, 72 90 Z" fill="#E8A87C" />
    <ellipse cx="80" cy="144" rx="10" ry="7" fill="#E8A87C" />
    <ellipse cx="64" cy="126" rx="5" ry="3" fill="none" stroke="#F59E0B" stroke-width="2.5" />
    <ellipse cx="66" cy="129" rx="5" ry="3" fill="none" stroke="#10B981" stroke-width="2" />
  </g>
</svg>
''';

  static const String ancSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80" width="80" height="80">
  <circle cx="40" cy="40" r="38" fill="#F0FDF4" />
  <g transform="translate(18, 12)">
    <circle cx="16" cy="10" r="7" fill="#15803D" />
    <path d="M14 18 C10 22, 6 30, 8 42 C10 52, 22 55, 30 52 C36 50, 36 38, 32 30 C28 22, 20 18, 14 18 Z" fill="#22C55E" />
    <path d="M12 24 Q 28 28, 30 46" stroke="#15803D" stroke-width="2.5" fill="none" />
    <path d="M10 20 Q 20 32, 22 48" stroke="#F59E0B" stroke-width="1.5" fill="none" />
  </g>
</svg>
''';

  static const String pncSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80" width="80" height="80">
  <circle cx="40" cy="40" r="38" fill="#EFF6FF" />
  <g transform="translate(18, 12)">
    <circle cx="24" cy="10" r="7" fill="#1E40AF" />
    <path d="M18 18 C14 24, 12 36, 14 48 C20 54, 34 52, 38 46 C42 40, 36 24, 28 18 Z" fill="#3B82F6" />
    <g transform="translate(6, 22)">
      <circle cx="8" cy="8" r="5" fill="#FBCFE8" />
      <path d="M4 14 C4 11, 14 11, 16 16 C18 22, 10 26, 4 22 Z" fill="#F472B6" />
    </g>
    <path d="M26 24 Q 10 32, 16 44" stroke="#1D4ED8" stroke-width="3" fill="none" stroke-linecap="round" />
  </g>
</svg>
''';

  static const String immunizationSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80" width="80" height="80">
  <circle cx="40" cy="40" r="38" fill="#FEF3C7" />
  <g transform="translate(18, 14)">
    <circle cx="16" cy="14" r="9" fill="#FDE68A" stroke="#D97706" stroke-width="1.5" />
    <circle cx="13" cy="13" r="1.5" fill="#92400E" />
    <circle cx="19" cy="13" r="1.5" fill="#92400E" />
    <path d="M14 17 Q 16 19, 18 17" stroke="#92400E" stroke-width="1.2" fill="none" />
    <g transform="translate(24, 20) rotate(-45)">
      <rect x="0" y="4" width="8" height="20" rx="1.5" fill="#0284C7" />
      <rect x="2" y="0" width="4" height="4" fill="#64748B" />
      <line x1="4" y1="24" x2="4" y2="30" stroke="#475569" stroke-width="1.5" />
      <line x1="2" y1="8" x2="6" y2="8" stroke="#FFFFFF" stroke-width="1" />
      <line x1="2" y1="12" x2="6" y2="12" stroke="#FFFFFF" stroke-width="1" />
      <line x1="2" y1="16" x2="6" y2="16" stroke="#FFFFFF" stroke-width="1" />
    </g>
  </g>
</svg>
''';

  static const String ncdSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80" width="80" height="80">
  <circle cx="40" cy="40" r="38" fill="#FEE2E2" />
  <g transform="translate(18, 16)">
    <rect x="2" y="4" width="28" height="38" rx="6" fill="#1E293B" />
    <rect x="5" y="8" width="22" height="16" rx="3" fill="#E2E8F0" />
    <polyline points="7,16 11,16 13,11 16,21 18,14 20,16 25,16" stroke="#EF4444" stroke-width="1.8" fill="none" stroke-linecap="round" />
    <circle cx="16" cy="32" r="4" fill="#3B82F6" />
    <g transform="translate(26, 22)">
      <path d="M8 0 C 8 0, 0 10, 0 15 A 8 8 0 0 0 16 15 C 16 10, 8 0, 8 0 Z" fill="#DC2626" />
      <circle cx="6" cy="14" r="2" fill="#FCA5A5" />
    </g>
  </g>
</svg>
''';

  static const String hbncSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80" width="80" height="80">
  <circle cx="40" cy="40" r="38" fill="#ECFDF5" />
  <g transform="translate(16, 18)">
    <path d="M4 28 Q 24 38, 44 28 L 46 38 Q 24 48, 2 38 Z" fill="#10B981" opacity="0.4" />
    <path d="M6 24 C 6 20, 42 20, 42 24 L 40 34 C 40 38, 8 38, 8 34 Z" fill="#D1FAE5" stroke="#059669" stroke-width="2" />
    <circle cx="20" cy="22" r="7" fill="#FDE68A" />
    <path d="M18 22 Q 20 24, 22 22" stroke="#92400E" stroke-width="1.2" fill="none" />
    <path d="M25 24 Q 35 24, 38 30" stroke="#059669" stroke-width="2" fill="none" />
  </g>
</svg>
''';

  static const String tbSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80" width="80" height="80">
  <circle cx="40" cy="40" r="38" fill="#FFF1F2" />
  <g transform="translate(18, 16)">
    <rect x="20" y="2" width="4" height="12" rx="1" fill="#FDA4AF" />
    <path d="M22 14 L 14 20" stroke="#FDA4AF" stroke-width="3" stroke-linecap="round" />
    <path d="M22 14 L 30 20" stroke="#FDA4AF" stroke-width="3" stroke-linecap="round" />
    <path d="M12 18 C 6 18, 2 24, 2 34 C 2 44, 10 48, 18 46 C 20 40, 18 24, 12 18 Z" fill="#F43F5E" />
    <path d="M32 18 C 38 18, 42 24, 42 34 C 42 44, 34 48, 26 46 C 24 40, 26 24, 32 18 Z" fill="#F43F5E" />
    <circle cx="22" cy="30" r="5" fill="#10B981" />
    <path d="M20 30 L 24 30 M 22 28 L 22 32" stroke="#FFFFFF" stroke-width="1.5" />
  </g>
</svg>
''';

  static const String interpreterMicSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" width="200" height="200">
  <defs>
    <radialGradient id="micGlow" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="#2D5F47" stop-opacity="0.15" />
      <stop offset="60%" stop-color="#2D5F47" stop-opacity="0.05" />
      <stop offset="100%" stop-color="#FFFFFF" stop-opacity="0" />
    </radialGradient>
  </defs>
  <circle cx="100" cy="100" r="90" fill="url(#micGlow)" />
  <circle cx="100" cy="100" r="72" fill="#E5F2EE" opacity="0.6" />
  <circle cx="100" cy="100" r="54" fill="#2D5F47" />
  <g transform="translate(85, 75)" fill="#FFFFFF">
    <rect x="10" y="4" width="10" height="22" rx="5" fill="#FFFFFF" />
    <path d="M5 16 C5 24, 25 24, 25 16" stroke="#FFFFFF" stroke-width="2.5" fill="none" stroke-linecap="round" />
    <line x1="15" y1="26" x2="15" y2="34" stroke="#FFFFFF" stroke-width="2.5" stroke-linecap="round" />
    <line x1="10" y1="34" x2="20" y2="34" stroke="#FFFFFF" stroke-width="2.5" stroke-linecap="round" />
  </g>
  <g stroke="#2D5F47" stroke-width="3" stroke-linecap="round">
    <line x1="25" y1="100" x2="25" y2="100" stroke-width="4" />
    <line x1="33" y1="92" x2="33" y2="108" />
    <line x1="41" y1="84" x2="41" y2="116" />
    <line x1="49" y1="94" x2="49" y2="106" />
    <line x1="151" y1="94" x2="151" y2="106" />
    <line x1="159" y1="84" x2="159" y2="116" />
    <line x1="167" y1="92" x2="167" y2="108" />
    <line x1="175" y1="100" x2="175" y2="100" stroke-width="4" />
  </g>
</svg>
''';
}

/// ASHA Logo with green medical emblem and bold modern wordmark (no leaves on top).
class AshaLogo extends StatelessWidget {
  const AshaLogo({
    super.key,
    this.height = 36,
    this.showEmblem = true,
  });

  final double height;
  final bool showEmblem;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showEmblem) ...[
          Image.asset(
            'assets/branding/favicon.png',
            width: height * 0.88,
            height: height * 0.88,
            fit: BoxFit.contain,
          ),
          SizedBox(width: height * 0.22),
        ],
        Text(
          'asha',
          style: TextStyle(
            fontSize: height * 0.82,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF1E4231),
            letterSpacing: -1.0,
            fontFamily: 'SF Pro Display',
          ),
        ),
      ],
    );
  }
}

/// ASHA Field Worker Illustration (Screen 1 Continue Work Card).
class AshaFieldWorkerIllustrationWidget extends StatelessWidget {
  const AshaFieldWorkerIllustrationWidget({super.key, this.height = 110});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      AshaSvgIllustrations.fieldWorkerSvg,
      height: height,
      fit: BoxFit.contain,
    );
  }
}

/// Triage Assessment Headache Illustration (Screen 5).
class AshaTriageHeadacheIllustrationWidget extends StatelessWidget {
  const AshaTriageHeadacheIllustrationWidget({super.key, this.height = 160});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      AshaSvgIllustrations.triageHeadacheSvg,
      height: height,
      fit: BoxFit.contain,
    );
  }
}

/// Clinical Program Illustration Badge (Screen 7).
enum ClinicalProgramType { anc, pnc, immunization, ncd, hbnc, tb }

class AshaClinicalProgramIllustrationWidget extends StatelessWidget {
  const AshaClinicalProgramIllustrationWidget({
    super.key,
    required this.type,
    this.size = 54,
  });

  final ClinicalProgramType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final svgString = switch (type) {
      ClinicalProgramType.anc => AshaSvgIllustrations.ancSvg,
      ClinicalProgramType.pnc => AshaSvgIllustrations.pncSvg,
      ClinicalProgramType.immunization => AshaSvgIllustrations.immunizationSvg,
      ClinicalProgramType.ncd => AshaSvgIllustrations.ncdSvg,
      ClinicalProgramType.hbnc => AshaSvgIllustrations.hbncSvg,
      ClinicalProgramType.tb => AshaSvgIllustrations.tbSvg,
    };

    return SvgPicture.string(
      svgString,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

/// Central ASHA Platform Showcase Card (From design overview center banner).
class AshaOverviewBanner extends StatelessWidget {
  const AshaOverviewBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: AshaColors.cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AshaColors.borderSubtle),
      ),
      child: Column(
        children: [
          const AshaLogo(height: 48),
          const SizedBox(height: 6),
          const Text(
            'Empowering ASHA for Healthier Communities',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AshaColors.primaryDark,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildFeatureTile(
                icon: Icons.wifi_off_rounded,
                title: 'Works Offline',
                subtitle: 'Your data is safe',
              ),
              _buildFeatureTile(
                icon: Icons.shield_outlined,
                title: 'Secure & Encrypted',
                subtitle: 'AES-256',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildFeatureTile(
                icon: Icons.people_outline_rounded,
                title: 'Local Languages',
                subtitle: 'Voice + Text',
              ),
              _buildFeatureTile(
                icon: Icons.phone_android_rounded,
                title: 'Designed for ASHA',
                subtitle: 'Simple & Easy',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: AshaColors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AshaColors.borderSubtle, width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AshaColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AshaColors.primary),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AshaColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AshaColors.textSecondary,
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
