<?php

namespace App\Http\Controllers;

use App\Models\Restaurant;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class RestaurantController extends Controller
{
    // Lấy danh sách quán ăn (có thể filter theo type, rating)
    public function index(Request $request)
    {
        $query = Restaurant::query();

        // // Filter theo loại món ăn
        // if ($request->has('type')) {
        //     $query->where('type', $request->type);
        // }

        // // Lọc theo rating trung bình
        // if ($request->has('min_rating')) {
        //     $query->whereHas('reviews', function ($q) use ($request) {
        //         $q->selectRaw('avg(rating) as avg_rating')
        //           ->havingRaw('avg(rating) >= ?', [$request->min_rating]);
        //     });
        // }

        $restaurants = $query->with(['reviews'])->get();

        return response()->json($restaurants);
    }

    // Xem chi tiết quán ăn kèm review
    // public function show($id)
    // {
    //     $restaurant = Restaurant::with([
    //         'reviews.user',     // thông tin người viết review
    //         'reviews.images',   // ảnh review
    //         'reviews.likes',    // like của review
    //         'reviews.comments'  // comment của review
    //     ])->findOrFail($id);

    //     return response()->json($restaurant);
    // }
    public function show($id)
{
    $user = auth()->user();

    $restaurant = Restaurant::with([
        'reviews.user',     // thông tin người viết review
        'reviews.images',   // ảnh review
        'reviews.likes',    // like của review
        'reviews.comments'  // comment của review
    ])
    ->withCount('favorites') // ✅ số lượng favorite
    ->findOrFail($id);

    // ✅ trạng thái user hiện tại đã favorite hay chưa
    $restaurant->is_favorite = false;
    if ($user) {
        $restaurant->is_favorite = $restaurant->favorites
                                    ->where('user_id', $user->id)
                                    ->isNotEmpty();
    }

    return response()->json($restaurant);
}

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'address' => 'required|string|max:255',
            'description' => 'nullable|string',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'image_url' => 'nullable|string|max:255',
        ]);

        $restaurant = Restaurant::create([
            'name' => $request->name,
            'address' => $request->address,
            'description' => $request->description,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'image_url' => $request->image_url, // lưu ảnh
        ]);

        return response()->json($restaurant, 201);
    }

    public function getByCategory($id)
{
    $restaurants = \App\Models\Restaurant::where('category_id', $id)
                    ->get(['id', 'name', 'image', 'address']); 

    return response()->json($restaurants);
}

public function storeBasic(Request $request)
{
    $request->validate([
        'name' => 'required|string|max:255',
        'address' => 'required|string|max:255',
        'description' => 'nullable|string',
    ]);

    // Kiểm tra tên nhà hàng đã tồn tại chưa
    $existing = Restaurant::where('name', $request->name)->first();
    if ($existing) {
        return response()->json([
            'message' => 'Nhà hàng đã tồn tại',
            'restaurant' => $existing
        ], 409); // 409 Conflict
    }

    $lat = null;
    $lng = null;

    // --- Gọi Mapbox Geocoding API ---
    try {
        $mapToken = config('services.mapbox.token');
        $address = rawurlencode($request->address);
        $url = "https://api.mapbox.com/geocoding/v5/mapbox.places/{$address}.json?access_token={$mapToken}&limit=1";

        $response = Http::get($url);
        $data = $response->json();

        if (isset($data['features']) && count($data['features']) > 0) {
            // Ưu tiên feature có place_type = "address"
            $feature = collect($data['features'])->firstWhere('place_type.0', 'address');

            if (!$feature) {
                $feature = $data['features'][0];
            }

            $coords = $feature['center']; // [lng, lat]
            $lng = $coords[0];
            $lat = $coords[1];
        }
    } catch (\Exception $e) {
        // Nếu lỗi thì vẫn lưu nhà hàng nhưng không có tọa độ
    }

    $restaurant = Restaurant::create([
        'name' => $request->name,
        'address' => $request->address,
        'description' => $request->description,
        'latitude' => $lat,
        'longitude' => $lng,
    ]);

    return response()->json($restaurant, 201);
}
public function nearby(Request $request)
{
    $lat = $request->query('lat');
    $lng = $request->query('lng');
    $radius = $request->query('radius', 5); // default 5 km
    $query = $request->query('query'); // tên quán nếu có

    if (!$lat || !$lng) {
        return response()->json([
            'message' => 'Thiếu tham số lat hoặc lng'
        ], 400);
    }

    $restaurants = Restaurant::selectRaw(
        "id, name, address, description, latitude, longitude, image_url,
        (6371 * acos(
            cos(radians(?)) * cos(radians(latitude)) *
            cos(radians(longitude) - radians(?)) +
            sin(radians(?)) * sin(radians(latitude))
        )) AS distance",
        [$lat, $lng, $lat]
    )
    ->when($query, function($q) use ($query) {
        $q->where('name', 'like', "%$query%");
    })
    ->having("distance", "<=", $radius)
    ->orderBy("distance", "asc")
    ->get();

    return response()->json($restaurants);
}
//-----------------------------------------------
// Lấy top N quán được đánh giá cao nhất
public function topRated(Request $request)
{
    $limit = $request->query('limit', 5);

    $restaurants = Restaurant::withCount('reviews')  // ✅ reviews_count
        ->withAvg('reviews', 'rating')              // ✅ avg_rating
        ->orderBy('reviews_count', 'desc')
        ->take($limit)
        ->get(['id', 'name', 'address', 'image_url', 'favorites_count']); // ✅ thêm favorites_count nếu cần

    // Thêm avg_rating vào mỗi restaurant
    $restaurants->transform(function ($r) {
        $r->avg_rating = round($r->reviews_avg_rating ?? 0, 1);
        // reviews_count đã có sẵn nhờ withCount('reviews')
        return $r;
    });

    return response()->json($restaurants);
}

//-------------------
// Lấy danh sách quán ăn theo từ khóa tìm kiếm
public function search(Request $request)
{
    $queryText = $request->query('q', '');  // từ khóa tìm kiếm
    $limit = $request->query('limit', 20);  // số lượng kết quả trả về

    if (empty($queryText)) {
        return response()->json([]);
    }

    // Truy vấn
    $restaurants = Restaurant::where('name', 'like', "%{$queryText}%")
        ->orWhere('address', 'like', "%{$queryText}%")
        ->withCount('reviews')        // số lượng review
        ->withAvg('reviews', 'rating') // trung bình rating
        ->take($limit)
        ->get(['id', 'name', 'address', 'image_url', 'favorites_count']);

    // Thêm avg_rating vào mỗi restaurant
    $restaurants->transform(function ($r) {
        $r->avg_rating = round($r->reviews_avg_rating ?? 0, 1);
        return $r;
    });

    return response()->json($restaurants);
}

}
