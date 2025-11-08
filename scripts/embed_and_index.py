import argparse, os
from qdrant_client import QdrantClient
from qdrant_client.http.models import PointStruct
import numpy as np

url = os.getenv("QDRANT_URL", "http://qdrant:6333")
col = os.getenv("QDRANT_COLLECTION", "amulet_clip_v1")
dim = int(os.getenv("EMBED_DIM", 768))

parser = argparse.ArgumentParser()
parser.add_argument('--sample', type=int, default=100)
args = parser.parse_args()

client = QdrantClient(url=url)

points = []
for i in range(args.sample):
    vec = np.random.normal(0,1,(dim,)).astype(np.float32)
    points.append(PointStruct(id=i, vector=vec.tolist(), payload={"tag": "fake-sample"}))

client.upsert(collection_name=col, points=points)
print(f"Inserted {len(points)} points into {col}")
