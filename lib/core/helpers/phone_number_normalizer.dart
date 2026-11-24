String normalizePhoneNumber(String phone) {
  final latinDigits = phone.replaceAllMapped(
    RegExp('[٠-٩۰-۹]'),
    (match) {
      final codePoint = match.group(0)!.runes.single;
      final digit = codePoint >= 0x0660 && codePoint <= 0x0669
          ? codePoint - 0x0660
          : codePoint - 0x06F0;
      return String.fromCharCode(0x30 + digit);
    },
  );
  var digits = latinDigits.replaceAll(RegExp(r'\D'), '');

  if (digits.startsWith('00')) digits = digits.substring(2);
  if (digits.startsWith('20')) digits = digits.substring(2);
  if (digits.startsWith('0')) digits = digits.substring(1);

  return digits;
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
