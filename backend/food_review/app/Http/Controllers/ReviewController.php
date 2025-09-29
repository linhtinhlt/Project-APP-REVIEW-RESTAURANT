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
    // Lấy tất cả review mới nhất
    public function index()
    {
        $reviews = Review::with(['user', 'images', 'restaurant'])
            ->withCount('likes')
            ->latest()
            ->get();

        return response()->json($reviews);
    }


    // Thêm review mới kèm nhiều ảnh
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
                    $url = asset('storage/' . $path); // tạo URL đầy đủ có http
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

    // Cập nhật review
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
                    $url = asset('storage/' . $path);
                    ReviewImage::create([
                        'review_id' => $review->id,
                        'image_url' => $url,
                    ]);
                }
            }
        });

        return response()->json($review->load('images', 'user', 'restaurant'));
    }

    // Xóa review
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

    // Like review
    public function like($review_id)
    {
        Like::firstOrCreate([
            'user_id'   => Auth::id(),
            'review_id' => $review_id
        ]);

        return response()->json(['message' => 'Liked']);
    }

    // Unlike review
    public function unlike($review_id)
    {
        Like::where('user_id', Auth::id())
            ->where('review_id', $review_id)
            ->delete();

        return response()->json(['message' => 'Unliked']);
    }

    // Thêm comment
    public function comment(Request $request, $id)
    {
        $request->validate([
            'content' => 'required|string|max:500',
        ]);

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

    // Lấy review chi tiết
    public function show($review_id)
    {
        $review = Review::with(['images', 'user', 'restaurant', 'comments.user'])
                        ->findOrFail($review_id);

        return response()->json($review);
    }

    // Lấy danh sách review theo restaurant
    public function listByRestaurant($restaurant_id)
    {
        $reviews = Review::with(['images', 'user', 'comments.user', 'restaurant'])
                         ->where('restaurant_id', $restaurant_id)
                         ->get();

        return response()->json($reviews);
    }

    // Lấy danh sách review theo user
    public function listByUser($user_id)
    {
        $reviews = Review::with(['images', 'restaurant', 'comments.user'])
                         ->where('user_id', $user_id)
                         ->get();

        return response()->json($reviews);
    }

    // Lấy review theo restaurant (API riêng)
    public function getByRestaurant($id)
    {
        $reviews = Review::where('restaurant_id', $id)
                         ->with('user', 'images', 'restaurant')
                         ->get();

        return response()->json($reviews);
    }

    // Lấy comments của review
    public function getComments($id)
    {
        $review = Review::with(['comments.user'])->find($id);

        if (!$review) {
            return response()->json(['error' => 'Review not found'], 404);
        }

        return response()->json($review->comments, 200);
    }
    //
     public function myReviews(Request $request)
    {
        $userId = $request->user()->id;

        $reviews = Review::where('user_id', $userId)
            ->with(['restaurant', 'user', 'comments', 'likes'])
            ->get();

        return response()->json($reviews);
    }

    // 2. Review mà tôi đã comment
    public function commentedReviews(Request $request)
    {
        $userId = $request->user()->id;

        $reviews = Review::whereHas('comments', function ($q) use ($userId) {
            $q->where('user_id', $userId);
        })->with(['restaurant', 'user', 'comments', 'likes'])
        ->get();

        return response()->json($reviews);
    }

    // 3. Review mà tôi đã like
    public function likedReviews(Request $request)
    {
        $userId = $request->user()->id;

        $reviews = Review::whereHas('likes', function ($q) use ($userId) {
            $q->where('user_id', $userId);
        })->with(['restaurant', 'user', 'comments', 'likes'])
        ->get();

        return response()->json($reviews);
    }


    // Thêm review kèm tạo nhà hàng mới
public function storeWithRestaurant(Request $request)
{
    $request->validate([
        // Thông tin nhà hàng
        'restaurant_name' => 'required|string|max:255',
        'restaurant_address' => 'required|string|max:255',
        'restaurant_description' => 'nullable|string',
        'restaurant_latitude' => 'nullable|numeric',
        'restaurant_longitude' => 'nullable|numeric',
        'restaurant_image_url' => 'nullable|string|max:255',

        // Thông tin review
        'rating' => 'required|integer|min:1|max:5',
        'content' => 'required|string',
        'images.*' => 'nullable|image|mimes:jpeg,png,jpg|max:2048',
    ]);

    $review = DB::transaction(function () use ($request) {
        // Tạo nhà hàng mới
        $restaurant = \App\Models\Restaurant::create([
            'name' => $request->restaurant_name,
            'address' => $request->restaurant_address,
            'description' => $request->restaurant_description,
            'latitude' => $request->restaurant_latitude,
            'longitude' => $request->restaurant_longitude,
            'image_url' => $request->restaurant_image_url,
        ]);

        // Tạo review liên kết nhà hàng vừa tạo
        $review = \App\Models\Review::create([
            'user_id' => Auth::id(),
            'restaurant_id' => $restaurant->id,
            'rating' => (int) $request->rating,
            'content' => $request->content,
        ]);

        // Thêm ảnh review nếu có
        if ($request->hasFile('images')) {
            foreach ($request->file('images') as $image) {
                $path = $image->store('reviews', 'public');
                $url = asset('storage/' . $path);
                \App\Models\ReviewImage::create([
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
