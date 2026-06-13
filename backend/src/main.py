import asyncio
import sys

# asyncpg SSL is broken under Windows ProactorEventLoop (Python 3.8+).
if sys.platform == "win32":
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy.exc import IntegrityError

from src.adapters.inbound.routers import auth, descriptions, shifts, technical_locations, users, work_orders
from src.adapters.outbound.postgres.database import engine
from src.domain.models.work_order import NoPm01StepError, OtNotAssignedError, StepAlreadyClosedError


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield
    await engine.dispose()


app = FastAPI(title="Maintenance App API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(IntegrityError)
async def integrity_error_handler(request: Request, exc: IntegrityError):
    return JSONResponse(status_code=409, content={"detail": "A conflict occurred with existing data."})


@app.exception_handler(NoPm01StepError)
async def no_pm01_handler(request: Request, exc: NoPm01StepError):
    return JSONResponse(status_code=400, content={"detail": str(exc)})


@app.exception_handler(StepAlreadyClosedError)
async def step_closed_handler(request: Request, exc: StepAlreadyClosedError):
    return JSONResponse(status_code=409, content={"detail": str(exc)})


@app.exception_handler(OtNotAssignedError)
async def ot_not_assigned_handler(request: Request, exc: OtNotAssignedError):
    return JSONResponse(status_code=403, content={"detail": str(exc)})


app.include_router(auth.router, prefix="/api/v1")
app.include_router(descriptions.router, prefix="/api/v1")
app.include_router(users.router, prefix="/api/v1")
app.include_router(shifts.router, prefix="/api/v1")
app.include_router(technical_locations.router, prefix="/api/v1")
app.include_router(work_orders.router, prefix="/api/v1")


@app.get("/health")
async def health():
    return {"status": "ok"}
