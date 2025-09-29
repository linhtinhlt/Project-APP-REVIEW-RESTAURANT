<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Favorite;
use App\Models\Restaurant;
use Illuminate\Support\Facades\Auth;

class FavoriteController extends Controller
{
    // Thêm quán vào yêu thích
    public function store($restaurantId)
    {
        $user = Auth::user();

        // Check nếu đã favorite
        if (Favorite::where('user_id', $user->id)
                    ->where('restaurant_id', $restaurantId)
                    ->exists()) {
            return response()->json(['message' => 'Already favorited'], 400);
        }

        $favorite = Favorite::create([
            'user_id' => $user->id,
            'restaurant_id' => $restaurantId
        ]);

        return response()->json([
            'message' => 'Added to favorites',
            'favorite' => $favorite->load('restaurant')
        ]);
    }

    // Hủy yêu thích
    public function destroy($restaurantId)
    {
        $user = Auth::user();

        $favorite = Favorite::where('user_id', $user->id)
                            ->where('restaurant_id', $restaurantId)
                            ->first();

        if (!$favorite) {
            return response()->json(['message' => 'Not favorited yet'], 400);
        }

        $favorite->delete();

        return response()->json(['message' => 'Removed from favorites']);
    }

    // Lấy danh sách quán yêu thích của user
    public function index()
{
    $user = Auth::user();

    $favorites = Favorite::where('user_id', $user->id)
        ->with(['restaurant' => function($query) {
            $query->withCount('favorites'); // thêm trường favorites_count
        }])
        ->get();

    // Chuyển lại data, thêm trường favorites_count cho restaurant
    $result = $favorites->map(function($fav) {
        $restaurant = $fav->restaurant;
        return [
            'id' => $restaurant->id,
            'name' => $restaurant->name,
            'address' => $restaurant->address,
            'image_url' => $restaurant->image_url,
            'favorites_count' => $restaurant->favorites_count, // tổng số lượt yêu thích
            'is_favorite' => true, // vì đây là danh sách của user
        ];
    });

    return response()->json($result);
}

}
