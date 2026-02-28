from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable, Optional, Union

from cocotb.triggers import Timer
from cocotb.handle import SimHandleBase


@dataclass(frozen=True)
class UartConfig:
    baud: int = 115200
    data_bits: int = 8         # typically 8
    stop_bits: int = 1         # 1 or 2
    parity: Optional[str] = None  # None, "even", "odd" (not implemented below)
    idle_level: int = 1        # UART idle is high in standard TTL UART
    lsb_first: bool = True     # UART is LSB-first


class UartTx:
    """
    Minimal UART TX driver for cocotb.

    - Default: 8N1, LSB-first, idle-high.
    - Drives a *wire* (usually DUT RX pin).
    - Timing uses Timer with picosecond resolution by default.

    Notes:
      * Parity is currently not implemented (config is there if you extend it).
      * Concurrency: send_* methods are guarded by an internal lock so multiple
        coroutines won't interleave frames.
    """

    def __init__(
        self,
        line: SimHandleBase,
        *,
        baud: int = 115200,
        data_bits: int = 8,
        stop_bits: int = 1,
        parity: Optional[str] = None,
        idle_level: int = 1,
        time_unit: str = "ns",
        name: str = "uart_tx",
    ):
        self.line = line
        self.cfg = UartConfig(
            baud=baud,
            data_bits=data_bits,
            stop_bits=stop_bits,
            parity=parity,
            idle_level=idle_level,
            lsb_first=True,
        )
        self.time_unit = time_unit
        self.name = name

        # Bit time in chosen units.
        # We compute in seconds then convert to ps/ns/us/etc via cocotb Timer units.
        self._bit_time_s = 1.0 / float(self.cfg.baud)

        # Internal lock to prevent interleaving frames
        try:
            from cocotb.triggers import Lock
            self._lock = Lock()
        except Exception:
            self._lock = None

        # Initialize line to idle
        self._drive(self.cfg.idle_level)

    def _drive(self, val: int) -> None:
        self.line.value = int(val)

    async def _sleep_bit(self, bits: float = 1.0) -> None:
        # Cocotb Timer takes a numeric quantity in the given units; we convert seconds.
        seconds = self._bit_time_s * float(bits)

        # Convert seconds -> requested unit count
        # (Timer supports: fs, ps, ns, us, ms, sec)
        scale = {
            "fs": 1e15,
            "ps": 1e12,
            "ns": 1e9,
            "us": 1e6,
            "ms": 1e3,
            "s": 1.0,
        }
        if self.time_unit not in scale:
            raise ValueError(f"Unsupported time_unit={self.time_unit!r}")

        ticks = round(seconds * scale[self.time_unit], 3)
        # Keep at least some resolution; cocotb can handle floats, but rounding helps stability
        await Timer(ticks, unit=self.time_unit)

    async def send_byte(self, byte: int) -> None:
        if not (0 <= byte <= 0xFF):
            raise ValueError(f"byte out of range: {byte}")

        if self._lock is not None:
            async with self._lock:
                await self._send_byte_unlocked(byte)
        else:
            await self._send_byte_unlocked(byte)

    async def _send_byte_unlocked(self, byte: int) -> None:
        # Ensure idle before start
        self._drive(self.cfg.idle_level)
        # Optional: short idle guard (comment out if you don't want it)
        # await self._sleep_bit(0.25)

        start_level = 0 if self.cfg.idle_level == 1 else 1
        self._drive(start_level)
        await self._sleep_bit(1)

        for i in range(self.cfg.data_bits):
            bit = (byte >> i) & 1 if self.cfg.lsb_first else (byte >> (self.cfg.data_bits - 1 - i)) & 1
            self._drive(bit)
            await self._sleep_bit(1)

        if self.cfg.parity is not None:
            raise NotImplementedError("Parity not implemented")

        self._drive(self.cfg.idle_level)
        await self._sleep_bit(self.cfg.stop_bits)

    async def send_bytes(self, data: Union[bytes, bytearray, Iterable[int]]) -> None:
        for b in data:
            await self.send_byte(int(b))

