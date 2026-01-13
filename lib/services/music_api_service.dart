import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models.dart';

class MusicApiService {
  static String get apiKey => dotenv.env['MUSIC_API_KEY'] ?? '';
  static String get baseUrl => dotenv.env['MUSIC_API_BASE_URL'] ?? '';
  static bool get useMockData => baseUrl.isEmpty || apiKey.isEmpty;

  // Fetch recently played songs (using Jamendo popular tracks)
  static Future<List<MusicItem>> fetchRecentlyPlayed({int retryCount = 0}) async {
    // Use mock data if API not configured
    if (useMockData) {
      await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
      return _getRecentlyPlayedMockData();
    }

    try {
      // Random offset to get different tracks each time (keep it reasonable to avoid empty results)
      final randomOffset = (DateTime.now().millisecondsSinceEpoch % 20) * 5;
      
      debugPrint('Fetching recently played with offset: $randomOffset (attempt ${retryCount + 1})');
      
      // Jamendo API endpoint for popular tracks (including audio download URL)
      final response = await http.get(
        Uri.parse('$baseUrl/tracks/?client_id=$apiKey&format=json&limit=10&order=popularity_week&audioformat=mp32&offset=$randomOffset'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        
        debugPrint('Recently Played API response: ${results.length} tracks');
        
        if (results.isEmpty) {
          // Retry with offset 0 if random offset returned empty results
          if (retryCount < 2) {
            debugPrint('API returned empty results, retrying with offset 0...');
            await Future.delayed(Duration(milliseconds: 300));
            final retryResponse = await http.get(
              Uri.parse('$baseUrl/tracks/?client_id=$apiKey&format=json&limit=10&order=popularity_week&audioformat=mp32&offset=0'),
            );
            
            if (retryResponse.statusCode == 200) {
              final retryData = json.decode(retryResponse.body);
              final List<dynamic> retryResults = retryData['results'] ?? [];
              
              if (retryResults.isNotEmpty) {
                debugPrint('Retry successful: ${retryResults.length} tracks');
                final List<MusicItem> retryTracks = retryResults.map((item) => MusicItem(
                  item['name'] ?? 'Unknown Track',
                  item['artist_name'] ?? 'Unknown Artist',
                  _getRandomColor(),
                  albumCoverUrl: item['album_image'] ?? item['image'],
                  audioUrl: item['audio'] ?? item['audiodownload'],
                )).toList();
                return retryTracks;
              }
            }
          }
          
          debugPrint('Still empty after retry, using mock data');
          return _getRecentlyPlayedMockData();
        }
        
        final List<MusicItem> tracks = results.map((item) => MusicItem(
          item['name'] ?? 'Unknown Track',
          item['artist_name'] ?? 'Unknown Artist',
          _getRandomColor(),
          albumCoverUrl: item['album_image'] ?? item['image'],
          audioUrl: item['audio'] ?? item['audiodownload'],
        )).toList();
        
        debugPrint('Successfully parsed ${tracks.length} recently played tracks');
        return tracks;
      } else {
        debugPrint('API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load songs: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('API error for recently played: $e');
      debugPrint('Falling back to mock data');
      return _getRecentlyPlayedMockData();
    }
  }

  // Fetch recommended songs (using Jamendo featured tracks)
  static Future<List<MusicItem>> fetchRecommendations({int retryCount = 0}) async {
    // Use mock data if API not configured
    if (useMockData) {
      await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
      return _getRecommendationsMockData();
    }

    try {
      // Random offset to get different tracks each time (keep it reasonable to avoid empty results)
      final randomOffset = (DateTime.now().millisecondsSinceEpoch % 30) * 5;
      
      debugPrint('Fetching recommendations with offset: $randomOffset (attempt ${retryCount + 1})');
      
      // Jamendo API endpoint for featured tracks (including audio download URL)
      final response = await http.get(
        Uri.parse('$baseUrl/tracks/?client_id=$apiKey&format=json&limit=10&featured=1&audioformat=mp32&offset=$randomOffset'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        
        debugPrint('Recommendations API response: ${results.length} tracks');
        
        if (results.isEmpty) {
          // Retry with offset 0 if random offset returned empty results
          if (retryCount < 2) {
            debugPrint('API returned empty results, retrying with offset 0...');
            await Future.delayed(Duration(milliseconds: 300));
            final retryResponse = await http.get(
              Uri.parse('$baseUrl/tracks/?client_id=$apiKey&format=json&limit=10&featured=1&audioformat=mp32&offset=0'),
            );
            
            if (retryResponse.statusCode == 200) {
              final retryData = json.decode(retryResponse.body);
              final List<dynamic> retryResults = retryData['results'] ?? [];
              
              if (retryResults.isNotEmpty) {
                debugPrint('Retry successful: ${retryResults.length} tracks');
                final List<MusicItem> retryTracks = retryResults.map((item) => MusicItem(
                  item['name'] ?? 'Unknown Track',
                  item['artist_name'] ?? 'Unknown Artist',
                  _getRandomColor(),
                  albumCoverUrl: item['album_image'] ?? item['image'],
                  audioUrl: item['audio'] ?? item['audiodownload'],
                )).toList();
                return retryTracks;
              }
            }
          }
          
          debugPrint('Still empty after retry, using mock data');
          return _getRecommendationsMockData();
        }
        
        final List<MusicItem> tracks = results.map((item) => MusicItem(
          item['name'] ?? 'Unknown Track',
          item['artist_name'] ?? 'Unknown Artist',
          _getRandomColor(),
          albumCoverUrl: item['album_image'] ?? item['image'],
          audioUrl: item['audio'] ?? item['audiodownload'],
        )).toList();
        
        debugPrint('Successfully parsed ${tracks.length} recommendation tracks');
        return tracks;
      } else {
        debugPrint('API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load recommendations: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('API error for recommendations: $e');
      debugPrint('Falling back to mock data');
      return _getRecommendationsMockData();
    }
  }

  // Helper method to generate random colors for tracks without images
  static Color _getRandomColor() {
    final colors = [
      const Color(0xFF4A3A5A),
      const Color(0xFF3A4A5A),
      const Color(0xFF5A3A4A),
      const Color(0xFF2A3A5A),
      const Color.fromARGB(255, 188, 160, 193),
    ];
    return colors[(DateTime.now().millisecondsSinceEpoch % colors.length)];
  }

  // Search songs by query
  static Future<List<MusicItem>> searchSongs(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/songs/search?q=$query'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => MusicItem.fromJson(item)).toList();
      } else {
        throw Exception('Failed to search songs: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error searching songs: $e');
      return [];
    }
  }

  // Fetch album details
  static Future<Map<String, dynamic>> fetchAlbumDetails(String albumId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/albums/$albumId'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load album: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching album: $e');
      return {};
    }
  }

  // Mock data for recently played
  static List<MusicItem> _getRecentlyPlayedMockData() {
    return [
      MusicItem('Designant.', '乗るるが無い', const Color.fromARGB(255, 188, 160, 193)),
      MusicItem('Synthesis', 'tn-shi', const Color(0xFF4A3A5A)),
      MusicItem('かなしばり...', 'あばうや', const Color(0xFF3A4A5A)),
      MusicItem('enchant', 'linear ring', const Color(0xFF5A3A4A)),
      MusicItem('Stellar', 'HOYO-MIX', const Color(0xFF2A3A5A)),
    ];
  }

  // Mock data for recommendations
  static List<MusicItem> _getRecommendationsMockData() {
    return [
      MusicItem('シンクロニカ', '桜マグネタイト', const Color(0xFFFF69B4)),
      MusicItem('Laur', 'Sound Chimera', const Color(0xFFFFD700)),
      MusicItem('Anomaly', 'TOGENASHI TOGEARI', const Color(0xFF32CD32)),
      MusicItem('Night Runner', 'Stellarium', const Color(0xFF9370DB)),
      MusicItem('Midnight City', 'Urban Echo', const Color(0xFF1E90FF)),
    ];
  }
}
