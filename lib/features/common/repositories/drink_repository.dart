import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/db_service.dart';

class DrinkRepository {
  Future<Map<String, dynamic>?> getDrink(String name) async {
    final snap = await DbService.doc('drinks/${Uri.encodeComponent(name)}').get();
    if (!snap.exists) return null;
    return snap.data()! as Map<String, dynamic>;
  }

  Future<void> updateApproval({
    required String name,
    required String uid,
    required String url,
  }) async {
    final ref = DbService.doc('drinks/${Uri.encodeComponent(name)}');

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);

      final prev = snap.exists ? snap.data()! as Map<String, dynamic> : {};
      final approvals = List<String>.from(prev['approvals'] ?? []);

      if (!approvals.contains(uid)) approvals.add(uid);

      tx.set(ref, {
        ...prev,
        'officialUrl': url,
        'approvals': approvals,
        'approvalCount': approvals.length,
      });
    });
  }

  Future<void> setVerified(String name, String url) async {
    await DbService.doc('drinks/${Uri.encodeComponent(name)}').update({'status': 'verified', 'officialUrl': url});
  }
}
