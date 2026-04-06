import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';

class FirestoreService {
  final CollectionReference _itemsRef =
      FirebaseFirestore.instance.collection('items');

  // create
  Future<void> addItem(Item item) async {
    await _itemsRef.add(item.toMap());
  }

  // stream items
  Stream<List<Item>> streamItems() {
    return _itemsRef.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs
              .map((d) => Item.fromMap(d.id, d.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  // update
  Future<void> updateItem(Item item) async {
    await _itemsRef.doc(item.id).update({
      'name': item.name,
      'price': item.price,
      'quantity': item.quantity,
      'category': item.category,
    });
  }

  // delete
  Future<void> deleteItem(String id) async {
    await _itemsRef.doc(id).delete();
  }
}
