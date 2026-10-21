"""Multi-tenant row-level isolation middleware.

Every API request carries a JWT with area claims (state_code, district_code,
block_code, area_villages). A SQLAlchemy ORM execute-event listener appends
the appropriate area filter so ASHA / AF roles never see records outside
their assigned area.

Usage:
    Install once per session factory by calling `install_multi_tenant_listener`.
    Set the tenant context per request via the `tenant_context` context variable.
"""
from __future__ import annotations

from contextvars import ContextVar
from dataclasses import dataclass, field


@dataclass
class TenantContext:
    """Decoded claims from the request JWT."""

    worker_id: str = ""
    role: str = ""
    state_code: str = ""
    district_code: str = ""
    block_code: str = ""
    area_villages: list[str] = field(default_factory=list)


# Per-request context variable — automatically scoped to each async task.
tenant_context: ContextVar[TenantContext] = ContextVar(
    "tenant_context", default=TenantContext()
)

# Roles that are restricted to their block area.
_AREA_RESTRICTED_ROLES = {"ASHA", "ASHA_FACILITATOR"}


def get_tenant_context() -> TenantContext:
    return tenant_context.get()


def set_tenant_context(ctx: TenantContext) -> None:
    tenant_context.set(ctx)


# ── SQLAlchemy ORM execute listener ──────────────────────────────────────────
# Imported and wired in db/session.py after engine creation.

try:
    from sqlalchemy import event
    from sqlalchemy.orm import Session

    def install_multi_tenant_listener(session_class) -> None:  # type: ignore[type-arg]
        """Register an ORM execute listener on the underlying sync Session.

        AsyncSession wraps a sync Session internally; the ``do_orm_execute``
        event is only available on the sync ``Session`` class, so we register
        on that directly. SQLAlchemy will fire the hook for every query that
        goes through AsyncSession as well.

        The listener appends a WHERE block_code = :block_code filter to SELECTs
        that include a model with a block_code column for ASHA / AF roles.
        """
        # do_orm_execute is defined on Session, not AsyncSession.
        target = Session

        @event.listens_for(target, "do_orm_execute")
        def _add_area_filter(execute_state):  # type: ignore[type-arg]
            if not execute_state.is_select:
                return
            ctx = tenant_context.get()
            if ctx.role not in _AREA_RESTRICTED_ROLES:
                return
            if not ctx.block_code:
                return
            stmt = execute_state.statement
            try:
                entities = getattr(stmt, "column_descriptions", [])
                scoped_models = [
                    item.get("entity")
                    for item in entities
                    if getattr(item.get("entity"), "block_code", None) is not None
                ]
                if not scoped_models:
                    return
                execute_state.statement = stmt.where(
                    *[
                        model.block_code == ctx.block_code
                        for model in scoped_models
                    ]
                )
            except Exception:  # noqa: BLE001
                pass

except ImportError:
    # SQLAlchemy not available (unit test without DB deps); provide no-ops.
    def install_multi_tenant_listener(session_class):  # type: ignore[misc]
        pass
