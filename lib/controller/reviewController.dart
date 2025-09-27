import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maebanjumpen/constant/constant_value.dart';
import 'package:maebanjumpen/controller/hireController.dart';
import 'package:maebanjumpen/controller/housekeeperController.dart';
import 'package:maebanjumpen/model/review.dart'; // ตรวจสอบให้แน่ใจว่า import ถูกต้อง

class Reviewcontroller {
  // ไม่ต้องสร้าง instance ของ HousekeeperController และ Hirecontroller ในที่นี้อีกแล้ว
  // เนื่องจากตรรกะการคำนวณ Rating ย้ายไปอยู่ฝั่ง Server (ReviewService)

  const Reviewcontroller();

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
          // 💡 ใส่ headers ที่จำเป็นอื่นๆ เช่น Authorization หากมี
        },
        // ส่งเฉพาะข้อมูลที่ ReviewDTO ต้องการ
        body: jsonEncode(<String, dynamic>{
          'reviewMessage': reviewMessage,
          'reviewDate': reviewDate,
          'score': score,
          'hireId': hireId, // Spring Boot จะใช้ hireId นี้เพื่อสร้าง Review และอัปเดต Rating
        }),
      );

      print('Review API Response Status: ${response.statusCode}');
      print('Review API Response Body: ${response.body}');

      if (response.statusCode == 201) {
        // หากสร้างรีวิวสำเร็จ (HTTP 201 Created)
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        // 🎯 ตรรกะการคำนวณและอัปเดต Rating ถูกย้ายไปทำใน ReviewService.saveReview() แล้ว
        return responseBody;
      } else if (response.statusCode == 409) {
        // จัดการกับ 409 Conflict: มีการรีวิวงานนี้ไปแล้ว
        Map<String, dynamic> errorBody = {};
        try {
          errorBody = jsonDecode(response.body);
        } catch (_) {
          errorBody['message'] = 'Conflict: ${response.body}';
        }

        return {
          'error': 'Conflict',
          'message': errorBody['message'] ?? 'งานนี้ถูกรีวิวไปแล้ว',
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 404) {
        // จัดการกรณี Hire Not Found (จาก Service)
        return {
          'error': 'Not Found',
          'message': 'ไม่พบรายการจ้างงาน (Hire) ที่ระบุ',
          'statusCode': response.statusCode,
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
          'message':
              'สถานะ: ${response.statusCode}, ข้อความ: ${errorBody['message'] ?? 'เกิดข้อผิดพลาดไม่ทราบสาเหตุ'}',
          'statusCode': response.statusCode,
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
    final url = Uri.parse('$baseURL/maeban/reviews'); // 💡 ใช้ /maeban/reviews
    try {
      final response = await http.get(url, headers: headers);
      print('Get All Reviews API Response Status: ${response.statusCode}');
      print('Get All Reviews API Response Body: ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
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
  // 💡 Note: Endpoint นี้ใน Spring Boot คืนค่า ReviewDTO ตัวเดียว (ไม่ใช่ List)
  Future<Review?> getReviewByHireId(int hireId) async {
    final url = Uri.parse('$baseURL/maeban/reviews/hire/$hireId');
    try {
      final response = await http.get(url, headers: headers);
      print('Get Review by Hire ID API Response Status: ${response.statusCode}');
      print('Get Review by Hire ID API Response Body: ${response.body}');
      if (response.statusCode == 200) {
        return Review.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else if (response.statusCode == 404) {
         print('No review found for hire ID $hireId.');
         return null;
      } else {
        print('Failed to fetch reviews for hire ID $hireId. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error calling getReviewByHireId API: $e');
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
    final url = Uri.parse('$baseURL/maeban/reviews/$reviewId');
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
        // Spring Boot Service จะคำนวณ Rating ใหม่ให้แล้ว
        final Map<String, dynamic> responseBody = jsonDecode(utf8.decode(response.bodyBytes));
        return responseBody;
      } else {
        return {
          'error': 'Failed to update review',
          'message': 'Status code: ${response.statusCode}, Body: ${utf8.decode(response.bodyBytes)}',
        };
      }
    } catch (e) {
      print('Error calling updateReview API: $e');
      return {'error': 'Exception during API call', 'message': e.toString()};
    }
  }

  // เมธอดสำหรับลบรีวิว
  Future<Map<String, dynamic>> deleteReview(int reviewId) async {
    final url = Uri.parse('$baseURL/maeban/reviews/$reviewId');
    try {
      final response = await http.delete(url, headers: headers);
      print('Delete Review API Response Status: ${response.statusCode}');
      print('Delete Review API Response Body: ${response.body}');

      if (response.statusCode == 204) {
        // หากลบรีวิวสำเร็จ (HTTP 204 No Content)
        // Spring Boot Service จะคำนวณ Rating ใหม่ให้แล้ว
        return {'message': 'Review deleted successfully'};
      } else {
        return {
          'error': 'Failed to delete review',
          'message': 'Status code: ${response.statusCode}, Body: ${utf8.decode(response.bodyBytes)}',
        };
      }
    } catch (e) {
      print('Error calling deleteReview API: $e');
      return {'error': 'Exception during API call', 'message': e.toString()};
    }
  }

  // เมธอดสำหรับดึงรีวิวตาม ID
  Future<Review?> getReviewById(int reviewId) async {
    final url = Uri.parse('$baseURL/maeban/reviews/$reviewId');
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        return Review.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        print('Failed to fetch review by ID $reviewId. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error calling getReviewById API: $e');
      return null;
    }
  }
  
  // 💡 Note: เมธอดเหล่านี้อาจไม่มี Endpoint ใน Spring Boot Controller ที่คุณให้มา
  // แต่หากมีใน ReviewService และคุณต้องการใช้ใน Flutter ก็สามารถคงไว้ได้
  
  // เมธอดสำหรับดึงรีวิวตาม hireId และ score
  Future<List<Review>?> getReviewsByHireIdAndScore(int hireId, int score) async {
    final url = Uri.parse('$baseURL/maeban/reviews/hire/$hireId/score/$score');
    // ... (ตรรกะการเรียก API)
    return null; // Placeholder
  }

  // เมธอดสำหรับดึงรีวิวตาม hireId และ reviewDate
  Future<List<Review>?> getReviewsByHireIdAndDate(int hireId, String reviewDate) async {
    final url = Uri.parse('$baseURL/maeban/reviews/hire/$hireId/date/$reviewDate');
    // ... (ตรรกะการเรียก API)
    return null; // Placeholder
  }
}