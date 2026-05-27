from pydantic import BaseModel


class DisputeCreate(BaseModel):
    reason: str


class AdminMessageCreate(BaseModel):
    content: str


class DisputeResolveRequest(BaseModel):
    winner_role: str
