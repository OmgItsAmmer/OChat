import 'user_model.dart';
import 'message_model.dart';

/// Conversation model representing a chat conversation between two users
/// This model helps organize messages and provides conversation metadata
class ConversationModel {
  /// Unique identifier for the conversation
  final String id;

  /// ID of the first participant in the conversation
  final String participant1Id;

  /// ID of the second participant in the conversation
  final String participant2Id;

  /// The most recent message in this conversation
  final MessageModel? lastMessage;

  /// Number of unread messages for the current user
  final int unreadCount;

  /// When this conversation was created
  final DateTime createdAt;

  /// When this conversation was last updated (last message time)
  final DateTime updatedAt;

  /// Whether this conversation is archived
  final bool isArchived;

  /// Whether notifications are muted for this conversation
  final bool isMuted;

  /// Optional: The other participant's user object
  final UserModel? otherParticipant;

  /// Constructor for ConversationModel
  const ConversationModel({
    required this.id,
    required this.participant1Id,
    required this.participant2Id,
    this.lastMessage,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
    this.isMuted = false,
    this.otherParticipant,
  });

  /// Create ConversationModel from JSON response
  /// This handles the conversion from our Rust backend JSON format
  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      participant1Id: json['participant1_id'] as String,
      participant2Id: json['participant2_id'] as String,
      lastMessage: json['last_message'] != null
          ? MessageModel.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isArchived: json['is_archived'] as bool? ?? false,
      isMuted: json['is_muted'] as bool? ?? false,
      otherParticipant: json['other_participant'] != null
          ? UserModel.fromJson(
              json['other_participant'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert ConversationModel to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participant1_id': participant1Id,
      'participant2_id': participant2Id,
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_archived': isArchived,
      'is_muted': isMuted,
    };
  }

  /// Create a copy of this conversation with some fields updated
  /// This follows the immutable data pattern for state management
  ConversationModel copyWith({
    String? id,
    String? participant1Id,
    String? participant2Id,
    MessageModel? lastMessage,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
    bool? isMuted,
    UserModel? otherParticipant,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      participant1Id: participant1Id ?? this.participant1Id,
      participant2Id: participant2Id ?? this.participant2Id,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
      isMuted: isMuted ?? this.isMuted,
      otherParticipant: otherParticipant ?? this.otherParticipant,
    );
  }

  /// Get the ID of the other participant in the conversation
  /// This helper method determines who the "other person" is based on current user
  String getOtherParticipantId(String currentUserId) {
    return participant1Id == currentUserId ? participant2Id : participant1Id;
  }

  /// Check if the conversation has unread messages
  bool get hasUnreadMessages => unreadCount > 0;

  /// Check if there are any messages in this conversation
  bool get hasMessages => lastMessage != null;

  /// Get display name for the conversation
  /// This uses the other participant's name or email as fallback
  String getDisplayName(String currentUserId) {
    if (otherParticipant != null) {
      return otherParticipant!.displayName;
    }
    // Fallback to participant ID if user object is not available
    return getOtherParticipantId(currentUserId);
  }

  /// Get the last message preview text
  /// This formats the last message content for display in conversation list
  String get lastMessagePreview {
    if (lastMessage == null) return 'No messages yet';

    switch (lastMessage!.type) {
      case MessageType.text:
        return lastMessage!.text;
      case MessageType.image:
        return '📷 Image';
      case MessageType.file:
        return '📎 ${lastMessage!.fileName ?? 'File'}';
      case MessageType.system:
        return lastMessage!.text;
      default:
        return 'No messages yet';
    }
  }

  /// Get formatted timestamp for the conversation list
  /// This shows when the last activity happened in this conversation
  String get formattedLastActivity {
    final lastActivityTime = lastMessage?.createdAt ?? updatedAt;
    final now = DateTime.now();
    final difference = now.difference(lastActivityTime);

    // If activity was today, show time
    if (difference.inDays == 0) {
      final hour = lastActivityTime.hour.toString().padLeft(2, '0');
      final minute = lastActivityTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    // If activity was this week, show day
    if (difference.inDays < 7) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[lastActivityTime.weekday - 1];
    }

    // For older activity, show date
    return '${lastActivityTime.day}/${lastActivityTime.month}/${lastActivityTime.year}';
  }

  /// Check if the other participant is currently online
  bool get isOtherParticipantOnline {
    return otherParticipant?.isOnline ?? false;
  }

  /// Get the other participant's profile picture URL
  String? getOtherParticipantProfilePicture(String currentUserId) {
    return otherParticipant?.profilePicture;
  }

  /// Mark conversation as read (reset unread count)
  ConversationModel markAsRead() {
    return copyWith(unreadCount: 0);
  }

  /// Archive or unarchive the conversation
  ConversationModel toggleArchived() {
    return copyWith(isArchived: !isArchived);
  }

  /// Mute or unmute the conversation
  ConversationModel toggleMuted() {
    return copyWith(isMuted: !isMuted);
  }

  /// Update the conversation with a new message
  /// This updates the last message and timestamp
  ConversationModel updateWithNewMessage(
      MessageModel message, String currentUserId) {
    // Increment unread count only if the message is from the other participant
    final newUnreadCount =
        message.senderId != currentUserId ? unreadCount + 1 : unreadCount;

    return copyWith(
      lastMessage: message,
      unreadCount: newUnreadCount,
      updatedAt: message.createdAt,
    );
  }

  @override
  String toString() {
    return 'ConversationModel(id: $id, participant1: $participant1Id, participant2: $participant2Id, unreadCount: $unreadCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConversationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
