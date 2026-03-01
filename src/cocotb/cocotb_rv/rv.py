from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable, Optional

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles
from cocotb.handle import SimHandleBase


@dataclass(frozen=True)
class ReadyValidCfg:
    data_bits: int
    idle_value: int = 0
    hold_valid_until_ready: bool = True
    timeout_cycles: Optional[int] = None


class ReadyValidSource:
    """
    Generic ready/valid source driver.

    Drives:
      - data
      - valid
    Observes:
      - ready
    Handshake is assumed when (valid && ready) sampled on a rising edge of clk.
    """

    def __init__(
        self,
        *,
        clk: SimHandleBase,
        data: SimHandleBase,
        valid: SimHandleBase,
        ready: SimHandleBase,
        cfg: ReadyValidCfg,
        name: str = "rv_src",
    ):
        self.clk = clk
        self.data = data
        self.valid = valid
        self.ready = ready
        self.cfg = cfg
        self.name = name

        self._mask = (1 << cfg.data_bits) - 1 if cfg.data_bits > 0 else 0

        # Init to idle
        self.data.value = cfg.idle_value & self._mask
        self.valid.value = 0

        # Lock prevents multiple coroutines interleaving sends
        try:
            from cocotb.triggers import Lock
            self._lock = Lock()
        except Exception:
            self._lock = None

    async def send(self, item: int) -> None:
        if self._lock is not None:
            async with self._lock:
                await self._send_unlocked(item)
        else:
            await self._send_unlocked(item)

    async def send_many(self, items: Iterable[int]) -> None:
        for it in items:
            await self.send(int(it))

    async def _send_unlocked(self, item: int) -> None:
        item &= self._mask
        self.data.value = item

        cycles = 0
        while True:
            self.valid.value = 1

            await RisingEdge(self.clk)

            # Handshake occurs when both high on the sampling edge
            if int(self.valid.value) == 1 and int(self.ready.value) == 1:
                break

            cycles += 1
            if self.cfg.timeout_cycles is not None and cycles >= self.cfg.timeout_cycles:
                self.valid.value = 0
                raise TimeoutError(f"{self.name}: timeout waiting for ready/handshake")

        # Deassert valid and optionally return bus to idle
        self.valid.value = 0
        self.data.value = self.cfg.idle_value & self._mask
