import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // The Master Submission Sequence
  Future<void> submitReport({
    required int categoryId,
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    required String landmark,
    required Uint8List imageBytes, // Using bytes ensures it works on Web and Mobile
    required String fileName,
  }) async {
    final userId = _supabase.auth.currentUser!.id;

    // 1. Fetch the default priority for the chosen category
    final categoryResponse = await _supabase
        .from('categories')
        .select('default_priority')
        .eq('id', categoryId)
        .single();

    final int defaultPriority = categoryResponse['default_priority'] ?? 2; // Fallback to 2 if missing

    // 2. Upload photo and get URL
    final imagePath = '$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _supabase.storage.from('issue-images').uploadBinary(imagePath, imageBytes);
    final imageUrl = _supabase.storage.from('issue-images').getPublicUrl(imagePath);

    // STEP 3: Insert into Reports table using the DYNAMIC priority
    final reportResponse = await _supabase.from('reports').insert({
      'user_id': userId,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'priority_level': defaultPriority,
    }).select('id').single();

    final reportId = reportResponse['id'];

    // STEP 4: Insert coordinates into Locations table
    await _supabase.from('locations').insert({
      'report_id': reportId,
      'latitude': latitude,
      'longitude': longitude,
      'landmark_details': landmark,
    });

    // STEP 5: Insert image URL into Media table
    await _supabase.from('media').insert({
      'report_id': reportId,
      'url': imageUrl,
      'media_type': 'image',
    });
  }
}