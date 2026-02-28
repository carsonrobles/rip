import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


from uart_cocotb import UartTx


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    clock = Clock(dut.clk_i, 10, unit="ns")
    cocotb.start_soon(clock.start())

    uart_tx = UartTx(dut.rx_i, baud=115200)

    dut._log.info("Reset")

    dut.tx_data_valid_i.value = 0;
    dut.tx_data_i.value = 0;

    dut.rx_i.value = 1;

    dut.rst_ni.value = 0

    await ClockCycles(dut.clk_i, 10)

    dut.rst_ni.value = 1

    await ClockCycles(dut.clk_i, 10)

    NUM_BYTES = 32
    data = bytes(random.getrandbits(8) for _ in range(NUM_BYTES))

    print("**************************************************")
    print("** Test UART Rx                                 **")
    print("**************************************************")
    print(f"sending bytes {data}")
    cocotb.start_soon(uart_tx.send_bytes(data))
    
    prev = None
    recv_cnt = 0
    while recv_cnt < len(data):
        await ClockCycles(dut.clk_i, 1)
        while dut.rx_data_valid_o.value == 0:
            if prev is None or (dut.rx_data_o.value != prev):
                #print(f"dut.rx_data_o = {dut.rx_data_o.value}")
                prev = dut.rx_data_o.value
            await ClockCycles(dut.clk_i, 1)

        print(f"{recv_cnt+1}/{len(data)}: received byte {hex(dut.rx_data_o.value)}, expecting byte {hex(data[recv_cnt])}")
        assert dut.rx_data_valid_o.value == 1
        assert dut.rx_data_o.value == data[recv_cnt] & 0xff
        recv_cnt += 1

    await ClockCycles(dut.clk_i, 1)

