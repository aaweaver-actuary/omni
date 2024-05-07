#/usr/bin/env zsh

url=https://www.casact.org/sites/default/files/2021-04/prodliab_pos.csv

# Download the data
wget $url -O data.csv

# Convert to parquet (with duckdb)
duckdb -c "COPY (SELECT * FROM read_csv_auto('data.csv')) TO 'data.parquet' WITH (FORMAT PARQUET);"

# Clean up
rm data.csv