// A signed-in Microsoft account.
//
// Stores: player name, UUID, Microsoft refresh_token, Minecraft access_token
// and expiry. The Microsoft access_token is used once to exchange for a
// Minecraft token and is not persisted.
//
// Note: the account JSON is now written to the system secure store by
// AccountStore, not plaintext shared_preferences. Callers only depend on the
// AccountStore layer.

class MinecraftAccount {
  const MinecraftAccount({
    required this.name,
    required this.uuid,
    required this.refreshToken,
    required this.accessToken,
    required this.accessExpiresAt,
  });

  /// In-game player name.
  final String name;

  /// UUID without hyphens (Mojang's `id`).
  final String uuid;

  /// Microsoft refresh_token used for silent renewal.
  final String refreshToken;

  /// Minecraft access_token used to launch the game.
  final String accessToken;

  /// Minecraft token expiry.
  final DateTime accessExpiresAt;

  /// Treat the token as expired 5 minutes early so it cannot expire right at launch.
  bool get isExpired => DateTime.now().isAfter(
    accessExpiresAt.subtract(const Duration(minutes: 5)),
  );

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name,
      'uuid': uuid,
      'refreshToken': refreshToken,
      'accessToken': accessToken,
      'accessExpiresAt': accessExpiresAt.toIso8601String(),
    };
  }

  /// Unreadable fields are treated as missing; a broken account returns null.
  static MinecraftAccount? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final Object? name = raw['name'];
    final Object? uuid = raw['uuid'];
    final Object? refresh = raw['refreshToken'];
    final Object? access = raw['accessToken'];
    final Object? expires = raw['accessExpiresAt'];
    if (name is! String ||
        uuid is! String ||
        refresh is! String ||
        access is! String ||
        expires is! String) {
      return null;
    }
    final DateTime? time = DateTime.tryParse(expires);
    if (time == null) return null;
    if (name.isEmpty || uuid.isEmpty || refresh.isEmpty || access.isEmpty) {
      return null;
    }
    return MinecraftAccount(
      name: name,
      uuid: uuid,
      refreshToken: refresh,
      accessToken: access,
      accessExpiresAt: time,
    );
  }
}
