// lib/view_model/favorites_provider.dart
import 'package:bayt_alhikma/model/Book.dart';
import 'package:bayt_alhikma/view_model/local_storage_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavoritesProvider extends ChangeNotifier {
  List<Book> _favoriteBooks = [];
  bool _isLoading = false;

  List<Book> get favoriteBooks => _favoriteBooks;
  bool get isLoading => _isLoading;

  // Load favorites (Call this in your main.dart or when app starts)
  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();

    try {
      Set<String> allFavIds = LocalStorageService.getFavoritesLocally().toSet();

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('profils')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          final List<dynamic> cloudFavs = data['favorites'] ?? [];
          for (var id in cloudFavs) {
            allFavIds.add(id.toString());
          }
        }
      }

      List<Book> fetchedBooks = [];
      for (String bookId in allFavIds) {
        // Use 'ID' field (int or string) to match your Firestore structure
        QuerySnapshot query = await FirebaseFirestore.instance
            .collection('books')
            .where(
              'ID',
              isEqualTo: bookId,
            ) // Ensure ID type matches DB (int/String)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final bData = query.docs.first.data() as Map<String, dynamic>;
          fetchedBooks.add(
            Book(
              id: bookId,
              nameAR: bData['nameAR'],
              nameEN: bData['nameEN'],
              authorAR: bData['authorAR'],
              authorEN: bData['authorEN'],
              descriptionAR: bData['descriptionAR'],
              descriptionEN: bData['descriptionEN'],
              image: bData['image'],
              audio: bData['audio'],
              pdf: bData['pdf'],
              price: bData['price'],
              isSaved: true,
            ),
          );
        }
      }
      _favoriteBooks = fetchedBooks;
    } catch (e) {
      print("Error loading favorites: $e");
    } finally {
      _isLoading = false;
      notifyListeners(); // This updates the UI!
    }
  }

  Future<void> addToFavorites(String bookId) async {
    // 1. Update Local & Cloud
    await LocalStorageService.addFavoriteLocally(bookId);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('profils')
          .doc(user.uid)
          .update({
            'favorites': FieldValue.arrayUnion([bookId]),
          });
    }

    // 2. Reload the list to update UI
    await loadFavorites();
  }

  Future<void> removeFromFavorites(String bookId) async {
    // 1. Update Local & Cloud
    await LocalStorageService.removeFavoriteLocally(bookId);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('profils')
          .doc(user.uid)
          .update({
            'favorites': FieldValue.arrayRemove([bookId]),
          });
    }

    // 2. Reload the list to update UI
    await loadFavorites();
  }

  // Helper to check if a book is favored
  bool isBookFavorite(String bookId) {
    return _favoriteBooks.any(
      (book) => book.id.toString() == bookId.toString(),
    );
  }
}
