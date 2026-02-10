import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminReviewsPage extends StatefulWidget {
  const AdminReviewsPage({super.key});

  @override
  State<AdminReviewsPage> createState() => _AdminReviewsPageState();
}

class _AdminReviewsPageState extends State<AdminReviewsPage> {
  final Color orange = const Color(0xFFFF8A3D);

  Widget _buildStarsRow(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: index < rating ? Colors.amber : Colors.grey,
          size: 16,
        );
      }),
    );
  }

  String _formatDate(Timestamp? createdAt) {
    if (createdAt == null) return 'Recently';
    final date = createdAt.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }

  Future<void> _confirmAndDeleteReview(
      BuildContext context, DocumentReference reviewRef) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete review?'),
            content: const Text(
              'Are you sure you want to delete this review? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete || !mounted) return;

    try {
      await reviewRef.delete();
      if (!mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review deleted')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete review: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reviews Management',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .orderBy('createdAt', descending: true)
            .limit(30)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Error loading reviews: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No reviews found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final reviewDoc = docs[index];
              final review = reviewDoc.data();
              final rating = (review['rating'] as num?)?.toInt() ?? 0;
              final comment = review['comment'] as String? ?? '';
              final createdAt = review['createdAt'] as Timestamp?;
              final itemId = review['itemId'] as String?;
              final userId = review['userId'] as String?;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  title: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
                    future: itemId != null
                        ? FirebaseFirestore.instance
                            .collection('rentify_items')
                            .doc(itemId)
                            .get()
                        : Future<DocumentSnapshot<Map<String, dynamic>>?>.value(
                            null),
                    builder: (context, itemSnapshot) {
                      final itemName =
                          itemSnapshot.data?.data()?['name'] as String? ??
                              'Unknown Item';
                      return Text(
                        itemName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      );
                    },
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildStarsRow(rating),
                          const SizedBox(width: 8),
                          Text(
                            '$rating',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                      if (comment.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          comment,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black.withValues(alpha: 0.87),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
                        future: userId != null
                            ? FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .get()
                            : Future<DocumentSnapshot<Map<String, dynamic>>?>.value(
                                null),
                        builder: (context, userSnapshot) {
                          final userEmail =
                              userSnapshot.data?.data()?['email'] as String? ??
                                  userId ??
                                  'Unknown User';
                          return Text(
                            'By $userEmail • ${_formatDate(createdAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black.withValues(alpha: 0.54),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () =>
                        _confirmAndDeleteReview(context, reviewDoc.reference),
                    tooltip: 'Delete review',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

