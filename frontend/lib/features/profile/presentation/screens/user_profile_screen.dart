import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:forja_trabajo/features/profile/presentation/screens/portfolio_job_detail_screen.dart';
import '../../../../core/theme/app_theme.dart';
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
                profile.profilePictureUrl != null && profile.profilePictureUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: profile.profilePictureUrl!,
                        imageBuilder: (context, imageProvider) => CircleAvatar(
                          radius: 50,
                          backgroundImage: imageProvider,
                        ),
                        placeholder: (context, url) => const CircleAvatar(
                          radius: 50,
                          child: Icon(Icons.person, size: 50),
                        ),
                        errorWidget: (context, url, error) => const CircleAvatar(
                          radius: 50,
                          child: Icon(Icons.person, size: 50),
                        ),
                      )
                    : const CircleAvatar(
                        radius: 50,
                        child: Icon(Icons.person, size: 50),
                      ),
                const SizedBox(height: 16),
                Text(
                  profile.fullName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (profile.isIdentityVerified)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified, color: Colors.blue, size: 18),
                        const SizedBox(width: 4),
                        Text('Identidad Verificada',
                            style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  profile.translatedRole,
                  style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600, letterSpacing: 1.2),
                ),
                const SizedBox(height: 16),
                _buildStatsRow(profile),
                if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[900]
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]!
                            : Colors.grey[200]!,
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Acerca de mí',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            profile.bio!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[300]
                                  : Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (profile.categories.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Servicios que realizo',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.categories.map((cat) {
                        return Chip(
                          label: Text(
                            cat.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          labelStyle: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                if (profile.completedJobs.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Trabajos completados',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...profile.completedJobs.map((job) => _buildJobCard(context, profile, job)),
                ],
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
            return SliverPadding(
              padding: const EdgeInsets.only(bottom: 44),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final review = reviews[index];
                    return _buildReviewCard(review);
                  },
                  childCount: reviews.length,
                ),
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

  Widget _buildJobCard(BuildContext context, PublicProfileModel profile, JobSummaryModel job) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, // Asegura que el ripple effect no se desborde del borde redondeado
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PortfolioJobDetailScreen(
                jobId: job.id,
                jobTitle: job.title,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.roleInJob == 'client' ? 'Como Cliente' : 'Como Trabajador',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (job.otherPartyName != null)
                Column(
                  children: [
                    job.otherPartyImageUrl != null && job.otherPartyImageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: job.otherPartyImageUrl!,
                            imageBuilder: (context, imageProvider) => CircleAvatar(
                              radius: 18,
                              backgroundImage: imageProvider,
                            ),
                            errorWidget: (context, url, error) => const CircleAvatar(
                              radius: 18,
                              child: Icon(Icons.person, size: 18),
                            ),
                          )
                        : const CircleAvatar(
                            radius: 18,
                            child: Icon(Icons.person, size: 18),
                          ),
                    const SizedBox(height: 4),
                    Text(
                      job.otherPartyName!.split(' ').first,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
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
                review.reviewerImageUrl != null && review.reviewerImageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: review.reviewerImageUrl!,
                          imageBuilder: (context, imageProvider) => CircleAvatar(
                            radius: 20,
                            backgroundImage: imageProvider,
                          ),
                          errorWidget: (context, url, error) => const CircleAvatar(
                            radius: 20,
                            child: Icon(Icons.person, size: 20),
                          ),
                        )
                      : const CircleAvatar(
                          radius: 20,
                          child: Icon(Icons.person, size: 20),
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
