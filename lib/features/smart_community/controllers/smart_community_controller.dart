import 'dart:developer';

import 'package:flutter/material.dart';

import '../../../core/services/analytics_service.dart';
import '../models/smart_post_model.dart';
import '../repositories/smart_community_repository.dart';

/// Controller for Smart Community Feed with AI personalization.
class SmartCommunityController extends ChangeNotifier {
  final SmartCommunityRepository _repository;
  final AnalyticsService _analytics;

  // ─── State ────────────────────────────────────────────────
  List<SmartPostModel> _recommendedPosts = [];
  List<SmartPostModel> get recommendedPosts => _recommendedPosts;

  List<SmartPostModel> _trendingPosts = [];
  List<SmartPostModel> get trendingPosts => _trendingPosts;

  List<SmartPostModel> _weeklyPosts = [];
  List<SmartPostModel> get weeklyPosts => _weeklyPosts;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  int? _currentWeek;
  int? get currentWeek => _currentWeek;

  SmartCommunityController({
    required SmartCommunityRepository repository,
    required AnalyticsService analytics,
  })  : _repository = repository,
        _analytics = analytics;

  /// Sets the current pregnancy week for personalized content.
  void setCurrentWeek(int? week) {
    _currentWeek = week;
    notifyListeners();
  }

  /// Loads all post types.
  Future<void> loadAllPosts({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        loadRecommendedPosts(forceRefresh: forceRefresh),
        loadTrendingPosts(forceRefresh: forceRefresh),
        loadWeeklyPosts(forceRefresh: forceRefresh),
      ]);

      _analytics.logScreenView('smart_community');
      _analytics.logFeatureUsed('smart_community_viewed');
    } catch (e) {
      log('Error loading posts: $e', name: 'SmartCommunityCtrl');
      _error = 'Failed to load community posts';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Loads recommended posts.
  Future<void> loadRecommendedPosts({bool forceRefresh = false}) async {
    try {
      _recommendedPosts = await _repository.getRecommendedPosts(
        forceRefresh: forceRefresh,
      );
      notifyListeners();
    } catch (e) {
      log('Error loading recommended posts: $e', name: 'SmartCommunityCtrl');
    }
  }

  /// Loads trending posts.
  Future<void> loadTrendingPosts({bool forceRefresh = false}) async {
    try {
      _trendingPosts = await _repository.getTrendingPosts(
        forceRefresh: forceRefresh,
      );
      notifyListeners();
    } catch (e) {
      log('Error loading trending posts: $e', name: 'SmartCommunityCtrl');
    }
  }

  /// Loads weekly-relevant posts.
  Future<void> loadWeeklyPosts({bool forceRefresh = false}) async {
    try {
      _weeklyPosts = await _repository.getWeeklyPosts(
        currentWeek: _currentWeek,
        forceRefresh: forceRefresh,
      );
      notifyListeners();
    } catch (e) {
      log('Error loading weekly posts: $e', name: 'SmartCommunityCtrl');
    }
  }

  /// Toggles like status for a post.
  Future<void> toggleLike(String postId) async {
    try {
      final newLikeStatus = await _repository.toggleLike(postId);

      // Update local state
      _updatePostLikeStatus(postId, newLikeStatus);

      _analytics.logFeatureUsed('community_post_liked', params: {
        'post_id': postId,
        'is_liked': newLikeStatus.toString(),
      });

      notifyListeners();
    } catch (e) {
      log('Error toggling like: $e', name: 'SmartCommunityCtrl');
    }
  }

  void _updatePostLikeStatus(String postId, bool isLiked) {
    // Update in recommended posts
    final recommendedIndex =
        _recommendedPosts.indexWhere((p) => p.id == postId);
    if (recommendedIndex != -1) {
      final post = _recommendedPosts[recommendedIndex];
      _recommendedPosts[recommendedIndex] = SmartPostModel(
        id: post.id,
        title: post.title,
        content: post.content,
        authorName: post.authorName,
        authorAvatar: post.authorAvatar,
        likes: isLiked ? post.likes + 1 : post.likes - 1,
        comments: post.comments,
        isLiked: isLiked,
        isRecommended: post.isRecommended,
        isTrending: post.isTrending,
        relevantWeek: post.relevantWeek,
        createdAt: post.createdAt,
        tags: post.tags,
      );
    }

    // Update in trending posts
    final trendingIndex = _trendingPosts.indexWhere((p) => p.id == postId);
    if (trendingIndex != -1) {
      final post = _trendingPosts[trendingIndex];
      _trendingPosts[trendingIndex] = SmartPostModel(
        id: post.id,
        title: post.title,
        content: post.content,
        authorName: post.authorName,
        authorAvatar: post.authorAvatar,
        likes: isLiked ? post.likes + 1 : post.likes - 1,
        comments: post.comments,
        isLiked: isLiked,
        isRecommended: post.isRecommended,
        isTrending: post.isTrending,
        relevantWeek: post.relevantWeek,
        createdAt: post.createdAt,
        tags: post.tags,
      );
    }

    // Update in weekly posts
    final weeklyIndex = _weeklyPosts.indexWhere((p) => p.id == postId);
    if (weeklyIndex != -1) {
      final post = _weeklyPosts[weeklyIndex];
      _weeklyPosts[weeklyIndex] = SmartPostModel(
        id: post.id,
        title: post.title,
        content: post.content,
        authorName: post.authorName,
        authorAvatar: post.authorAvatar,
        likes: isLiked ? post.likes + 1 : post.likes - 1,
        comments: post.comments,
        isLiked: isLiked,
        isRecommended: post.isRecommended,
        isTrending: post.isTrending,
        relevantWeek: post.relevantWeek,
        createdAt: post.createdAt,
        tags: post.tags,
      );
    }
  }
}
