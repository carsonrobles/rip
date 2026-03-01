from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable, Optional, Union, List

from cocotb.triggers import Timer
from cocotb.handle import SimHandleBase


@dataclass(frozen=True)
class UartConfig:
    baud: int = 115200
    data_bits: int = 8
    stop_bits: int = 1
    parity: Optional[str] = None  # None, "even", "odd" (not implemented below)
    idle_level: int = 1
    lsb_first: bool = True


class UartBitTimer:
    """Shared UART bit-time helper (composition)."""

    _SCALE = {
        "fs": 1e15,
        "ps": 1e12,
        "ns": 1e9,
        "us": 1e6,
        "ms": 1e3,
        "s": 1.0,
    }

    def __init__(self, *, baud: int, time_unit: str = "ns", round_digits: int = 3):
        self.baud = int(baud)
        self.time_unit = time_unit
        self.round_digits = int(round_digits)
        self._bit_time_s = 1.0 / float(self.baud)

        if self.time_unit not in self._SCALE:
            raise ValueError(f"Unsupported time_unit={self.time_unit!r}")

    async def sleep_bits(self, bits: float = 1.0) -> None:
        seconds = self._bit_time_s * float(bits)
        ticks = seconds * self._SCALE[self.time_unit]

        # Keep timings stable for simulators that don't love huge-float precision.
        if self.round_digits is not None:
            ticks = round(ticks, self.round_digits)

        await Timer(ticks, unit=self.time_unit)


class UartTx:
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
        self.name = name
        self.timer = UartBitTimer(baud=self.cfg.baud, time_unit=time_unit)

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

    async def send_byte(self, byte: int) -> None:
        if not (0 <= byte <= 0xFF):
            raise ValueError(f"byte out of range: {byte}")

        if self._lock is not None:
            async with self._lock:
                await self._send_byte_unlocked(byte)
        else:
            await self._send_byte_unlocked(byte)

    async def _send_byte_unlocked(self, byte: int) -> None:
        start_level = 0 if self.cfg.idle_level == 1 else 1

        # Start bit
        self._drive(start_level)
        await self.timer.sleep_bits(1)

        # Data bits
        for i in range(self.cfg.data_bits):
            bit = (byte >> i) & 1 if self.cfg.lsb_first else (byte >> (self.cfg.data_bits - 1 - i)) & 1
            self._drive(bit)
            await self.timer.sleep_bits(1)

        # Parity (not implemented)
        if self.cfg.parity is not None:
            raise NotImplementedError("Parity not implemented")

        # Stop bit(s)
        self._drive(self.cfg.idle_level)
        await self.timer.sleep_bits(self.cfg.stop_bits)

    async def send_bytes(self, data: Union[bytes, bytearray, Iterable[int]]) -> None:
        for b in data:
            await self.send_byte(int(b))


class UartRx:
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
        name: str = "uart_rx",
        strict_framing: bool = True,
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
        self.name = name
        self.strict_framing = strict_framing
        self.timer = UartBitTimer(baud=self.cfg.baud, time_unit=time_unit)

        if self.cfg.parity is not None:
            raise NotImplementedError("Parity not implemented")

    def _sample(self) -> int:
        try:
            return int(self.line.value)
        except Exception:
            return int(self.line.value.integer)

    async def _wait_for_start(self) -> None:
        start_level = 0 if self.cfg.idle_level == 1 else 1

        # If already low (start_level), wait for a transition first to avoid locking onto mid-frame.
        if self._sample() == start_level:
            await self.line.value_change

        # Wait for any edge that results in start_level.
        while True:
            await self.line.value_change
            if self._sample() == start_level:
                return

    async def recv_byte(self) -> int:
        start_level = 0 if self.cfg.idle_level == 1 else 1

        # Wait for start bit edge
        await self._wait_for_start()

        # Validate start bit in the middle (reject glitches)
        await self.timer.sleep_bits(0.5)
        if self._sample() != start_level:
            return await self.recv_byte()

        # Move to the middle of data bit 0: already +0.5 into start, add +1.0 => +1.5 total
        await self.timer.sleep_bits(1.0)

        bits: List[int] = []
        for _ in range(self.cfg.data_bits):
            bits.append(self._sample() & 1)
            await self.timer.sleep_bits(1.0)

        # Stop bits should be idle_level
        for i in range(self.cfg.stop_bits):
            stop_val = self._sample() & 1
            if stop_val != (self.cfg.idle_level & 1) and self.strict_framing:
                raise ValueError(
                    f"{self.name}: Framing error (stop bit={stop_val}, expected={self.cfg.idle_level})"
                )
        
            # don't step a full bit time on the last bit
            if i != self.cfg.stop_bits - 1:
                await self.timer.sleep_bits(1.0)
        
        # do we need to recenter? or is it okay to just wait for next start bit?
        #await self.timer.sleep_bits(0.5)

        value = 0
        if self.cfg.lsb_first:
            for i, b in enumerate(bits):
                value |= (b & 1) << i
        else:
            for b in bits:
                value = (value << 1) | (b & 1)

        return value

    async def recv_bytes(self, n: int) -> bytes:
        out = bytearray()
        for _ in range(n):
            out.append(await self.recv_byte())
        return bytes(out)
