FROM r-base
RUN apt-get update && apt-get install -y libpq-dev
RUN Rscript -e 'install.packages(c("dbplyr","RPostgres","data.table"))'
CMD [ "R", "-f", "/app/populate_db/gather_runtime.R" ]
