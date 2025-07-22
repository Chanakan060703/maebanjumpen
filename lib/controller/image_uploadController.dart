// lib/services/image_upload_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:maebanjumpen/constant/constant_value.dart';

class ImageUploadService {
  static const String _baseUrl = baseURL;

  Future<String?> uploadImage({
    required int id,
    required String imageType, // 'person', 'housekeeper', 'hire'
    required XFile imageFile,
  }) async {
    String endpoint;
    String folderName; // ชื่อคีย์ใน JSON response ที่ Backend คาดหวังว่าเป็น URL ของรูปภาพ

    switch (imageType) {
      case 'person':
        endpoint = '/maeban/files/upload/person/profile-picture/$id';
        folderName = 'pictureUrl'; // สมมติว่า Backend คืนค่า URL ในคีย์นี้
        break;
      case 'housekeeper':
        endpoint = '/maeban/files/upload/housekeeper/verify-photo/$id';
        folderName = 'photoVerifyUrl'; // สมมติว่า Backend คืนค่า URL ในคีย์นี้
        break;
      case 'hire':
        endpoint = '/maeban/files/upload/hire/progression-image/$id';
        folderName = 'progressionImageUrl'; // สมมติว่า Backend คืนค่า URL ในคีย์นี้
        break;
      default:
        print('Error: Invalid imageType provided.');
        return null;
    }

    final uri = Uri.parse('$_baseUrl$endpoint');

    var request = http.MultipartRequest('POST', uri);
    request.files.add(
      await http.MultipartFile.fromPath(
        'file', // ชื่อ field ที่ Backend คาดหวัง (@RequestParam("file") MultipartFile file)
        imageFile.path,
      ),
    );

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseBody);
        print('Image upload successful: $jsonResponse');
        // คืนค่า URL ของรูปภาพที่ Backend ส่งกลับมา
        return jsonResponse[folderName];
      } else {
        final errorBody = await response.stream.bytesToString();
        print('Image upload failed with status: ${response.statusCode}');
        print('Error response: $errorBody');
        return null;
      }
    } catch (e) {
      print('Exception during image upload: $e');
      return null;
    }
  }
}