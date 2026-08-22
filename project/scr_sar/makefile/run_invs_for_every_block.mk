WINDOW_NAMES := Window_A Window_B windowC
# Interval seconds between launching each xterm
LAUNCH_INTERVAL := 3
# Target shell script to run in every xterm
SCRIPT := ./task.sh

# Generate task list from window name list
TASKS := $(WINDOW_NAMES)

# ==============================================
# Main Target
# ==============================================
.PHONY: all $(TASKS) stop

# Main entry: launch xterm one by one with interval
all: $(TASKS)
	@echo "All xterm windows have been launched."

# Pattern rule: launch xterm for each window name
# Sleep N seconds first, then start xterm
$(TASKS):
	@echo "Launching xterm: $@"
	xterm -title "$@" -e "bash -c '$(SCRIPT); exec bash'" &
	sleep $(LAUNCH_INTERVAL)

# Kill all xterm processes
stop:
	@pkill xterm || true
	@echo "All xterm windows closed."
