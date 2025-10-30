# ==========================================================
# model_state.py
# ----------------------------------------------------------
# Giữ dữ liệu và mô hình đang hoạt động trong bộ nhớ (RAM)
# Dùng chung cho CBF, CF, và Hybrid
# ==========================================================

import pandas as pd

# Biến toàn cục model_data sẽ chứa các dữ liệu mới nhất
# được cập nhật định kỳ bởi auto_trainer.py
model_data = {
    # Dữ liệu gốc từ MySQL
    "restaurants": pd.DataFrame(),    # danh sách quán ăn
    "all_data": pd.DataFrame(),       # dữ liệu gộp (review + like + favorite + comment)

    # Ma trận và mô hình đã train
    "feature_matrix": None,           # TF-IDF feature cho CBF
    "user_item_matrix": None,         # Ma trận user-item cho CF

    # Thông tin cập nhật
    "last_update": None               # Thời gian cập nhật gần nhất
}

# ==========================================================
# ⚙️ Hỗ trợ kiểm tra nhanh trạng thái model
# ==========================================================

def model_summary():
    """Trả về thông tin tóm tắt về trạng thái hiện tại của model."""
    summary = {
        "restaurants": len(model_data["restaurants"]),
        "interactions": len(model_data["all_data"]),
        "feature_matrix_ready": model_data["feature_matrix"] is not None,
        "user_item_matrix_ready": model_data["user_item_matrix"] is not None,
        "last_update": model_data["last_update"]
    }
    return summary


if __name__ == "__main__":
    # Test nhanh
    print("🔍 Trạng thái model hiện tại:")
    print(model_summary())
