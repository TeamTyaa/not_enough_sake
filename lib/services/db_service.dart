// ============================================================
// DBサービス
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class DbService {
  static FirebaseFirestore get db => FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> collection(String path) {
    return db.collection(path);
  }

  static DocumentReference doc(String path) {
    return db.doc(path);
  }
}
