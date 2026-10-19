/// Kangaroo Mother Care (KMC) guidance model and protocol text for low-birth-weight
/// and preterm newborns.
///
/// Implements Requirement 12.4:
/// - Enrols newborn in high-risk pathway when birth weight < 2.5 kg or preterm.
/// - Presents standardized KMC guidance on each relevant HBNC visit screen.
class KmcGuidance {
  static const String title = 'Kangaroo Mother Care (KMC) Protocol';

  static const List<String> coreSteps = [
    'Positioning: Place baby upright between mother\'s breasts in frog position with hips flexed and abducted.',
    'Airway: Turn baby\'s head slightly to one side in slightly extended position to maintain open airway.',
    'Clothing: Baby wears only cap, socks, and nappy; skin firmly touches mother\'s bare chest.',
    'Support: Secure baby with a firm cotton wrap or binder around mother\'s chest.',
    'Duration: Minimum 8 hours daily; continuous (up to 24 hours) is recommended until baby reaches 2.5 kg.',
    'Family Involvement: Father and other female relatives can take turns providing KMC when mother rests.',
    'Nutrition: Support frequent and exclusive breastfeeding every 2 hours; use expressed breastmilk if suckling is weak.',
    'Thermal Chain: Do not bathe baby until weight exceeds 2.5 kg; wipe with warm damp cloth only if needed.',
  ];

  static const List<String> dangerSignAlerts = [
    'Baby feels cold to touch despite KMC (hypothermia < 35.5°C)',
    'Baby stops breathing or has pauses longer than 20 seconds',
    'Baby breathes faster than 60 breaths per minute or has chest indrawing',
    'Baby is unusually lethargic or refuses to suckle',
    'Jaundice appears on palms and soles',
  ];

  /// Recommended daily target KMC hours based on birth weight.
  static double recommendedTargetHours(double birthWeightKg) {
    if (birthWeightKg < 1.5) return 18.0;
    if (birthWeightKg < 2.0) return 12.0;
    return 8.0;
  }
}
