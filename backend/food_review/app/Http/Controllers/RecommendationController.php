<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use App\Models\Restaurant;

class RecommendationController extends Controller
{
    public function recommend(Request $request)
    {
        // ✅ Lấy user từ token (Laravel sẽ decode từ JWT Sanctum/Passport)
        $user = $request->user(); 
        if (!$user) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }
        $userId = $user->id;

        $topN = $request->query('top_n', 5);
        $alpha = $request->query('alpha', 0.6);

        // ✅ Gọi Flask API với userId
       $response = Http::get('http://172.20.10.10:5000/recommend', [
    'user_id'   => $userId,
    'top_n'     => $topN,
    'alpha_cf'  => $alpha,         // sửa key
    'alpha_cbf' => 1 - $alpha,     // đảm bảo tổng = 1
]);


        if ($response->successful()) {
            $data = $response->json();

            // Lấy danh sách ID quán
            $ids = collect($data['recommendations'])->pluck('id')->toArray();

            // Lấy thông tin từ DB
            $restaurants = Restaurant::whereIn('id', $ids)->get(['id', 'name', 'address', 'image_url']);

            // Kết hợp Flask score + DB info
            $recommendations = collect($data['recommendations'])->map(function ($item) use ($restaurants) {
                $rest = $restaurants->firstWhere('id', $item['id']);
                return [
                    'id'       => $item['id'],
                    'name'     => $rest ? $rest->name : $item['name'],
                    'score'    => $item['score'],
                    'address'  => $rest ? $rest->address : null,
                    'image_url'=> $rest ? $rest->image_url : null,
                ];
            });

            return response()->json([
                'user_id' => $userId,
                'recommendations' => $recommendations,
            ]);

        } else {
    return response()->json([
        'error' => 'Flask API failed',
        'status' => $response->status(),
        'body' => $response->body(),
    ], 500);
}
    }
}
