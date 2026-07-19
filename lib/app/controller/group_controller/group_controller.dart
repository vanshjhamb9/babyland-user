import 'package:flutter/material.dart';
import '../../data/repository/repository.dart';
import '../../widgets/app_popup.dart';
import '../pregnancy_flow/model/communities_data_model.dart';
import 'model/group_model.dart';
import '../../../main.dart'; // for repository singleton if needed

class GroupController extends ChangeNotifier {
  final Repository _repository = repository;

  // --- State Variables ---
  
  // Groups Main List
  List<GroupModel> _groups = [];
  List<GroupModel> get groups => _groups;
  
  bool _isLoadingGroups = false;
  bool get isLoadingGroups => _isLoadingGroups;
  
  String? _groupsError;
  String? get groupsError => _groupsError;

  // Group Posts
  List<PostData> _groupPosts = [];
  List<PostData> get groupPosts => _groupPosts;
  
  bool _isLoadingPosts = false;
  bool get isLoadingPosts => _isLoadingPosts;

  String? _postsError;
  String? get postsError => _postsError;

  // Saved Posts
  List<PostData> _savedPosts = [];
  List<PostData> get savedPosts => _savedPosts;
  
  bool _isLoadingSaved = false;
  bool get isLoadingSaved => _isLoadingSaved;

  final TextEditingController createPostController = TextEditingController();

  // --- Methods ---

  Future<void> fetchMyGroups() async {
    _isLoadingGroups = true;
    _groupsError = null;
    notifyListeners();

    try {
      final res = await _repository.getMyGroups();
      if (res.success == true && res.data != null) {
        _groups = res.data!;
      } else {
        _groupsError = res.message ?? "Failed to load groups";
      }
    } catch (e) {
      _groupsError = "Something went wrong. Please try again.";
    }

    _isLoadingGroups = false;
    notifyListeners();
  }

  Future<void> fetchGroupPosts(String groupId) async {
    _isLoadingPosts = true;
    _postsError = null;
    notifyListeners();

    try {
      final res = await _repository.getGroupPosts(groupId);
      if (res.success == true && res.data?.posts != null) {
        _groupPosts = res.data!.posts!;
      } else {
        _postsError = res.message ?? "Failed to load posts";
      }
    } catch (e) {
      _postsError = "Something went wrong. Please try again.";
    }

    _isLoadingPosts = false;
    notifyListeners();
  }

  // To prevent duplicate likes/saves
  final Set<String> _processingPosts = {};

  Future<void> createGroupPost(String groupId, String message) async {
    try {
      final data = {
        "groupId": groupId,
        "message": message,
      };
      
      final res = await _repository.createGroupPost(data);
      if (res.success == true) {
        AppPopUp.showToast(message: res.message ?? "Post created safely.");
        await fetchGroupPosts(groupId); 
      } else {
        AppPopUp.showToast(message: res.message ?? "Failed to create post.");
      }
    } catch (e) {
      AppPopUp.showToast(message: "Something went wrong.");
    }
  }

  Future<void> toggleLike(String postId, String? myUserId, {String? groupId, bool isSavedScreen = false}) async {
    if (myUserId == null || myUserId.isEmpty) return;
    if (_processingPosts.contains('like_$postId')) return;
    
    _processingPosts.add('like_$postId');

    // Optimistic Update
    bool wasLiked = false;
    final List<PostData> targetList = isSavedScreen ? _savedPosts : _groupPosts;
    final int index = targetList.indexWhere((p) => p.sId == postId);
    
    if (index != -1) {
      final post = targetList[index];
      wasLiked = _isLikedInternally(post, myUserId);
      if (wasLiked) {
        post.likes?.removeWhere((id) {
          if (id is Map) return id['_id'] == myUserId || id['userId'] == myUserId;
          return id == myUserId;
        });
      } else {
        post.likes ??= [];
        post.likes!.add(myUserId);
      }
      notifyListeners();
    }

    try {
      final res = await _repository.likeGroupPost(postId);
      if (res.success != true) {
        // Revert Optimistic Update
        _revertLike(index, targetList, myUserId, wasLiked);
        AppPopUp.showToast(message: res.message ?? "Failed to toggle like");
      }
    } catch (e) {
      // Revert Optimistic Update
      _revertLike(index, targetList, myUserId, wasLiked);
      AppPopUp.showToast(message: "Something went wrong.");
    } finally {
      _processingPosts.remove('like_$postId');
    }
  }

  void _revertLike(int index, List<PostData> targetList, String myUserId, bool wasLiked) {
    if (index != -1) {
      final post = targetList[index];
      if (wasLiked) {
        post.likes ??= [];
        post.likes!.add(myUserId);
      } else {
        post.likes?.removeWhere((id) {
          if (id is Map) return id['_id'] == myUserId || id['userId'] == myUserId;
          return id == myUserId;
        });
      }
      notifyListeners();
    }
  }

  bool _isLikedInternally(PostData post, String myUserId) {
    final likes = post.likes;
    if (likes == null || likes.isEmpty) return false;
    for (final e in likes) {
      if (e == myUserId) return true;
      if (e is Map) {
        final id = e['_id']?.toString() ?? e['userId']?.toString();
        if (id == myUserId) return true;
      }
    }
    return false;
  }

  Future<void> addComment(String postId, String comment, String? myUserId, {String? groupId, bool isSavedScreen = false}) async {
    final text = comment.trim();
    if (text.isEmpty || myUserId == null || myUserId.isEmpty) {
      if (text.isEmpty) AppPopUp.showToast(message: 'Please enter a comment.');
      return;
    }
    
    if (_processingPosts.contains('comment_$postId')) return;
    _processingPosts.add('comment_$postId');

    // Optimistic Update
    final List<PostData> targetList = isSavedScreen ? _savedPosts : _groupPosts;
    final int index = targetList.indexWhere((p) => p.sId == postId);
    
    if (index != -1) {
      final post = targetList[index];
      post.comments ??= [];
      post.comments!.add(CommentModel(
        userId: myUserId,
        comment: text,
        createdAt: DateTime.now().toIso8601String(),
        id: "temp_${DateTime.now().millisecondsSinceEpoch}",
      ));
      post.commentsCount = ((int.tryParse(post.commentsCount ?? "0") ?? 0) + 1).toString();
      notifyListeners();
    }

    try {
      final res = await _repository.commentGroupPost(postId, text);
      if (res.success == true) {
        AppPopUp.showToast(message: res.message ?? "Comment added");
      } else {
        _revertComment(index, targetList);
        AppPopUp.showToast(message: res.message ?? "Failed to add comment.");
      }
    } catch (e) {
      _revertComment(index, targetList);
      AppPopUp.showToast(message: "Something went wrong.");
    } finally {
      _processingPosts.remove('comment_$postId');
    }
  }

  void _revertComment(int index, List<PostData> targetList) {
    if (index != -1) {
      final post = targetList[index];
      if (post.comments != null && post.comments!.isNotEmpty) {
        post.comments!.removeLast();
        post.commentsCount = ((int.tryParse(post.commentsCount ?? "0") ?? 0) - 1).toString();
        if (int.parse(post.commentsCount!) < 0) post.commentsCount = '0';
      }
      notifyListeners();
    }
  }

  // Main local Set to track saved posts across the app
  final Set<String> _localSavedPostIds = {};
  bool isPostSavedLocally(String postId) => _localSavedPostIds.contains(postId);

  Future<void> toggleSave(String postId, {String? groupId, bool isSavedScreen = false}) async {
    if (_processingPosts.contains('save_$postId')) return;
    _processingPosts.add('save_$postId');

    // Optimistic Update
    final bool wasSaved = _localSavedPostIds.contains(postId);
    if (wasSaved) {
      _localSavedPostIds.remove(postId);
      if (isSavedScreen) {
        _savedPosts.removeWhere((p) => p.sId == postId);
      }
    } else {
      _localSavedPostIds.add(postId);
      // We can't immediately add the full post to _savedPosts if we are not on the SavedScreen,
      // but if we are on GroupFeed, just the icon changes.
    }
    notifyListeners();

    try {
      final res = await _repository.saveGroupPost(postId);
      if (res.success != true) {
        // Revert
        if (wasSaved) {
          _localSavedPostIds.add(postId);
          // Re-fetching saved posts if needed since we removed it
          if (isSavedScreen) await fetchSavedPosts();
        } else {
          _localSavedPostIds.remove(postId);
        }
        notifyListeners();
        AppPopUp.showToast(message: res.message ?? "Failed to toggle save");
      } else {
        if (!isSavedScreen && !wasSaved) {
           AppPopUp.showToast(message: "Saved to Profile");
        }
      }
    } catch (e) {
      // Revert
      if (wasSaved) {
        _localSavedPostIds.add(postId);
        if (isSavedScreen) await fetchSavedPosts();
      } else {
        _localSavedPostIds.remove(postId);
      }
      notifyListeners();
      AppPopUp.showToast(message: "Something went wrong.");
    } finally {
      _processingPosts.remove('save_$postId');
    }
  }

  Future<void> fetchSavedPosts() async {
    _isLoadingSaved = true;
    notifyListeners();

    try {
      final res = await _repository.getSavedPosts();
      if (res.success == true && res.data?.posts != null) {
        _savedPosts = res.data!.posts!;
        // Sync local saved ids with backend
        _localSavedPostIds.clear();
        for (var p in _savedPosts) {
          if (p.sId != null) _localSavedPostIds.add(p.sId!);
        }
      }
    } catch (e) {
      // Ignored for now
    }

    _isLoadingSaved = false;
    notifyListeners();
  }
}
