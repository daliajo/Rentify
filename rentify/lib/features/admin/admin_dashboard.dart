import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'admin_reviews_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const String _adminEmail = 'ddaliayousef16@gmail.com';

  bool _isAdmin(User? user) {
    return user != null && user.email == _adminEmail;
  }

  final CollectionReference<Map<String, dynamic>> _usersRef =
      FirebaseFirestore.instance.collection('users');

  final CollectionReference<Map<String, dynamic>> _itemsRef =
      FirebaseFirestore.instance.collection('rentify_items');

  final Color orange = const Color(0xFFFF8A3D);
  final Color fieldBg = const Color(0xFFF1F1F1);

  void _triggerRefresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (!_isAdmin(user)) {
      Future.microtask(() {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      });

      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset("assets/images/logoo.png", width: 36),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Admin Dashboard',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _triggerRefresh,
            icon: const Icon(Icons.refresh, color: Colors.black),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreeting(),
            const SizedBox(height: 30),
            _buildStats(),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminReviewsPage()),
                    );
                  },
                  icon: const Icon(Icons.rate_review_outlined,
                      color: Color(0xFFFF8A3D)),
                  label: const Text(
                    'View Reviews',
                    style: TextStyle(
                      color: Color(0xFFFF8A3D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/admin/users'),
                  icon: const Icon(Icons.manage_accounts_outlined,
                      color: Color(0xFFFF8A3D)),
                  label: const Text(
                    'Manage Users',
                    style: TextStyle(
                      color: Color(0xFFFF8A3D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildRecentItemsSection(),
            const SizedBox(height: 32),
            _buildRecentReviewsSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome, Admin',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Here's an overview of Rentify activity.",
          style: TextStyle(
            fontSize: 15,
            color: Colors.black.withValues(alpha: 0.65),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: isNarrow
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 32) / 3,
              child: _StatCard(
                title: 'Total Users',
                icon: Icons.people_alt_rounded,
                color: orange,
                stream: _usersRef.snapshots(),
              ),
            ),
            SizedBox(
              width: isNarrow
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 32) / 3,
              child: _StatCard(
                title: 'Total Items',
                icon: Icons.inventory_2_rounded,
                color: orange,
                stream: _itemsRef.snapshots(),
              ),
            ),
            SizedBox(
              width: isNarrow
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 32) / 3,
              child: _StatCard(
                title: 'Active Items',
                icon: Icons.check_circle_rounded,
                color: orange,
                stream: _itemsRef
                    .where('status', isEqualTo: 'Available')
                    .snapshots(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Items',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _itemsRef
              .orderBy('createdAt', descending: true)
              .limit(10)
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
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: fieldBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Unable to load items.',
                  style: TextStyle(color: Colors.redAccent),
                ),
              );
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 12),
                decoration: BoxDecoration(
                  color: fieldBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'No items found.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final data = docs[index].data();
                return _ItemCard(
                  docId: docs[index].id,
                  name: data['name'] ?? 'Unnamed item',
                  category: data['category'] ?? 'N/A',
                  price: data['price'] is num
                      ? (data['price'] as num).toDouble()
                      : double.tryParse(data['price']?.toString() ?? ''),
                  renterEmail:
                      data['renterEmail'] ?? data['renterId'] ?? 'Unknown',
                  status: data['status'] ?? 'Unknown',
                  ownerId: data['renterId'] as String?,
                  imageUrl: data['imageUrl'] as String?,
                  onDelete: () => _deleteItem(docs[index].id, context),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _deleteItem(String docId, BuildContext context) async {
    try {
      await _itemsRef.doc(docId).delete();
      if (!mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted successfully')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete item: $e')),
        );
      }
    }
  }

  Widget _buildRecentReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Reviews',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.black,
              ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('reviews')
              .orderBy('createdAt', descending: true)
              .limit(10)
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
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: fieldBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Unable to load reviews.',
                  style: TextStyle(color: Colors.redAccent),
                ),
              );
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 12),
                decoration: BoxDecoration(
                  color: fieldBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'No reviews found.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _ReviewCard(
                  reviewDoc: docs[index],
                  onDelete: () =>
                      _confirmAndDeleteReview(context, docs[index].reference),
                );
              },
            );
          },
        ),
      ],
    );
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
}

class _StatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;

  const _StatCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: stream,
          builder: (context, snapshot) {
            Widget number;
            if (snapshot.connectionState == ConnectionState.waiting) {
              number = const SizedBox(
                height: 32,
                width: 32,
                child: CircularProgressIndicator(strokeWidth: 3),
              );
            } else if (snapshot.hasError) {
              number = const Text(
                '—',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              );
            } else {
              number = Text(
                snapshot.data?.docs.length.toString() ?? '0',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      number,
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final String docId;
  final String name;
  final String category;
  final double? price;
  final String renterEmail;
  final String status;
  final String? ownerId;
  final String? imageUrl;
  final VoidCallback onDelete;
  const _ItemCard({
    required this.docId,
    required this.name,
    required this.category,
    required this.price,
    required this.renterEmail,
    required this.status,
    required this.ownerId,
    required this.imageUrl,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const fieldBg = Color(0xFFF1F1F1);
    final isAvailable = status.toLowerCase() == 'available';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: fieldBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.inventory_rounded,
                          color: Color(0xFFFF8A3D),
                          size: 28,
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFFF8A3D)),
                            ),
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.inventory_rounded,
                      color: Color(0xFFFF8A3D),
                      size: 28,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$category • ${price != null ? '${price!.toStringAsFixed(2)} JOD/day' : 'Price N/A'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Owner: $renterEmail',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.54),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isAvailable ? Colors.green : Colors.blueGrey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Delete item',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> reviewDoc;
  final VoidCallback onDelete;

  const _ReviewCard({
    required this.reviewDoc,
    required this.onDelete,
  });

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
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final review = reviewDoc.data();
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final comment = review['comment'] as String? ?? '';
    final createdAt = review['createdAt'] as Timestamp?;
    final itemId = review['itemId'] as String?;
    final userId = review['userId'] as String?;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
          future: itemId != null
              ? FirebaseFirestore.instance
                  .collection('rentify_items')
                  .doc(itemId)
                  .get()
              : Future<DocumentSnapshot<Map<String, dynamic>>?>.value(null),
          builder: (context, itemSnapshot) {
            final itemName =
                itemSnapshot.data?.data()?['name'] as String? ?? 'Unknown Item';
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
                maxLines: 2,
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
                  : Future<DocumentSnapshot<Map<String, dynamic>>?>.value(null),
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
          onPressed: onDelete,
          tooltip: 'Delete review',
        ),
      ),
    );
  }
}
