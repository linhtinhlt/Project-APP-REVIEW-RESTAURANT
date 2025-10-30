# ==========================================================
# test_data.py — Kiểm tra dữ liệu từ MySQL & Model Realtime
# ----------------------------------------------------------
# Có 2 chế độ:
#   1️⃣ MySQL mode: test kết nối và bảng gốc (load trực tiếp từ DB)
#   2️⃣ Realtime mode: test dữ liệu đang trong model_state (RAM)
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

from model_state import model_data
from cbf import recommend_cbf
from cf import recommend_for_user
from hybrid import hybrid_recommend


# ==========================================================
# 🧩 1️⃣ Kiểm tra dữ liệu gốc trong MySQL
# ==========================================================
def test_mysql_connection():
    print("🔹 Kiểm tra MySQL Connection & các bảng:")

    print("\n📘 Reviews:")
    print(load_reviews().head())

    print("\n⭐ Favorites:")
    print(load_favorites().head())

    print("\n❤️ Likes:")
    print(load_likes().head())

    print("\n💬 Comments:")
    print(load_comments().head())

    print("\n📊 All Data (Hợp nhất hành vi):")
    print(load_all_data().head())

    print("\n🏠 Restaurants:")
    print(load_restaurants().head())

    print("\n🏷️ Categories:")
    print(load_categories().head())

    print("\n👤 Users:")
    print(load_users().head())


# ==========================================================
# ⚡ 2️⃣ Kiểm tra dữ liệu trong model_state (Realtime)
# ==========================================================
def test_model_state():
    print("\n\n============================")
    print("🧠 KIỂM TRA DỮ LIỆU TRONG MODEL_STATE")
    print("============================")

    restaurants = model_data["restaurants"]
    all_data = model_data["all_data"]

    print(f"✅ Tổng quán ăn: {len(restaurants)}")
    print(f"✅ Tổng tương tác: {len(all_data)}")

    print("\n🔹 5 quán đầu tiên:")
    print(restaurants[["id", "name"]].head())

    print("\n🔹 5 dòng dữ liệu hành vi đầu tiên:")
    print(all_data.head())

    # --- Test gợi ý ---
    user_test = 4
    print(f"\n\n🔎 Gợi ý cho user {user_test}:")

    print("\n[CF] Collaborative Filtering:")
    print(recommend_for_user(user_test, top_n=5))

    print("\n[CBF] Content-Based Filtering:")
    print(recommend_cbf(user_test, top_n=5))

    print("\n[Hybrid] Kết hợp CF + CBF:")
    print(hybrid_recommend(user_test, top_n=5))


# ==========================================================
# 🚀 Chạy kiểm thử
# ==========================================================
if __name__ == "__main__":
    # Chọn chế độ test bạn muốn
    mode = input("Chọn chế độ (1=MySQL, 2=Realtime): ").strip()

    if mode == "1":
        test_mysql_connection()
    else:
        test_model_state()
