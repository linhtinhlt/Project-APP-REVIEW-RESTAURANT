# ==========================================================
# cf.py — Collaborative Filtering (Realtime version)
# ----------------------------------------------------------
# Lấy dữ liệu từ model_state (được auto_trainer cập nhật liên tục)
# Không còn load DB mỗi lần gọi recommend => tốc độ cực nhanh
# ==========================================================

import pandas as pd
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.preprocessing import normalize
from model_state import model_data

# --- Tham số cấu hình ---
TOP_SIMILAR_USERS = 5


# ==========================================================
def build_user_item_matrix():
    """Tạo ma trận user–item (người dùng – quán ăn) từ model_state."""
    data = model_data.get("all_data", pd.DataFrame())

    if data.empty:
        print("⚠️ [CF] all_data rỗng — chưa có dữ liệu trong model_state.")
        return pd.DataFrame()

    # 🧱 Pivot table user–item matrix
    user_item_matrix = data.pivot_table(
        index="user_id",
        columns="restaurant_id",
        values="rating",
        aggfunc="mean"
    ).fillna(0)

    # ✅ Chuẩn hóa theo hàng (mỗi user có vector độ dài 1)
    if not user_item_matrix.empty:
        user_item_matrix = pd.DataFrame(
            normalize(user_item_matrix, norm="l2", axis=1),
            index=user_item_matrix.index,
            columns=user_item_matrix.columns
        )
    else:
        print("⚠️ [CF] user_item_matrix trống.")
    return user_item_matrix


# ==========================================================
def calculate_similarity(user_item_matrix):
    """Tính độ tương đồng giữa các user (cosine similarity)."""
    if user_item_matrix.empty or len(user_item_matrix) < 2:
        return pd.DataFrame(1.0, index=user_item_matrix.index, columns=user_item_matrix.index)

    sim = cosine_similarity(user_item_matrix)
    return pd.DataFrame(sim, index=user_item_matrix.index, columns=user_item_matrix.index)


# ==========================================================
def recommend_for_user(user_id, top_n=5, exclude_user_rated=True):
    """
    Gợi ý dựa trên cộng tác (Collaborative Filtering).
    - exclude_user_rated: loại bỏ quán user đã tương tác.
    """
    restaurants = model_data.get("restaurants", pd.DataFrame())
    user_item_matrix = build_user_item_matrix()

    if user_item_matrix.empty or user_id not in user_item_matrix.index:
        print(f"⚠️ [CF] User {user_id} chưa có dữ liệu hoặc matrix rỗng.")
        return fallback_recommendations(top_n, restaurants)

    similarity_df = calculate_similarity(user_item_matrix)
    similar_users = similarity_df[user_id].drop(user_id).sort_values(ascending=False)

    if similar_users.empty:
        print(f"⚠️ [CF] Không tìm thấy user tương tự cho user {user_id}.")
        return fallback_recommendations(top_n, restaurants)

    top_sim_users = similar_users.head(max(TOP_SIMILAR_USERS, 1))
    user_rated_restaurants = set(user_item_matrix.loc[user_id][user_item_matrix.loc[user_id] > 0].index)

    # 🔹 Tính điểm gợi ý weighted average
    recommendations = {}
    sim_sum = {}

    for sim_user_id, sim_score in top_sim_users.items():
        for rid, rating in user_item_matrix.loc[sim_user_id].items():
            if rating > 0:
                if exclude_user_rated and rid in user_rated_restaurants:
                    continue
                recommendations[rid] = recommendations.get(rid, 0.0) + rating * sim_score
                sim_sum[rid] = sim_sum.get(rid, 0.0) + sim_score

    if not recommendations:
        print(f"⚠️ [CF] Không có quán mới để gợi ý cho user {user_id}.")
        return fallback_recommendations(top_n, restaurants)

    scores = {rid: recommendations[rid] / sim_sum[rid] for rid in recommendations if sim_sum[rid] > 0}
    recs_df = pd.DataFrame(scores.items(), columns=["id", "score"])
    recs_df = recs_df.merge(restaurants[["id", "name"]], on="id", how="left")
    recs_df = recs_df.sort_values("score", ascending=False).head(top_n)

    return recs_df


# ==========================================================
def fallback_recommendations(top_n, restaurants):
    """Gợi ý mặc định khi không có dữ liệu CF."""
    if restaurants.empty:
        return pd.DataFrame(columns=["id", "name", "score"])
    top_restaurants = restaurants.head(top_n)
    return pd.DataFrame({
        "id": top_restaurants["id"],
        "name": top_restaurants["name"],
        "score": 1.0
    })


# ==========================================================
# ✅ Test độc lập
# ==========================================================
if __name__ == "__main__":
    from auto_trainer import start_auto_trainer
    import time

    print("🚀 Khởi động AutoTrainer (test mode)...")
    start_auto_trainer(interval=30)
    time.sleep(5)

    user_test = 4
    recs = recommend_for_user(user_test, top_n=5)
    print(f"🔹 CF (Realtime) gợi ý cho user {user_test}:")
    print(recs)
