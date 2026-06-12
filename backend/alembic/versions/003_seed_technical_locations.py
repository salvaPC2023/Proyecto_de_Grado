"""Seed technical locations sample data

Revision ID: 003
Revises: 002
Create Date: 2026-06-08
"""
import uuid
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "003"
down_revision: Union[str, None] = "002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

_LOCATIONS = [
    {"sector": "Planta Norte", "subsector": "Sistema Hidráulico", "system": "Bombas", "subsystem": "Bomba Centrífuga B-01"},
    {"sector": "Planta Norte", "subsector": "Sistema Hidráulico", "system": "Bombas", "subsystem": "Bomba Centrífuga B-02"},
    {"sector": "Planta Norte", "subsector": "Sistema Eléctrico", "system": "Transformadores", "subsystem": "Transformador T-01"},
    {"sector": "Planta Norte", "subsector": "Sistema Eléctrico", "system": "Tableros", "subsystem": "Tablero de Distribución TD-01"},
    {"sector": "Planta Sur", "subsector": "Línea de Producción", "system": "Motores", "subsystem": "Motor Principal M-01"},
    {"sector": "Planta Sur", "subsector": "Línea de Producción", "system": "Motores", "subsystem": "Motor Auxiliar M-02"},
    {"sector": "Planta Sur", "subsector": "Refrigeración", "system": "Compresores", "subsystem": "Compresor C-01"},
    {"sector": "Planta Sur", "subsector": "Refrigeración", "system": "Torres de Enfriamiento", "subsystem": "Torre TE-01"},
]


_UUID_TYPE = sa.dialects.postgresql.UUID(as_uuid=True)


def upgrade() -> None:
    insert = sa.text(
        "INSERT INTO technical_locations (id, sector, subsector, system, subsystem) "
        "VALUES (:id, :sector, :subsector, :system, :subsystem)"
    )
    for loc in _LOCATIONS:
        op.execute(
            insert.bindparams(
                sa.bindparam("id", value=uuid.uuid4(), type_=_UUID_TYPE),
                **loc,
            )
        )


def downgrade() -> None:
    op.execute(sa.text("DELETE FROM technical_locations"))
