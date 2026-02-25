# common.mk — shared rules for all IPs under src/
#
# Each IP Makefile should set:
#   IP_TOP       (top level ip module)
#   RTL_DIR      (default: rtl)
#   SIM_DIR      (default: sim)
#   RTL_SOURCES  (optional; default: all .sv/.v in RTL_DIR)
#
# And optionally override:
#   VERILATOR_FLAGS
RTL_DIR      ?= rtl
SIM_DIR      ?= sim
RTL_SOURCES  ?= $(wildcard $(RTL_DIR)/*.sv) $(wildcard $(RTL_DIR)/*.v)

VERILATOR    ?= verilator

VERILATOR_FLAGS ?= --lint-only --Wall
#VERILATOR_INC   ?= -I$(RTL_DIR)

YOSYS ?= yosys
YOSYS_OUT_DIR ?= synth_build
YOSYS_JSON ?= $(YOSYS_OUT_DIR)/$(IP_TOP).json
YOSYS_STAT ?= $(YOSYS_OUT_DIR)/$(IP_TOP).stat

define assert_defined
  @if [ -z "$($(1))" ]; then \
    echo "ERROR: $(IP_TOP): variable $(1) is required"; \
    exit 1; \
  fi
endef

define assert_files
  @if [ -z "$(strip $(1))" ]; then \
    echo "ERROR: $(IP_TOP): no RTL sources found (set RTL_SOURCES or check $(RTL_DIR))"; \
    exit 1; \
  fi
endef

.PHONY: echo sim lint synth

echo:
	@echo "==> [$(IP_TOP)] echo"
	@echo "IP_TOP = $(IP_TOP)"
	@echo "RTL_DIR = $(RTL_DIR)"
	@echo "SIM_DIR = $(SIM_DIR)"
	@echo "RTL_SOURCES = $(RTL_SOURCES)"
	@echo "VERILATOR = $(VERILATOR)"
	@echo "VERILATOR_FLAGS = $(VERILATOR_FLAGS)"
	@echo "VERILATOR_INC = $(VERILATOR_INC)"

# TODO: for now this calls sim.mk in sim folder, can this be integrated here?
sim:
	@echo "==> [$(IP_TOP)] sim"
	@$(MAKE) -C $(SIM_DIR) -f sim.mk clean
	@$(MAKE) -C $(SIM_DIR) -f sim.mk

lint:
	@echo "==> [$(IP_TOP)] lint"
	$(call assert_files,$(RTL_SOURCES))
	$(call assert_defined,IP_TOP)
	@$(VERILATOR) $(VERILATOR_FLAGS) $(VERILATOR_INC) --top-module $(IP_TOP) $(RTL_SOURCES)

synth:
	@echo "==> [$(IP_TOP)] synth"
	$(call assert_files,$(RTL_SOURCES))
	$(call assert_defined,IP_TOP)
	@mkdir -p $(YOSYS_OUT_DIR)
	@$(YOSYS) -p "\
		read_verilog -sv $(RTL_SOURCES); \
		hierarchy -check -top $(IP_TOP); \
		proc; opt; \
		fsm; opt; \
		memory; opt; \
		techmap; opt; \
    abc -g AND,NAND,OR,NOR,XOR,XNOR,MUX; \
		clean; \
    tee -o $(YOSYS_STAT) stat -top $(IP_TOP); \
		write_json $(YOSYS_JSON); \
	"
