import 'package:flutter/material.dart';

// Data Models used across pages
class MusicItem {
  final String title;
  final String artist;
  final Color color;
  final String? albumCoverUrl;
  final String? albumName;
  final String? id;
  final String? audioUrl;

  MusicItem(
    this.title, 
    this.artist, 
    this.color, {
    this.albumCoverUrl,
    this.albumName,
    this.id,
    this.audioUrl,
  });

  // Factory constructor to create MusicItem from API JSON
  factory MusicItem.fromJson(Map<String, dynamic> json) {
    return MusicItem(
      json['title'] ?? json['name'] ?? 'Unknown',
      json['artist'] ?? json['artist_name'] ?? 'Unknown Artist',
      Colors.purple, // Default color, can be randomized
      albumCoverUrl: json['album_cover_url'] ?? json['cover_url'],
      albumName: json['album'] ?? json['album_name'],
      id: json['id']?.toString(),
      audioUrl: json['audio'] ?? json['audio_url'],
    );
  }
}

class Artist {
  final String name;
  final Color color;

  Artist(this.name, this.color);
}

class Friend {
  final String name;
  final String listeningTo;
  final String profilePicture;

  Friend(this.name, this.listeningTo, this.profilePicture);
}

class ChatMessage {
  final String text;
  final bool isBot;
  final List<String>? songs;

  ChatMessage({required this.text, required this.isBot, this.songs});
}
