FROM ghcr.io/dhis2-chap/docker_r_inla:master

RUN apt-get update
RUN apt-get install -y libharfbuzz-dev libfribidi-dev
RUN R -e 'r = getOption("repos"); r["CRAN"] = "http://cran.us.r-project.org"; options(repos = r); install.packages(c("tidyverse", "fable", "tsibble", "fabletools", "fpp3", "doParallel"), repos=c(getOption("repos"), dep=TRUE))'