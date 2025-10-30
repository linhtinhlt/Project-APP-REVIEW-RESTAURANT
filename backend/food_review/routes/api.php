<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Http;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\RestaurantController;
use App\Http\Controllers\ReviewController;
use App\Http\Controllers\FavoriteController;
use App\Http\Controllers\CommentController;
use App\Http\Controllers\LikeController;
use App\Http\Controllers\CategoryController;
use App\Http\Controllers\RecommendationController;

// ================== Auth (Public) ==================
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// ================== Restaurants (Public) ==================
Route::get('/restaurants/top-rated', [RestaurantController::class, 'topRated']);
Route::get('/restaurants', [RestaurantController::class, 'index']);
Route::get('/restaurants/search', [RestaurantController::class, 'search']);
Route::get('/restaurants/nearby', [RestaurantController::class, 'nearby']);
Route::get('/restaurants/{id}', [RestaurantController::class, 'show']);


// ================== Reviews (Public) ==================
Route::get('/reviews', [ReviewController::class, 'index']);
Route::get('/reviews/restaurant/{id}', [ReviewController::class, 'getByRestaurant']);
Route::get('/reviews/{id}/comments', [ReviewController::class, 'getComments']);


Route::get('/categories', [CategoryController::class, 'index']);
Route::post('/categories', [CategoryController::class, 'store']);
Route::get('/categories/{id}/restaurants', [CategoryController::class, 'getRestaurants']);


// ================== Routes cần token (Private) ==================
Route::middleware('auth:api')->group(function () {

    // ----- Auth -----
    Route::get('/user', [AuthController::class, 'user']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user-test', function() {
        return auth()->user();
    });
    Route::post('/user/avatar', [AuthController::class, 'uploadAvatar']); // upload ảnh avatar
    Route::put('/user/update', [AuthController::class, 'updateUserInfo']);
    
    // ----- Restaurants (Admin/User có quyền) -----
    Route::post('/restaurants', [RestaurantController::class, 'store']);
    Route::put('/restaurants/{id}', [RestaurantController::class, 'update']);
    Route::delete('/restaurants/{id}', [RestaurantController::class, 'destroy']);
    Route::put('/restaurants/{id}/update-location', [RestaurantController::class, 'updateLocation']);


    Route::get('/recommend', [RecommendationController::class, 'recommend']);
    // ----- Reviews -----
    Route::post('/reviews', [ReviewController::class, 'store']);
    Route::post('/reviews/{id}/like', [ReviewController::class, 'like']);
    Route::post('/reviews/{id}/unlike', [ReviewController::class, 'unlike']);
    Route::post('/reviews/{id}/comment', [ReviewController::class, 'comment']);
    Route::delete('/reviews/{id}', [ReviewController::class, 'destroy']);

    Route::post('/restaurants/basic', [RestaurantController::class, 'storeBasic']); 
    // Likes
    Route::post('/reviews/{id}/like', [LikeController::class, 'store']);
    Route::delete('/reviews/{id}/like', [LikeController::class, 'destroy']);

    // ----- Comments -----
    Route::get('/comments/my', [CommentController::class, 'getMyComments']);
    Route::post('/comments', [CommentController::class, 'store']);
    Route::put('/comments/{id}', [CommentController::class, 'update']);
    Route::delete('/comments/{id}', [CommentController::class, 'destroy']);


    // ----- Favorites -----
     Route::post('/restaurants/{id}/favorite', [FavoriteController::class, 'store']);
    Route::delete('/restaurants/{id}/favorite', [FavoriteController::class, 'destroy']);
    Route::get('/favorites', [FavoriteController::class, 'index']);
    //
    Route::get('/reviews/my', [ReviewController::class, 'myReviews']);
    Route::get('/reviews/commented', [ReviewController::class, 'commentedReviews']);
    Route::get('/reviews/liked', [ReviewController::class, 'likedReviews']);

});
Route::get('/reviews/{id}', [ReviewController::class, 'show']); 
