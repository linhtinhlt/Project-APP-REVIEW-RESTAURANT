<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Review extends Model
{
    protected $fillable = [
        'user_id', 'restaurant_id', 'rating', 'content'
    ];

    protected $casts = [
        'rating' => 'integer',
    ];

    // Khai báo để luôn append vào JSON
    protected $appends = ['is_liked'];

    // Accessor cho is_liked
    public function getIsLikedAttribute()
    {
        $userId = auth()->id();
        if (!$userId) {
            return false;
        }
        return $this->likes()->where('user_id', $userId)->exists();
    }

    public function user() {
        return $this->belongsTo(User::class);
    }

    public function restaurant() {
        return $this->belongsTo(Restaurant::class);
    }

    public function images() {
        return $this->hasMany(ReviewImage::class);
    }

    public function likes() {
        return $this->hasMany(Like::class);
    }

    public function comments() {
        return $this->hasMany(Comment::class);
    }
}
