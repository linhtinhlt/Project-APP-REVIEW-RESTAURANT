<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    // -------------------- Đăng ký --------------------
    public function register(Request $request)
    {
        $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|string|email|unique:users',
            'password' => 'required|string|min:6',
        ]);

        $user = User::create([
            'name'     => $request->name,
            'email'    => $request->email,
            'password' => Hash::make($request->password),
        ]);

        $token = $user->createToken('MyAppToken')->accessToken;

        return response()->json([
            'user'  => $user,
            'token' => $token
        ], 201);
    }

    // -------------------- Đăng nhập --------------------
    public function login(Request $request)
    {
        $request->validate([
            'email'    => 'required|string|email',
            'password' => 'required|string',
        ]);

        if (!Auth::attempt($request->only('email', 'password'))) {
            return response()->json(['error' => 'Sai tài khoản hoặc mật khẩu'], 401);
        }

        $user  = Auth::user();
        $token = $user->createToken('MyAppToken')->accessToken;

        return response()->json([
            'user'  => $user,
            'token' => $token
        ]);
    }

    // -------------------- Đăng xuất --------------------
    public function logout(Request $request)
    {
        $request->user()->token()->revoke();

        return response()->json(['message' => 'Đăng xuất thành công']);
    }

    // -------------------- Lấy thông tin user hiện tại --------------------
    public function user(Request $request)
    {
        return response()->json($request->user());
    }

    // -------------------- Cập nhật avatar --------------------
    // Cập nhật thông tin user (name + email)
public function updateUserInfo(Request $request)
{
    $request->validate([
        'name'  => 'required|string|max:255',
        'email' => 'required|string|email|unique:users,email,' . $request->user()->id,
    ]);

    $user = $request->user();
    $user->name = $request->name;
    $user->email = $request->email;
    $user->save();

    return response()->json([
        'success' => true,
        'user'    => $user,
    ]);
}

// Upload avatar (giữ nguyên như trước)
public function uploadAvatar(Request $request)
{
    $request->validate([
        'avatar' => 'required|image|mimes:jpg,jpeg,png|max:2048',
    ]);

    $user = $request->user();

    // Lưu vào storage/app/public/avatars
    $path = $request->file('avatar')->store('avatars', 'public');

    // Lấy URL public
    //$url = asset('storage/' . $path);

    $url = '/storage/' . $path;

    // Lưu vào DB
    $user->avatar = $url;
    $user->save();

    return response()->json([
        'message' => 'Upload thành công',
        'avatar_url' => $url,
    ]);
}


}
