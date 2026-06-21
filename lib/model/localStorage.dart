import 'package:bayt_alhikma/model/Book.dart';

class LocalStorage {
  // persisted in-memory for now
  static List<Book> savedBooks = [];

  // return the current saved books (synchronous)
  List<Book> getSavedBooks() {
    return savedBooks;
  }
}
