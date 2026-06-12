from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/maintenance_db"
    JWT_SECRET_KEY: str = "change-me-in-production-use-a-long-random-string"
    JWT_EXPIRE_HOURS: int = 24
    DEFAULT_TECHNICIAN_PASSWORD: str = "COLBO2026"
    SUPERVISOR_USERNAME: str = "admin"
    SUPERVISOR_PASSWORD: str = "Admin2026"
    SERVER_TIMEZONE: str = "America/La_Paz"


settings = Settings()
