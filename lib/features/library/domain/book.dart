import 'package:flutter/material.dart';

class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.genre,
    required this.coverColor,
    required this.accentColor,
    required this.progress,
    this.coverUrl,
    this.description,
    this.rating = 0,
    this.reviewCount = 0,
  });
  final String id;
  final String title;
  final String author;
  final String genre;
  final Color coverColor;
  final Color accentColor;
  final double progress;
  final String? coverUrl;
  final String? description;
  final double rating;
  final int reviewCount;
}
