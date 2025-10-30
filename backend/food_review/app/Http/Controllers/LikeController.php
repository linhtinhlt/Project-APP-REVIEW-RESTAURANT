<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Like;
use App\Models\Review;

class LikeController extends Controller
{
    // ✅ Thêm like cho review
    public function store($reviewId)
    {
        $user = auth('api')->user(); // ✅ đảm bảo lấy user từ token
        if (!$user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $review = Review::findOrFail($reviewId);

        // Nếu đã like rồi thì không cần thêm nữa
        $existing = Like::where('user_id', $user->id)
            ->where('review_id', $reviewId)
            ->first();

        if ($existing) {
            return response()->json([
                'success' => true,
                'message' => 'Already liked',
                'likes_count' => $review->likes()->count(),
                'is_liked' => true, 
            ]);
        }

        Like::create([
            'user_id' => $user->id,
            'review_id' => $reviewId,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Liked successfully',
            'likes_count' => $review->likes()->count(),
            'is_liked' => true, 
        ]);
    }

    // ✅ Bỏ like review
    public function destroy($reviewId)
    {
        $user = auth('api')->user(); // ✅ đọc token
        if (!$user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $review = Review::findOrFail($reviewId);

        $like = Like::where('user_id', $user->id)
            ->where('review_id', $reviewId)
            ->first();

        if (!$like) {
            return response()->json([
                'success' => true,
                'message' => 'Not liked yet',
                'likes_count' => $review->likes()->count(),
                'is_liked' => false,
            ]);
        }

        $like->delete();

        return response()->json([
            'success' => true,
            'message' => 'Unliked successfully',
            'likes_count' => $review->likes()->count(),
            'is_liked' => false,
        ]);
    }
}
