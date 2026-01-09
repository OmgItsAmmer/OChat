/// 👤 User Model for Chat System
///
/// This model represents a user in the chat application.
/// It matches the UserResponse structure from the Rust backend.
///
/// FLUTTER CONCEPT: Models are immutable data classes that represent
/// the structure of data we receive from APIs or store locally.
///
/// Best Practice: Keep models simple and focused on data representation.
/// Business logic should be in controllers or services, not models.
class UserModel {
  /// Unique identifier for the user (Supabase user ID)
  final String id;

  /// User's email address
  final String email;

  /// Display name for the user (shown in UI)
  final String displayName;

  /// Optional avatar URL for profile picture
  final String? avatarUrl;

  /// Whether the user is currently online
  final bool isOnline;

  /// When the user was last seen (if not online)
  final DateTime? lastSeen;

  /// When the user account was created
  final DateTime createdAt;

  /// Constructor for UserModel
  ///
  /// DART CONCEPT: const constructor for immutable objects
  /// This helps with performance and memory usage
  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeen,
    required this.createdAt,
  });

  /// Create UserModel from JSON response (from Rust backend)
  ///
  /// This method converts the JSON response from our Rust API
  /// into a UserModel object that Flutter can use.
  ///
  /// BACKEND INTEGRATION: This matches the UserResponse struct from Rust
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Create UserModel from Supabase JSON response
  ///
  /// This method converts the JSON response directly from Supabase
  /// into a UserModel object that Flutter can use.
  ///
  /// DIRECT SUPABASE: This matches the users table schema
  factory UserModel.fromSupabaseJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['username'] as String? ?? json['email'].split('@')[0],
      avatarUrl: json['avatar_url'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert UserModel to JSON for API requests
  ///
  /// Used when we need to send user data to the backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'is_online': isOnline,
      'last_seen': lastSeen?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy of this user with some fields updated
  ///
  /// DART PATTERN: Immutable objects use copyWith for updates
  /// This is safer than modifying objects directly
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get initials for avatar display (when no avatar image)
  ///
  /// UTILITY METHOD: Extract first letters of display name
  /// Example: "John Doe" -> "JD"
  String get initials {
    final names = displayName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0][0].toUpperCase();
    } else {
      return email[0].toUpperCase();
    }
  }

  /// Get online status text for UI
  ///
  /// UTILITY METHOD: Convert online status to human-readable text
  String get statusText {
    if (isOnline) {
      return 'Online';
    } else if (lastSeen != null) {
      final now = DateTime.now();
      final difference = now.difference(lastSeen!);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } else {
      return 'Offline';
    }
  }

  /// Check if this user can be messaged
  ///
  /// BUSINESS LOGIC: Determine if we can start a conversation
  /// (For now, all users can be messaged)
  bool get canMessage => true;

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, displayName: $displayName, isOnline: $isOnline)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
