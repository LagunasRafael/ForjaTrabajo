from enum import Enum

class Role(str, Enum):
    ADMIN = "admin"
    CLIENT = "client"
    WORKER = "worker"
