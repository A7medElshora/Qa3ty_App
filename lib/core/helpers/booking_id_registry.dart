class BookingIdRegistry {
  BookingIdRegistry._();

  static final Map<int, String> _uuidByLocalId = {};
  static final Map<String, int> _localIdByUuid = {};
  static int _nextLocalId = 2000;

  static int ensureLocalId(String uuid) {
    final numericId = int.tryParse(uuid);
    if (numericId != null) {
      _uuidByLocalId[numericId] = uuid;
      _localIdByUuid[uuid] = numericId;
      return numericId;
    }

    final existingId = _localIdByUuid[uuid];
    if (existingId != null) return existingId;

    while (_uuidByLocalId.containsKey(_nextLocalId)) {
      _nextLocalId++;
    }
    final localId = _nextLocalId++;
    _uuidByLocalId[localId] = uuid;
    _localIdByUuid[uuid] = localId;
    return localId;
  }

  static String? uuidForLocalId(int localId) => _uuidByLocalId[localId];
}
