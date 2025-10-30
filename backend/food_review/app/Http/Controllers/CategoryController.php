<?php

namespace App\Http\Controllers;

use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CategoryController extends Controller
{
    /**
     * Lấy tất cả danh mục
     */
    public function index()
    {
        // Lấy danh sách category, chỉ 3 trường
        $categories = Category::all(['id', 'name', 'image']);

        // Trả về thẳng array JSON (giống Restaurant)
        return response()->json($categories);
    }

    /**
     * Lấy chi tiết 1 danh mục theo id
     */
    public function show($id)
    {
        $category = Category::find($id, ['id', 'name', 'image']);

        if (!$category) {
            return response()->json([
                'message' => 'Category not found'
            ], 404);
        }

        return response()->json($category);
    }

    /**
     * Tạo danh mục mới
     */
    public function store(Request $request)
    {
        $request->validate([
            'name'  => 'required|unique:categories,name',
            'image' => 'nullable|string'
        ]);

        $category = Category::create([
            'name'  => $request->name,
            'image' => $request->image ?? null
        ]);

        return response()->json($category, 201);
    }

    /**
     * Cập nhật danh mục
     */
    public function update(Request $request, $id)
    {
        $category = Category::find($id);

        if (!$category) {
            return response()->json([
                'message' => 'Category not found'
            ], 404);
        }

        $request->validate([
            'name'  => 'required|unique:categories,name,' . $id,
            'image' => 'nullable|string'
        ]);

        $category->update([
            'name'  => $request->name,
            'image' => $request->image ?? $category->image
        ]);

        return response()->json($category);
    }

    /**
     * Xóa danh mục
     */
    public function destroy($id)
    {
        $category = Category::find($id);

        if (!$category) {
            return response()->json([
                'message' => 'Category not found'
            ], 404);
        }

        $category->delete();

        return response()->json([
            'message' => 'Category deleted'
        ]);
    }
   public function getRestaurants($id)
{
    $category = \App\Models\Category::find($id);

    if (!$category) {
        return response()->json([
            'message' => 'Category not found'
        ], 404);
    }

    // ✅ Lấy danh sách nhà hàng theo category, kèm avg_rating và reviews_count
    $restaurants = \App\Models\Restaurant::where('category_id', $id)
        ->withCount('reviews')              // đếm số lượng đánh giá
        ->withAvg('reviews', 'rating')      // trung bình số sao
        ->orderByDesc('reviews_avg_rating') // sắp xếp theo rating cao nhất
        ->get(['id', 'name', 'address', 'image_url']);

    // ✅ Đổi tên field cho trùng Flutter model
    $restaurants = $restaurants->map(function ($r) {
        return [
            'id' => $r->id,
            'name' => $r->name,
            'address' => $r->address,
            'image_url' => $r->image_url,
            'avg_rating' => round($r->reviews_avg_rating ?? 0, 1),
            'reviews_count' => $r->reviews_count ?? 0,
        ];
    });

    return response()->json($restaurants, 200);
}


}
