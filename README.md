UAE Oncology Analytics & Clinical Database Architecture

📌 Project Overview
This project transforms a massive, unorganized clinical dataset into a highly optimized, production-ready relational database tracking cancer patient records across the UAE. The goal was to clean the raw data, engineer key clinical health metrics, normalize the architecture to eliminate redundancy, and build automated reporting tools for healthcare administrators.

📊 Key Insights Discovered
Critical Fatality Vectors: Identified Pancreatic Cancer as the highest-fatality oncology segment within the dataset, exhibiting an 11.67% mortality rate (145 deaths out of 1,243 patients).
https://github.com/Khushimali31/uae-cancer-sql-analysis/blob/main/Results/Screenshots/Result%201.png 
Demographic Risks: Isolated high-risk patient segments by mapping advanced cancer stages (Stage 3 & 4) against behavioral risk factors like active smoking status.
https://github.com/Khushimali31/uae-cancer-sql-analysis/blob/main/Results/Screenshots/Result%203.png 

🛠️ Technical Workflow & Phases
Phase 1: Database Setup & Normalization: Ingested `cancer_data_raw` and successfully normalized a single flat table into 4 relational tables (`patients`, `diagnosis`, `treatment`, `outcomes`) to ensure data integrity.
Phase 2: Feature Engineering: Created and calculated patient `bmi` using standard metric formulas, categorizing individuals into standardized weight risk profiles alongside localized age groups.
Phase 3: Relational Joins & Aggregate Matrices: Developed multi-table JOIN frameworks to benchmark hospital operational recovery rates and distribution patterns.
https://github.com/Khushimali31/uae-cancer-sql-analysis/blob/main/Results/Screenshots/Result%202.png 
Phase 4: Advanced Analytics: Utilized window functions (`RANK()`, `SUM() OVER`) and subqueries to calculate localized intake velocity and rank medical provider case volumes.
Phase 5: Production Database Objects: Built permanent virtual reporting layers (`Views`) and dynamic `Stored Procedures` to allow medical staff to instantly query real-time hospital and oncology metrics.

💻 Tech Stack Used
Database Engine: MySQL Server 8.0
Interface Tool: MySQL Workbench
Language: SQL (Structured Query Language)
Dataset Source: Kaggle (ak0212)
Data Source: UAE Cancer Patient Dataset  (https://www.kaggle.com/datasets/ak0212/uae-cancer-patient-dataset) _cancer_dataset_uae.csv
