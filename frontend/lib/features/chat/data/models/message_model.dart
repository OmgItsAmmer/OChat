import 'user_model.dart';

/// 📨 Message Model
///
/// Represents a single chat message with all its properties.
/// Includes message content, metadata, status tracking, and type information.
///
/// This model is used throughout the chat system for:
/// - Displaying messages in the UI
/// - Storing messages locally and on the server
/// - Tracking message status (sent, delivered, read)
/// - Supporting different message types (text, image, file, etc.)
class MessageModel {
  /// Unique identifier for the message
  final String id;

  /// ID of the conversation this message belongs to
  final String conversationId;

  /// ID of the user who sent this message
  final String senderId;

  /// Sender's display name (cached for performance)
  final String? senderName;

  /// Message content (text, file path, etc.)
  final String text;

  /// When the message was sent
  final DateTime timestamp;

  /// Current status of the message
  final MessageStatus status;

  /// Type of message (text, image, file, etc.)
  final MessageType type;

  /// ID of message this is replying to (if any)
  final String? replyToId;

  /// Message this is replying to (populated for UI)
  final MessageModel? replyToMessage;

  /// File URL for media messages
  final String? fileUrl;

  /// File name for file messages
  final String? fileName;

  /// File size in bytes
  final int? fileSize;

  /// MIME type for media files
  final String? mimeType;

  /// Thumbnail URL for images/videos
  final String? thumbnailUrl;

  /// Message reactions (emoji reactions from users)
  final Map<String, List<String>>? reactions;

  /// Whether this message has been edited
  final bool isEdited;

  /// When the message was last edited
  final DateTime? editedAt;

  /// When the message was created
  final DateTime? createdAt;

  /// Message metadata (location, mentions, etc.)
  final Map<String, dynamic>? metadata;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderName,
    required this.text,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.type = MessageType.text,
    this.replyToId,
    this.replyToMessage,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.thumbnailUrl,
    this.reactions,
    this.isEdited = false,
    this.editedAt,
    this.metadata,
    this.createdAt,
  });

  /// Create MessageModel from JSON (from database or API)
  ///
  /// This handles the conversion from database format to our model.
  /// Includes proper type checking and default values.
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      senderName: json['sender_name'] as String?,
      text: json['text'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: MessageStatus.fromString(json['status'] as String? ?? 'sent'),
      type: MessageType.fromString(json['type'] as String? ?? 'text'),
      replyToId: json['reply_to_id'] as String?,
      fileUrl: json['file_url'] as String?,
      fileName: json['file_name'] as String?,
      fileSize: json['file_size'] as int?,
      mimeType: json['mime_type'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      reactions: json['reactions'] != null
          ? Map<String, List<String>>.from(json['reactions'])
          : null,
      isEdited: json['is_edited'] as bool? ?? false,
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Convert MessageModel to JSON (for database or API)
  ///
  /// This prepares the model for storage or transmission.
  /// Excludes computed properties and formats dates properly.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_name': senderName,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'status': status.value,
      'type': type.value,
      'reply_to_id': replyToId,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'thumbnail_url': thumbnailUrl,
      'reactions': reactions,
      'is_edited': isEdited,
      'edited_at': editedAt?.toIso8601String(),
      'metadata': metadata,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Create a copy of this message with some properties changed
  ///
  /// Useful for updating message status, adding reactions, etc.
  /// This follows the immutable pattern common in Flutter/Dart.
  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? text,
    DateTime? timestamp,
    MessageStatus? status,
    MessageType? type,
    String? replyToId,
    MessageModel? replyToMessage,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? mimeType,
    String? thumbnailUrl,
    Map<String, List<String>>? reactions,
    bool? isEdited,
    DateTime? editedAt,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      type: type ?? this.type,
      replyToId: replyToId ?? this.replyToId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      reactions: reactions ?? this.reactions,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      );
  }

  /// Check if this message is from the current user
  ///
  /// Helper method to determine if the message should be displayed
  /// on the right side (own message) or left side (other's message).
  bool isFromUser(String currentUserId) {
    return senderId == currentUserId;
  }

  /// Check if this message is a reply to another message
  bool get isReply => replyToId != null;

  /// Check if this message has media content
  bool get hasMedia => type != MessageType.text && fileUrl != null;

  /// Check if this message has reactions
  bool get hasReactions => reactions != null && reactions!.isNotEmpty;

  /// Get formatted timestamp for display
  ///
  /// Returns a user-friendly time format for the message.
  /// This could be customized based on locale and preferences.
  String get formattedTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      // Today: show time only
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday';
    } else {
      // Older: show date
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  @override
  String toString() {
    return 'MessageModel(id: $id, text: $text, status: $status, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 📊 Message Status Enumeration
///
/// Tracks the delivery and read status of messages.
/// This provides real-time feedback to users about their message delivery.
enum MessageStatus {
  /// Message is being sent (temporary state)
  sending('sending'),

  /// Message has been sent to server
  sent('sent'),

  /// Message has been delivered to recipient's device
  delivered('delivered'),

  /// Message has been read by recipient
  read('read'),

  /// Message failed to send
  failed('failed');

  const MessageStatus(this.value);

  /// String representation for database storage
  final String value;

  /// Create MessageStatus from string value
  static MessageStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.sent;
    }
  }

  /// Get icon for this status
  ///
  /// Returns the appropriate icon to show next to the message
  /// based on its current status.
  String get icon {
    switch (this) {
      case MessageStatus.sending:
        return '⏳';
      case MessageStatus.sent:
        return '✓';
      case MessageStatus.delivered:
        return '✓✓';
      case MessageStatus.read:
        return '✓✓'; // Could be blue or different color
      case MessageStatus.failed:
        return '❌';
    }
  }
}

/// 📱 Message Type Enumeration
///
/// Defines the different types of messages supported by the chat system.
/// Each type may require different handling in the UI.
enum MessageType {
  /// Plain text message
  text('text'),

  /// Image message
  image('image'),

  /// Video message
  video('video'),

  /// Audio message or voice note
  audio('audio'),

  /// File attachment
  file('file'),

  /// Location sharing
  location('location'),

  /// System message (user joined, left, etc.)
  system('system');

  const MessageType(this.value);

  /// String representation for database storage
  final String value;

  /// Create MessageType from string value
  static MessageType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'audio':
        return MessageType.audio;
      case 'file':
        return MessageType.file;
      case 'location':
        return MessageType.location;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  /// Check if this message type requires file handling
  bool get requiresFile {
    return this != MessageType.text && this != MessageType.system;
  }

  /// Check if this message type is media (image, video, audio)
  bool get isMedia {
    return this == MessageType.image ||
        this == MessageType.video ||
        this == MessageType.audio;
  }
}
