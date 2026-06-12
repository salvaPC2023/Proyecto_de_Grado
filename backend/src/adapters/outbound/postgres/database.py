import ssl

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from src.config import settings


class Base(DeclarativeBase):
    pass


def _build_engine():
    url = settings.DATABASE_URL
    connect_args = {}

    # Strip ?ssl= query param and pass SSL via connect_args for asyncpg
    if "?ssl=" in url or "&ssl=" in url:
        url = (
            url
            .replace("?ssl=require", "")
            .replace("?ssl=true", "")
            .replace("&ssl=require", "")
            .replace("&ssl=true", "")
        )
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
        connect_args["ssl"] = ctx

    return create_async_engine(url, echo=False, connect_args=connect_args)


engine = _build_engine()
AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False)


async def get_session() -> AsyncSession:
    async with AsyncSessionLocal() as session:
        yield session
