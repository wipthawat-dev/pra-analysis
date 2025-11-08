import os
from qdrant_client import QdrantClient
from qdrant_client.http.models import Distance, VectorParams

url = os.getenv("QDRANT_URL", "http://qdrant:6333")
col = os.getenv("QDRANT_COLLECTION", "amulet_clip_v1")
dim = int(os.getenv("EMBED_DIM", 768))

c = QdrantClient(url=url)
print("Ensuring collection:", col)
c.recreate_collection(
    collection_name=col,
    vectors_config=VectorParams(size=dim, distance=Distance.COSINE),
)
print("OK")
