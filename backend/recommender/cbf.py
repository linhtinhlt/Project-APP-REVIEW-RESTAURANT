# ==========================================================
# cbf.py — Content-Based Filtering (Realtime version)
# ----------------------------------------------------------
# Sử dụng dữ liệu được cập nhật liên tục từ model_state
# (do auto_trainer.py tự động nạp & huấn luyện lại)
# ==========================================================

import numpy as np
import pandas as pd
from sklearn.metrics.pairwise import cosine_similarity
from model_state import model_data


def recommend_cbf(user_id, top_n=5, exclude_seen=True):
    """
    Gợi ý quán ăn cho user dựa trên đặc điểm quán (Content-Based Filtering).
    Dữ liệu được lấy trực tiếp từ model_state (RAM), không đọc DB mỗi lần.
    """
    # ✅ Lấy dữ liệu đã được auto_trainer cập nhật
    restaurants = model_data.get("restaurants", pd.DataFrame())
    all_data = model_data.get("all_data", pd.DataFrame())
    feature_matrix = model_data.get("feature_matrix", None)

    # Kiểm tra model đã sẵn sàng chưa
    if restaurants.empty or all_data.empty or feature_matrix is None:
        print("⚠️ [CBF] Model chưa sẵn sàng hoặc dữ liệu rỗng.")
        return pd.DataFrame(columns=["id", "name", "score"])

    # Lấy các quán user từng tương tác
    user_items = all_data[all_data["user_id"] == user_id]

    # Cold-start: user chưa từng có hành vi nào
    if user_items.empty:
        top_restaurants = (
            all_data.groupby("restaurant_id").size()
            .sort_values(ascending=False)
            .head(top_n).index
        )
        recs = restaurants[restaurants["id"].isin(top_restaurants)][["id", "name"]].copy()
        recs["score"] = 1.0
        return recs

    # Lấy index quán đã tương tác
    user_idx = restaurants[restaurants["id"].isin(user_items["restaurant_id"])].index

    # Vector rating tương ứng (mặc định = 1 nếu thiếu)
    ratings = (
        user_items.set_index("restaurant_id")
        .reindex(restaurants.loc[user_idx, "id"])
        ["rating"].fillna(1)
        .values.reshape(-1, 1)
    )

    # Hồ sơ người dùng = trung bình có trọng số của các vector đặc trưng quán
    weighted_sum = feature_matrix[user_idx].T @ ratings
    denom = ratings.sum() if ratings.sum() != 0 else 1.0
    user_profile = (weighted_sum / denom).T  # (1, n_features)

    # Tính độ tương đồng cosine giữa hồ sơ user và tất cả quán
    sim = cosine_similarity(user_profile, feature_matrix).flatten()

    # Loại bỏ quán đã tương tác để tránh trùng
    if exclude_seen:
        sim[user_idx] = -1e9

    # Chọn Top N
    top_idx = sim.argsort()[::-1][:top_n]
    recs = restaurants.iloc[top_idx][["id", "name"]].copy()
    recs["score"] = sim[top_idx]
    return recs


# ==========================================================
# ✅ Test độc lập (chạy riêng để kiểm tra)
# ==========================================================
if __name__ == "__main__":
    from auto_trainer import start_auto_trainer
    import time

    print("🚀 Khởi động AutoTrainer (test mode)...")
    start_auto_trainer(interval=30)
    time.sleep(5)

    user_test = 4
    recs = recommend_cbf(user_id=user_test, top_n=5)
    print(f"🔹 Gợi ý CBF (Realtime) cho user {user_test}:")
    for _, row in recs.iterrows():
        print(f"- {row['name']} (id={row['id']}, score={row['score']:.3f})")
