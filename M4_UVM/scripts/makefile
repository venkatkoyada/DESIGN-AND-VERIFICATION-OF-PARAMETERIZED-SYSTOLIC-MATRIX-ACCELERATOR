# Makefile for Milestone 4 — UVM Testbench
# Systolic Array Matrix-Multiply Accelerator
#
# Usage:
#   make          — compile + simulate (default)
#   make all      — same as make (compile + simulate)
#   make wave     — open Verdi waveform after simulation
#   make cov      — generate coverage report
#   make clean    — remove all generated files

VCS   = vcs
VERDI = verdi

SEED ?= 42

# ── RTL source files ──────────────────────────────────────────────────────────
RTL = ../rtl/pe.sv              \
      ../rtl/input_skew.sv      \
      ../rtl/controller.sv      \
      ../rtl/systolic_array.sv  \
      ../rtl/mm_accelerator_top.sv

# ── UVM Testbench top file ────────────────────────────────────────────────────
# All UVM class files are `included by tb_top.sv — do NOT list them separately
# (VCS would see duplicate class definitions if listed here)
TB = tb_top.sv

SRCS    = $(RTL) $(TB)
SIMV    = simv
COV_DIR = uvm_cov_dir

# ── VCS compile flags ─────────────────────────────────────────────────────────
VCS_FLAGS = -full64                      \
            -sverilog                    \
            -timescale=1ns/1ps           \
            -debug_access+all            \
            -kdb                         \
            +define+FSDB                 \
            +incdir+.                    \
            -ntb_opts uvm-1.1            \
            -cm line+branch+cond+fsm+tgl \
            -cm_dir $(COV_DIR)

# ── Simulation flags ──────────────────────────────────────────────────────────
SIM_FLAGS = -cm line+branch+cond+fsm+tgl \
            -cm_dir $(COV_DIR)           \
            +ntb_random_seed=$(SEED)     \
            +UVM_VERBOSITY=UVM_MEDIUM    \
            +UVM_TESTNAME=mm_test

# ═════════════════════════════════════════════════════════════════════════════
# DEFAULT TARGET — compile + simulate + coverage report in one command
# ═════════════════════════════════════════════════════════════════════════════
.PHONY: all wave cov clean

all:
	@echo "========================================================"
	@echo "  STEP 1 of 3 : Compiling RTL + UVM Testbench ..."
	@echo "========================================================"
	$(VCS) $(VCS_FLAGS) $(SRCS) -o $(SIMV) 2>&1 | tee compile.log
	@echo ""
	@echo "========================================================"
	@echo "  STEP 2 of 3 : Running Simulation ..."
	@echo "========================================================"
	./$(SIMV) $(SIM_FLAGS) 2>&1 | tee sim.log
	@echo ""
	@echo "========================================================"
	@echo "  STEP 3 of 3 : Generating Coverage Report ..."
	@echo "========================================================"
	urg -dir $(COV_DIR) -format both -report uvm_cov_report 2>&1 | tee cov.log
	@echo ""
	@echo "========================================================"
	@echo "  ALL DONE"
	@echo "  compile log : compile.log"
	@echo "  sim log     : sim.log"
	@echo "  coverage    : uvm_cov_report/"
	@echo "  waveform    : novas_uvm.fsdb  (run: make wave)"
	@echo "========================================================"

# ── Open Verdi waveform ───────────────────────────────────────────────────────
wave:
	$(VERDI) -ssf novas_uvm.fsdb &

# ── Coverage report only (if sim already ran) ────────────────────────────────
cov:
	urg -dir $(COV_DIR) -format both -report uvm_cov_report
	@echo "Coverage report generated in uvm_cov_report/"

# ── Clean all generated files ─────────────────────────────────────────────────
clean:
	rm -rf $(SIMV) $(SIMV).daidir csrc ucli.key  \
	       *.log *.fsdb *.fsdb.*                  \
	       verdiLog novas* urgReport              \
	       $(COV_DIR) uvm_cov_report              \
	       .vcs_lib_lock
