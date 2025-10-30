<?php

namespace App\Http\Controllers;

use App\Models\Review;
use App\Models\ReviewImage;
use App\Models\Like;
use App\Models\Comment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class ReviewController extends Controller
{
//    public function index(Request $request)
// {
//     $user = auth('api')->user(); // ✅ lấy user từ token nếu có

//     $reviews = Review::with([
//         'user:id,name,avatar',
//         'images:id,review_id,image_url',
//         'restaurant:id,name,address,image_url',
//         'comments.user:id,name,avatar',
//     ])
//     ->withCount('likes')
//     ->latest()
//     ->get();

//     // ✅ Đánh dấu từng review đã like hay chưa
//     $reviews->transform(function ($review) use ($user) {
//         $review->is_liked = false;

//         if ($user) {
//             // ⚡ kiểm tra nhanh có tồn tại like của user không
//             $review->is_liked = $review->likes()
//                 ->where('user_id', $user->id)
//                 ->exists();
//         }

//         // ✅ đảm bảo có trường likes_count luôn trả ra (dù là 0)
//         $review->likes_count = $review->likes_count ?? $review->likes()->count();

//         return $review;
//     });

//     return response()->json($reviews, 200);
// }

public function index(Request $request)
{
    $user = auth('api')->user();

    // 🔹 Lấy danh sách review có thời gian hoạt động gần nhất
    $reviews = Review::with([
            'user:id,name,avatar',
            'images:id,review_id,image_url',
            'restaurant:id,name,address,image_url',
            'comments.user:id,name,avatar',
        ])
        ->withCount('likes')
        ->select('reviews.*')
        ->addSelect([
            // lấy thời gian hoạt động gần nhất giữa review và comment
            'last_activity' => Comment::selectRaw('MAX(created_at)')
                ->whereColumn('review_id', 'reviews.id')
        ])
        ->orderByDesc(DB::raw('COALESCE(last_activity, reviews.created_at)'))
        ->get();

    // ✅ Gắn trạng thái like cho từng review
    $reviews->transform(function ($review) use ($user) {
        $review->is_liked = false;

        if ($user) {
            $review->is_liked = $review->likes()
                ->where('user_id', $user->id)
                ->exists();
        }

        $review->likes_count = $review->likes_count ?? $review->likes()->count();

        return $review;
    });

    return response()->json($reviews, 200);
}
//-------------
// ==========================
// 🔍 Lấy chi tiết 1 review
// ==========================
public function show($id)
{
    $user = auth('api')->user();

    $review = Review::with([
            'user:id,name,avatar',
            'images:id,review_id,image_url',
            'restaurant:id,name,address,image_url',
            'comments.user:id,name,avatar',
        ])
        ->withCount('likes')
        ->find($id);

    if (!$review) {
        return response()->json(['error' => 'Review not found'], 404);
    }

    // ✅ Gắn trạng thái like cho user hiện tại
    $review->is_liked = false;
    if ($user) {
        $review->is_liked = $review->likes()
            ->where('user_id', $user->id)
            ->exists();
    }

    // ✅ Đảm bảo luôn có likes_count
    $review->likes_count = $review->likes_count ?? $review->likes()->count();

    return response()->json($review, 200);
}


    // ==========================
    // 📝 Thêm review mới
    // ==========================
    public function store(Request $request)
    {
        $request->validate([
            'restaurant_id' => 'required|exists:restaurants,id',
            'rating'        => 'required|integer|min:1|max:5',
            'content'       => 'required|string',
            'images.*'      => 'nullable|image|mimes:jpeg,png,jpg|max:2048',
        ]);

        $review = DB::transaction(function () use ($request) {
            $review = Review::create([
                'user_id'       => Auth::id(),
                'restaurant_id' => (int) $request->restaurant_id,
                'rating'        => (int) $request->rating,
                'content'       => $request->content,
            ]);

            if ($request->hasFile('images')) {
                foreach ($request->file('images') as $image) {
                    $path = $image->store('reviews', 'public');
                    //$url = asset('storage/' . $path);
                    $url = '/storage/' . $path;
                    ReviewImage::create([
                        'review_id' => $review->id,
                        'image_url' => $url,
                    ]);
                }
            }

            return $review;
        });

        return response()->json([
            'message' => 'Review created successfully',
            'review'  => $review->load('images', 'user', 'restaurant'),
        ], 201);
    }

    // ==========================
    // ✏️ Cập nhật review
    // ==========================
    public function update(Request $request, $review_id)
    {
        $review = Review::findOrFail($review_id);

        if ($review->user_id !== Auth::id()) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $request->validate([
            'rating'   => 'sometimes|integer|min:1|max:5',
            'content'  => 'sometimes|string',
            'images.*' => 'nullable|image|mimes:jpeg,png,jpg|max:2048',
        ]);

        DB::transaction(function () use ($request, $review) {
            if ($request->has('rating') || $request->has('content')) {
                $review->update([
                    'rating'  => $request->has('rating') ? (int) $request->rating : $review->rating,
                    'content' => $request->has('content') ? $request->content : $review->content,
                ]);
            }

            if ($request->hasFile('images')) {
                $review->images()->delete();
                foreach ($request->file('images') as $image) {
                    $path = $image->store('reviews', 'public');
                    //$url = asset('storage/' . $path);
                    $url = '/storage/' . $path;
                    ReviewImage::create([
                        'review_id' => $review->id,
                        'image_url' => $url,
                    ]);
                }
            }
        });

        return response()->json($review->load('images', 'user', 'restaurant'));
    }

    // ==========================
    // 🗑️ Xóa review
    // ==========================
    public function destroy($review_id)
    {
        $review = Review::findOrFail($review_id);

        if ($review->user_id !== Auth::id()) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        DB::transaction(function () use ($review) {
            $review->images()->delete();
            $review->likes()->delete();
            $review->comments()->delete();
            $review->delete();
        });

        return response()->json(['message' => 'Review đã được xóa thành công.']);
    }

    // ==========================
    // ❤️ Like / Unlike Review
    // ==========================
    public function like($review_id)
    {
        $user = Auth::user();
        $review = Review::findOrFail($review_id);

        $review->likes()->firstOrCreate(['user_id' => $user->id]);

        return response()->json([
            'success' => true,
            'message' => 'Liked',
            'likes_count' => $review->likes()->count(),
            'is_liked' => true, 
        ]);
    }

    public function unlike($review_id)
    {
        $user = Auth::user();
        $review = Review::findOrFail($review_id);

        $review->likes()->where('user_id', $user->id)->delete();

        return response()->json([
            'success' => true,
            'message' => 'Unliked',
            'likes_count' => $review->likes()->count(),
            'is_liked' => false,
        ]);
    }

    // ==========================
    // 💬 Thêm comment
    // ==========================
    public function comment(Request $request, $id)
    {
        $request->validate(['content' => 'required|string|max:500']);

        $review = Review::find($id);
        if (!$review) {
            return response()->json(['error' => 'Review not found'], 404);
        }

        $comment = new Comment();
        $comment->user_id = auth()->id();
        $comment->review_id = $review->id;
        $comment->content = $request->content;
        $comment->save();

        $comment->load('user');

        return response()->json([
            'message' => 'Comment added successfully',
            'comment' => $comment,
        ], 201);
    }

    // ==========================
    // 💬 Lấy danh sách comments theo review
    // ==========================
    public function getComments($id)
    {
        $review = Review::with(['comments.user'])->find($id);

        if (!$review) {
            return response()->json(['error' => 'Review not found'], 404);
        }

        return response()->json($review->comments, 200);
    }

   //---
   


    // ==========================
    // 📍 Lấy danh sách review theo restaurant
    // ==========================
    public function getByRestaurant($id)
    {
        $user = auth('api')->user();

        $reviews = Review::with(['images', 'user', 'comments.user', 'restaurant', 'likes'])
            ->where('restaurant_id', $id)
            ->latest()
            ->get();

        $reviews->transform(function ($review) use ($user) {
            $review->likes_count = $review->likes()->count();
            $review->is_liked = $user
                ? $review->likes()->where('user_id', $user->id)->exists()
                : false;
            return $review;
        });

        return response()->json($reviews);
    }


    // ==========================
    // 👤 Các nhóm review theo user
    // ==========================
    public function myReviews(Request $request)
    {
        $user = $request->user();

        $reviews = Review::where('user_id', $user->id)
            ->with(['restaurant', 'user', 'comments.user', 'likes'])
            ->get();

        $reviews->transform(function ($review) use ($user) {
            $review->likes_count = $review->likes()->count();
            $review->is_liked = $review->likes()->where('user_id', $user->id)->exists();
            return $review;
        });

        return response()->json($reviews);
    }

    public function commentedReviews(Request $request)
    {
        $user = $request->user();

        $reviews = Review::whereHas('comments', function ($q) use ($user) {
            $q->where('user_id', $user->id);
        })->with(['restaurant', 'user', 'comments.user', 'likes'])
        ->get();

        $reviews->transform(function ($review) use ($user) {
            $review->likes_count = $review->likes()->count();
            $review->is_liked = $review->likes()->where('user_id', $user->id)->exists();
            return $review;
        });

        return response()->json($reviews);
    }

    public function likedReviews(Request $request)
    {
        $user = $request->user();

        $reviews = Review::whereHas('likes', function ($q) use ($user) {
            $q->where('user_id', $user->id);
        })->with(['restaurant', 'user', 'comments.user', 'likes'])
        ->get();

        $reviews->transform(function ($review) use ($user) {
            $review->likes_count = $review->likes()->count();
            $review->is_liked = true; 
            return $review;
        });

        return response()->json($reviews);
    }

    // ==========================
    // 🏗️ Thêm review kèm tạo nhà hàng mới
    // ==========================
    public function storeWithRestaurant(Request $request)
    {
        $request->validate([
            'restaurant_name' => 'required|string|max:255',
            'restaurant_address' => 'required|string|max:255',
            'restaurant_description' => 'nullable|string',
            'restaurant_latitude' => 'nullable|numeric',
            'restaurant_longitude' => 'nullable|numeric',
            'restaurant_image_url' => 'nullable|string|max:255',
            'rating' => 'required|integer|min:1|max:5',
            'content' => 'required|string',
            'images.*' => 'nullable|image|mimes:jpeg,png,jpg|max:2048',
        ]);

        $review = DB::transaction(function () use ($request) {
            $restaurant = \App\Models\Restaurant::create([
                'name' => $request->restaurant_name,
                'address' => $request->restaurant_address,
                'description' => $request->restaurant_description,
                'latitude' => $request->restaurant_latitude,
                'longitude' => $request->restaurant_longitude,
                'image_url' => $request->restaurant_image_url,
            ]);

            $review = Review::create([
                'user_id' => Auth::id(),
                'restaurant_id' => $restaurant->id,
                'rating' => (int) $request->rating,
                'content' => $request->content,
            ]);

            if ($request->hasFile('images')) {
                foreach ($request->file('images') as $image) {
                    $path = $image->store('reviews', 'public');
                    $url = asset('storage/' . $path);
                    ReviewImage::create([
                        'review_id' => $review->id,
                        'image_url' => $url,
                    ]);
                }
            }

            return $review->load('images', 'user', 'restaurant');
        });

        return response()->json([
            'message' => 'Review và nhà hàng được tạo thành công',
            'review' => $review,
        ], 201);
    }
}
