# ==========================================================
# test_data_from_loader.py — Kiểm tra dữ liệu thông qua data_loader
# ----------------------------------------------------------
# Gọi trực tiếp các hàm load_* trong data_loader.py
# và in kết quả giống như "Kiểm tra MySQL Connection & các bảng"
# ==========================================================

from data_loader import (
    load_reviews,
    load_favorites,
    load_likes,
    load_comments,
    load_all_data,
    load_restaurants,
    load_categories,
    load_users
)

import pandas as pd


def print_section(title, df, show_rows=5):
    """In tiêu đề và DataFrame có format đẹp"""
    print(f"\n{title}")
    if df is None or df.empty:
        print("(⚠️ Không có dữ liệu)\n")
        return
    print(df.head(show_rows))
    print(f"({len(df)} bản ghi)\n")


if __name__ == "__main__":
    print("🔹 Kiểm tra MySQL Connection & các bảng:")

    # 1️⃣ Reviews
    reviews = load_reviews()
    print_section("📘 Reviews:", reviews)

    # 2️⃣ Favorites
    favorites = load_favorites()
    print_section("⭐ Favorites:", favorites)

    # 3️⃣ Likes
    likes = load_likes()
    print_section("❤️ Likes:", likes)

    # 4️⃣ Comments
    comments = load_comments()
    print_section("💬 Comments:", comments)

    # 5️⃣ All Data (tổng hợp)
    all_data = load_all_data()
    print(f"\n📊 All Data (Hợp nhất hành vi):")
    print(f"✅ Load dữ liệu huấn luyện thành công: {len(all_data)} bản ghi.")
    print(all_data.head())

    # 6️⃣ Restaurants
    restaurants = load_restaurants()
    print_section("🏠 Restaurants:", restaurants)

    # 7️⃣ Categories
    categories = load_categories()
    print_section("🏷️ Categories:", categories)

    # 8️⃣ Users
    users = load_users()
    print_section("👤 Users:", users)

    print("✅ Hoàn tất kiểm tra dữ liệu.\n")
