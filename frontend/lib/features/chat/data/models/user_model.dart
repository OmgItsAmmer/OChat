/// User model representing a user in the OChat system
/// This model matches the user structure from our Rust backend
///
/// This class handles JSON serialization manually for better control
/// and to avoid additional dependencies
class UserModel {
  /// Unique identifier for the user (UUID from database)
  final String id;

  /// User's email address (used for authentication)
  final String email;

  /// User's display name
  final String? name;

  /// Optional profile picture URL
  final String? profilePicture;

  /// User's current online status
  final bool isOnline;

  /// Timestamp when user was last seen
  final DateTime? lastSeen;

  /// When this user account was created
  final DateTime createdAt;

  /// When user profile was last updated
  final DateTime updatedAt;

  /// Constructor for UserModel
  /// All required fields must be provided, optional fields default to null
  const UserModel({
    required this.id,
    required this.email,
    this.name,
    this.profilePicture,
    this.isOnline = false,
    this.lastSeen,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create UserModel from JSON response
  /// This is used when receiving user data from the API
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      profilePicture: json['profile_picture'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert UserModel to JSON for API requests
  /// This is used when sending user data to the backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profile_picture': profilePicture,
      'is_online': isOnline,
      'last_seen': lastSeen?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of this user with some fields updated
  /// This is useful for updating user state without modifying the original object
  /// This follows the immutable data pattern which is a best practice in Flutter
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? profilePicture,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      profilePicture: profilePicture ?? this.profilePicture,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get display name or fallback to email
  /// This is a helper method for UI components
  String get displayName => name ?? email.split('@').first;

  /// Check if user has a profile picture
  bool get hasProfilePicture =>
      profilePicture != null && profilePicture!.isNotEmpty;

  /// Get formatted last seen text
  String get lastSeenText {
    if (isOnline) return 'Online';
    if (lastSeen == null) return 'Last seen: Never';

    final now = DateTime.now();
    final difference = now.difference(lastSeen!);

    if (difference.inMinutes < 1) return 'Last seen: Just now';
    if (difference.inHours < 1)
      return 'Last seen: ${difference.inMinutes}m ago';
    if (difference.inDays < 1) return 'Last seen: ${difference.inHours}h ago';
    if (difference.inDays < 7) return 'Last seen: ${difference.inDays}d ago';

    return 'Last seen: ${lastSeen!.day}/${lastSeen!.month}/${lastSeen!.year}';
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name, isOnline: $isOnline)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
