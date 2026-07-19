import 'dart:convert';
import 'dart:developer';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/cache_service.dart';
import '../models/smart_post_model.dart';

/// Repository for Smart Community Feed with AI personalization.
class SmartCommunityRepository {
  final ApiClient _apiClient;
  final CacheService _cacheService;
  final AnalyticsService _analyticsService;

  static const _recommendedCacheKey = 'smart_community_recommended';
  static const _trendingCacheKey = 'smart_community_trending';
  static const _weeklyCacheKey = 'smart_community_weekly';

  SmartCommunityRepository({
    required ApiClient apiClient,
    required CacheService cacheService,
    required AnalyticsService analyticsService,
  })  : _apiClient = apiClient,
        _cacheService = cacheService,
        _analyticsService = analyticsService;

  /// Fetches AI-recommended posts for the user.
  Future<List<SmartPostModel>> getRecommendedPosts({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _getCachedPosts(_recommendedCacheKey);
      if (cached.isNotEmpty) return cached;
    }

    try {
      // In production, this would call an AI-personalized endpoint
      // For now, we use the general communities endpoint with AI ranking
      final response = await _apiClient.get(
        ApiEndpoints.communitiesAll,
        params: {'personalized': 'true', 'limit': '20'},
      );

      if (response is Map<String, dynamic> && response['data'] != null) {
        final posts = (response['data'] as List<dynamic>)
            .map((e) => SmartPostModel.fromJson(e as Map<String, dynamic>))
            .toList();

        // Mark as recommended
        final recommendedPosts = posts.map((post) {
          return SmartPostModel(
            id: post.id,
            title: post.title,
            content: post.content,
            authorName: post.authorName,
            authorAvatar: post.authorAvatar,
            likes: post.likes,
            comments: post.comments,
            isLiked: post.isLiked,
            isRecommended: true, // AI-recommended
            isTrending: post.isTrending,
            relevantWeek: post.relevantWeek,
            createdAt: post.createdAt,
            tags: post.tags,
          );
        }).toList();

        await _cachePosts(_recommendedCacheKey, recommendedPosts);
        return recommendedPosts;
      }

      return _getCachedPosts(_recommendedCacheKey);
    } catch (e) {
      log('Error fetching recommended posts: $e', name: 'SmartCommunityRepo');
      return _getCachedPosts(_recommendedCacheKey);
    }
  }

  /// Fetches trending posts.
  Future<List<SmartPostModel>> getTrendingPosts({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _getCachedPosts(_trendingCacheKey);
      if (cached.isNotEmpty) return cached;
    }

    try {
      final response = await _apiClient.get(
        ApiEndpoints.communitiesAll,
        params: {'sort': 'trending', 'limit': '20'},
      );

      if (response is Map<String, dynamic> && response['data'] != null) {
        final posts = (response['data'] as List<dynamic>)
            .map((e) => SmartPostModel.fromJson(e as Map<String, dynamic>))
            .toList();

        final trendingPosts = posts.map((post) {
          return SmartPostModel(
            id: post.id,
            title: post.title,
            content: post.content,
            authorName: post.authorName,
            authorAvatar: post.authorAvatar,
            likes: post.likes,
            comments: post.comments,
            isLiked: post.isLiked,
            isRecommended: post.isRecommended,
            isTrending: true, // Mark as trending
            relevantWeek: post.relevantWeek,
            createdAt: post.createdAt,
            tags: post.tags,
          );
        }).toList();

        await _cachePosts(_trendingCacheKey, trendingPosts);
        return trendingPosts;
      }

      return _getCachedPosts(_trendingCacheKey);
    } catch (e) {
      log('Error fetching trending posts: $e', name: 'SmartCommunityRepo');
      return _getCachedPosts(_trendingCacheKey);
    }
  }

  /// Fetches posts relevant to the user's current pregnancy week.
  Future<List<SmartPostModel>> getWeeklyPosts({
    int? currentWeek,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = _getCachedPosts(_weeklyCacheKey);
      if (cached.isNotEmpty) return cached;
    }

    try {
      final response = await _apiClient.get(
        ApiEndpoints.communitiesAll,
        params: {
          'week': currentWeek?.toString() ?? '',
          'limit': '20',
        },
      );

      if (response is Map<String, dynamic> && response['data'] != null) {
        final posts = (response['data'] as List<dynamic>)
            .map((e) => SmartPostModel.fromJson(e as Map<String, dynamic>))
            .toList();

        final weeklyPosts = posts.map((post) {
          return SmartPostModel(
            id: post.id,
            title: post.title,
            content: post.content,
            authorName: post.authorName,
            authorAvatar: post.authorAvatar,
            likes: post.likes,
            comments: post.comments,
            isLiked: post.isLiked,
            isRecommended: post.isRecommended,
            isTrending: post.isTrending,
            relevantWeek: currentWeek ?? post.relevantWeek,
            createdAt: post.createdAt,
            tags: post.tags,
          );
        }).toList();

        await _cachePosts(_weeklyCacheKey, weeklyPosts);
        return weeklyPosts;
      }

      return _getCachedPosts(_weeklyCacheKey);
    } catch (e) {
      log('Error fetching weekly posts: $e', name: 'SmartCommunityRepo');
      return _getCachedPosts(_weeklyCacheKey);
    }
  }

  /// Toggles like status for a post.
  Future<bool> toggleLike(String postId) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.communityToggleLike(postId),
      );

      if (response is Map<String, dynamic>) {
        _analyticsService.logFeatureUsed('community_post_liked', params: {
          'post_id': postId,
        });
        return response['isLiked'] == true;
      }

      return false;
    } catch (e) {
      log('Error toggling like: $e', name: 'SmartCommunityRepo');
      return false;
    }
  }

  List<SmartPostModel> _getCachedPosts(String cacheKey) {
    final cached = _cacheService.get(cacheKey);
    if (cached == null) return [];

    try {
      final data = cached is String ? jsonDecode(cached) : cached;
      return (data as List<dynamic>)
          .map((e) => SmartPostModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _cachePosts(String cacheKey, List<SmartPostModel> posts) async {
    await _cacheService.put(
      cacheKey,
      jsonEncode(posts.map((p) => p.toJson()).toList()),
      expiry: const Duration(hours: 2),
    );
  }
}
