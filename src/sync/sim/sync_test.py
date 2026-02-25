import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    clock = Clock(dut.clk_i, 10, unit="ns")
    cocotb.start_soon(clock.start())

    dut.async_i.value = 0;

    await ClockCycles(dut.clk_i, 10)

    dut.async_i.value = 1;
    assert dut.sync_o.value == 0
    await ClockCycles(dut.clk_i, 1)

    dut.async_i.value = 0;
    assert dut.sync_o.value == 0
    await ClockCycles(dut.clk_i, 1)

    assert dut.sync_o.value == 0
    await ClockCycles(dut.clk_i, 1)

    assert dut.sync_o.value == 1
    await ClockCycles(dut.clk_i, 1)

    assert dut.sync_o.value == 0
    await ClockCycles(dut.clk_i, 1)

    await ClockCycles(dut.clk_i, 1)

