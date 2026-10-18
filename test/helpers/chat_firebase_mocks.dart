// Firestore marks SDK interfaces sealed; mocks intentionally replace their I/O.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';

class MockChatFirestore extends Mock implements FirebaseFirestore {}

class MockChatAuth extends Mock implements FirebaseAuth {}

class MockChatUser extends Mock implements User {}

class MockChatCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockChatDocument extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockChatQuery extends Mock implements Query<Map<String, dynamic>> {}

class MockChatSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockChatQueryDocument extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

class MockChatQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockChatTransaction extends Mock implements Transaction {}

MockChatSnapshot chatSnapshot(
  String id,
  Map<String, dynamic>? data, {
  bool exists = true,
}) {
  final snapshot = MockChatSnapshot();
  when(() => snapshot.id).thenReturn(id);
  when(() => snapshot.exists).thenReturn(exists);
  when(() => snapshot.data()).thenReturn(data);
  return snapshot;
}

MockChatQueryDocument chatQueryDocument(String id, Map<String, dynamic> data) {
  final snapshot = MockChatQueryDocument();
  when(() => snapshot.id).thenReturn(id);
  when(() => snapshot.exists).thenReturn(true);
  when(() => snapshot.data()).thenReturn(data);
  return snapshot;
}

MockChatQuerySnapshot chatQuerySnapshot(
  Map<String, Map<String, dynamic>> documents,
) {
  final snapshot = MockChatQuerySnapshot();
  final docs = documents.entries
      .map((entry) => chatQueryDocument(entry.key, entry.value))
      .toList();
  when(() => snapshot.docs).thenReturn(docs);
  return snapshot;
}

void stubChatUser(MockChatAuth auth, {String uid = 'student-1'}) {
  final user = MockChatUser();
  when(() => user.uid).thenReturn(uid);
  when(() => auth.currentUser).thenReturn(user);
}
