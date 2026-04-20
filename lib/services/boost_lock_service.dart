class BoostLockService {
  static bool isLocked(String placement) {
    // Definer hva som er låst
    // Juster etter behov senere
    return placement.contains('elite') || placement.contains('premium');
  }
}
