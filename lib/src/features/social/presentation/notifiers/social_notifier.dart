import 'package:flutter/foundation.dart';
import '../../../../core/services/session_token_service.dart';
import '../../data/datasources/social_remote_datasource.dart';
import '../../domain/entities/social_entities.dart';

enum SocialLoadingState { idle, loading, success, error }

class SocialNotifier extends ChangeNotifier {
  final SocialRemoteDatasource _datasource;
  final SessionTokenService _tokenService;

  SocialNotifier({
    required SocialRemoteDatasource datasource,
    required SessionTokenService tokenService,
  })  : _datasource = datasource,
        _tokenService = tokenService;

  // ---- Rankings ----
  SocialLoadingState _rankingsState = SocialLoadingState.idle;
  List<RankingEntry> _rankings = [];
  SocialLoadingState get rankingsState => _rankingsState;
  List<RankingEntry> get rankings => _rankings;

  // ---- Friends ----
  SocialLoadingState _friendsState = SocialLoadingState.idle;
  List<Friend> _friends = [];
  SocialLoadingState get friendsState => _friendsState;
  List<Friend> get friends => _friends;
  List<Friend> get acceptedFriends => _friends.where((f) => f.isAccepted).toList();
  List<Friend> get pendingFriends => _friends.where((f) => f.isPending).toList();

  // ---- Challenges ----
  SocialLoadingState _challengesState = SocialLoadingState.idle;
  List<SocialChallenge> _challenges = [];
  SocialLoadingState get challengesState => _challengesState;
  List<SocialChallenge> get challenges => _challenges;

  // ---- Search ----
  List<UserSearchResult> _searchResults = [];
  bool _isSearching = false;
  List<UserSearchResult> get searchResults => _searchResults;
  bool get isSearching => _isSearching;

  Future<String?> _getToken() => _tokenService.getValidAccessToken();

  Future<void> loadRankings() async {
    _rankingsState = SocialLoadingState.loading;
    notifyListeners();
    try {
      final token = await _getToken();
      if (token == null) {
        _rankingsState = SocialLoadingState.error;
        notifyListeners();
        return;
      }
      _rankings = await _datasource.getRankings(token: token);
      _rankingsState = SocialLoadingState.success;
    } catch (_) {
      _rankingsState = SocialLoadingState.error;
    }
    notifyListeners();
  }

  Future<void> loadFriends() async {
    _friendsState = SocialLoadingState.loading;
    notifyListeners();
    try {
      final token = await _getToken();
      if (token == null) {
        _friendsState = SocialLoadingState.error;
        notifyListeners();
        return;
      }
      _friends = await _datasource.getFriends(token: token);
      _friendsState = SocialLoadingState.success;
    } catch (_) {
      _friendsState = SocialLoadingState.error;
    }
    notifyListeners();
  }

  Future<void> loadChallenges() async {
    _challengesState = SocialLoadingState.loading;
    notifyListeners();
    try {
      final token = await _getToken();
      if (token == null) {
        _challengesState = SocialLoadingState.error;
        notifyListeners();
        return;
      }
      _challenges = await _datasource.getChallenges(token: token);
      _challengesState = SocialLoadingState.success;
    } catch (_) {
      _challengesState = SocialLoadingState.error;
    }
    notifyListeners();
  }

  Future<void> searchUsers(String query) async {
    if (query.trim().length < 2) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _isSearching = true;
    notifyListeners();
    try {
      final token = await _getToken();
      if (token == null) return;
      _searchResults = await _datasource.searchUsers(query: query.trim(), token: token);
    } catch (_) {
      _searchResults = [];
    }
    _isSearching = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }

  Future<bool> sendFriendRequest(String targetUserId) async {
    try {
      final token = await _getToken();
      if (token == null) return false;
      final newFriend = await _datasource.sendFriendRequest(targetUserId: targetUserId, token: token);
      _friends.add(newFriend);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> acceptFriendRequest(String friendshipId) async {
    try {
      final token = await _getToken();
      if (token == null) return false;
      final updated = await _datasource.acceptFriendRequest(friendshipId: friendshipId, token: token);
      final idx = _friends.indexWhere((f) => f.friendshipId == friendshipId);
      if (idx >= 0) _friends[idx] = updated;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rejectFriendRequest(String friendshipId) async {
    try {
      final token = await _getToken();
      if (token == null) return false;
      await _datasource.rejectFriendRequest(friendshipId: friendshipId, token: token);
      _friends.removeWhere((f) => f.friendshipId == friendshipId);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeFriend(String friendshipId) async {
    try {
      final token = await _getToken();
      if (token == null) return false;
      await _datasource.removeFriend(friendshipId: friendshipId, token: token);
      _friends.removeWhere((f) => f.friendshipId == friendshipId);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<FriendDetail?> getFriendDetail(String friendId) async {
    try {
      final token = await _getToken();
      if (token == null) return null;
      return await _datasource.getFriendDetail(friendId: friendId, token: token);
    } catch (_) {
      return null;
    }
  }

  Future<bool> nudgeFriend(String friendId) async {
    try {
      final token = await _getToken();
      if (token == null) return false;
      return await _datasource.nudgeFriend(friendId: friendId, token: token);
    } catch (_) {
      return false;
    }
  }

  Future<bool> joinChallenge(String challengeId, {String? joinCode}) async {
    try {
      final token = await _getToken();
      if (token == null) return false;
      final updated = await _datasource.joinChallenge(
        challengeId: challengeId,
        token: token,
        joinCode: joinCode,
      );
      final idx = _challenges.indexWhere((c) => c.id == challengeId);
      if (idx >= 0) _challenges[idx] = updated;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
