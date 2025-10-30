from flask import Flask, request, jsonify
from hybrid import hybrid_recommend
from auto_trainer import start_auto_trainer
from model_state import model_summary, model_data
import os

app = Flask(__name__)

# 🚀 Chỉ khởi động auto-trainer 1 lần khi Flask reload
if not app.debug or os.environ.get("WERKZEUG_RUN_MAIN") == "true":
    start_auto_trainer(interval=60)


# ==========================================================
# 🧠 API chính: Gợi ý quán ăn
# ==========================================================
@app.route("/recommend", methods=["GET"])
def recommend():
    try:
        user_id = request.args.get("user_id", type=int)
        top_n = request.args.get("top_n", default=5, type=int)
        alpha_cf = request.args.get("alpha_cf", default=0.6, type=float)
        alpha_cbf = request.args.get("alpha_cbf", default=0.4, type=float)
        min_ratings = request.args.get("min_ratings", default=1, type=int)

        if user_id is None:
            return jsonify({"error": "user_id is required"}), 400

        # Kiểm tra model đã sẵn sàng chưa
        if (
            model_data.get("all_data") is None or
            model_data.get("restaurants") is None
        ):
            return jsonify({"error": "Model chưa sẵn sàng, vui lòng thử lại sau"}), 503

        # 🔹 Gọi hàm gợi ý
        top_recs = hybrid_recommend(
            user_id=user_id,
            top_n=top_n,
            alpha_cf=alpha_cf,
            alpha_cbf=alpha_cbf,
            min_ratings=min_ratings
        )

        recommendations = top_recs.rename(columns={'score_final': 'score'}).to_dict(orient='records')

        return jsonify({
            "user_id": user_id,
            "recommendations": recommendations
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ==========================================================
# 🔍 API kiểm tra trạng thái model
# ==========================================================
@app.route("/model-status", methods=["GET"])
def model_status():
    return jsonify(model_summary())


# ==========================================================
# 🚀 Khởi chạy server Flask
# ==========================================================
if __name__ == "__main__":
    app.run(host="172.20.10.10", port=5000, debug=False)
