# Makefile for Milestone 4 — UVM Testbench
# Systolic Array Matrix-Multiply Accelerator
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

#  Bug injection controls 
# Normal clean run   : make all
# RTL Bug 1 only     : make all BUG1=1   (controller drain off-by-one)
# RTL Bug 2 only     : make all BUG2=1   (pe clear ignored)
# UVM Bug 3 only     : make all BUG3=1   (monitor result unpack transposed)
# UVM Bug 4 only     : make all BUG4=1   (error seq: ref model uses A+B not A*B)
# All bugs active    : make all BUG1=1 BUG2=1 BUG3=1 BUG4=1
BUG1 ?= 0
BUG2 ?= 0
BUG3 ?= 0
BUG4 ?= 0

BUG_FLAGS =
ifeq ($(BUG1),1)
BUG_FLAGS += +define+BUG1
endif
ifeq ($(BUG2),1)
BUG_FLAGS += +define+BUG2
endif
ifeq ($(BUG3),1)
BUG_FLAGS += +define+BUG3
endif
ifeq ($(BUG4),1)
BUG_FLAGS += +define+BUG4
endif

#  RTL source files 
RTL = ../rtl/pe.sv              \
      ../rtl/input_skew.sv      \
      ../rtl/controller.sv      \
      ../rtl/systolic_array.sv  \
      ../rtl/mm_accelerator_top.sv

#  UVM Testbench top file 
# All UVM class files are `included by tb_top.sv — do NOT list them separately
# (VCS would see duplicate class definitions if listed here)
TB = tb_top.sv

SRCS    = $(RTL) $(TB)
SIMV    = simv
COV_DIR = uvm_cov_dir.vdb

#  VCS compile flags 
VCS_FLAGS = -full64                      \
            -sverilog                    \
            -timescale=1ns/1ps           \
            -debug_access+all            \
            -kdb                         \
            +define+FSDB                 \
            +define+MATRIX_N=$(N)        \
            $(BUG_FLAGS)                 \
            +incdir+.                    \
            -ntb_opts uvm-1.1            \
            -cm line+branch+cond+fsm+tgl \
            -cm_dir $(COV_DIR)           \
            -cm_hier cm_hier.cfg

#  Simulation flags 
SIM_FLAGS = -cm line+branch+cond+fsm+tgl \
            -cm_dir $(COV_DIR)           \
            +ntb_random_seed=$(SEED)     \
            +UVM_VERBOSITY=UVM_MEDIUM    \
            +UVM_TESTNAME=mm_test

#  DEFAULT TARGET — compile + simulate + coverage report in one command 
.PHONY: all wave cov clean

all:
	@echo "========================================================"
	@echo "  UVM TESTBENCH  (N=$(N))"
	@echo "  BUG1 RTL (drain off-by-one)    : $(BUG1)"
	@echo "  BUG2 RTL (pe clear ignored)    : $(BUG2)"
	@echo "  BUG3 UVM (monitor result transposed): $(BUG3)"
	@echo "  BUG4 UVM (error seq ref model) : $(BUG4)"
	@echo "========================================================"
	@echo "  STEP 1 of 3 : Compiling RTL + UVM Testbench ..."
	@echo "========================================================"
	$(VCS) $(VCS_FLAGS) $(SRCS) -o $(SIMV) 2>&1 | tee compile.log ; test $${PIPESTATUS[0]} -eq 0
	@echo ""
	@echo "========================================================"
	@echo "  STEP 2 of 3 : Running Simulation ..."
	@echo "========================================================"
	./$(SIMV) $(SIM_FLAGS) 2>&1 | tee sim.log ; test $${PIPESTATUS[0]} -eq 0
	@echo ""
	@echo "========================================================"
	@echo "  Opening Verdi waveform (novas_uvm.fsdb) ..."
	@echo "========================================================"
	$(VERDI) -ssf novas_uvm.fsdb &
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

#  Open Verdi waveform 
wave:
	$(VERDI) -ssf novas_uvm.fsdb &

#  Coverage report only (if sim already ran)
cov:
	urg -dir $(COV_DIR) -format both -report uvm_cov_report
	@echo "Coverage report generated in uvm_cov_report/"

#  Clean all generated files 
clean:
	rm -rf $(SIMV) $(SIMV).daidir csrc ucli.key  \
	       *.log *.fsdb *.fsdb.*                  \
	       verdiLog novas* urgReport              \
	       $(COV_DIR) uvm_cov_report              \
	       .vcs_lib_lock
