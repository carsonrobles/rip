import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    clock = Clock(dut.clk_i, 10, unit="ns")
    cocotb.start_soon(clock.start())

    dut._log.info("Reset")

    dut.push_i.value = 0
    dut.data_i.value = 0
    dut.pop_i.value  = 0

    dut.rst_ni.value = 0

    await ClockCycles(dut.clk_i, 10)

    dut.rst_ni.value = 1

    for i in range(10):
        dut.push_i.value = 1
        dut.data_i.value = i

        await ClockCycles(dut.clk_i, 1)

    dut.push_i.value = 0
    dut.pop_i.value  = 1

    for i in range(10):
        await ClockCycles(dut.clk_i, 1)

        print(dut.empty_o.value)
        print(dut.data_o.value)
        assert dut.empty_o.value == 0
        assert dut.data_o.value == i

    await ClockCycles(dut.clk_i, 1)
    assert dut.empty_o.value == 1

