# ==========================================================
# evaluate.py — Đánh giá độ chính xác CF / CBF / Hybrid (Realtime)
# ----------------------------------------------------------
# Sử dụng dữ liệu đã được auto_trainer cập nhật vào model_state
# ==========================================================

import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split

from cf import recommend_for_user as cf_recommend_for_user
from cbf import recommend_cbf
from hybrid import hybrid_recommend
from model_state import model_data


# ==========================================================
# 🧩 1️⃣ Lấy dữ liệu từ model_state
# ==========================================================
all_data = model_data.get("all_data", pd.DataFrame())

if all_data.empty:
    print("⚠️ Chưa có dữ liệu trong model_state — hãy chạy auto_trainer trước.")
    exit()

# Chia train/test (để mô phỏng offline evaluation)
train_data, test_data = train_test_split(all_data, test_size=0.2, random_state=42)


# ==========================================================
# 🧮 2️⃣ Metric functions
# ==========================================================
def precision_recall_at_k(recommended_ids, actual_ids, k=5):
    recommended_ids = recommended_ids[:k]
    recommended_set = set(recommended_ids)
    actual_set = set(actual_ids)
    true_positives = len(recommended_set & actual_set)
    precision = true_positives / k
    recall = true_positives / len(actual_set) if actual_set else 0
    return precision, recall


def dcg_at_k(recommended_ids, actual_ids, k=5):
    recommended_ids = recommended_ids[:k]
    dcg = 0.0
    for i, rid in enumerate(recommended_ids):
        if rid in actual_ids:
            dcg += 1 / (np.log2(i + 2))
    return dcg


def ndcg_at_k(recommended_ids, actual_ids, k=5):
    dcg = dcg_at_k(recommended_ids, actual_ids, k)
    idcg = sum(1 / (np.log2(i + 2)) for i in range(min(len(actual_ids), k)))
    return dcg / idcg if idcg > 0 else 0


# ==========================================================
# 🚀 3️⃣ Đánh giá tất cả user trong test
# ==========================================================
users = test_data['user_id'].unique()
metrics = {'CF': [], 'CBF': [], 'Hybrid': []}

print(f"🧪 Đang đánh giá trên {len(users)} user...")

for user_id in users:
    user_test = test_data[test_data['user_id'] == user_id]
    actual_ids = user_test['restaurant_id'].tolist()

    # --- CF ---
    cf_recs = cf_recommend_for_user(user_id, top_n=5)
    cf_ids = cf_recs['id'].tolist()
    p_cf, r_cf = precision_recall_at_k(cf_ids, actual_ids)
    ndcg_cf = ndcg_at_k(cf_ids, actual_ids)
    metrics['CF'].append((p_cf, r_cf, ndcg_cf))

    # --- CBF ---
    cbf_recs = recommend_cbf(user_id, top_n=5)
    cbf_ids = cbf_recs['id'].tolist()
    p_cbf, r_cbf = precision_recall_at_k(cbf_ids, actual_ids)
    ndcg_cbf = ndcg_at_k(cbf_ids, actual_ids)
    metrics['CBF'].append((p_cbf, r_cbf, ndcg_cbf))

    # --- Hybrid ---
    hybrid_recs = hybrid_recommend(user_id, top_n=5)
    hybrid_ids = hybrid_recs['id'].tolist()
    p_h, r_h = precision_recall_at_k(hybrid_ids, actual_ids)
    ndcg_h = ndcg_at_k(hybrid_ids, actual_ids)
    metrics['Hybrid'].append((p_h, r_h, ndcg_h))


# ==========================================================
# 📊 4️⃣ Tổng hợp kết quả trung bình
# ==========================================================
print("\n===== 📈 KẾT QUẢ ĐÁNH GIÁ =====")
for model in ['CF', 'CBF', 'Hybrid']:
    p_avg = np.mean([x[0] for x in metrics[model]])
    r_avg = np.mean([x[1] for x in metrics[model]])
    ndcg_avg = np.mean([x[2] for x in metrics[model]])
    print(f"{model:<8} | Precision@5: {p_avg:.3f} | Recall@5: {r_avg:.3f} | NDCG@5: {ndcg_avg:.3f}")
