from pydantic import BaseModel
from typing import Optional

class ResourceBase(BaseModel):
    title: str
    url: str
    description: Optional[str] = None

class ResourceCreate(ResourceBase):
    pass

class ResourceResponse(ResourceBase):
    id: int

    model_config = {'from_attributes': True}
