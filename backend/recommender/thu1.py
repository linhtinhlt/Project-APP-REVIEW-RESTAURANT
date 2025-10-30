import pandas as pd
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.preprocessing import normalize
from sklearn.metrics.pairwise import cosine_similarity
from scipy import sparse
from data_loader import (
    load_reviews, load_favorites, load_likes, load_comments,
    load_restaurants, load_categories
)

# ---- Trọng số hành vi ----
WEIGHT_REVIEW = 5
WEIGHT_FAVORITE = 5
WEIGHT_LIKE = 3
WEIGHT_COMMENT = 1

# ---- Load dữ liệu ----
reviews = load_reviews()[["user_id", "restaurant_id", "rating"]]
favorites = load_favorites()[["user_id", "restaurant_id", "rating"]]
likes = load_likes()[["user_id", "restaurant_id", "rating"]]
comments = load_comments()[["user_id", "restaurant_id", "rating"]]
restaurants = load_restaurants()[["id", "name", "category_id", "description"]]
categories = load_categories()[["id", "name"]].rename(columns={"name": "category_name"})

# ---- Gộp hành vi với trọng số ----
reviews["rating"] *= WEIGHT_REVIEW
favorites["rating"] *= WEIGHT_FAVORITE
likes["rating"] *= WEIGHT_LIKE
comments["rating"] *= WEIGHT_COMMENT

all_data = pd.concat([reviews, favorites, likes, comments], ignore_index=True)
all_data = all_data.groupby(["user_id", "restaurant_id"])["rating"].mean().reset_index()

# ---- Kết hợp nhà hàng + danh mục ----
restaurants = restaurants.merge(categories, left_on="category_id", right_on="id", how="left", suffixes=("", "_cat"))

# ---- Feature text: name + category_name + description ----
restaurants["description"] = restaurants["description"].fillna("")
restaurants["category_name"] = restaurants["category_name"].fillna("")

# ⚡ Tăng trọng số danh mục (nhân 3 lần để mô hình coi trọng category hơn)
restaurants["feature_text"] = (
    restaurants["name"].fillna("") + " " +
    (restaurants["category_name"] + " ") * 3 +  # thêm category nhiều lần
    restaurants["description"]
)

# ---- TF-IDF trên feature_text ----
tfidf = TfidfVectorizer(stop_words="english")
feature_matrix = tfidf.fit_transform(restaurants["feature_text"])

# Chuẩn hóa
feature_matrix = normalize(feature_matrix, axis=0)

# ---- Hàm recommend CBF ----
def recommend_cbf(user_id, top_n=5, min_interactions=0):  # ⬅️ HẠ XUỐNG 0 để không bỏ quán nào khi test
    user_items = all_data[all_data["user_id"] == user_id]

    # Nếu user chưa có hành vi nào
    if user_items.empty:
        top_restaurants = all_data.groupby("restaurant_id").size().sort_values(ascending=False).head(top_n).index
        recs = restaurants[restaurants["id"].isin(top_restaurants)][["id", "name"]].copy()
        recs["score"] = 1.0
        return recs

    # Chỉ lấy quán đủ tương tác
    restaurant_counts = all_data.groupby("restaurant_id").size()
    # ⬇️ Hạ tiêu chuẩn — cho phép tất cả quán đều hợp lệ
    valid_restaurants = restaurant_counts[restaurant_counts >= min_interactions].index

    # ⬇️ Nếu test dữ liệu nhỏ, có thể bỏ lọc hoàn toàn:
    # valid_restaurants = restaurants["id"]

    user_items = user_items[user_items["restaurant_id"].isin(valid_restaurants)]

    # Nếu user chỉ còn 0 quán sau khi lọc, bỏ qua bước lọc để tránh lỗi
    if user_items.empty:
        user_items = all_data[all_data["user_id"] == user_id]

    user_idx = restaurants[restaurants["id"].isin(user_items["restaurant_id"])].index
    ratings = user_items.set_index("restaurant_id").reindex(
        restaurants.loc[user_idx, "id"]
    )["rating"].values.reshape(-1, 1)

    # Hồ sơ người dùng
    user_profile = feature_matrix[user_idx].multiply(ratings).mean(axis=0)
    user_profile = np.asarray(user_profile)

    # Tính độ tương đồng cosine
    sim = cosine_similarity(user_profile, feature_matrix).flatten()

    # Giảm điểm quán đã tương tác (tránh lặp)
    sim[user_idx] *= 0.5

    top_idx = sim.argsort()[::-1][:top_n]
    recs = restaurants.iloc[top_idx][["id", "name"]].copy()
    recs["score"] = sim[top_idx]
    return recs


if __name__ == "__main__":
    user_test = 4
    recs = recommend_cbf(user_id=user_test, top_n=5)
    print(f"🔹 CBF dựa trên hành vi + đặc điểm gợi ý cho user {user_test}:")
    for _, row in recs.iterrows():
        print(f"- {row['name']} (id={row['id']}, score={row['score']:.3f})")
