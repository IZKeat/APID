/*
==========================================================================
⚠️ DEPRECATED: THIS FILE IS NO LONGER IN USE.
⚠️ PLEASE REFER TO `lib/pages_user/digital_id_view.dart` FOR THE ACTIVE IMPLEMENTATION.
==========================================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import '../services/user_cache_service.dart';
import '../config/secure_config.dart';

class QrShowPage extends StatefulWidget {
  const QrShowPage({super.key});

  @override
  State<QrShowPage> createState() => _QrShowPageState();
}

class _QrShowPageState extends State<QrShowPage> {
  // ... (Commented out legacy code)
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("This page is deprecated. Use DigitalIdView ('My ID') instead."),
      ),
    );
  }
}
*/
