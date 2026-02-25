import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    clock = Clock(dut.clk_i, 10, unit="ns")
    cocotb.start_soon(clock.start())

    dut._log.info("Reset")

    dut.tx_data_valid_i.value = 0;
    dut.tx_data_i.value = 0;

    dut.rx_i.value = 1;

    dut.rst_ni.value = 0

    await ClockCycles(dut.clk_i, 10)

    dut.rst_ni.value = 1

    await ClockCycles(dut.clk_i, 10)

    b = 0x3c
    b = b | 1 << 8 # put stop bit in upper position
    b = b << 1     # shift word over 1 for start bit

    for i in range(10):
        dut.rx_i.value = (b >> i) & 0x1
        await ClockCycles(dut.clk_i, 5)
        print(f"dut.rx_data_o = {dut.rx_data_o.value}")

    await ClockCycles(dut.clk_i, 1)

    print(f"dut.rx_data_o = {dut.rx_data_o.value}")

    assert dut.rx_data_valid_o.value == 1
    assert dut.rx_data_o.value == (b >> 1) & 0xff

    await ClockCycles(dut.clk_i, 1)

