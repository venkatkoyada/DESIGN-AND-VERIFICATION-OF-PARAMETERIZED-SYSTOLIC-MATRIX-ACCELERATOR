# =========================
# Makefile for Systolic MM Accelerator
# =========================

# Tools
VCS   = vcs
VERDI = verdi

# Source files
RTL = rtl/systolic_array.sv \
      rtl/pe.sv \
      rtl/input_skew.sv \
      rtl/controller.sv \
     rtl/mm_accelerator_top.sv

TB  = TRAD_TB/tb_mm_accelerator.sv

SRCS = $(RTL) $(TB)

# Output binary
SIMV = simv

# Coverage directory
COV_DIR = cov_dir

# Default target
all: run

# Compile
compile:
	$(VCS) -full64 -sverilog -timescale=1ns/1ps \
	-debug_access+all -kdb \
	-cm line+branch+cond+fsm+tgl \
	-cm_dir $(COV_DIR) \
	$(SRCS) -o $(SIMV)

# Run simulation
run: compile
	./$(SIMV) | tee sim.log

# Open waveform (if using FSDB)
wave:
	$(VERDI) -ssf novas.fsdb &

# Coverage report
cov:
	urg -dir $(COV_DIR) -report cov_report

# Clean
clean:
	rm -rf simv simv.daidir csrc ucli.key *.log *.vpd *.fsdb *.fsdb.* verdiLog novas* $(COV_DIR) cov_report
