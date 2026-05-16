// lib/utils/seed_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:apid/utils/book_seeder.dart';

/// 🔹 Firestore Seeder for QR Virtual Identity System
/// Supports multi-type ScanPoint system: commerce, library, access, booking
class SeedService {
  static Future<void> rebuildFirestore({bool clearExisting = true}) async {
    final db = FirebaseFirestore.instance;

    print('\n🚀 Starting Firestore rebuild with ScanPoints system...');
    print('════════════════════════════════════════════════════════');

    // --- (1) Clear old collections if needed ---
    if (clearExisting) {
      print('\n🧹 Clearing previous data...');
      final collections = [
        'admins',
        'users',
        'scan_points', // NEW: replaces 'merchants'
        'interactions', // NEW: replaces 'transactions'
        'logs',
        'events',
        'user_tickets', // NEW: User event tickets
        'scanner_triggers', // For mobile scanner trigger feature
      ];

      int totalDeleted = 0;
      for (final name in collections) {
        final snapshot = await db.collection(name).get();
        final count = snapshot.docs.length;
        for (final doc in snapshot.docs) {
          await doc.reference.delete();
        }
        if (count > 0) {
          print('  ├─ Deleted $count documents from \'$name\'');
          totalDeleted += count;
        }
      }
      print(
        '✅ Cleared $totalDeleted total documents from ${collections.length} collections.\n',
      );
    } else {
      print('✅ Existing data will be preserved.\n');
    }

    // --- (2) Admin ---
    print('🌱 Seeding admin account...');
    final adminCred = await _createAuthUser(
      email: 'admin@apu.edu.my',
      password: '123456',
    );
    await db.collection('admins').doc(adminCred.user!.uid).set({
      'uid': adminCred.user!.uid,
      'admin_id': 'ADM001',
      'name': 'Kevin Lim',
      'email': 'admin@apu.edu.my',
      'role': 'admin',
      'privilege': ['manage_users', 'approve_merchants', 'view_logs'],
      'created_at': FieldValue.serverTimestamp(),
      'is_blacklisted': false, // Access control blacklist
      'access_permissions': [], // Whitelist for access points
    });
    print('✅ Created admin account: admin@apu.edu.my\n');

    // --- (3) Students (3 sample users) ---
    print('🌱 Seeding student accounts...');
    final students = [
      {'email': 'tp072580@mail.apu.edu.my', 'first': 'Po', 'last': 'Keat'},
      {'email': 'tp072581@mail.apu.edu.my', 'first': 'Lim', 'last': 'Han'},
      {'email': 'tp072582@mail.apu.edu.my', 'first': 'Wei', 'last': 'Jun'},
    ];
    for (final s in students) {
      final cred = await _createAuthUser(
        email: s['email']!,
        password: '123456',
      );
      await db.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'email': s['email'],
        'first_name': s['first'],
        'last_name': s['last'],
        'role': 'student',
        'qr_status': 'active',
        'total_spent': 0.0,
        'balance': 100.0, // Initial wallet balance
        'last_login': FieldValue.serverTimestamp(),
        'is_blacklisted': false, // Access control blacklist
        'access_permissions': [
          'SP003',
          'SP006',
        ], // Whitelist: Main Gate + Lecture Hall
      });
    }
    print('✅ Created ${students.length} student accounts.\n');

    // --- (4) ScanPoints (replaces merchants - supports 4 types) ---
    print('🌱 Seeding scan_points...');
    final scanPointsList = [
      {
        'scan_point_id': 'SP001',
        'name': 'Smokey Café',
        'type': 'commerce',
        'location': 'APU Campus Block B - Level 1',
        'description':
            'Campus cafeteria serving coffee, sandwiches, and snacks',
        'tags': ['food', 'beverage', 'cafe'],
      },
      {
        'scan_point_id': 'SP002',
        'name': 'Library Counter',
        'type': 'library',
        'location': 'APU Library - Ground Floor',
        'description': 'Book borrowing and return checkpoint',
        'tags': ['library', 'books', 'study'],
      },
      {
        'scan_point_id': 'SP003',
        'name': 'Main Gate Access',
        'type': 'access',
        'location': 'APU Main Entrance',
        'description': 'Campus entry and exit checkpoint for security',
        'tags': ['security', 'access', 'gate'],
      },
      {
        'scan_point_id': 'SP004',
        'name': 'Lab A Room Booking',
        'type': 'booking',
        'location': 'APU Block C - Level 3',
        'description': 'Computer lab booking and check-in point',
        'tags': ['lab', 'booking', 'computer'],
      },
      {
        'scan_point_id': 'SP005',
        'name': 'Campus Mart',
        'type': 'commerce',
        'location': 'APU Block A - Ground Floor',
        'description': 'Retail store for snacks, drinks, and stationery',
        'tags': ['retail', 'convenience', 'shopping'],
      },
      {
        'scan_point_id': 'SP006',
        'name': 'Lecture Hall B Attendance',
        'type': 'access',
        'location': 'APU Block D - Level 2',
        'description': 'Lecture attendance check-in point',
        'tags': ['attendance', 'lecture', 'access'],
      },
      {
        'scan_point_id': 'SP007',
        'name': 'Event Check-In Counter',
        'type': 'event',
        'location': 'APU Main Auditorium Entrance',
        'description': 'Event ticket verification and check-in point',
        'tags': ['event', 'check-in', 'ticket', 'verification'],
      },
    ];

    for (final sp in scanPointsList) {
      final scanPointId = sp['scan_point_id'] as String;
      final spType = sp['type'] as String;

      // Create owner auth user for commerce and booking types
      UserCredential? ownerCred;
      if (spType == 'commerce' || spType == 'booking') {
        ownerCred = await _createAuthUser(
          email: '${scanPointId.toLowerCase()}@apu.edu.my',
          password: '123456',
        );

        await db.collection('users').doc(ownerCred.user!.uid).set({
          'uid': ownerCred.user!.uid,
          'email': '${scanPointId.toLowerCase()}@apu.edu.my',
          'first_name': sp['name'],
          'last_name': '',
          'role': 'merchant', // All scan point owners use merchant role
          'qr_status': 'active',
          'scan_point_id': scanPointId,
          'total_spent': 0.0,
          'balance': 0.0,
          'last_login': FieldValue.serverTimestamp(),
          'is_blacklisted': false, // Access control blacklist
          'access_permissions': [], // Whitelist for access points
        });
      }

      // Create owner auth user for library type (SP002)
      if (spType == 'library') {
        ownerCred = await _createAuthUser(
          email: '${scanPointId.toLowerCase()}@apu.edu.my',
          password: '123456',
        );

        await db.collection('users').doc(ownerCred.user!.uid).set({
          'uid': ownerCred.user!.uid,
          'email': '${scanPointId.toLowerCase()}@apu.edu.my',
          'first_name': sp['name'], // "Library Counter"
          'last_name': '',
          'role': 'merchant',
          'qr_status': 'active',
          'scan_point_id': scanPointId,
          'total_spent': 0.0,
          'is_blacklisted': false, // Access control blacklist
          'access_permissions': [], // Whitelist for access points
          'balance': 0.0,
          'last_login': FieldValue.serverTimestamp(),
        });
      }

      // Create owner auth user for access type (SP003, SP006, etc.)
      if (spType == 'access') {
        ownerCred = await _createAuthUser(
          email: '${scanPointId.toLowerCase()}@apu.edu.my',
          password: '123456',
        );

        await db.collection('users').doc(ownerCred.user!.uid).set({
          'uid': ownerCred.user!.uid,
          'email': '${scanPointId.toLowerCase()}@apu.edu.my',
          'first_name':
              sp['name'], // "Main Gate Access" or "Lecture Hall B Attendance"
          'last_name': '',
          'role': 'merchant',
          'qr_status': 'active',
          'scan_point_id': scanPointId,
          'total_spent': 0.0,
          'is_blacklisted': false, // Access control blacklist
          'access_permissions': [], // Whitelist for access points
          'balance': 0.0,
          'last_login': FieldValue.serverTimestamp(),
        });
      }

      // Create owner auth user for booking type (SP004, etc.)
      if (spType == 'booking') {
        ownerCred = await _createAuthUser(
          email: '${scanPointId.toLowerCase()}@apu.edu.my',
          password: '123456',
        );

        await db.collection('users').doc(ownerCred.user!.uid).set({
          'uid': ownerCred.user!.uid,
          'email': '${scanPointId.toLowerCase()}@apu.edu.my',
          'first_name': sp['name'], // "Lab A Room Booking"
          'last_name': '',
          'role': 'merchant',
          'qr_status': 'active',
          'scan_point_id': scanPointId,
          'total_spent': 0.0,
          'is_blacklisted': false, // Access control blacklist
          'access_permissions': [], // Whitelist for access points
          'balance': 0.0,
          'last_login': FieldValue.serverTimestamp(),
        });
      }

      // Create owner auth user for event type (SP007, etc.)
      if (spType == 'event') {
        ownerCred = await _createAuthUser(
          email: '${scanPointId.toLowerCase()}@apu.edu.my',
          password: '123456',
        );

        await db.collection('users').doc(ownerCred.user!.uid).set({
          'uid': ownerCred.user!.uid,
          'email': '${scanPointId.toLowerCase()}@apu.edu.my',
          'first_name': sp['name'], // "Event Check-In Counter"
          'last_name': '',
          'role': 'merchant',
          'qr_status': 'active',
          'scan_point_id': scanPointId,
          'total_spent': 0.0,
          'is_blacklisted': false, // Access control blacklist
          'access_permissions': [], // Whitelist for access points
          'balance': 0.0,
          'last_login': FieldValue.serverTimestamp(),
        });
      }

      await db.collection('scan_points').doc(scanPointId).set({
        'scan_point_id': scanPointId,
        'name': sp['name'],
        'type': spType,
        'location': sp['location'],
        'description': sp['description'],
        'tags': sp['tags'],
        'qr_code': 'QR_$scanPointId',
        'active': true,
        'scan_count': 0,
        'interaction_count': 0,
        'revenue': spType == 'commerce' ? 0.0 : null, // Only for commerce
        'today_revenue': spType == 'commerce' ? 0.0 : null,
        'owner_uid': ownerCred?.user?.uid,
        'created_at': FieldValue.serverTimestamp(),
        'last_active': FieldValue.serverTimestamp(),
      });
      print(
        '  ├─ Created ScanPoint: $scanPointId (${sp['name']}) - Type: $spType',
      );
    }

    print('✅ Created ${scanPointsList.length} scan_points.\n');

    // --- (4B) Seed Commerce Products for SP001 -------------------------------
    print("🌱 Seeding default products for SP001 (Smokey Café)...");

    // Helper to get default images based on category
    String _getCategoryImage(String category) {
      switch (category) {
        case 'Rice':
          return 'https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=500&q=80'; // Nasi Lemak / Rice dish
        case 'Noodles':
          return 'https://images.unsplash.com/photo-1552611052-33e04de081de?auto=format&fit=crop&w=500&q=80'; // Fried Noodles
        case 'Drinks':
          return 'https://images.unsplash.com/photo-1544145945-f90425340c7e?auto=format&fit=crop&w=500&q=80'; // Iced Drink
        case 'Western':
          return 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?auto=format&fit=crop&w=500&q=80'; // Chicken Chop / Steak
        case 'Snacks':
          return 'https://images.unsplash.com/photo-1621939514649-28b12e81658b?auto=format&fit=crop&w=500&q=80'; // Pastry / Puff
        default:
          return 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=500&q=80'; // Generic Food
      }
    }

    final sp001Products = [
      {
        "product_id": "P001",
        "name": "Chicken Rice",
        "price": 7.00,
        "category": "Rice",
        "image": "https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?auto=format&fit=crop&w=500&q=80",
      },
      {
        "product_id": "P002",
        "name": "Nasi Lemak",
        "price": 6.50,
        "category": "Rice",
        "image": "https://images.unsplash.com/photo-1574484284008-be9d62827022?auto=format&fit=crop&w=500&q=80",
      },
      {
        "product_id": "P003",
        "name": "Milo Ice",
        "price": 2.50,
        "category": "Drinks",
        "image": "https://images.unsplash.com/photo-1544145945-f90425340c7e?auto=format&fit=crop&w=500&q=80",
      },
      {
        "product_id": "P004",
        "name": "Teh Tarik",
        "price": 2.20,
        "category": "Drinks",
        "image": "https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=500&q=80",
      },
      {
        "product_id": "P005",
        "name": "Fried Rice",
        "price": 8.00,
        "category": "Rice",
        "image": "https://images.unsplash.com/photo-1603133872878-684f10842619?auto=format&fit=crop&w=500&q=80",
      },
      {
        "product_id": "P006",
        "name": "Mee Goreng",
        "price": 7.50,
        "category": "Noodles",
        "image": "https://images.unsplash.com/photo-1612929633738-8fe44f7ec841?auto=format&fit=crop&w=500&q=80",
      },
      {
        "product_id": "P007",
        "name": "Chicken Chop",
        "price": 12.00,
        "category": "Western",
        "image": "https://images.unsplash.com/photo-1632778149955-e80f8ceca2e8?auto=format&fit=crop&w=500&q=80",
      },
      {
        "product_id": "P008",
        "name": "Curry Puff",
        "price": 1.80,
        "category": "Snacks",
        "image": "https://images.unsplash.com/photo-1621939514649-28b12e81658b?auto=format&fit=crop&w=500&q=80",
      },
      {
        "product_id": "P009",
        "name": "Iced Lemon Tea",
        "price": 2.80,
        "category": "Drinks",
        "image": "https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=500&q=80",
      },
      {
        "product_id": "P010",
        "name": "Fruit Salad",
        "price": 5.00,
        "category": "Snacks",
        "image": "https://images.unsplash.com/photo-1519996529931-28324d1a630e?auto=format&fit=crop&w=500&q=80",
      },
    ];

    for (final p in sp001Products) {
      // Use provided image or fallback to category default
      final imageUrl = (p['image'] as String?)?.isNotEmpty == true 
          ? p['image'] 
          : _getCategoryImage(p['category'] as String);

      await db
          .collection('scan_points')
          .doc('SP001')
          .collection('products')
          .doc(p['product_id'] as String)
          .set({
            'product_id': p['product_id'],
            'name': p['name'],
            'price': p['price'],
            'category': p['category'],
            'image': imageUrl, // FIX: Use real or default image
            'created_at': FieldValue.serverTimestamp(),
          });

      print("  ├─ Added product ${p['product_id']} – ${p['name']}");
    }

    print("✅ Finished seeding 10 products for SP001.\n");

    // --- (X) Seed Library Books --------------------------------------------------
    print("🌱 Seeding library books...");
    try {
      await BookSeeder.seedBooks();
      print("✅ Library books seeded.\n");
    } catch (e) {
      print("❌ Failed to seed library books: $e\n");
    }

    // --- (5) Interactions (replaces transactions - multi-type support) ---
    print('🌱 Seeding interactions...');
    final now = DateTime.now();
    final interactionsData = [
      // 1. Library - Borrow ✅
      {
        'interaction_id': 'INT001',
        'user_email': 'tp072580@mail.apu.edu.my',
        'scan_point_id': 'SP002',
        'type': 'borrow',
        'status': 'success',
        'remarks': 'Borrowed book: Data Security Fundamentals',
        'book_title': 'Data Security Fundamentals',
        'book_id': 'BK001',
        'due_date': now.add(const Duration(days: 14)),
        'timestamp': now.subtract(const Duration(days: 3)),
      },

      // 2. Library - Return ✅
      {
        'interaction_id': 'INT002',
        'user_email': 'tp072581@mail.apu.edu.my',
        'scan_point_id': 'SP002',
        'type': 'return',
        'status': 'success',
        'remarks': 'Returned book: Clean Code',
        'book_title': 'Clean Code',
        'book_id': 'BK002',
        'timestamp': now.subtract(const Duration(days: 1)),
      },

      // 3. Gate - Entry Success ✅
      {
        'interaction_id': 'INT003',
        'user_email': 'tp072582@mail.apu.edu.my',
        'scan_point_id': 'SP003',
        'type': 'entry',
        'status': 'success',
        'remarks': 'Campus entry approved',
        'access_point': 'Main Gate',
        'timestamp': now.subtract(const Duration(hours: 8)),
      },

      // 4. Gate - Denied ✅
      {
        'interaction_id': 'INT004',
        'user_email': 'tp072582@mail.apu.edu.my',
        'scan_point_id': 'SP003',
        'type': 'entry',
        'status': 'denied',
        'remarks': 'Access denied: QR code expired',
        'access_point': 'Main Gate',
        'timestamp': now.subtract(const Duration(hours: 12)),
      },

      // 5. Café - Purchase ✅
      {
        'interaction_id': 'INT005',
        'user_email': 'tp072580@mail.apu.edu.my',
        'scan_point_id': 'SP001',
        'type': 'purchase',
        'status': 'success',
        'remarks': 'Iced Latte + Sandwich',
        'amount': 8.90,
        'currency': 'MYR',
        'payment_method': 'QR Pay',
        'receipt_id': 'RCP001',
        'timestamp': now.subtract(const Duration(days: 1)),
      },

      // 6. Café - Refund ✅
      {
        'interaction_id': 'INT006',
        'user_email': 'tp072581@mail.apu.edu.my',
        'scan_point_id': 'SP001',
        'type': 'refund',
        'status': 'success',
        'remarks': 'Refunded: Wrong order',
        'amount': -12.50,
        'currency': 'MYR',
        'payment_method': 'QR Pay',
        'receipt_id': 'RCP002',
        'timestamp': now.subtract(const Duration(hours: 6)),
      },

      // Additional interactions for better data
      // 7. Campus Mart - Purchase
      {
        'interaction_id': 'INT007',
        'user_email': 'tp072581@mail.apu.edu.my',
        'scan_point_id': 'SP005',
        'type': 'purchase',
        'status': 'success',
        'remarks': 'Snacks and drinks',
        'amount': 12.90,
        'currency': 'MYR',
        'payment_method': 'Touch n Go',
        'receipt_id': 'RCP003',
        'timestamp': now.subtract(const Duration(days: 2)),
      },

      // 8. Lecture Hall - Attendance
      {
        'interaction_id': 'INT008',
        'user_email': 'tp072580@mail.apu.edu.my',
        'scan_point_id': 'SP006',
        'type': 'attendance',
        'status': 'success',
        'remarks': 'Attended lecture: Mobile App Development',
        'class_code': 'CT038-3-1',
        'class_name': 'Mobile Application Development',
        'timestamp': now.subtract(const Duration(hours: 2)),
      },

      // 9. Lab Booking - Check In
      {
        'interaction_id': 'INT009',
        'user_email': 'tp072581@mail.apu.edu.my',
        'scan_point_id': 'SP004',
        'type': 'booking',
        'status': 'success',
        'remarks': 'Lab session check-in',
        'resource_name': 'Computer Lab A',
        'booking_id': 'BOOK001',
        'slot_start': now.subtract(const Duration(hours: 1)),
        'slot_end': now.add(const Duration(hours: 1)),
        'timestamp': now.subtract(const Duration(hours: 1)),
      },

      // 10. Café - Today's purchase
      {
        'interaction_id': 'INT010',
        'user_email': 'tp072582@mail.apu.edu.my',
        'scan_point_id': 'SP001',
        'type': 'purchase',
        'status': 'success',
        'remarks': 'Morning coffee',
        'amount': 5.50,
        'currency': 'MYR',
        'payment_method': 'QR Pay',
        'receipt_id': 'RCP004',
        'timestamp': now.subtract(const Duration(hours: 4)),
      },

      // 11. Campus Mart - Today's purchase
      {
        'interaction_id': 'INT011',
        'user_email': 'tp072580@mail.apu.edu.my',
        'scan_point_id': 'SP005',
        'type': 'purchase',
        'status': 'success',
        'remarks': 'Stationery supplies',
        'amount': 7.00,
        'currency': 'MYR',
        'payment_method': 'Cash',
        'receipt_id': 'RCP005',
        'timestamp': now.subtract(const Duration(hours: 5)),
      },

      // 12. Library - Another borrow
      {
        'interaction_id': 'INT012',
        'user_email': 'tp072582@mail.apu.edu.my',
        'scan_point_id': 'SP002',
        'type': 'borrow',
        'status': 'success',
        'remarks': 'Borrowed book: Introduction to Algorithms',
        'book_title': 'Introduction to Algorithms',
        'book_id': 'BK003',
        'due_date': now.add(const Duration(days: 14)),
        'timestamp': now.subtract(const Duration(hours: 10)),
      },

      // 13. Gate - Exit
      {
        'interaction_id': 'INT013',
        'user_email': 'tp072580@mail.apu.edu.my',
        'scan_point_id': 'SP003',
        'type': 'exit',
        'status': 'success',
        'remarks': 'Campus exit logged',
        'access_point': 'Main Gate',
        'timestamp': now.subtract(const Duration(hours: 1)),
      },

      // 14. Café - Pending payment
      {
        'interaction_id': 'INT014',
        'user_email': 'tp072582@mail.apu.edu.my',
        'scan_point_id': 'SP001',
        'type': 'purchase',
        'status': 'pending',
        'remarks': 'Lunch combo - payment pending',
        'amount': 15.00,
        'currency': 'MYR',
        'payment_method': 'QR Pay',
        'receipt_id': 'RCP006',
        'timestamp': now.subtract(const Duration(hours: 3)),
      },
    ];

    for (final interaction in interactionsData) {
      final interactionId = interaction['interaction_id'] as String;
      final userEmail = interaction['user_email'] as String;
      final scanPointId = interaction['scan_point_id'] as String;
      final type = interaction['type'] as String;
      final timestamp = interaction['timestamp'] as DateTime;

      final userQuery = await db
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();
      if (userQuery.docs.isEmpty) continue;

      final uid = userQuery.docs.first.id;

      // Get scan point name
      final spDoc = await db.collection('scan_points').doc(scanPointId).get();
      final scanPointName = spDoc.data()?['name'] ?? 'Unknown';

      // Base interaction data
      final interactionData = {
        'interaction_id': interactionId,
        'user_email': userEmail,
        'user_id': uid,
        'scan_point_id': scanPointId,
        'scan_point_name': scanPointName,
        'type': type,
        'status': interaction['status'],
        'remarks': interaction['remarks'],
        'timestamp': Timestamp.fromDate(timestamp),
        'created_at': FieldValue.serverTimestamp(),
      };

      // Add optional fields based on interaction type
      // Commerce fields (purchase, refund)
      if (interaction.containsKey('amount')) {
        interactionData['amount'] = interaction['amount'];
      }
      if (interaction.containsKey('currency')) {
        interactionData['currency'] = interaction['currency'];
      }
      if (interaction.containsKey('payment_method')) {
        interactionData['payment_method'] = interaction['payment_method'];
      }
      if (interaction.containsKey('receipt_id')) {
        interactionData['receipt_id'] = interaction['receipt_id'];
      }

      // Library fields (borrow, return)
      if (interaction.containsKey('book_title')) {
        interactionData['book_title'] = interaction['book_title'];
      }
      if (interaction.containsKey('book_id')) {
        interactionData['book_id'] = interaction['book_id'];
      }
      if (interaction.containsKey('due_date')) {
        interactionData['due_date'] = Timestamp.fromDate(
          interaction['due_date'] as DateTime,
        );
      }

      // Access fields (entry, exit, attendance)
      if (interaction.containsKey('access_point')) {
        interactionData['access_point'] = interaction['access_point'];
      }
      if (interaction.containsKey('class_code')) {
        interactionData['class_code'] = interaction['class_code'];
      }
      if (interaction.containsKey('class_name')) {
        interactionData['class_name'] = interaction['class_name'];
      }

      // Booking fields
      if (interaction.containsKey('resource_name')) {
        interactionData['resource_name'] = interaction['resource_name'];
      }
      if (interaction.containsKey('booking_id')) {
        interactionData['booking_id'] = interaction['booking_id'];
      }
      if (interaction.containsKey('slot_start')) {
        interactionData['slot_start'] = Timestamp.fromDate(
          interaction['slot_start'] as DateTime,
        );
      }
      if (interaction.containsKey('slot_end')) {
        interactionData['slot_end'] = Timestamp.fromDate(
          interaction['slot_end'] as DateTime,
        );
      }

      await db
          .collection('interactions')
          .doc(interactionId)
          .set(interactionData);

      print(
        '  ├─ Created Interaction: $interactionId (${interaction['type']}) - ${interaction['remarks']}',
      );
    }

    print('✅ Created ${interactionsData.length} interactions.\n');

    // --- (6) Generate logs from interactions ---
    print('🌱 Generating interaction logs...');
    final logsRef = db.collection('logs');
    for (final interaction in interactionsData) {
      await logsRef.add({
        'action': interaction['type'],
        'scan_point_id': interaction['scan_point_id'], // ✅ Added for efficient filtering
        'detail':
            'User ${interaction['user_email']} performed ${interaction['type']} at ${interaction['scan_point_id']} - ${interaction['remarks']}',
        'timestamp': FieldValue.serverTimestamp(),
        'by': 'SeedService',
      });
    }
    print('✅ Created ${interactionsData.length} log entries.\n');

    // --- (7) Aggregate statistics for ScanPoints ---
    print('📊 Calculating ScanPoint analytics...');
    final scanPointsSnap = await db.collection('scan_points').get();

    for (final sp in scanPointsSnap.docs) {
      final scanPointId = sp['scan_point_id'];
      final spType = sp['type'];

      final interactionsSnap = await db
          .collection('interactions')
          .where('scan_point_id', isEqualTo: scanPointId)
          .where('status', isEqualTo: 'success')
          .get();

      final interactionCount = interactionsSnap.docs.length;
      final scanCount = interactionCount * 2; // Assume 2 scans per interaction

      // Calculate revenue for commerce type (purchase and refund)
      double? revenue;
      double? todayRevenue;
      if (spType == 'commerce') {
        // Get all purchase and refund interactions
        revenue = interactionsSnap.docs
            .where((i) => i['type'] == 'purchase' || i['type'] == 'refund')
            .fold<double>(
              0.0,
              (total, i) => total + ((i['amount'] ?? 0) as num).toDouble(),
            );

        // Calculate today's revenue
        todayRevenue = interactionsSnap.docs
            .where((i) {
              if (i['type'] != 'purchase' && i['type'] != 'refund') {
                return false;
              }
              final ts = i['timestamp'];
              if (ts is Timestamp) {
                final d = ts.toDate();
                return d.year == now.year &&
                    d.month == now.month &&
                    d.day == now.day;
              }
              return false;
            })
            .fold<double>(
              0.0,
              (sum, i) => sum + ((i['amount'] ?? 0) as num).toDouble(),
            );
      }

      // Update scan point statistics
      final updateData = <String, dynamic>{
        'interaction_count': interactionCount,
        'scan_count': scanCount,
        'last_active': FieldValue.serverTimestamp(),
      };

      if (spType == 'commerce' && revenue != null) {
        updateData['revenue'] = revenue;
        updateData['today_revenue'] = todayRevenue ?? 0.0;
        updateData['average_transaction'] = interactionCount > 0
            ? (revenue / interactionCount)
            : 0.0;
      }

      await db.collection('scan_points').doc(scanPointId).update(updateData);
    }
    print(
      '✅ Updated statistics for ${scanPointsSnap.docs.length} scan_points.\n',
    );

    // --- (8) Update student statistics ---
    print('� Calculating student statistics...');
    final userSnap = await db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();

    for (final user in userSnap.docs) {
      final email = user['email'];

      // Calculate total spending from purchase interactions (minus refunds)
      final purchaseInteractions = await db
          .collection('interactions')
          .where('user_email', isEqualTo: email)
          .where('type', isEqualTo: 'purchase')
          .where('status', isEqualTo: 'success')
          .get();

      final refundInteractions = await db
          .collection('interactions')
          .where('user_email', isEqualTo: email)
          .where('type', isEqualTo: 'refund')
          .where('status', isEqualTo: 'success')
          .get();

      final totalPurchased = purchaseInteractions.docs.fold<double>(
        0.0,
        (sum, i) => sum + ((i['amount'] ?? 0) as num).toDouble(),
      );

      final totalRefunded = refundInteractions.docs.fold<double>(
        0.0,
        (sum, i) => sum + ((i['amount'] ?? 0) as num).abs().toDouble(),
      );

      final totalSpent = totalPurchased - totalRefunded;

      // Count total interactions
      final allInteractions = await db
          .collection('interactions')
          .where('user_email', isEqualTo: email)
          .get();

      await db.collection('users').doc(user.id).update({
        'total_spent': totalSpent,
        'total_interactions': allInteractions.docs.length,
      });
    }
    print('✅ Updated statistics for ${userSnap.docs.length} students.\n');

    // --- (9) Seed Public Events for Guest Mode ---
    print('🌱 Seeding public events...');
    final eventsData = [
      {
        'event_id': 'EVT001',
        'name': 'APU Tech Talk 2025: AI & Future of Work',
        'description':
            'Join us for an inspiring discussion about artificial intelligence and its impact on future careers. Industry experts will share insights and predictions.',
        'category': 'seminar',
        'location': 'APU Auditorium - Block A',
        'date': '2025-11-20',
        'start_time': '14:00',
        'end_time': '17:00',
        'image_url':
            'https://via.placeholder.com/400x200/5E35B1/FFFFFF?text=Tech+Talk',
        'capacity': 200,
        'current_attendees': 45,
        'is_public': true,
        'is_active': true,
        'organizer': 'Event Check-In Counter', // Updated for SP007
        'tags': ['technology', 'AI', 'career', 'seminar'],
      },
      {
        'event_id': 'EVT002',
        'name': 'Campus Open Day 2025',
        'description':
            'Explore APU campus! Tour our facilities, meet faculty, attend demo sessions, and learn about our programs. Perfect for prospective students and parents.',
        'category': 'open_house',
        'location': 'APU Main Campus',
        'date': '2025-12-05',
        'start_time': '09:00',
        'end_time': '15:00',
        'image_url':
            'https://via.placeholder.com/400x200/00897B/FFFFFF?text=Open+Day',
        'capacity': 500,
        'current_attendees': 127,
        'is_public': true,
        'is_active': true,
        'organizer': 'APU Admissions Office',
        'tags': ['campus', 'open_house', 'tour', 'prospective_students'],
      },
      {
        'event_id': 'EVT003',
        'name': 'Mobile App Development Workshop',
        'description':
            'Hands-on Flutter workshop! Learn to build your first mobile app from scratch. Suitable for beginners. Bring your laptop.',
        'category': 'workshop',
        'location': 'APU Computer Lab C - Level 3',
        'date': '2025-11-15',
        'start_time': '10:00',
        'end_time': '14:00',
        'image_url':
            'https://via.placeholder.com/400x200/1976D2/FFFFFF?text=Workshop',
        'capacity': 50,
        'current_attendees': 38,
        'is_public': true,
        'is_active': true,
        'organizer': 'APU Mobile Dev Club',
        'tags': ['workshop', 'flutter', 'mobile', 'coding'],
      },
      {
        'event_id': 'EVT004',
        'name': 'Annual Career Fair 2025',
        'description':
            'Meet top employers! Network with recruiters, submit resumes, and explore internship and job opportunities. Dress professionally.',
        'category': 'career_fair',
        'location': 'APU Sports Complex',
        'date': '2025-12-15',
        'start_time': '09:00',
        'end_time': '17:00',
        'image_url':
            'https://via.placeholder.com/400x200/F57C00/FFFFFF?text=Career+Fair',
        'capacity': 1000,
        'current_attendees': 312,
        'is_public': true,
        'is_active': true,
        'organizer': 'APU Career Services',
        'tags': ['career', 'jobs', 'internship', 'networking'],
      },
      {
        'event_id': 'EVT005',
        'name': 'Cybersecurity Challenge 2025',
        'description':
            'Test your hacking skills! Compete in Capture The Flag (CTF) challenges. Prizes for top 3 teams. Form teams of 3-5 members.',
        'category': 'competition',
        'location': 'APU Lab D - Block C',
        'date': '2025-11-22',
        'start_time': '13:00',
        'end_time': '19:00',
        'image_url':
            'https://via.placeholder.com/400x200/C62828/FFFFFF?text=CTF',
        'capacity': 75,
        'current_attendees': 54,
        'is_public': true,
        'is_active': true,
        'organizer': 'APU CyberSec Club',
        'tags': ['cybersecurity', 'CTF', 'competition', 'hacking'],
      },
      {
        'event_id': 'EVT006',
        'name': 'Alumni Networking Night',
        'description':
            'Connect with APU alumni working in leading tech companies. Share experiences, get career advice, and expand your professional network.',
        'category': 'networking',
        'location': 'APU Conference Hall',
        'date': '2025-11-28',
        'start_time': '18:00',
        'end_time': '21:00',
        'image_url':
            'https://via.placeholder.com/400x200/7B1FA2/FFFFFF?text=Networking',
        'capacity': 150,
        'current_attendees': 67,
        'is_public': true,
        'is_active': true,
        'organizer': 'APU Alumni Association',
        'tags': ['networking', 'alumni', 'career', 'mentorship'],
      },
    ];

    for (final event in eventsData) {
      await db.collection('events').doc(event['event_id'] as String).set({
        'event_id': event['event_id'],
        'name': event['name'],
        'description': event['description'],
        'category': event['category'],
        'location': event['location'],
        'date': event['date'],
        'start_time': event['start_time'],
        'end_time': event['end_time'],
        'image_url': event['image_url'],
        'capacity': event['capacity'],
        'current_attendees': event['current_attendees'],
        'is_public': event['is_public'],
        'is_active': event['is_active'],
        'organizer': event['organizer'],
        'tags': event['tags'],
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      print('  ├─ Created Event: ${event['event_id']} (${event['name']})');
    }
    print('✅ Created ${eventsData.length} public events.\n');

    // --- (10) Seed User Tickets (sample event registrations) ---
    print('🎫 Seeding user event tickets...');
    final userTicketsData = [
      {
        'ticket_id': 'TKT001',
        'user_email': 'tp072580@mail.apu.edu.my',
        'event_id': 'EVT003',
        'event_name': 'Mobile App Development Workshop',
        'event_date': '2025-11-15',
        'event_location': 'APU Computer Lab C - Level 3',
        'category': 'workshop',
        'status': 'active',
        'joined_at': now.subtract(const Duration(days: 2)),
      },
      {
        'ticket_id': 'TKT002',
        'user_email': 'tp072581@mail.apu.edu.my',
        'event_id': 'EVT001',
        'event_name': 'APU Tech Talk 2025: AI & Future of Work',
        'event_date': '2025-11-20',
        'event_location': 'APU Auditorium - Block A',
        'category': 'seminar',
        'status': 'active',
        'joined_at': now.subtract(const Duration(days: 1)),
      },
      {
        'ticket_id': 'TKT003',
        'user_email': 'tp072582@mail.apu.edu.my',
        'event_id': 'EVT005',
        'event_name': 'Cybersecurity Challenge 2025',
        'event_date': '2025-11-22',
        'event_location': 'APU Lab D - Block C',
        'category': 'competition',
        'status': 'active',
        'joined_at': now.subtract(const Duration(hours: 12)),
      },
      {
        'ticket_id': 'TKT004',
        'user_email': 'tp072580@mail.apu.edu.my',
        'event_id': 'EVT006',
        'event_name': 'Alumni Networking Night',
        'event_date': '2025-11-28',
        'event_location': 'APU Conference Hall',
        'category': 'networking',
        'status': 'active',
        'joined_at': now.subtract(const Duration(hours: 6)),
      },
      {
        'ticket_id': 'TKT005',
        'user_email': 'tp072581@mail.apu.edu.my',
        'event_id': 'EVT004',
        'event_name': 'Annual Career Fair 2025',
        'event_date': '2025-12-15',
        'event_location': 'APU Sports Complex',
        'category': 'career_fair',
        'status': 'cancelled', // Example of cancelled ticket
        'joined_at': now.subtract(const Duration(days: 3)),
        'cancelled_at': now.subtract(const Duration(hours: 24)),
      },
    ];

    for (final ticket in userTicketsData) {
      final userEmail = ticket['user_email'] as String;
      final eventId = ticket['event_id'] as String;
      final joinedAt = ticket['joined_at'] as DateTime;
      final cancelledAt = ticket['cancelled_at'] as DateTime?;

      // Get user UID
      final userQuery = await db
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();
      if (userQuery.docs.isEmpty) continue;

      final uid = userQuery.docs.first.id;

      // Create ticket data
      final ticketData = {
        'ticket_id': ticket['ticket_id'],
        'user_id': uid,
        'user_email': userEmail,
        'event_id': eventId,
        'event_name': ticket['event_name'],
        'event_date': ticket['event_date'],
        'event_location': ticket['event_location'],
        'category': ticket['category'],
        'status': ticket['status'],
        'joined_at': Timestamp.fromDate(joinedAt),
        'created_at': FieldValue.serverTimestamp(),
      };

      if (cancelledAt != null) {
        ticketData['cancelled_at'] = Timestamp.fromDate(cancelledAt);
      }

      await db
          .collection('user_tickets')
          .doc(ticket['ticket_id'] as String)
          .set(ticketData);

      // Update event attendee count and add UID to attendees array
      if (ticket['status'] == 'active') {
        await db.collection('events').doc(eventId).update({
          'current_attendees': FieldValue.increment(1),
          'attendees': FieldValue.arrayUnion([uid]),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      print(
        '  ├─ Created Ticket: ${ticket['ticket_id']} for $userEmail (${ticket['status']})',
      );
    }

    print('✅ Created ${userTicketsData.length} user tickets.\n');

    // --- (11) Update user statistics with event data ---
    print('👥 Updating user event statistics...');
    final userSnap2 = await db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();

    for (final user in userSnap2.docs) {
      final uid = user.id;
      final email = user['email'];

      // Count user tickets
      final userTicketsSnap = await db
          .collection('user_tickets')
          .where('user_id', isEqualTo: uid)
          .get();

      final totalTickets = userTicketsSnap.docs.length;
      final activeTickets = userTicketsSnap.docs
          .where((doc) => (doc.data() as Map)['status'] == 'active')
          .length;
      final cancelledTickets = userTicketsSnap.docs
          .where((doc) => (doc.data() as Map)['status'] == 'cancelled')
          .length;

      await db.collection('users').doc(uid).update({
        'events_joined': totalTickets,
        'active_tickets': activeTickets,
        'cancelled_tickets': cancelledTickets,
      });

      print('  ├─ Updated stats for $email: $totalTickets events joined');
    }
    print('✅ Updated event statistics for ${userSnap2.docs.length} users.\n');

    // --- (12) Analytics validation for commerce scan points ---
    print('🔍 Commerce ScanPoint Revenue Validation:');
    print('────────────────────────────────────────');
    double totalRevenue = 0.0;

    for (final sp in scanPointsSnap.docs) {
      if (sp['type'] != 'commerce') continue;

      final savedRevenue = (sp['revenue'] ?? 0.0) as num;
      final scanPointId = sp['scan_point_id'];

      // Get purchases and refunds for this scan point
      final purchaseSnap = await db
          .collection('interactions')
          .where('scan_point_id', isEqualTo: scanPointId)
          .where('type', isEqualTo: 'purchase')
          .where('status', isEqualTo: 'success')
          .get();

      final refundSnap = await db
          .collection('interactions')
          .where('scan_point_id', isEqualTo: scanPointId)
          .where('type', isEqualTo: 'refund')
          .where('status', isEqualTo: 'success')
          .get();

      final purchases = purchaseSnap.docs.fold<double>(
        0.0,
        (sum, i) => sum + ((i['amount'] ?? 0) as num).toDouble(),
      );

      final refunds = refundSnap.docs.fold<double>(
        0.0,
        (sum, i) => sum + ((i['amount'] ?? 0) as num).abs().toDouble(),
      );

      final calcRevenue = purchases - refunds;

      totalRevenue += calcRevenue;

      final result = (savedRevenue.toDouble() - calcRevenue).abs() < 0.001
          ? '✅'
          : '⚠️';
      print(
        '  $result ScanPoint $scanPointId → stored: RM${savedRevenue.toStringAsFixed(2)} / calculated: RM${calcRevenue.toStringAsFixed(2)}',
      );
    }
    print('────────────────────────────────────────\n');

    // --- (13) Console Summary ---
    final scanPointsCount = scanPointsSnap.docs.length;
    final usersCount = (await db.collection('users').get()).docs.length;
    final interactionsCount =
        (await db.collection('interactions').get()).docs.length;
    final eventsCount = eventsData.length;
    final userTicketsCount = userTicketsData.length;

    // Count interactions by type
    final purchaseCount = interactionsData
        .where((i) => i['type'] == 'purchase')
        .length;
    final refundCount = interactionsData
        .where((i) => i['type'] == 'refund')
        .length;
    final borrowCount = interactionsData
        .where((i) => i['type'] == 'borrow')
        .length;
    final returnCount = interactionsData
        .where((i) => i['type'] == 'return')
        .length;
    final entryCount = interactionsData
        .where((i) => i['type'] == 'entry')
        .length;
    final exitCount = interactionsData.where((i) => i['type'] == 'exit').length;
    final attendanceCount = interactionsData
        .where((i) => i['type'] == 'attendance')
        .length;
    final bookingCount = interactionsData
        .where((i) => i['type'] == 'booking')
        .length;

    print('📊 Firestore Seeding Summary');
    print('════════════════════════════════════════════════════════');
    print('ScanPoints     : $scanPointsCount');
    print(
      '  ├─ Commerce  : ${scanPointsSnap.docs.where((sp) => sp['type'] == 'commerce').length}',
    );
    print(
      '  ├─ Library   : ${scanPointsSnap.docs.where((sp) => sp['type'] == 'library').length}',
    );
    print(
      '  ├─ Access    : ${scanPointsSnap.docs.where((sp) => sp['type'] == 'access').length}',
    );
    print(
      '  └─ Booking   : ${scanPointsSnap.docs.where((sp) => sp['type'] == 'booking').length}',
    );
    print('');
    print('Users (Total)  : $usersCount');
    print('');
    print('Interactions   : $interactionsCount');
    print('  ├─ Purchase  : $purchaseCount');
    print('  ├─ Refund    : $refundCount');
    print('  ├─ Borrow    : $borrowCount');
    print('  ├─ Return    : $returnCount');
    print('  ├─ Entry     : $entryCount');
    print('  ├─ Exit      : $exitCount');
    print('  ├─ Attendance: $attendanceCount');
    print('  └─ Booking   : $bookingCount');
    print('');
    print('Events         : $eventsCount');
    print('User Tickets   : $userTicketsCount');
    print('');
    print('Total Revenue  : RM ${totalRevenue.toStringAsFixed(2)}');
    print('════════════════════════════════════════════════════════');
    print('✅ Firestore rebuild complete!\n');
  }

  /// 🔐 Helper: Create or Sign in Auth User
  static Future<UserCredential> _createAuthUser({
    required String email,
    required String password,
  }) async {
    final auth = FirebaseAuth.instance;
    try {
      final user = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('👤 Created Auth user: $email');
      return user;
    } catch (e) {
      print('⚠️ $email already exists, signing in instead.');
      return await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    }
  }

  static Future<void> fixProductCategories() async {
    final db = FirebaseFirestore.instance;
    print('\n🔧 Starting Category Migration...');

    final updates = {
      "P001": "Rice", // Chicken Rice
      "P002": "Rice", // Nasi Lemak
      "P003": "Drinks", // Milo Ice
      "P004": "Drinks", // Teh Tarik
      "P005": "Rice", // Fried Rice
      "P006": "Noodles", // Mee Goreng
      "P007": "Western", // Chicken Chop
      "P008": "Snacks", // Curry Puff
      "P009": "Drinks", // Iced Lemon Tea
      "P010": "Snacks", // Fruit Salad
    };

    int count = 0;
    for (final entry in updates.entries) {
      try {
        final docRef = db
            .collection('scan_points')
            .doc('SP001')
            .collection('products')
            .doc(entry.key);

        final doc = await docRef.get();
        if (doc.exists) {
          await docRef.update({'category': entry.value});
          print('  ✅ [${entry.key}] Updated category to "${entry.value}"');
          count++;
        } else {
          print('  ⚠️ [${entry.key}] Product not found, skipping.');
        }
      } catch (e) {
        print('  ❌ [${entry.key}] Error: $e');
      }
    }
    print('✨ Migration Complete. Updated $count products.\n');
  }
  /// 🖼️ Surgical Update: Only update product images (No Auth changes)
  static Future<void> updateProductImagesOnly() async {
    final db = FirebaseFirestore.instance;
    print('\n🖼️ Starting Surgical Product Image Update...');

    // Helper to get default images based on category
    String _getCategoryImage(String category) {
      switch (category) {
        case 'Rice':
          return 'https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=500&q=80';
        case 'Noodles':
          return 'https://images.unsplash.com/photo-1552611052-33e04de081de?auto=format&fit=crop&w=500&q=80';
        case 'Drinks':
          return 'https://images.unsplash.com/photo-1544145945-f90425340c7e?auto=format&fit=crop&w=500&q=80';
        case 'Western':
          return 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?auto=format&fit=crop&w=500&q=80';
        case 'Snacks':
          return 'https://images.unsplash.com/photo-1621939514649-28b12e81658b?auto=format&fit=crop&w=500&q=80';
        default:
          return 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=500&q=80';
      }
    }

    final updates = {
      "P001": {"cat": "Rice", "img": "https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?auto=format&fit=crop&w=500&q=80"},
      "P002": {"cat": "Rice", "img": "https://images.unsplash.com/photo-1574484284008-be9d62827022?auto=format&fit=crop&w=500&q=80"},
      "P003": {"cat": "Drinks", "img": "https://images.unsplash.com/photo-1544145945-f90425340c7e?auto=format&fit=crop&w=500&q=80"},
      "P004": {"cat": "Drinks", "img": "https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=500&q=80"},
      "P005": {"cat": "Rice", "img": "https://images.unsplash.com/photo-1603133872878-684f10842619?auto=format&fit=crop&w=500&q=80"},
      "P006": {"cat": "Noodles", "img": "https://images.unsplash.com/photo-1612929633738-8fe44f7ec841?auto=format&fit=crop&w=500&q=80"},
      "P007": {"cat": "Western", "img": "https://images.unsplash.com/photo-1632778149955-e80f8ceca2e8?auto=format&fit=crop&w=500&q=80"},
      "P008": {"cat": "Snacks", "img": "https://images.unsplash.com/photo-1621939514649-28b12e81658b?auto=format&fit=crop&w=500&q=80"},
      "P009": {"cat": "Drinks", "img": "https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=500&q=80"},
      "P010": {"cat": "Snacks", "img": "https://images.unsplash.com/photo-1519996529931-28324d1a630e?auto=format&fit=crop&w=500&q=80"},
    };

    int count = 0;
    for (final entry in updates.entries) {
      try {
        final docRef = db.collection('scan_points').doc('SP001').collection('products').doc(entry.key);
        final doc = await docRef.get();
        
        if (doc.exists) {
          final category = entry.value['cat']!;
          final specificImg = entry.value['img']!;
          // Use specific image if available, else default
          final finalImg = specificImg.isNotEmpty ? specificImg : _getCategoryImage(category);

          await docRef.update({
            'image': finalImg,
            'category': category, // Ensure category is also correct
          });
          print('  ✅ [${entry.key}] Updated image & category');
          count++;
        }
      } catch (e) {
        print('  ❌ [${entry.key}] Failed: $e');
      }
    }
    print('✨ Surgical Update Complete. Updated $count products.\n');
  }
}
