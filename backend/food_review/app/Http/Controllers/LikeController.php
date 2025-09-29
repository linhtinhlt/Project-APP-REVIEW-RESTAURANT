<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Like;

class LikeController extends Controller
{
    public function store($reviewId)
    {
        $user = auth()->user();

        // Check nếu đã like
        if (Like::where('user_id', $user->id)->where('review_id', $reviewId)->exists()) {
            return response()->json(['message' => 'Already liked'], 400);
        }

        $like = Like::create([
            'user_id' => $user->id,
            'review_id' => $reviewId
        ]);

        return response()->json([
            'message' => 'Liked successfully',
            'like' => $like->load('user')
        ]);
    }

    public function destroy($reviewId)
    {
        $user = auth()->user();

        $like = Like::where('user_id', $user->id)->where('review_id', $reviewId)->first();
        if (!$like) {
            return response()->json(['message' => 'Not liked yet'], 400);
        }

        $like->delete();
        return response()->json(['message' => 'Unliked successfully']);
    }
}
