SIM ?= icarus
FST ?= -fst
TOPLEVEL_LANG ?= verilog
SRC_DIR = $(PWD)/../rtl
PROJECT_SOURCES = uart_pkg.sv uart_rx.sv uart_tx.sv uart.sv

SIM_BUILD				= sim_build/rtl
VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))

COMPILE_ARGS 		+= -I$(SRC_DIR)

VERILOG_SOURCES += $(PWD)/uart_tb.sv
TOPLEVEL = uart_tb

COCOTB_TEST_MODULES = uart_test

include $(shell cocotb-config --makefiles)/Makefile.sim
