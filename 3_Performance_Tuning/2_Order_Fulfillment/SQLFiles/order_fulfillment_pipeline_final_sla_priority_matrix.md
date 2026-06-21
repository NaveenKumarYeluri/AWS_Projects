# Order Fulfillment

## Architectural Background & Schema Selection
To finalize the 250-million-row Order Fulfillment pipeline, three distinct physical schemas were engineered and stress-tested under concurrent load:

* **Default Schema (DISTKEY(fc_id), No Sort Key):**

    **Result:** Exhibited perfectly balanced compute distribution (1.16 data skew). However, lacking a Sort Key meant time-series queries were forced to perform slow, full-table scans.

* **"Optimized" Schema (DISTKEY(mfg_facility_id), SORTKEY(fc_release_to_mfg_date)):**

    **Result:** Attempted to eliminate network broadcasts for manufacturing-heavy queries. However, system logs revealed a fatal 5.51 data skew. Centralized "Super-Factories" forced too many rows onto a single compute slice, creating a processing bottleneck (a "straggler node") that crippled performance.

* **Hybrid Schema (DISTKEY(fc_id), SORTKEY(fc_release_to_mfg_date)):**

    **Result:** The Chosen Production Model. By reverting to the balanced fulfillment center distribution key and pairing it with a date-based sort key, this schema achieved the best of both worlds. It maintained perfectly balanced parallel processing (bypassing the 5.51 skew penalty) while unlocking sub-second Zone Map I/O pruning for date-filtered queries.

## Priority & SLA
SLAs are calculated using a strict 2x Concurrency Buffer applied to the final multi-session load tests to protect against standard "noisy neighbor" cluster variance.

### Priority 1: Live Interactive Dashboards (SLA: < 5 Seconds)
These queries are designed for real-time UI consumption. They rely on aggressive I/O pruning (Zone Maps), Result Caching, or return extremely small data sets that render instantly on a dashboard.

* **Q3 (Volume Aggregation):**

    * **Base Load Time:** 48 ms

    * **Architecture Advantage:** Perfect collocated aggregation (Groups by the fc_id DISTKEY). Cached efficiently by Leader Node under load.

    * **Final SLA:** < 1 Second

* **Q7 (Top N Ranking):**

    * **Base Load Time:** 304 ms

    * **Architecture Advantage:** Limits the result set early and relies on the Leader Node for final sort/cache.

    * **Final SLA:** < 1 Second

* **Q5 (Time-Filtered Aggregation):**

    * **Base Load Time:** 578 ms

    * **Architecture Advantage:** The ultimate Zone Map victory. The SORTKEY(fc_release_to_mfg_date) skips 99% of physical disk blocks instantly.

    * **Final SLA:** < 2 Seconds

* **Q8 (Attribute Correlation Analysis):**

    * **Base Load Time:** 2.4s

    * **Architecture Advantage:** Small string group-by footprint allows rapid consolidation on the Leader Node.

    * **Final SLA:** < 5 Seconds

### Priority 2: Standard Reporting (SLA: < 25 Seconds)
These queries scan and process massive volumes (250 million rows) to generate high-level daily operational summaries. They are fast, but their broad aggregations make them better suited for background report loading rather than instantaneous UI clicks.

* **Q4 (Global System Average):**

    * **Base Load Time:** 5.4s

    * **Architecture Advantage:** Pure scalar math (AVG) distributed perfectly evenly across the 1.16 non-skewed compute slices.

    * **Final SLA:** < 15 Second

* **Q1 (Average Metric by Entity):**

    * **Base Load Time:** 11.3s

    * **Architecture Advantage:** Even though grouping by mfg_facility_id requires a network broadcast, avoiding the 5.51 data skew keeps the slice processing times tightly synchronized.

    * **Final SLA:** < 25 Seconds

* **Q6 (Delta Audit Report):**

    * **Base Load Time:** 11.9s

    * **Architecture Advantage:** Heavy column-to-column math (input - output), but efficiently processed due to the balanced default distribution.

    * **Final SLA:** < 25 Seconds

### Priority 3: Heavy / Background Audits (SLA: < 3 Minutes 45 Seconds)
Operational diagnostic queries requiring massive time-series math. These should be scheduled as asynchronous background jobs or converted to Materialized Views to protect cluster resources.

* **Q2 (Time-Series Accumulation):**

    * **Base Load Time:** 1m 46.5s

    * **Architecture Advantage:** This is the heaviest query, grouping 250M rows by both facility and date. The Hybrid schema dominates this because the DISTKEY(fc_id) handles the facility grouping locally, while the SORTKEY(date) organizes the time-series groupings on disk.

    * **Final SLA:** < 3 Minutes 45 Seconds
