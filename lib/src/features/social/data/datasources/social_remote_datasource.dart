import 'dart:convert';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/custom_http_client.dart';
import '../../domain/entities/social_entities.dart';

class SocialRemoteDatasource {
  final CustomHttpClient _client;

  SocialRemoteDatasource(this._client);

  Future<List<Friend>> getFriends({required String token}) async {
    final response = await _client.get(ApiConstants.friendshipsEndpoint, token: token);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.map((j) => Friend.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('Error cargando amigos: ${response.statusCode}');
  }

  Future<List<UserSearchResult>> searchUsers({
    required String query,
    required String token,
  }) async {
    final endpoint = '${ApiConstants.friendshipsSearchEndpoint}?q=${Uri.encodeComponent(query)}';
    final response = await _client.get(endpoint, token: token);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.map((j) => UserSearchResult.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('Error buscando usuarios: ${response.statusCode}');
  }

  Future<Friend> sendFriendRequest({
    required String targetUserId,
    required String token,
  }) async {
    final response = await _client.post(
      ApiConstants.friendshipsEndpoint,
      body: {'targetUserId': targetUserId},
      token: token,
    );
    if (response.statusCode == 200) {
      return Friend.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Error enviando solicitud: ${response.statusCode}');
  }

  Future<Friend> acceptFriendRequest({
    required String friendshipId,
    required String token,
  }) async {
    final response = await _client.post(
      ApiConstants.acceptFriendByIdEndpoint(friendshipId),
      body: {},
      token: token,
    );
    if (response.statusCode == 200) {
      return Friend.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Error aceptando solicitud: ${response.statusCode}');
  }

  Future<void> rejectFriendRequest({
    required String friendshipId,
    required String token,
  }) async {
    final response = await _client.post(
      ApiConstants.rejectFriendByIdEndpoint(friendshipId),
      body: {},
      token: token,
    );
    if (response.statusCode != 204) {
      throw Exception('Error rechazando solicitud: ${response.statusCode}');
    }
  }

  Future<void> removeFriend({
    required String friendshipId,
    required String token,
  }) async {
    final response = await _client.delete(
      ApiConstants.removeFriendByIdEndpoint(friendshipId),
      token: token,
    );
    if (response.statusCode != 204) {
      throw Exception('Error eliminando amigo: ${response.statusCode}');
    }
  }

  Future<FriendDetail> getFriendDetail({
    required String friendId,
    required String token,
  }) async {
    final response = await _client.get(
      ApiConstants.friendHabitsEndpoint(friendId),
      token: token,
    );
    if (response.statusCode == 200) {
      return FriendDetail.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Error cargando detalle: ${response.statusCode}');
  }

  Future<bool> nudgeFriend({
    required String friendId,
    required String token,
  }) async {
    final response = await _client.post(
      ApiConstants.nudgeFriendEndpoint(friendId),
      body: {},
      token: token,
    );
    return response.statusCode == 200;
  }

  Future<List<RankingEntry>> getRankings({required String token}) async {
    final response = await _client.get(ApiConstants.rankingsEndpoint, token: token);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.map((j) => RankingEntry.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('Error cargando ranking: ${response.statusCode}');
  }

  Future<List<SocialChallenge>> getChallenges({required String token}) async {
    final response = await _client.get(ApiConstants.challengesEndpoint, token: token);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.map((j) => SocialChallenge.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('Error cargando retos: ${response.statusCode}');
  }

  Future<SocialChallenge> joinChallenge({
    required String challengeId,
    required String token,
    String? joinCode,
  }) async {
    final response = await _client.post(
      ApiConstants.joinChallengeEndpoint(challengeId),
      body: joinCode != null ? {'joinCode': joinCode} : {},
      token: token,
    );
    if (response.statusCode == 200) {
      return SocialChallenge.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Error uniéndose al reto: ${response.statusCode}');
  }
}
