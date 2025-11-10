from pydantic import BaseModel
from typing import List, Any, Optional

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
    prediction_id: Optional[str] = None
