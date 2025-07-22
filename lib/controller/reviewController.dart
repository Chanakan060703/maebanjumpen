// src/main/java/com/itsci/mju/maebanjumpen.controller/Reviewcontroller.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maebanjumpen/constant/constant_value.dart';
import 'package:maebanjumpen/model/review.dart'; // ตรวจสอบให้แน่ใจว่า import ถูกต้อง

  class Reviewcontroller {
  Future<Map<String, dynamic>> addReview({
    required String reviewMessage,
    required String reviewDate,
    required int score,
    required int hireId,
  }) async {
    final url = Uri.parse('$baseURL/maeban/reviews');

    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'reviewMessage': reviewMessage,
          'reviewDate': reviewDate,
          'score': score,
          'hire': {'hireId': hireId},
        }),
      );

      print('Review API Response Status: ${response.statusCode}');
      print('Review API Response Body: ${response.body}');

      if (response.statusCode == 201) {
        // หากสร้างรีวิวสำเร็จ (HTTP 201 Created)
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        return responseBody;
      } else if (response.statusCode == 409) { // จัดการกับ 409 Conflict โดยเฉพาะ
        Map<String, dynamic> errorBody = {};
        try {
          errorBody = jsonDecode(response.body);
        } catch (_) {
          // หาก body ไม่ใช่ JSON ที่ถูกต้อง
          errorBody['message'] = 'Conflict: ${response.body}';
        }
        return {
          'error': 'Conflict',
          'message': errorBody['message'] ?? 'งานนี้ถูกรีวิวไปแล้ว', // ใช้ข้อความจาก Backend หากมี
          'statusCode': response.statusCode, // ส่ง status code กลับไปด้วยเพื่อการจัดการที่ง่ายขึ้น
        };
      } else {
        // จัดการกับสถานะ Error อื่นๆ
        Map<String, dynamic> errorBody = {};
        try {
          errorBody = jsonDecode(response.body);
        } catch (_) {
          errorBody['message'] = response.body;
        }
        return {
          'error': 'Failed to submit review',
          'message': 'สถานะ: ${response.statusCode}, ข้อความ: ${errorBody['message'] ?? 'เกิดข้อผิดพลาดไม่ทราบสาเหตุ'}',
          'statusCode': response.statusCode, // ส่ง status code กลับไปด้วย
        };
      }
    } catch (e) {
      print('Error calling addReview API: $e');
      return {
        'error': 'Exception during API call',
        'message': e.toString(),
        'statusCode': 0, // ระบุว่าเป็นการยกเว้นฝั่ง client
      };
    }
  }

  // เมธอดสำหรับดึงรีวิวทั้งหมด
  Future<List<Review>?> getAllReviews() async {
    final url = Uri.parse('$baseURL/reviews'); // ใช้ baseURL ที่กำหนดไว้ใน constant_value.dart

    try {
      final response = await http.get(url, headers: headers);

      print('Get All Reviews API Response Status: ${response.statusCode}');
      print('Get All Reviews API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // แปลง JSON string เป็น List ของ Review objects
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Review.fromJson(json)).toList();
      } else {
        print('Failed to fetch reviews. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error calling getAllReviews API: $e');
      return null;
    }
  }
  // เมธอดสำหรับดึงรีวิวตาม hireId
  Future<List<Review>?> getReviewsByHireId(int hireId) async {
    final url = Uri.parse('$baseURL/reviews/hire/$hireId'); // ใช้ baseURL ที่กำหนดไว้ใน constant_value.dart

    try {
      final response = await http.get(url, headers: headers);

      print('Get Reviews by Hire ID API Response Status: ${response.statusCode}');
      print('Get Reviews by Hire ID API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // แปลง JSON string เป็น List ของ Review objects
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Review.fromJson(json)).toList();
      } else {
        print('Failed to fetch reviews for hire ID $hireId. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error calling getReviewsByHireId API: $e');
      return null;
    }
  }
  // เมธอดสำหรับอัปเดตรีวิว
  Future<Map<String, dynamic>> updateReview({
    required int reviewId,
    required String reviewMessage,
    required String reviewDate,
    required int score,
  }) async {
    final url = Uri.parse('$baseURL/reviews/$reviewId'); // ใช้ baseURL ที่กำหนดไว้ใน constant_value.dart

    try {
      final response = await http.put(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'reviewMessage': reviewMessage,
          'reviewDate': reviewDate,
          'score': score,
        }),
      );

      print('Update Review API Response Status: ${response.statusCode}');
      print('Update Review API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // หากอัปเดตรีวิวสำเร็จ (HTTP 200 OK)
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        return responseBody; // คืนค่า Map กลับไป
      } else {
        // หากเกิดข้อผิดพลาด
        return {
          'error': 'Failed to update review',
          'message': 'Status code: ${response.statusCode}, Body: ${response.body}',
        };
      }
    } catch (e) {
      // ดักจับข้อผิดพลาดในการเชื่อมต่อหรือประมวลผล
      print('Error calling updateReview API: $e');
      return {
        'error': 'Exception during API call',
        'message': e.toString(),
      };
    }
  }
  // เมธอดสำหรับลบรีวิว
  Future<Map<String, dynamic>> deleteReview(int reviewId) async {
    final url = Uri.parse('$baseURL/reviews/$reviewId'); // ใช้ baseURL ที่กำหนดไว้ใน constant_value.dart

    try {
      final response = await http.delete(url, headers: headers);

      print('Delete Review API Response Status: ${response.statusCode}');
      print('Delete Review API Response Body: ${response.body}');

      if (response.statusCode == 204) {
        // หากลบรีวิวสำเร็จ (HTTP 204 No Content)
        return {'message': 'Review deleted successfully'};
      } else {
        // หากเกิดข้อผิดพลาด
        return {
          'error': 'Failed to delete review',
          'message': 'Status code: ${response.statusCode}, Body: ${response.body}',
        };
      }
    } catch (e) {
      // ดักจับข้อผิดพลาดในการเชื่อมต่อหรือประมวลผล
      print('Error calling deleteReview API: $e');
      return {
        'error': 'Exception during API call',
        'message': e.toString(),
      };
    }
  }
  // เมธอดสำหรับดึงรีวิวตาม ID
  Future<Review?> getReviewById(int reviewId) async {
    final url = Uri.parse('$baseURL/reviews/$reviewId'); // ใช้ baseURL ที่กำหนดไว้ใน constant_value.dart

    try {
      final response = await http.get(url, headers: headers);

      print('Get Review by ID API Response Status: ${response.statusCode}');
      print('Get Review by ID API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // แปลง JSON string เป็น Review object
        return Review.fromJson(jsonDecode(response.body));
      } else {
        print('Failed to fetch review by ID $reviewId. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error calling getReviewById API: $e');
      return null;
    }
  }
  // เมธอดสำหรับดึงรีวิวตาม hireId และ score
  Future<List<Review>?> getReviewsByHireIdAndScore(int hireId, int score) async {
    final url = Uri.parse('$baseURL/reviews/hire/$hireId/score/$score'); // ใช้ baseURL ที่กำหนดไว้ใน constant_value.dart

    try {
      final response = await http.get(url, headers: headers);

      print('Get Reviews by Hire ID and Score API Response Status: ${response.statusCode}');
      print('Get Reviews by Hire ID and Score API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // แปลง JSON string เป็น List ของ Review objects
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Review.fromJson(json)).toList();
      } else {
        print('Failed to fetch reviews for hire ID $hireId with score $score. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error calling getReviewsByHireIdAndScore API: $e');
      return null;
    }
  }
  // เมธอดสำหรับดึงรีวิวตาม hireId และ reviewDate
  Future<List<Review>?> getReviewsByHireIdAndDate(int hireId, String reviewDate) async {
    final url = Uri.parse('$baseURL/reviews/hire/$hireId/date/$reviewDate'); // ใช้ baseURL ที่กำหนดไว้ใน constant_value.dart

    try {
      final response = await http.get(url, headers: headers);

      print('Get Reviews by Hire ID and Date API Response Status: ${response.statusCode}');
      print('Get Reviews by Hire ID and Date API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // แปลง JSON string เป็น List ของ Review objects
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Review.fromJson(json)).toList();
      } else {
        print('Failed to fetch reviews for hire ID $hireId on date $reviewDate. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error calling getReviewsByHireIdAndDate API: $e');
      return null;
    }
  }
  // เมธอดสำหรับดึงรีวิวตาม hireId และ reviewMessage
  
}

