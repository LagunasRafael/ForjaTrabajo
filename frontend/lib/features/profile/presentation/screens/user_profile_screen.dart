import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/public_profile_provider.dart';
import '../../domain/models/public_profile_model.dart';
import '../../domain/models/review_model.dart';

class UserProfileScreen extends ConsumerWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsyncValue = ref.watch(publicProfileProvider(userId));
    final reviewsAsyncValue = ref.watch(userReviewsProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
      ),
      body: profileAsyncValue.when(
        data: (profile) => _buildProfileBody(context, profile, reviewsAsyncValue),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error al cargar perfil: $error', textAlign: TextAlign.center),
        ),
      ),
    );
  }

  Widget _buildProfileBody(
      BuildContext context, PublicProfileModel profile, AsyncValue<List<ReviewModel>> reviewsAsyncValue) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: profile.profilePictureUrl != null && profile.profilePictureUrl!.isNotEmpty
                      ? NetworkImage(profile.profilePictureUrl!)
                      : null,
                  child: profile.profilePictureUrl == null || profile.profilePictureUrl!.isEmpty
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  profile.fullName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.role.toUpperCase(),
                  style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600, letterSpacing: 1.2),
                ),
                const SizedBox(height: 16),
                _buildStatsRow(profile),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Reseñas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        reviewsAsyncValue.when(
          data: (reviews) {
            if (reviews.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(
                    child: Text(
                      'Este usuario aún no tiene reseñas.',
                      style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final review = reviews[index];
                  return _buildReviewCard(review);
                },
                childCount: reviews.length,
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => SliverToBoxAdapter(
            child: Center(child: Text('Error al cargar reseñas: $error')),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(PublicProfileModel profile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 28),
                const SizedBox(width: 4),
                Text(
                  profile.averageRating.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Text('Calificación', style: TextStyle(color: Colors.grey)),
          ],
        ),
        const SizedBox(width: 40),
        Container(width: 1, height: 40, color: Colors.grey[300]),
        const SizedBox(width: 40),
        Column(
          children: [
            Text(
              profile.totalReviews.toString(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text('Reseñas', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: review.reviewerImageUrl != null && review.reviewerImageUrl!.isNotEmpty
                      ? NetworkImage(review.reviewerImageUrl!)
                      : null,
                  child: review.reviewerImageUrl == null || review.reviewerImageUrl!.isEmpty
                      ? const Icon(Icons.person, size: 20)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.reviewerName ?? 'Usuario',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                review.comment!,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
