from pydantic import BaseModel
from typing import List, Any

class SimilarItem(BaseModel):
    id: str
    similarity: float
    thumb_url: str | None = None

class AnalyzeResponse(BaseModel):
    verdict: str
    score: float
    model_version: str
    topk: List[SimilarItem]
    heatmaps: List[Any]
