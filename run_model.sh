#!/bin/bash
# This script is designed to read a Parquet file, process it using DuckDB, and then run a Stan model.

# Assume the Parquet file is named data.parquet and is in the workspace directory
duckdb -c "COPY (SELECT * FROM read_parquet('data.parquet')) TO 'data.csv' WITH (FORMAT CSV, HEADER);" 

# Now run the Stan model
cmdstan_model --name=model --model-file=model.stan
cmdstan_model model --data-file=data.csv --output-file=output.csv

# Optionally, you can add here additional commands to process the output as needed
