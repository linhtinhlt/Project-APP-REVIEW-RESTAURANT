# hybrid.py
import pandas as pd
from cf import recommend_for_user as cf_recommend_for_user
from cbf import recommend_cbf
from sklearn.preprocessing import MinMaxScaler

def hybrid_recommend(user_id, top_n=5, alpha_cf=0.6, alpha_cbf=0.4, min_ratings=0):
    """
    Mô hình kết hợp CF + CBF.
    - alpha_cf, alpha_cbf: trọng số CF/CBF (tổng = 1)
    - Nếu 1 trong 2 mô hình không có dữ liệu → fallback sang mô hình còn lại.
    """

    # --- CF ---
    cf_df = cf_recommend_for_user(user_id, top_n=50, exclude_user_rated=True)
    if cf_df is None or cf_df.empty:
        print("⚠️ CF rỗng → fallback sang CBF.")
        return recommend_cbf(user_id, top_n=top_n)

    # --- CBF ---
    cbf_df = recommend_cbf(user_id, top_n=50)
    if cbf_df is None or cbf_df.empty:
        print("⚠️ CBF rỗng → fallback sang CF.")
        return cf_df.rename(columns={'score': 'score_final'}).head(top_n)

    # --- Chuẩn hóa cột ---
    cf_df = cf_df.rename(columns={'score': 'score_cf'})
    cbf_df = cbf_df.rename(columns={'score': 'score_cbf'})

    # --- Merge theo id (tránh lỗi khi name khác nhau) ---
    hybrid_df = pd.merge(cf_df[['id', 'score_cf']], cbf_df[['id', 'score_cbf']], on='id', how='outer').fillna(0)

    # --- Normalize cả 2 score về 0–1 ---
    scaler = MinMaxScaler()
    hybrid_df[['score_cf', 'score_cbf']] = scaler.fit_transform(hybrid_df[['score_cf', 'score_cbf']])

    # --- Tính điểm tổng ---
    hybrid_df['score_final'] = alpha_cf * hybrid_df['score_cf'] + alpha_cbf * hybrid_df['score_cbf']

    # --- Nối lại tên quán (ưu tiên theo CF nếu trùng) ---
    all_names = pd.concat([
        cf_df[['id', 'name']],
        cbf_df[['id', 'name']]
    ]).drop_duplicates(subset='id', keep='first')
    hybrid_df = hybrid_df.merge(all_names, on='id', how='left')

    # --- Sort & chọn top_n ---
    top_recs = hybrid_df.sort_values('score_final', ascending=False).head(top_n).reset_index(drop=True)

    return top_recs[['id', 'name', 'score_final']]


# Test trực tiếp
if __name__ == "__main__":
    recs = hybrid_recommend(user_id=4, top_n=5, alpha_cf=0.6, alpha_cbf=0.4)
    print("🔹 Gợi ý Hybrid (chuẩn hóa) cho user 4:")
    for _, row in recs.iterrows():
        print(f"- {row['name']} (id={row['id']}, score={row['score_final']:.3f})")
