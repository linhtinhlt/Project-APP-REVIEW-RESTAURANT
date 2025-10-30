from sklearn.metrics.pairwise import cosine_similarity

def compute_similarity(matrix):
    """Tính cosine similarity cho ma trận"""
    return cosine_similarity(matrix)
