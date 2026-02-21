class CardCatalog {
  // Poeng per 100 NOK (int)
  static const Map<String, int> rates = {
    'sas_amex': 20,
    'sas_mc': 15,
    'sas_visa': 10,
    'trumf_visa': 10,
    'trumf_mc': 8,
  };

  static const Map<String, String> names = {
    'sas_amex': 'SAS Amex',
    'sas_mc': 'SAS Mastercard',
    'sas_visa': 'SAS Visa',
    'trumf_visa': 'Trumf Visa',
    'trumf_mc': 'Trumf Mastercard',
  };

  static int rateFor(String? cardId) {
    if (cardId == null) return 0;
    return rates[cardId] ?? 0;
  }

  static String nameFor(String? cardId) {
    if (cardId == null) return 'Ingen kort valgt';
    return names[cardId] ?? cardId;
  }
}
