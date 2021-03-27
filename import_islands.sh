head -n 1  nz-place-names-nzgb.csv > islands.csv
cat nz-place-names-nzgb.csv | grep ",Island," >> islands.csv

