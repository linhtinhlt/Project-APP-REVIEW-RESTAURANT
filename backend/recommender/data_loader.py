# ==========================================================
# data_loader.py — Load dữ liệu từ MySQL cho hệ thống AI
# ----------------------------------------------------------
# Cung cấp các hàm load từng bảng và gộp dữ liệu hành vi
# Sử dụng bởi auto_trainer.py để huấn luyện CF + CBF
# ==========================================================

import pandas as pd
from sqlalchemy import create_engine, text

# --- Cấu hình MySQL ---
DB_USER = "root"
DB_PASSWORD = ""   # để trống nếu dùng XAMPP mặc định
DB_HOST = "127.0.0.1"
DB_PORT = "3306"
DB_NAME = "foodreview"


# ==========================================================
# 🧠 Hàm tạo engine kết nối
# ==========================================================
def get_engine():
    """Tạo kết nối MySQL qua SQLAlchemy."""
    url = f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    return create_engine(
        url,
        pool_pre_ping=True,   # kiểm tra kết nối trước khi dùng
        pool_recycle=3600,    # reset kết nối sau 1h tránh timeout
        echo=False
    )


# ==========================================================
# 1️⃣ Load từng bảng gốc
# ==========================================================
def load_reviews():
    """Bảng reviews (user_id, restaurant_id, rating, content)."""
    query = "SELECT user_id, restaurant_id, rating, content FROM reviews"
    with get_engine().connect() as conn:
        df = pd.read_sql(text(query), conn)
    return df


def load_favorites():
    """Bảng favorites, quy đổi thành rating = 5."""
    query = "SELECT user_id, restaurant_id, 5 AS rating FROM favorites"
    with get_engine().connect() as conn:
        df = pd.read_sql(text(query), conn)
    return df


def load_likes():
    """Bảng likes (user_id, review_id) -> rating = 2."""
    query = """
        SELECT l.user_id, r.restaurant_id, 2 AS rating
        FROM likes l
        JOIN reviews r ON l.review_id = r.id
    """
    with get_engine().connect() as conn:
        df = pd.read_sql(text(query), conn)
    return df


def load_comments():
    """Bảng comments (user_id, review_id) -> rating = 1."""
    query = """
        SELECT c.user_id, r.restaurant_id, 1 AS rating
        FROM comments c
        JOIN reviews r ON c.review_id = r.id
    """
    with get_engine().connect() as conn:
        df = pd.read_sql(text(query), conn)
    return df


def load_restaurants():
    """Bảng restaurants (id, name, address, category_id, description...)."""
    query = """
        SELECT id, name, address, latitude, longitude, category_id, description
        FROM restaurants
    """
    with get_engine().connect() as conn:
        df = pd.read_sql(text(query), conn)
    return df


def load_categories():
    """Bảng categories (id, name)."""
    query = "SELECT id, name FROM categories"
    with get_engine().connect() as conn:
        df = pd.read_sql(text(query), conn)
    return df


def load_users():
    """Bảng users (id, name)."""
    query = "SELECT id, name FROM users"
    with get_engine().connect() as conn:
        df = pd.read_sql(text(query), conn)
    return df


# ==========================================================
# 2️⃣ Gộp dữ liệu cho huấn luyện CF + CBF
# ==========================================================
def load_all_data():
    """
    Gộp tất cả hành vi (reviews + favorites + likes + comments)
    thành 1 DataFrame duy nhất: user_id, restaurant_id, rating
    """
    try:
        reviews = load_reviews()[["user_id", "restaurant_id", "rating"]]
        favorites = load_favorites()[["user_id", "restaurant_id", "rating"]]
        likes = load_likes()[["user_id", "restaurant_id", "rating"]]
        comments = load_comments()[["user_id", "restaurant_id", "rating"]]

        # Gộp tất cả hành vi
        all_data = pd.concat(
            [reviews, favorites, likes, comments],
            ignore_index=True
        )

        # Gom nhóm lấy trung bình nếu user có nhiều hành vi trên cùng quán
        all_data = (
            all_data.groupby(["user_id", "restaurant_id"])
            .rating.mean()
            .reset_index()
        )

        print(f"✅ Load dữ liệu huấn luyện thành công: {len(all_data)} bản ghi.")
        return all_data

    except Exception as e:
        print(f"❌ [data_loader] Lỗi khi load dữ liệu: {e}")
        return pd.DataFrame(columns=["user_id", "restaurant_id", "rating"])
