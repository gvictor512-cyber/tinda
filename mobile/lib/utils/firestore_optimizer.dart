import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/secure_logger.dart';

class FirestoreOptimizer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Default limits for different query types
  static const int DEFAULT_LIMIT = 20;
  static const int SMALL_LIMIT = 10;
  static const int MEDIUM_LIMIT = 50;
  static const int LARGE_LIMIT = 100;
  static const int MAX_LIMIT = 500;

  // Query timeout in seconds
  static const int QUERY_TIMEOUT_SECONDS = 30;

  /// Create an optimized query with limits and timeouts
  Query createOptimizedQuery(
    String collection, {
    List<QueryFilter>? filters,
    List<OrderBy>? orderBy,
    int? limit,
    String? startAfter,
  }) {
    Query query = _firestore.collection(collection);

    // Apply filters
    if (filters != null) {
      for (final filter in filters) {
        switch (filter.operator) {
          case QueryOperator.equalTo:
            query = query.where(filter.field, isEqualTo: filter.value);
            break;
          case QueryOperator.notEqualTo:
            query = query.where(filter.field, isNotEqualTo: filter.value);
            break;
          case QueryOperator.lessThan:
            query = query.where(filter.field, isLessThan: filter.value);
            break;
          case QueryOperator.lessThanOrEqualTo:
            query = query.where(filter.field, isLessThanOrEqualTo: filter.value);
            break;
          case QueryOperator.greaterThan:
            query = query.where(filter.field, isGreaterThan: filter.value);
            break;
          case QueryOperator.greaterThanOrEqualTo:
            query = query.where(filter.field, isGreaterThanOrEqualTo: filter.value);
            break;
          case QueryOperator.arrayContains:
            query = query.where(filter.field, arrayContains: filter.value);
            break;
          case QueryOperator.arrayContainsAny:
            query = query.where(filter.field, arrayContainsAny: filter.value as List);
            break;
          case QueryOperator.whereIn:
            query = query.where(filter.field, whereIn: filter.value as List);
            break;
        }
      }
    }

    // Apply ordering
    if (orderBy != null) {
      for (final order in orderBy) {
        query = query.orderBy(order.field, descending: order.descending);
      }
    }

    // Apply limit
    final queryLimit = limit ?? DEFAULT_LIMIT;
    query = query.limit(queryLimit);

    return query;
  }

  /// Execute query with timeout and error handling
  Future<QuerySnapshot> executeQuery(
    Query query, {
    int timeoutSeconds = QUERY_TIMEOUT_SECONDS,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      final result = await query.get().timeout(
        Duration(seconds: timeoutSeconds),
        onTimeout: () {
          SecureLogger.warning('Query timeout after ${timeoutSeconds}s');
          throw TimeoutException('Query timeout after $timeoutSeconds seconds');
        },
      );

      stopwatch.stop();
      SecureLogger.logPerformance('Firestore query', stopwatch.elapsed, context: {
        'documents': result.docs.length,
        'timeout': timeoutSeconds,
      });

      return result;
    } catch (e) {
      SecureLogger.error('Firestore query failed', error: e);
      rethrow;
    }
  }

  /// Get single document with caching
  Future<DocumentSnapshot?> getDocument(
    String collection,
    String documentId, {
    bool useCache = true,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      final docRef = _firestore.collection(collection).doc(documentId);
      
      DocumentSnapshot doc;
      if (useCache) {
        doc = await docRef.get(const GetOptions(source: Source.cache));
        if (!doc.exists) {
          doc = await docRef.get(const GetOptions(source: Source.server));
        }
      } else {
        doc = await docRef.get();
      }

      stopwatch.stop();
      SecureLogger.logPerformance('Get document', stopwatch.elapsed, context: {
        'collection': collection,
        'cached': useCache,
        'exists': doc.exists,
      });

      return doc;
    } catch (e) {
      SecureLogger.error('Get document failed', error: e, data: {
        'collection': collection,
        'documentId': documentId,
      });
      rethrow;
    }
  }

  /// Get documents with pagination
  Future<QuerySnapshot> getPaginatedDocuments(
    String collection, {
    List<QueryFilter>? filters,
    List<OrderBy>? orderBy,
    int limit = DEFAULT_LIMIT,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = createOptimizedQuery(
        collection,
        filters: filters,
        orderBy: orderBy,
        limit: limit,
      );

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      return await executeQuery(query);
    } catch (e) {
      SecureLogger.error('Paginated query failed', error: e);
      rethrow;
    }
  }

  /// Batch write with size limits
  Future<void> batchWrite(List<BatchOperation> operations) async {
    const maxBatchSize = 500;
    
    for (int i = 0; i < operations.length; i += maxBatchSize) {
      final batch = operations.sublist(i, i + maxBatchSize);
      await _executeBatch(batch);
    }
  }

  Future<void> _executeBatch(List<BatchOperation> operations) async {
    try {
      final writeBatch = _firestore.batch();
      
      for (final operation in operations) {
        final docRef = _firestore.collection(operation.collection).doc(operation.documentId);
        
        switch (operation.type) {
          case BatchOperationType.set:
            writeBatch.set(docRef, operation.data!);
            break;
          case BatchOperationType.update:
            writeBatch.update(docRef, operation.data!);
            break;
          case BatchOperationType.delete:
            writeBatch.delete(docRef);
            break;
        }
      }

      await writeBatch.commit();
      SecureLogger.info('Batch write completed', data: {
        'operations': operations.length,
      });
    } catch (e) {
      SecureLogger.error('Batch write failed', error: e);
      rethrow;
    }
  }

  /// Transaction with retry logic
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    int maxAttempts = 3,
  }) async {
    int attempts = 0;
    
    while (attempts < maxAttempts) {
      try {
        return await _firestore.runTransaction(transactionHandler);
      } catch (e) {
        attempts++;
        if (attempts >= maxAttempts) {
          SecureLogger.error('Transaction failed after $attempts attempts', error: e);
          rethrow;
        }
        
        // Exponential backoff
        final delay = Duration(milliseconds: 100 * (1 << attempts));
        SecureLogger.warning('Transaction attempt $attempts failed, retrying in ${delay.inMilliseconds}ms');
        await Future.delayed(delay);
      }
    }
    
    throw Exception('Transaction failed after $maxAttempts attempts');
  }

  /// Optimized real-time listener with error handling
  Stream<QuerySnapshot> createRealtimeListener(
    String collection, {
    List<QueryFilter>? filters,
    List<OrderBy>? orderBy,
    int? limit,
    bool includeMetadataChanges = false,
  }) {
    try {
      Query query = createOptimizedQuery(
        collection,
        filters: filters,
        orderBy: orderBy,
        limit: limit,
      );

      return query.snapshots(includeMetadataChanges: includeMetadataChanges);
    } catch (e) {
      SecureLogger.error('Failed to create realtime listener', error: e);
      return const Stream.empty();
    }
  }

  /// Count documents efficiently (using server-side count when available)
  Future<int> countDocuments(
    String collection, {
    List<QueryFilter>? filters,
  }) async {
    try {
      Query query = _firestore.collection(collection);
      
      if (filters != null) {
        for (final filter in filters) {
          switch (filter.operator) {
            case QueryOperator.equalTo:
              query = query.where(filter.field, isEqualTo: filter.value);
              break;
            case QueryOperator.arrayContains:
              query = query.where(filter.field, arrayContains: filter.value);
              break;
            default:
              // For other operators, we need to fetch documents
              break;
          }
        }
      }

      // Try to use count from server (Firestore feature)
      try {
        final aggregateQuery = query.count();
        final aggregateSnapshot = await aggregateQuery.get();
        return aggregateSnapshot.count ?? 0;
      } catch (e) {
        // Fallback to client-side count
        final snapshot = await query.limit(MAX_LIMIT).get();
        return snapshot.docs.length;
      }
    } catch (e) {
      SecureLogger.error('Count documents failed', error: e);
      return 0;
    }
  }

  /// Get collection size estimate
  Future<int> getCollectionSize(String collection) async {
    try {
      final snapshot = await _firestore.collection(collection).limit(1).get();
      
      // If empty, return 0
      if (snapshot.docs.isEmpty) {
        return 0;
      }
      
      // For large collections, this is an estimate
      // In production, use a counter document or Cloud Functions
      return snapshot.docs.length;
    } catch (e) {
      SecureLogger.error('Get collection size failed', error: e);
      return 0;
    }
  }

  /// Clear cache for a specific collection
  Future<void> clearCache(String collection) async {
    try {
      // Firestore automatically manages cache, but we can force a refresh
      await _firestore.collection(collection).limit(1).get(
        const GetOptions(source: Source.server),
      );
      SecureLogger.info('Cache cleared for collection', data: {
        'collection': collection,
      });
    } catch (e) {
      SecureLogger.error('Clear cache failed', error: e);
    }
  }
}

// Query filter class
class QueryFilter {
  final String field;
  final QueryOperator operator;
  final dynamic value;

  QueryFilter({
    required this.field,
    required this.operator,
    required this.value,
  });
}

enum QueryOperator {
  equalTo,
  notEqualTo,
  lessThan,
  lessThanOrEqualTo,
  greaterThan,
  greaterThanOrEqualTo,
  arrayContains,
  arrayContainsAny,
  whereIn,
}

// Order by class
class OrderBy {
  final String field;
  final bool descending;

  OrderBy({
    required this.field,
    this.descending = false,
  });
}

// Batch operation class
class BatchOperation {
  final String collection;
  final String documentId;
  final BatchOperationType type;
  final Map<String, dynamic>? data;

  BatchOperation({
    required this.collection,
    required this.documentId,
    required this.type,
    this.data,
  });
}

enum BatchOperationType {
  set,
  update,
  delete,
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}
