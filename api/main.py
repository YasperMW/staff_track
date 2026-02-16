from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from endpoints import auth_endpoints
from database import engine
from models.db_models import Base
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Staff Track API",
    description="API for Staff Track Hospital Management System",
    version="1.0.0"
)

# Configure CORS
cors_origins = os.getenv("CORS_ORIGINS", "*").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth_endpoints.router, prefix="/auth", tags=["auth"])

@app.get("/")
async def root():
    return {"message": "Staff Track API is running"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "version": "1.0.0"}

if __name__ == "__main__":
    import uvicorn
    host = os.getenv("API_HOST", "0.0.0.0")
    port = int(os.getenv("API_PORT", "8000"))  # Changed to match Flutter config
    debug = os.getenv("DEBUG", "false").lower() == "true"
    uvicorn.run(app, host=host, port=port, reload=debug)
