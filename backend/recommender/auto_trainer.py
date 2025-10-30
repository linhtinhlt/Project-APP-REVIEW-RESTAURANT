# ==========================================================
# auto_trainer.py — Tự động nạp dữ liệu & huấn luyện lại model AI
# ==========================================================

import time
import threading
from datetime import datetime
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.preprocessing import normalize
from data_loader import load_all_data, load_restaurants, load_categories
from model_state import model_data


# ==========================================================
# ⚙️ Build TF-IDF Feature Matrix (CBF)
# ==========================================================
def build_feature_matrix(restaurants, categories):
    try:
        restaurants = restaurants.merge(
            categories.rename(columns={"name": "category_name"}),
            left_on="category_id", right_on="id",
            how="left", suffixes=("", "_cat")
        )

        restaurants["category_name"] = restaurants["category_name"].fillna("")
        restaurants["description"] = restaurants["description"].fillna("")

        # ⚡ Nhấn mạnh danh mục
        restaurants["feature_text"] = (
            restaurants["name"].fillna("") + " " +
            (restaurants["category_name"] + " ") * 3 +
            restaurants["description"]
        )

        # ⚙️ TF-IDF vectorization (tối ưu tiếng Việt)
        tfidf = TfidfVectorizer(ngram_range=(1, 2), min_df=1)
        feature_matrix = tfidf.fit_transform(restaurants["feature_text"])
        feature_matrix = normalize(feature_matrix, axis=0)

        return feature_matrix

    except Exception as e:
        print(f"❌ [AutoTrainer] Lỗi build feature_matrix: {e}")
        return None


# ==========================================================
# ⚙️ Build User–Item Matrix (CF)
# ==========================================================
def build_user_item_matrix(all_data):
    try:
        if all_data.empty:
            return None

        user_item = all_data.pivot_table(
            index="user_id",
            columns="restaurant_id",
            values="rating",
            aggfunc="mean"
        ).fillna(0)

        # ✅ Chuẩn hóa vector mỗi user
        user_item = pd.DataFrame(
            normalize(user_item, norm="l2", axis=1),
            index=user_item.index,
            columns=user_item.columns
        )
        return user_item

    except Exception as e:
        print(f"❌ [AutoTrainer] Lỗi build user_item_matrix: {e}")
        return None


# ==========================================================
# 🔁 Auto update model loop
# ==========================================================
def auto_update(interval=60):
    while True:
        try:
            print("🔄 [AutoTrainer] Đang tải dữ liệu từ MySQL...")

            all_data = load_all_data()
            restaurants = load_restaurants()
            categories = load_categories()

            if all_data.empty or restaurants.empty:
                print("⚠️ [AutoTrainer] Dữ liệu rỗng — bỏ qua vòng này.")
                time.sleep(interval)
                continue

            feature_matrix = build_feature_matrix(restaurants, categories)
            user_item_matrix = build_user_item_matrix(all_data)

            model_data["all_data"] = all_data
            model_data["restaurants"] = restaurants
            model_data["feature_matrix"] = feature_matrix
            model_data["user_item_matrix"] = user_item_matrix
            model_data["last_update"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

            print(f"✅ [AutoTrainer] Model cập nhật: {len(restaurants)} quán, {len(all_data)} tương tác")
            print(f"🕓 Lần cập nhật cuối: {model_data['last_update']}")

        except Exception as e:
            print(f"❌ [AutoTrainer] Lỗi cập nhật: {e}")

        time.sleep(interval)


# ==========================================================
# 🚀 Start AutoTrainer Thread
# ==========================================================
def start_auto_trainer(interval=60):
    thread = threading.Thread(target=auto_update, args=(interval,), daemon=True)
    thread.start()
    print(f"🚀 [AutoTrainer] Khởi động — cập nhật mỗi {interval} giây.")


# ==========================================================
# 🔍 Test thủ công
# ==========================================================
if __name__ == "__main__":
    print("🧠 Đang khởi động AutoTrainer thủ công...")
    start_auto_trainer(interval=30)
    while True:
        time.sleep(10)
