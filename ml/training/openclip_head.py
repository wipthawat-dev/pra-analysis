import torch
import torch.nn as nn

class ClipHead(nn.Module):
    def __init__(self, in_dim=1024, out_dim=768):
        super().__init__()
        self.proj = nn.Sequential(
            nn.Linear(in_dim, 1024), nn.ReLU(),
            nn.Linear(1024, out_dim)
        )

    def forward(self, x):
        z = self.proj(x)
        return torch.nn.functional.normalize(z, dim=-1)
