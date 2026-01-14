# Webinar: Leveraging Chap and the DHIS2 Platform for Stock Forecasting

This repository contains the **demo materials** for the webinar:

**Leveraging CHAP and the DHIS2 Platform for Stock Forecasting**

Well-functioning health supply chains are essential to ensure patient care. Stock availability is a key indicator of supply chain performance at the last mile. The extremes include **stockouts**, where medicines and products are unavailable to treat patients, and **overstock**, which may lead to expiry and other negative impacts. To optimize stock availability at sub-national level, **demand planning based on forecasts** is essential. This webinar explores how the **AI-powered DHIS2 CHAP Modeling Platform** can be adapted for **stock forecasting** and **inventory policy**.  
(Full webinar page + slides are available via the talk page.)

## What you will see in the webinar

- How last-mile stock data can be collected and used in DHIS2
- Research on adapting the CHAP machine learning platform for stock forecasting
- How this method provides stock forecasts and informs inventory policy
- A live demo of the system
- Q&A session

## Demo note (important)

This demo shows how we can use **existing CHAP pipelines** to execute external forecasting and inventory models using **external data**.  
To avoid changing core pipelines, external datasets may be **mapped to CHAP-standard variable names** for schema compatibility only (e.g., renaming a field like `dispensed` to `disease_cases`). This is naming-only: **data meaning and modelling logic are unchanged**.

## Repository contents (high level)

- `ets-r/`  
  R implementation used for the demo (forecasting + inventory pieces).
- `renv/`, `renv.lock`, `.Rprofile`  
  Reproducible R environment (dependency lockfile + project bootstrap).
- `dhis2_demo.Rproj`  
  RStudio project file.

## How to run locally (R)

1. Clone the repository.
2. Open `dhis2_demo.Rproj` in RStudio.
3. Restore the environment:
   - `renv::restore()`
4. Run the demo scripts inside `ets-r/`.

> Tip: If you run into package compilation issues, install system requirements for common R packages (e.g., curl/ssl/xml) depending on your OS.

## Reproducibility

This repo uses `renv` to lock package versions and support reproducible execution.  
If you add or update packages, run `renv::snapshot()` to update `renv.lock`.

## Links

- [Slides + webinar page: see the talk page (includes “Slides” + “GitHub Repo” buttons)](https://chamara7h.github.io/talks/dhis2_demo/)

## Further documentation (CHAP & DHIS2)

For participants who would like to explore the broader CHAP and DHIS2 modeling ecosystem, the following **official documentation** provides useful background and implementation guidance:

- **[Documentation for Model Developers](https://dhis2-chap.github.io/chap-core/external_models/index.html)**  
  Overview of how external models are structured, integrated, and executed within the CHAP platform.

- **[Running Models through CHAP](https://dhis2-chap.github.io/chap-core/external_models/running_models_in_chap.html)**  
  Step-by-step guidance on executing external models using CHAP Core.

- **[Configure the DHIS2 Modeling App and CHAP Core](https://dhis2-chap.github.io/chap-core/modeling-app/running-chap-on-server.html)**  
  Instructions for configuring the DHIS2 Modeling App and connecting it to CHAP Core services.

These resources describe the **standard CHAP workflows** that this demo intentionally **reuses**, illustrating how research models can be operationalised within existing DHIS2 infrastructure.
