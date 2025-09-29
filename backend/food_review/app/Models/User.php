<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Passport\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'avatar', // ✅ thêm trường avatar
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];
    public function reviews() { return $this->hasMany(Review::class); }
    public function favorites() { return $this->hasMany(Favorite::class); }
    public function likes() { return $this->hasMany(Like::class); }
    public function comments() { return $this->hasMany(Comment::class); }

}
