<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;   // ✅ Bổ sung dòng này
use App\Models\Comment;

class CommentController extends Controller
{
    // ✅ Áp dụng middleware Passport cho tất cả các hàm
    public function __construct()
    {
        $this->middleware('auth:api');
    }

    // 🟢 Thêm comment mới
    public function store(Request $request)
    {
        $request->validate([
            'review_id' => 'required|exists:reviews,id',
            'content' => 'required|string|max:1000',
        ]);

        $comment = Comment::create([
            'user_id' => Auth::id(),
            'review_id' => $request->review_id,
            'content' => $request->content,
        ]);

        return response()->json([
            'message' => 'Comment added successfully',
            'comment' => $comment
        ], 201);
    }

    // 🟡 Sửa comment
    public function update(Request $request, $id)
    {
        $comment = Comment::findOrFail($id);

        if ($comment->user_id !== Auth::id()) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $request->validate([
            'content' => 'required|string|max:1000',
        ]);

        $comment->update([
            'content' => $request->content,
        ]);

        return response()->json([
            'message' => 'Comment updated successfully',
            'comment' => $comment
        ]);
    }

    // 🔴 Xoá comment
    public function destroy($id)
    {
        $comment = Comment::findOrFail($id);

        if ($comment->user_id !== Auth::id()) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $comment->delete();

        return response()->json(['message' => 'Comment deleted successfully']);
    }

    // 🟣 Lấy tất cả bình luận của người dùng hiện tại
    public function getMyComments()
    {
        $user = Auth::guard('api')->user();

        if (!$user) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $comments = Comment::with([
            'review.restaurant:id,name',
            'user:id,name,avatar'
        ])
            ->where('user_id', $user->id)
            ->latest()
            ->get(['id', 'content', 'review_id', 'user_id']);

        return response()->json($comments, 200);
    }
}
