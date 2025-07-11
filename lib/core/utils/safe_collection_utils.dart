// lib/core/utils/safe_collection_utils.dart


/// Utility class for safe collection operations to prevent "Bad state: No element" errors
class SafeCollectionUtils {
  /// Safely gets the first element of a list
  /// Returns null if the list is empty
  static T? safeFirst<T>(List<T>? list) {
    if (list == null || list.isEmpty) return null;
    return list.first;
  }

  /// Safely gets the last element of a list
  /// Returns null if the list is empty
  static T? safeLast<T>(List<T>? list) {
    if (list == null || list.isEmpty) return null;
    return list.last;
  }

  /// Safely gets a single element from a list
  /// Returns null if the list is empty or has more than one element
  static T? safeSingle<T>(List<T>? list) {
    if (list == null || list.isEmpty || list.length > 1) return null;
    return list.single;
  }

  /// Safely finds the first element that matches a condition
  /// Returns null if no element is found
  static T? safeFirstWhere<T>(List<T>? list, bool Function(T) test) {
    if (list == null || list.isEmpty) return null;
    try {
      return list.firstWhere(test);
    } catch (e) {
      return null;
    }
  }

  /// Safely finds the last element that matches a condition
  /// Returns null if no element is found
  static T? safeLastWhere<T>(List<T>? list, bool Function(T) test) {
    if (list == null || list.isEmpty) return null;
    try {
      return list.lastWhere(test);
    } catch (e) {
      return null;
    }
  }

  /// Safely gets an element at a specific index
  /// Returns null if the index is out of bounds
  static T? safeElementAt<T>(List<T>? list, int index) {
    if (list == null || index < 0 || index >= list.length) return null;
    return list[index];
  }

  /// Safely reduces a list with a combining function
  /// Returns null if the list is empty
  static T? safeReduce<T>(List<T>? list, T Function(T, T) combine) {
    if (list == null || list.isEmpty) return null;
    return list.reduce(combine);
  }

  /// Safely gets the minimum value from a list of comparable items
  /// Returns null if the list is empty
  static T? safeMin<T extends Comparable<T>>(List<T>? list) {
    if (list == null || list.isEmpty) return null;
    return list.reduce((a, b) => a.compareTo(b) < 0 ? a : b);
  }

  /// Safely gets the maximum value from a list of comparable items
  /// Returns null if the list is empty
  static T? safeMax<T extends Comparable<T>>(List<T>? list) {
    if (list == null || list.isEmpty) return null;
    return list.reduce((a, b) => a.compareTo(b) > 0 ? a : b);
  }

  /// Safely gets a value from a map
  /// Returns null if the key doesn't exist
  static V? safeMapGet<K, V>(Map<K, V>? map, K key) {
    return map?[key];
  }

  /// Safely removes and returns the first element from a list
  /// Returns null if the list is empty
  static T? safeRemoveFirst<T>(List<T>? list) {
    if (list == null || list.isEmpty) return null;
    return list.removeAt(0);
  }

  /// Safely removes and returns the last element from a list
  /// Returns null if the list is empty
  static T? safeRemoveLast<T>(List<T>? list) {
    if (list == null || list.isEmpty) return null;
    return list.removeLast();
  }

  /// Safely gets elements in a range
  /// Returns empty list if indices are out of bounds
  static List<T> safeGetRange<T>(List<T>? list, int start, int end) {
    if (list == null || list.isEmpty) return [];
    if (start < 0) start = 0;
    if (end > list.length) end = list.length;
    if (start >= end) return [];
    return list.getRange(start, end).toList();
  }

  /// Safely checks if a list contains all elements from another list
  static bool safeContainsAll<T>(List<T>? list, List<T>? elements) {
    if (list == null || elements == null) return false;
    if (elements.isEmpty) return true;
    if (list.isEmpty) return false;
    return elements.every((element) => list.contains(element));
  }

  /// Safely converts any iterable to a list
  static List<T> safeToList<T>(Iterable<T>? iterable) {
    return iterable?.toList() ?? [];
  }

  /// Safely converts any iterable to a set
  static Set<T> safeToSet<T>(Iterable<T>? iterable) {
    return iterable?.toSet() ?? {};
  }
}
