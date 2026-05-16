// lib/models/event_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 🎫 Event Model for QR Virtual Identity System
/// Represents campus events with full Firestore integration
class EventModel {
  final String eventId;
  final String name;
  final String category;
  final String location;
  final String date;
  final String startTime;
  final String endTime;
  final int capacity;
  final int currentAttendees;
  final bool isPublic;
  final bool isActive;
  final String organizer;
  final List<String> attendees;
  final List<String> tags;
  final String? imageUrl;
  final String? description;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EventModel({
    required this.eventId,
    required this.name,
    required this.category,
    required this.location,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    required this.currentAttendees,
    required this.isPublic,
    required this.isActive,
    required this.organizer,
    this.attendees = const [],
    this.tags = const [],
    this.imageUrl,
    this.description,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  /// Create EventModel from Firestore DocumentSnapshot
  factory EventModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      eventId: data['event_id'] ?? doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      location: data['location'] ?? '',
      date: data['date'] ?? '',
      startTime: data['start_time'] ?? '',
      endTime: data['end_time'] ?? '',
      capacity: (data['capacity'] ?? 0) as int,
      currentAttendees: (data['current_attendees'] ?? 0) as int,
      isPublic: data['is_public'] ?? false,
      isActive: data['is_active'] ?? true,
      organizer: data['organizer'] ?? '',
      attendees:
          (data['attendees'] as List?)?.map((e) => e.toString()).toList() ?? [],
      tags: (data['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      imageUrl: data['image_url'],
      description: data['description'],
      status: data['status'],
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  /// Create EventModel from Map (for testing or manual data creation)
  factory EventModel.fromMap(Map<String, dynamic> data) {
    return EventModel(
      eventId: data['event_id'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      location: data['location'] ?? '',
      date: data['date'] ?? '',
      startTime: data['start_time'] ?? '',
      endTime: data['end_time'] ?? '',
      capacity: (data['capacity'] ?? 0) as int,
      currentAttendees: (data['current_attendees'] ?? 0) as int,
      isPublic: data['is_public'] ?? false,
      isActive: data['is_active'] ?? true,
      organizer: data['organizer'] ?? '',
      attendees:
          (data['attendees'] as List?)?.map((e) => e.toString()).toList() ?? [],
      tags: (data['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      imageUrl: data['image_url'],
      description: data['description'],
      status: data['status'],
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert EventModel to Map for Firestore operations
  Map<String, dynamic> toMap() {
    return {
      'event_id': eventId,
      'name': name,
      'category': category,
      'location': location,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'capacity': capacity,
      'current_attendees': currentAttendees,
      'is_public': isPublic,
      'is_active': isActive,
      'organizer': organizer,
      'attendees': attendees,
      'tags': tags,
      'image_url': imageUrl,
      'description': description,
      'status': status,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Check if event is full
  bool get isFull => currentAttendees >= capacity;

  /// Get available slots
  int get availableSlots => capacity - currentAttendees;

  /// Check if event date has passed
  bool get isPast {
    try {
      final eventDate = DateTime.parse(date);
      return eventDate.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  /// Check if event is today
  bool get isToday {
    try {
      final eventDate = DateTime.parse(date);
      final today = DateTime.now();
      return eventDate.year == today.year &&
          eventDate.month == today.month &&
          eventDate.day == today.day;
    } catch (e) {
      return false;
    }
  }

  /// Check if event is upcoming
  bool get isUpcoming {
    try {
      final eventDate = DateTime.parse(date);
      return eventDate.isAfter(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  /// Get formatted date string
  String get formattedDate {
    try {
      final eventDate = DateTime.parse(date);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      return '${weekdays[eventDate.weekday - 1]}, ${months[eventDate.month - 1]} ${eventDate.day}, ${eventDate.year}';
    } catch (e) {
      return date;
    }
  }

  /// Create copy with modified fields
  EventModel copyWith({
    String? eventId,
    String? name,
    String? category,
    String? location,
    String? date,
    String? startTime,
    String? endTime,
    int? capacity,
    int? currentAttendees,
    bool? isPublic,
    bool? isActive,
    String? organizer,
    List<String>? attendees,
    List<String>? tags,
    String? imageUrl,
    String? description,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      category: category ?? this.category,
      location: location ?? this.location,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      capacity: capacity ?? this.capacity,
      currentAttendees: currentAttendees ?? this.currentAttendees,
      isPublic: isPublic ?? this.isPublic,
      isActive: isActive ?? this.isActive,
      organizer: organizer ?? this.organizer,
      attendees: attendees ?? this.attendees,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'EventModel(eventId: $eventId, name: $name, category: $category, date: $date, capacity: $capacity, currentAttendees: $currentAttendees)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventModel && other.eventId == eventId;
  }

  @override
  int get hashCode => eventId.hashCode;
}

/// 🎫 User Event Ticket Model
/// Represents a user's ticket/registration for an event
class UserEventTicket {
  final String eventId;
  final String userId;
  final String eventName;
  final String eventDate;
  final String eventLocation;
  final String category;
  final String status; // active, cancelled, attended
  final DateTime joinedAt;
  final DateTime? cancelledAt;
  final DateTime? attendedAt;

  UserEventTicket({
    required this.eventId,
    required this.userId,
    required this.eventName,
    required this.eventDate,
    required this.eventLocation,
    required this.category,
    required this.status,
    required this.joinedAt,
    this.cancelledAt,
    this.attendedAt,
  });

  /// Create UserEventTicket from Firestore DocumentSnapshot
  factory UserEventTicket.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserEventTicket(
      eventId: data['event_id'] ?? doc.id,
      userId: data['user_id'] ?? '',
      eventName: data['event_name'] ?? '',
      eventDate: data['event_date'] ?? '',
      eventLocation: data['event_location'] ?? '',
      category: data['category'] ?? '',
      status: data['status'] ?? 'active',
      joinedAt: (data['joined_at'] as Timestamp).toDate(),
      cancelledAt: (data['cancelled_at'] as Timestamp?)?.toDate(),
      attendedAt: (data['attended_at'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Map for Firestore operations
  Map<String, dynamic> toMap() {
    return {
      'event_id': eventId,
      'user_id': userId,
      'event_name': eventName,
      'event_date': eventDate,
      'event_location': eventLocation,
      'category': category,
      'status': status,
      'joined_at': Timestamp.fromDate(joinedAt),
      'cancelled_at': cancelledAt != null
          ? Timestamp.fromDate(cancelledAt!)
          : null,
      'attended_at': attendedAt != null
          ? Timestamp.fromDate(attendedAt!)
          : null,
    };
  }

  /// Check if ticket is active
  bool get isActive => status == 'active';

  /// Check if ticket is cancelled
  bool get isCancelled => status == 'cancelled';

  /// Check if user attended the event
  bool get isAttended => status == 'attended';

  @override
  String toString() {
    return 'UserEventTicket(eventId: $eventId, userId: $userId, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserEventTicket &&
        other.eventId == eventId &&
        other.userId == userId;
  }

  @override
  int get hashCode => eventId.hashCode ^ userId.hashCode;
}
