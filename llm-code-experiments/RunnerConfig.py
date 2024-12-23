from EventManager.Models.RunnerEvents import RunnerEvents
from EventManager.EventSubscriptionController import EventSubscriptionController
from ConfigValidator.Config.Models.RunTableModel import RunTableModel
from ConfigValidator.Config.Models.FactorModel import FactorModel
from ConfigValidator.Config.Models.RunnerContext import RunnerContext
from ConfigValidator.Config.Models.OperationType import OperationType
from ProgressManager.Output.OutputProcedure import OutputProcedure as output

from typing import Dict, List, Any, Optional
from pathlib import Path
from os.path import dirname, realpath

import os
import signal
import pandas as pd
import time
import subprocess
import shlex
import config

class RunnerConfig:
    ROOT_DIR = Path(dirname(realpath(__file__)))

    # ================================ USER SPECIFIC CONFIG ================================
    """The name of the experiment."""
    name:                       str             = "new_runner_experiment"

    """The path in which Experiment Runner will create a folder with the name `self.name`, in order to store the
    results from this experiment. (Path does not need to exist - it will be created if necessary.)
    Output path defaults to the config file's path, inside the folder 'experiments'"""
    results_output_path:        Path             = ROOT_DIR / 'experiments'

    """Experiment operation type. Unless you manually want to initiate each run, use `OperationType.AUTO`."""
    operation_type:             OperationType   = OperationType.AUTO

    """The time Experiment Runner will wait after a run completes.
    This can be essential to accommodate for cooldown periods on some systems."""
    time_between_runs_in_ms:    int             = 60000

    # Dynamic configurations can be one-time satisfied here before the program takes the config as-is
    # e.g. Setting some variable based on some criteria
    def __init__(self):
        """Executes immediately after program start, on config load"""

        EventSubscriptionController.subscribe_to_multiple_events([
            (RunnerEvents.BEFORE_EXPERIMENT, self.before_experiment),
            (RunnerEvents.BEFORE_RUN       , self.before_run       ),
            (RunnerEvents.START_RUN        , self.start_run        ),
            (RunnerEvents.START_MEASUREMENT, self.start_measurement),
            (RunnerEvents.INTERACT         , self.interact         ),
            (RunnerEvents.STOP_MEASUREMENT , self.stop_measurement ),
            (RunnerEvents.STOP_RUN         , self.stop_run         ),
            (RunnerEvents.POPULATE_RUN_DATA, self.populate_run_data),
            (RunnerEvents.AFTER_EXPERIMENT , self.after_experiment )
        ])
        self.run_table_model = None  # Initialized later
        output.console_log("Custom config loaded")

    def create_run_table_model(self) -> RunTableModel:
        """Create and return the run_table model here. A run_table is a List (rows) of tuples (columns),
        representing each run performed"""
        problem_factor = FactorModel("problem", ["fibonacci_modified", "closest_numbers", "array_manipulation",
                                                 "hourglass_sum", "largest_rectangle", "median_array"])
        solution_factor = FactorModel("solution", ["human", "basic", "efficient"])
        self.run_table_model = RunTableModel(
            factors = [problem_factor, solution_factor],
            data_columns=[
                'Time', 'PACKAGE_ENERGY', 'CPU_USAGE_0_MEAN', 'CPU_USAGE_1_MEAN', 'CPU_USAGE_2_MEAN',
                'CPU_USAGE_3_MEAN',
                'CPU_USAGE_4_MEAN', 'CPU_USAGE_5_MEAN', 'CPU_USAGE_6_MEAN', 'CPU_USAGE_7_MEAN', 'CPU_USAGE_0_MEDIAN',
                'CPU_USAGE_1_MEDIAN', 'CPU_USAGE_2_MEDIAN', 'CPU_USAGE_3_MEDIAN', 'CPU_USAGE_4_MEDIAN',
                'CPU_USAGE_5_MEDIAN',
                'CPU_USAGE_6_MEDIAN', 'CPU_USAGE_7_MEDIAN', 'USED_MEMORY_MEAN', 'USED_SWAP_MEAN', 'USED_MEMORY_MEDIAN',
                'USED_SWAP_MEDIAN', 'USED_MEMORY_MAX', 'USED_SWAP_MAX'
            ],
            repetitions=25,
            shuffle=True
        )
        return self.run_table_model

    def before_experiment(self) -> None:
        """Perform any activity required before starting the experiment here
        Invoked only once during the lifetime of the program."""
        pass

    def before_run(self) -> None:
        """Perform any activity required before starting a run.
        No context is available here as the run is not yet active (BEFORE RUN)"""
        pass

    def start_run(self, context: RunnerContext) -> None:
        """Perform any activity required for starting the run here.
        For example, starting the target system to measure.
        Activities after starting the run should also be performed here."""
        pass

    def start_measurement(self, context: RunnerContext) -> None:
        """Perform any activity required for starting measurements."""
        solution = context.run_variation['solution']
        problem = context.run_variation['problem']

        profiler_cmd = f'ssh {config.USERNAME}@{config.IP} "sudo -n energibridge \
                        --interval 200 \
                        --max-execution 0 \
                        --output {config.REMOTE_DIR}/llm-code-experiments/energibridge.csv \
                        python3 {config.REMOTE_DIR}/problems/{problem}/{solution}.py"'

        #time.sleep(1) # allow the process to run a little before measuring
        energibridge_log = open(f'{context.run_dir}/energibridge.log', 'w')
        self.profiler = subprocess.Popen(shlex.split(profiler_cmd), stdout=energibridge_log)

    def interact(self, context: RunnerContext) -> None:
        """Perform any interaction with the running target system here, or block here until the target finishes."""

        # No interaction. We just run it for XX seconds.
        # Another example would be to wait for the target to finish, e.g. via `self.target.wait()`
        output.console_log("Waiting for program to finish")
        self.profiler.wait()
        # time.sleep(20)

    def stop_measurement(self, context: RunnerContext) -> None:
        """Perform any activity here required for stopping measurements."""
        self.profiler.wait()

    def stop_run(self, context: RunnerContext) -> None:
        """Perform any activity here required for stopping the run.
        Activities after stopping the run should also be performed here."""
        pass
    
    def populate_run_data(self, context: RunnerContext) -> Optional[Dict[str, Any]]:
        """Parse and process any measurement data here.
        You can also store the raw measurement data under `context.run_dir`
        Returns a dictionary with keys `self.run_table_model.data_columns` and their values populated"""
        scp_command = f"scp -r {config.USERNAME}@{config.IP}:{config.REMOTE_CSV_PATH} {context.run_dir}"

        try:
            # Run the scp command
            subprocess.run(scp_command, shell=True, check=True, capture_output=True, text=True)
        except subprocess.CalledProcessError as e:
            print(f"An error occurred during file transfer: {e}")
            print(f"Error output: {e.stderr}")

        # energibridge.csv - Power consumption of the whole system
        df = pd.read_csv(context.run_dir / f"energibridge.csv")

        run_data = {
            'Time': df['Time'].iloc[-1] - df['Time'].iloc[0],
            'PACKAGE_ENERGY': df['PACKAGE_ENERGY (J)'].iloc[-1] - df['PACKAGE_ENERGY (J)'].iloc[0],
            'CPU_USAGE_0_MEAN': df['CPU_USAGE_0'].mean(),
            'CPU_USAGE_1_MEAN': df['CPU_USAGE_1'].mean(),
            'CPU_USAGE_2_MEAN': df['CPU_USAGE_2'].mean(),
            'CPU_USAGE_3_MEAN': df['CPU_USAGE_3'].mean(),
            'CPU_USAGE_4_MEAN': df['CPU_USAGE_4'].mean(),
            'CPU_USAGE_5_MEAN': df['CPU_USAGE_5'].mean(),
            'CPU_USAGE_6_MEAN': df['CPU_USAGE_6'].mean(),
            'CPU_USAGE_7_MEAN': df['CPU_USAGE_7'].mean(),
            'CPU_USAGE_0_MEDIAN': df['CPU_USAGE_0'].median(),
            'CPU_USAGE_1_MEDIAN': df['CPU_USAGE_1'].median(),
            'CPU_USAGE_2_MEDIAN': df['CPU_USAGE_2'].median(),
            'CPU_USAGE_3_MEDIAN': df['CPU_USAGE_3'].median(),
            'CPU_USAGE_4_MEDIAN': df['CPU_USAGE_4'].median(),
            'CPU_USAGE_5_MEDIAN': df['CPU_USAGE_5'].median(),
            'CPU_USAGE_6_MEDIAN': df['CPU_USAGE_6'].median(),
            'CPU_USAGE_7_MEDIAN': df['CPU_USAGE_7'].median(),
            'USED_MEMORY_MEAN': df['USED_MEMORY'].mean(),
            'USED_SWAP_MEAN': df['USED_SWAP'].mean(),
            'USED_MEMORY_MEDIAN': df['USED_MEMORY'].median(),
            'USED_SWAP_MEDIAN': df['USED_SWAP'].median(),
            'USED_MEMORY_MAX': df['USED_MEMORY'].max(),
            'USED_SWAP_MAX': df['USED_SWAP'].max()
        }
        return run_data

    def after_experiment(self) -> None:
        """Perform any activity required after stopping the experiment here
        Invoked only once during the lifetime of the program."""
        pass

    # ================================ DO NOT ALTER BELOW THIS LINE ================================
    experiment_path:            Path             = None
