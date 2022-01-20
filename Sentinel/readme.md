#Overview
The MonitorSentinelConnectors.json file can be imported to any Sentinel Workspace. Upon being imported, five scheduled query rules will be built that run on a daily interval. The specifics of each are outlined in detail below.
|Connector|Table Monitoring|Alert Criteria|
| --- | --- | --- |
|Azure Activity|AzureActivity|Alert if no logs in past 72 Hours|
|Azure Active Directory (AuditLogs)|AuditLogs|Alert if no logs in past 72 hours|
|Azure Active Directory (SigninLogs)|SigninLogs|Alert if no logs in past 72 hours|
|Office 365|OfficeActivity|Alert if no logs in past 72 hours|
|Security Events via Legacy Agent|SecurityEvents|Alert if no logs in past 72 hours|
#Instructions
1) Log into your Sentinel workspace.
2) Click on Analytics.
3) Click on Import.
4) Import the attached file.
5) Confirm successful upload by ensuring the scheduled query rules in the table above show. These are listed in the Analytics blade in Sentinel.
#Logic
Each rule listed in the table above has a similar query. Below is a simple breakdown.
##Query Breakdown
```
<TableName>
| where TimeGenerated > ago(7d)
| summarize lastlog=datetime_diff("Hour", now(), max(TimeGenerated)) by Type
| where lastlog >= 72
```
First, pull in the table we're monitoring.
Next, filter only logs generated in the past 7 days.
Then, calculate how many hours it has been since the last log was generated.
Finally, filter only results where the last log has been more than 72 hours ago.
##Modification
If 72 hours does not make sense for your environment, you can modify this setting. In the last line, modify ```72``` to a number that is more appropriate for your environment.  ```| where lastlog >=72```
> ⚠ If this query is changed to a number greater than 168, ensure you're also modifying the second line of each query to expand the logs being evaluated.
# License
[![CC BY-NC-SA 4.0][cc-by-nc-sa-shield]][cc-by-nc-sa]
This work is licensed under a
[Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License][cc-by-nc-sa].
[![CC BY-NC-SA 4.0][cc-by-nc-sa-image]][cc-by-nc-sa]
[cc-by-nc-sa]: http://creativecommons.org/licenses/by-nc-sa/4.0/
[cc-by-nc-sa-image]: https://licensebuttons.net/l/by-nc-sa/4.0/88x31.png
[cc-by-nc-sa-shield]: https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg
