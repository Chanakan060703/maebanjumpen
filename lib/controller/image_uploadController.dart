import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:maebanjumpen/constant/constant_value.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ImageUploadService {
  static const String _baseUrl = baseURL;

  /// อัปโหลดรูปภาพเดียวไปยัง API
  Future<String?> uploadImage({
    required int id,
    required String imageType,
    required XFile imageFile,
  }) async {
    String endpoint;
    String folderName; // ตัวแปรสำหรับคีย์ใน JSON response

    switch (imageType) {
      case 'person':
        endpoint = '/maeban/files/upload/person/profile-picture/$id';
        folderName = 'pictureUrl';
        break;
      case 'housekeeper':
        endpoint = '/maeban/files/upload/housekeeper/verify-photo/$id';
        folderName = 'photoVerifyUrl';
        break;
      case 'hire':
        // การอัปโหลดรูปภาพความคืบหน้าของงานควรใช้เมธอด uploadImages แทน
        print('Warning: For "hire" imageType, please use the uploadImages method.');
        return null;
      default:
        print('Error: Invalid imageType provided.');
        return null;
    }

    final uri = Uri.parse('$_baseUrl$endpoint');
    var request = http.MultipartRequest('POST', uri);

    if (kIsWeb) {
      final bytes = await imageFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: imageFile.name,
      ));
    } else {
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        filename: imageFile.name,
      ));
    }

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseBody);
        print('Image upload successful: $jsonResponse');
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

  /// อัปโหลดรูปภาพหลายรูปไปยัง API สำหรับภาพความคืบหน้าของงาน
  Future<List<String>?> uploadImages({
    required int id,
    required List<XFile> imageFiles,
  }) async {
    if (imageFiles.isEmpty) return [];

    try {
      final uri = Uri.parse('$_baseUrl/maeban/files/upload/hire/progression-images/$id');
      var request = http.MultipartRequest('POST', uri);

      for (var file in imageFiles) {
        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes(
            'files', // แก้ไข: ใช้ 'files' ตามแบ็กเอนด์
            await file.readAsBytes(),
            filename: file.name,
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'files', // แก้ไข: ใช้ 'files' ตามแบ็กเอนด์
            file.path,
            filename: file.name,
          ));
        }
      }

      var response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(respStr);
        
        // แก้ไข: ใช้คีย์ที่ถูกต้องตาม JSON response จากแบ็กเอนด์
        if (jsonResponse.containsKey('progressionImageUrls') &&
            jsonResponse['progressionImageUrls'] is List) {
          return List<String>.from(jsonResponse['progressionImageUrls']);
        }
      } else {
        final errorBody = await response.stream.bytesToString();
        print('Image upload failed with status: ${response.statusCode}');
        print('Error response: $errorBody');
        return null;
      }
    } catch (e) {
      print('Error during image upload: $e');
      return null;
    }

    return null;
  }
}