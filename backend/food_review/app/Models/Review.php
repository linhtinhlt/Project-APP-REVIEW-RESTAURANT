<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Review extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'restaurant_id',
        'rating',
        'content',
    ];

    // ✅ Cho phép Laravel tự trả is_liked khi toJson()
    protected $appends = ['is_liked'];

    // ✅ Các quan hệ
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function restaurant()
    {
        return $this->belongsTo(Restaurant::class);
    }

    public function images()
    {
        return $this->hasMany(ReviewImage::class);
    }

    public function comments()
    {
        return $this->hasMany(Comment::class);
    }

    public function likes()
    {
        return $this->hasMany(Like::class);
    }

    // ✅ Auto-field is_liked để trả về JSON
    public function getIsLikedAttribute()
    {
        $user = auth('api')->user();
        if (!$user) return false;

        return $this->likes()->where('user_id', $user->id)->exists();
    }
}
