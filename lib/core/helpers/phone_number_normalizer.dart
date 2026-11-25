String normalizePhoneNumber(String phone) {
  final latinDigits = _toLatinDigits(phone);
  var digits = latinDigits.replaceAll(RegExp(r'\D'), '');

  if (digits.startsWith('00')) digits = digits.substring(2);
  if (digits.startsWith('20')) digits = digits.substring(2);
  if (digits.startsWith('0')) digits = digits.substring(1);

  return digits;
}

String normalizePhoneNumberForWhatsApp(String phone) {
  final trimmed = phone.trim();
  var digits = _toLatinDigits(trimmed).replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('00')) {
    digits = digits.substring(2);
  } else if (!trimmed.startsWith('+')) {
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (!digits.startsWith('20')) digits = '20$digits';
  }
  return digits;
}

String _toLatinDigits(String phone) {
  return phone.replaceAllMapped(
    RegExp('[٠-٩۰-۹]'),
    (match) {
      final codePoint = match.group(0)!.runes.single;
      final digit = codePoint >= 0x0660 && codePoint <= 0x0669
          ? codePoint - 0x0660
          : codePoint - 0x06F0;
      return String.fromCharCode(0x30 + digit);
    },
  );
}

bool phoneNumbersMatch(String first, String second) {
  final firstNormalized = normalizePhoneNumber(first);
  final secondNormalized = normalizePhoneNumber(second);
  if (firstNormalized.isEmpty || secondNormalized.isEmpty) return false;
  if (firstNormalized == secondNormalized) return true;

  final shorter = firstNormalized.length <= secondNormalized.length
      ? firstNormalized
      : secondNormalized;
  final longer = firstNormalized.length <= secondNormalized.length
      ? secondNormalized
      : firstNormalized;

  return shorter.length >= 7 && longer.endsWith(shorter);
}
