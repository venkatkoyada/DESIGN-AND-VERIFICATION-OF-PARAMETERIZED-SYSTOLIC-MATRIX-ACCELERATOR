# Makefile for RTL Simple Testbench
# Systolic Array Matrix-Multiply Accelerator  (ECE 593)
#
# Runs 5 directed tests against the RTL for any matrix size N:
#   Test 1 : all-zero A     → C = 0
#   Test 2 : identity A     → C = B
#   Test 3 : all-max A & B  → overflow boundary
#   Test 4 : all-zero B     → C = 0
#   Test 5 : random A & B   → reference model check
#
# Usage:
#   make              — compile + simulate + coverage report  (N=4 default)
#   make N=<val> all  — run with a different matrix size
#   make wave         — open Verdi waveform after simulation
#   make cov          — re-generate coverage report (if sim already ran)
#   make clean        — remove all generated files
#
# Examples:
#   make clean && make N=4 all
#   make clean && make N=2 all
#   make clean && make N=8 all

VCS   = vcs
VERDI = verdi

SEED ?= 42
N    ?= 4

# ── Bug injection controls ────────────────────────────────────────────────────
# Normal clean run  : make all
# Bug 1 only        : make all BUG1=1   (controller drain off-by-one)
# Bug 2 only        : make all BUG2=1   (pe clear ignored)
# Both bugs active  : make all BUG1=1 BUG2=1
BUG1 ?= 0
BUG2 ?= 0

BUG_FLAGS =
ifeq ($(BUG1),1)
BUG_FLAGS += +define+BUG1
endif
ifeq ($(BUG2),1)
BUG_FLAGS += +define+BUG2
endif

# ── RTL source files + simple testbench ──────────────────────────────────────
RTL = pe.sv              \
      input_skew.sv      \
      controller.sv      \
      systolic_array.sv  \
      mm_accelerator_top.sv

TB = rtl_tb.sv

SRCS    = $(RTL) $(TB)
SIMV    = simv_rtl
COV_DIR = rtl_cov_dir.vdb

# ── VCS compile flags ─────────────────────────────────────────────────────────
VCS_FLAGS = -full64                      \
            -sverilog                    \
            -timescale=1ns/1ps           \
            -debug_access+all            \
            -kdb                         \
            +define+FSDB                 \
            +define+MATRIX_N=$(N)        \
            $(BUG_FLAGS)                 \
            -cm line+branch+cond+fsm+tgl \
            -cm_dir $(COV_DIR)

# ── Simulation flags ──────────────────────────────────────────────────────────
SIM_FLAGS = -cm line+branch+cond+fsm+tgl \
            -cm_dir $(COV_DIR)           \
            +ntb_random_seed=$(SEED)

# ═════════════════════════════════════════════════════════════════════════════
# DEFAULT TARGET — compile + simulate + coverage report in one command
# ═════════════════════════════════════════════════════════════════════════════
.PHONY: all wave cov clean

all:
	@echo "========================================================"
	@echo "  RTL TESTBENCH  (N=$(N))"
	@echo "  BUG1 (drain off-by-one) : $(BUG1)"
	@echo "  BUG2 (pe clear ignored) : $(BUG2)"
	@echo "========================================================"
	@echo "  STEP 1 of 3 : Compiling RTL + Simple Testbench (N=$(N)) ..."
	@echo "========================================================"
	$(VCS) $(VCS_FLAGS) $(SRCS) -o $(SIMV) 2>&1 | tee rtl_compile.log ; test $${PIPESTATUS[0]} -eq 0
	@echo ""
	@echo "========================================================"
	@echo "  STEP 2 of 3 : Running Simulation ..."
	@echo "========================================================"
	./$(SIMV) $(SIM_FLAGS) 2>&1 | tee rtl_sim.log ; test $${PIPESTATUS[0]} -eq 0
	@echo ""
	@echo "========================================================"
	@echo "  Opening Verdi waveform (novas_rtl.fsdb) ..."
	@echo "========================================================"
	$(VERDI) -ssf novas_rtl.fsdb &
	@echo ""
	@echo "========================================================"
	@echo "  STEP 3 of 3 : Generating Coverage Report ..."
	@echo "========================================================"
	urg -dir $(COV_DIR) -format both -report rtl_cov_report 2>&1 | tee rtl_cov.log
	@echo ""
	@echo "========================================================"
	@echo "  ALL DONE"
	@echo "  compile log : rtl_compile.log"
	@echo "  sim log     : rtl_sim.log"
	@echo "  coverage    : rtl_cov_report/"
	@echo "  waveform    : novas_rtl.fsdb  (run: make wave)"
	@echo "========================================================"

# ── Open Verdi waveform ───────────────────────────────────────────────────────
wave:
	$(VERDI) -ssf novas_rtl.fsdb &

# ── Coverage report only (if sim already ran) ─────────────────────────────────
cov:
	urg -dir $(COV_DIR) -format both -report rtl_cov_report
	@echo "Coverage report generated in rtl_cov_report/"

# ── Clean all generated files ─────────────────────────────────────────────────
clean:
	rm -rf $(SIMV) $(SIMV).daidir csrc ucli.key  \
	       *.log *.fsdb *.fsdb.*                  \
	       verdiLog novas* urgReport              \
	       $(COV_DIR) rtl_cov_report              \
	       .vcs_lib_lock
