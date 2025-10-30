import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/restaurant.dart';
import '../models/review.dart';
import '../models/comment.dart';
import '../models/category.dart';
//import '../models/like.dart';

class ApiService {
  //static const String baseUrl = 'http://127.0.0.1:8000/api';
  // static const String storageUrl =
  //     'http://127.0.0.1:8000';
  static const String baseUrl = 'http://172.20.10.10:8000/api';
  static const String storageUrl = 'http://172.20.10.10:8000';

  static String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return ""; // tránh null/empty
    }

    if (path.startsWith("http")) {
      return path;
    }

    if (path.startsWith("/")) {
      return "$storageUrl$path";
    }

    return "$storageUrl/$path";
  }

  // -------------------- TOKEN --------------------
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // -------------------- LOGIN --------------------
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse("$baseUrl/login");
    final response = await http.post(
      url,
      body: {"email": email, "password": password},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = data['token'];
      final userName = data['user']['name'];
      final avatar = data['user']['avatar'] ?? '';
      final userEmail = data['user']['email'] ?? email;
      if (token == null) throw Exception("No token in response");

      await saveToken(token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', userName);
      await prefs.setString('avatar', avatar);
      await prefs.setString('email', userEmail);

      return {
        'success': true,
        'token': token,
        'userName': userName,
        'avatar': avatar,
        'email': userEmail,
      };
    } else {
      return {'success': false};
    }
  }

  // -------------------- REGISTER --------------------
  Future<bool> register(String name, String email, String password) async {
    final url = Uri.parse("$baseUrl/register");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
          "password_confirmation": password,
        }),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        // In lỗi để debug
        print('Register failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Register exception: $e');
      return false;
    }
  }

  // -------------------- REQUESTS --------------------
  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse("$baseUrl/$endpoint");
    final response = await http.get(url);
    print('GET $endpoint (public) response: ${response.statusCode}');
    return response;
  }

  Future<http.Response> getWithToken(String endpoint) async {
    final token = await getToken();
    if (token == null) throw Exception("No token found, login first.");
    final url = Uri.parse("$baseUrl/$endpoint");
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );
    print('GET $endpoint (private) response: ${response.statusCode}');
    return response;
  }

  Future<http.Response> postWithToken(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final token = await getToken();
    if (token == null) throw Exception("No token found, login first.");
    final url = Uri.parse("$baseUrl/$endpoint");
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );
    print('POST $endpoint (private) response: ${response.statusCode}');
    return response;
  }

  // -------------------- RESTAURANTS --------------------
  Future<List<Restaurant>> getRestaurants() async {
    final response = await get("restaurants");
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((e) => Restaurant.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch restaurants: ${response.statusCode}");
    }
  }

  Future<Restaurant> getRestaurantDetail(int id) async {
    final token = await getToken();

    final headers = {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token', // ✅ gửi token nếu có
    };

    final response = await http.get(
      Uri.parse('$baseUrl/restaurants/$id'),
      headers: headers,
    );

    print(
      'GET restaurant/$id response: ${response.statusCode} ${response.body}',
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Restaurant.fromJson(data);
    } else {
      throw Exception(
        'Failed to fetch restaurant detail: ${response.statusCode}',
      );
    }
  }

  // -------------------- REVIEWS --------------------
  Future<Review> addReview({
    required int restaurantId,
    required int rating,
    required String content,
    List<File>? images, // đổi từ List<String> -> List<File>
  }) async {
    final token = await getToken();
    if (token == null) throw Exception("Chưa đăng nhập");

    final uri = Uri.parse('$baseUrl/reviews');
    final request = http.MultipartRequest('POST', uri);

    // Headers
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    // Fields
    request.fields['restaurant_id'] = restaurantId.toString();
    request.fields['rating'] = rating.toString();
    request.fields['content'] = content;

    // Files
    if (images != null && images.isNotEmpty) {
      for (var img in images) {
        request.files.add(
          await http.MultipartFile.fromPath('images[]', img.path),
        );
      }
    }

    // Gửi request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // server trả {"review": {...}} hoặc {...}
      final reviewJson = data['review'] ?? data;
      return Review.fromJson(reviewJson);
    } else {
      throw Exception(
        'Thêm review thất bại: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<List<Review>> getAllReviews() async {
    final token = await getToken();
    final headers = {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final url = Uri.parse('$baseUrl/reviews');
    print('GET $url');

    final response = await http.get(url, headers: headers);
    print('Response ${response.statusCode}: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => Review.fromJson(e)).toList();
    } else {
      throw Exception(
        'Lấy tất cả review thất bại: ${response.statusCode} ${response.body}',
      );
    }
  }

  // ------------------------------
  // 🍽️ Lấy review theo restaurant
  // ------------------------------
  Future<List<Review>> getReviewsByRestaurant(int restaurantId) async {
    final token = await getToken();
    final headers = {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final url = Uri.parse('$baseUrl/reviews/restaurant/$restaurantId');
    print('GET $url');

    final response = await http.get(url, headers: headers);
    print('Response ${response.statusCode}: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => Review.fromJson(e)).toList();
    } else {
      throw Exception(
        'Lấy review theo quán ăn thất bại: ${response.statusCode} ${response.body}',
      );
    }
  }

  // 🧩 Lấy chi tiết 1 review theo ID
  Future<Review> getReviewById(int reviewId) async {
    final token = await getToken();
    final headers = {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final url = Uri.parse('$baseUrl/reviews/$reviewId');
    print('GET $url');

    final response = await http.get(url, headers: headers);
    print('Response ${response.statusCode}: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final reviewJson =
          data is Map && data.containsKey('data') ? data['data'] : data;
      return Review.fromJson(reviewJson);
    } else {
      throw Exception(
        'Lấy chi tiết review thất bại: ${response.statusCode} ${response.body}',
      );
    }
  }

  // -------------------- COMMENTS --------------------
  Future<List<Comment>> getComments(int reviewId) async {
    final response = await getWithToken("reviews/$reviewId/comments");
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((c) => Comment.fromJson(c)).toList();
    } else {
      throw Exception("Lỗi load comments: ${response.body}");
    }
  }

  Future<bool> addComment(int reviewId, String content) async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/reviews/$reviewId/comment'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'content': content}),
    );

    // ✅ Thành công nếu mã nằm trong khoảng 200–299
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  // -------------------- LIKES --------------------
  // ❤️ Like review
  Future<bool> likeReview(int reviewId) async {
    final token = await getToken();
    if (token == null) throw Exception("No token found, login first.");

    final url = Uri.parse('$baseUrl/reviews/$reviewId/like');
    final response = await http.post(
      url,
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );

    print('POST reviews/$reviewId/like → ${response.statusCode}');
    return response.statusCode == 200 || response.statusCode == 201;
  }

  // 💔 Unlike review
  Future<bool> unlikeReview(int reviewId) async {
    final token = await getToken();
    if (token == null) throw Exception("No token found, login first.");

    final url = Uri.parse('$baseUrl/reviews/$reviewId/like');
    final response = await http.delete(
      url,
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );

    print('DELETE reviews/$reviewId/like → ${response.statusCode}');
    return response.statusCode == 200 || response.statusCode == 204;
  }

  // 🔁 Toggle like / unlike
  Future<bool> toggleLikeReview(int reviewId, bool isLiked) async {
    if (isLiked) {
      return await unlikeReview(reviewId);
    } else {
      return await likeReview(reviewId);
    }
  }

  // -------------------- UPLOAD AVATAR --------------------
  Future<String> uploadAvatar(File file) async {
    final token = await getToken();
    if (token == null) throw Exception("Chưa login");

    final uri = Uri.parse('$baseUrl/user/avatar');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('avatar', file.path));

    final response = await request.send();
    final resBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(resBody);
      final avatarUrl = data['avatar_url'] ?? '';

      // Lưu lại avatar mới vào local
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('avatar', avatarUrl);

      return avatarUrl;
    } else {
      throw Exception('Upload avatar thất bại: $resBody');
    }
  }

  // -------------------- UPDATE USER INFO --------------------
  Future<Map<String, dynamic>> updateUserInfo({
    required String name,
    required String email,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception("Chưa login");

    final uri = Uri.parse('$baseUrl/user/update');
    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'name': name, 'email': email}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Lưu lại vào local
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', data['user']['name']);
      await prefs.setString('email', data['user']['email']);

      return data['user'];
    } else {
      throw Exception('Update user info thất bại: ${response.body}');
    }
  }

  //-------------------------------------------------------------
  // -------------------- MY REVIEWS --------------------
  Future<List<Review>> getMyReviews() async {
    final response = await getWithToken("reviews/my");
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => Review.fromJson(e)).toList();
    } else {
      throw Exception('Lấy bài review của tôi thất bại: ${response.body}');
    }
  }

  Future<List<Review>> getLikedReviews() async {
    final response = await getWithToken("reviews/liked");
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => Review.fromJson(e)).toList();
    } else {
      throw Exception('Lấy bài review đã thích thất bại: ${response.body}');
    }
  }

  Future<List<Review>> getCommentedReviews() async {
    final response = await getWithToken("reviews/commented");
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => Review.fromJson(e)).toList();
    } else {
      throw Exception('Lấy bài review đã bình luận thất bại: ${response.body}');
    }
  }

  Future<List<Comment>> getMyComments() async {
    final response = await getWithToken("comments/my");
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => Comment.fromJson(e)).toList();
    } else {
      throw Exception('Lấy danh sách bình luận thất bại: ${response.body}');
    }
  }

  // -------------------- CATEGORY --------------------
  Future<List<Category>> getCategories() async {
    final response = await get("categories"); // dùng hàm get trong ApiService
    print("=== GET categories status: ${response.statusCode} ===");
    print("body: ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // API của bạn trả về List trực tiếp
      if (data is List) {
        return data.map((e) => Category.fromJson(e)).toList();
      } else {
        throw Exception("Unexpected response format: $data");
      }
    } else {
      throw Exception("Failed to fetch categories: ${response.statusCode}");
    }
  }

  Future<List<Restaurant>> getRestaurantsByCategory(int categoryId) async {
    final response = await get("categories/$categoryId/restaurants");
    print(
      "=== GET restaurants by category $categoryId: ${response.statusCode} ===",
    );
    print("body: ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data is List) {
        return data.map((e) => Restaurant.fromJson(e)).toList();
      } else {
        throw Exception("Invalid response format: expected a List");
      }
    } else {
      throw Exception(
        "Failed to fetch restaurants by category: ${response.statusCode}",
      );
    }
  }

  //-----------------------------------------------------------------
  Future<int> addBasicRestaurant({
    required String name,
    required String address,
    String? description,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception("Chưa đăng nhập");

    final response = await http.post(
      Uri.parse('$baseUrl/restaurants/basic'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'address': address,
        if (description != null) 'description': description,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['id'];
    } else if (response.statusCode == 409) {
      final data = jsonDecode(response.body);
      throw Exception("Nhà hàng đã tồn tại: ${data['restaurant']['name']}");
    } else {
      throw Exception(
        'Thêm nhà hàng thất bại: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<List<Restaurant>> getNearbyRestaurants({
    required double lat,
    required double lng,
    double? radius,
    String? query,
  }) async {
    final uri = Uri.parse('$baseUrl/restaurants/nearby').replace(
      queryParameters: {
        'lat': lat.toString(),
        'lng': lng.toString(),
        if (radius != null) 'radius': radius.toString(),
        if (query != null) 'query': query,
      },
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => Restaurant.fromJson(e)).toList();
    } else {
      throw Exception(
        "Failed to fetch nearby restaurants: ${response.statusCode}",
      );
    }
  }

  //-----------------------------------------------------------------------
  Future<bool> favoriteRestaurant(int restaurantId) async {
    final token = await getToken();
    if (token == null) throw Exception("No token found, login first.");

    final url = Uri.parse('$baseUrl/restaurants/$restaurantId/favorite');
    final response = await http.post(
      url,
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );

    print(
      'POST restaurants/$restaurantId/favorite response: ${response.statusCode}',
    );
    return response.statusCode == 200;
  }

  // Hủy yêu thích
  Future<bool> unfavoriteRestaurant(int restaurantId) async {
    final token = await getToken();
    if (token == null) throw Exception("No token found, login first.");

    final url = Uri.parse('$baseUrl/restaurants/$restaurantId/favorite');
    final response = await http.delete(
      url,
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );

    print(
      'DELETE restaurants/$restaurantId/favorite response: ${response.statusCode}',
    );
    return response.statusCode == 200;
  }

  // Toggle favorite
  Future<bool> toggleFavoriteRestaurant(
    int restaurantId,
    bool isFavorite,
  ) async {
    if (isFavorite) {
      return await unfavoriteRestaurant(restaurantId);
    } else {
      return await favoriteRestaurant(restaurantId);
    }
  }

  Future<List<Restaurant>> getMyFavorites() async {
    final token = await getToken();
    if (token == null) throw Exception("No token found, login first.");

    final url = Uri.parse('$baseUrl/favorites');
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => Restaurant.fromJson(e)).toList();
    } else {
      throw Exception(
        'Lấy danh sách favorite thất bại: ${response.statusCode}',
      );
    }
  }

  Future<List<Restaurant>> getTopRatedRestaurants({int limit = 5}) async {
    final response = await get(
      "restaurants/top-rated?limit=$limit",
    ); // tự động nối với _baseUrl
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((e) => Restaurant.fromJson(e)).toList();
    } else {
      throw Exception(
        "Failed to fetch top rated restaurants: ${response.statusCode}",
      );
    }
  }

  //-----------------------------------------------------------------
  Future<List<Restaurant>> searchRestaurants({
    required String query,
    int? limit,
  }) async {
    final uri = Uri.parse('$baseUrl/restaurants/search').replace(
      queryParameters: {
        'q': query,
        if (limit != null) 'limit': limit.toString(),
      },
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => Restaurant.fromJson(e)).toList();
    } else {
      throw Exception("Failed to search restaurants: ${response.statusCode}");
    }
  }

  //--------------------------
  Future<List<Restaurant>> getRecommendations({
    int topN = 5,
    double alpha = 0.6,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception("No token found, login first.");

    final url = Uri.parse('$baseUrl/recommend?top_n=$topN&alpha=$alpha');

    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );

    print('GET /recommend response: ${response.statusCode}'); // debug

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List recs = data['recommendations'] ?? [];

      return recs
          .map(
            (e) => Restaurant(
              id: e['id'],
              name: e['name'],
              address: e['address'],
              imageUrl: e['image_url'],
            ),
          )
          .toList();
    } else {
      throw Exception('Failed to load recommendations: ${response.body}');
    }
  }

  //-----------------------------------------
  // 🗑️ Xoá review
  Future<bool> deleteReview(int reviewId) async {
    final token = await getToken();
    if (token == null) throw Exception("No token found, login first.");

    final url = Uri.parse('$baseUrl/reviews/$reviewId');
    final response = await http.delete(
      url,
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );

    print('DELETE reviews/$reviewId → ${response.statusCode}');

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 403) {
      throw Exception("Bạn không có quyền xoá review này");
    } else if (response.statusCode == 404) {
      throw Exception("Review không tồn tại");
    } else {
      throw Exception(
        "Lỗi khi xoá review: ${response.statusCode} ${response.body}",
      );
    }
  }

  // 💬🗑️ Xoá comment
  Future<bool> deleteComment(int commentId) async {
    final token = await getToken();
    if (token == null) throw Exception("No token found, login first.");

    final url = Uri.parse('$baseUrl/comments/$commentId');
    final response = await http.delete(
      url,
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );

    print('DELETE comments/$commentId → ${response.statusCode}');

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 403) {
      throw Exception("Bạn không có quyền xoá comment này");
    } else if (response.statusCode == 404) {
      throw Exception("Comment không tồn tại");
    } else {
      throw Exception(
        "Lỗi khi xoá comment: ${response.statusCode} ${response.body}",
      );
    }
  }

  //-------------------
  // ✅ Cập nhật tọa độ quán ăn
  Future<bool> updateRestaurantLocation({
    required int restaurantId,
    required double latitude,
    required double longitude,
  }) async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;

    final url = Uri.parse('$baseUrl/restaurants/$restaurantId/update-location');

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
    );

    return response.statusCode == 200;
  }
}
