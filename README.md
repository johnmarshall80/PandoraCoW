# PandoraCondor
A simple bash script to run Pandora on Condor.

## Basic usage
First, modify the settings at the top of `submitBatch.sh` to your needs.

| Variable              | Description                                                                                                                     |
|:---------------------:|:--------------------------------------------------------------------------------------------------------------------------------|
|`PANDORA_CONDOR_DIR`   | The location of PandoraCondor you just cloned. If using `.`, then be sure to `cd` to `PandoraCondor` before running the script! |
|`PANDORA_BIN`          | The location of the Pandora binary to run.                                                                                      |
|`SETUP_SCRIPT`         | The location of a setup script (that will be sourced) before attempting to execute the Pandora binary.                          |
|`RECO_OPTION`          | The reconstruction option - see Pandora help for more details                                                                   |
|`SETTINGS_FILE`        | The location of the Pandora XML settings file to use                                                                            |
|`EVENTS`               | The path to the event files to run on (can include wildcards). You can specify how many files to use later.                     |
|`GEOMETRY_FILE`        | The location of the Pandora XML/pndr geometry file to use                                                                       |
|`FILES_PER_JOB`        | The number of files (specified by EVENTS) to use per job                                                                        |
|`NUM_JOBS`             | The total number of jobs to submit                                                                                              |
|`MAX_SIMULTANEOUS_JOBS`| The maximum number of jobs to be queued at any one time                                                                         |

Submit your jobs by using:
```bash
source submitBatch.sh
```

The script will submit your jobs one by one (without exceeding `MAX_SIMULTANEOUS_JOBS`) until all jobs are queued.
Then the script will automatically monitor the status of your jobs. When it finishes, all of your jobs should be done!

You can find the output of your jobs in the `work` directory. A new subdirectory is made for each job containing the logs, errors, and any files that Pandora produced.

## Things to modify
In the `generic` directory, there are two files you can modify.

`condor.job` is the condor submit description file to be used by your jobs. It contains a number of "placeholder" values, 
which are replaced by `submitBatch.sh` according to the settings you specify. The `arguments` are passed to `pandoraJob`, which actually
run pandora.

`pandoraJob` is a simple executable bash file that first runs the setup script, and then executes the Pandora binary with the specified settings.
You can modify this if you require any custom behaviour, e.g. copying/moving files after Pandora finishes.
