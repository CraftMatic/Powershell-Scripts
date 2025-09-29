**COPY RG Role Assignment Script**
This powershell script is to copy role assignments that are not inherited from a subscription in Azure. 
When making copies of resource via ARM template deployments Uninherited role assignments are not copied over so this tool can be used to copy those role assignments over when making a new resource group that is suppoed to have permission of the original but doesnt. 


**Json to  CSV conversion tool**
This tool is used to pull data from an azure storage account and convert it to CSV format and reupload that data back into an azure storage account. This uses service principal auth to achieve this due to automation mechanism (non user interactions) that had to be adhered to.

**VM OS Version tool**
This tool pulls all vms from a subscription and puts their Computername, OS Name, OS Version and source subscription into a CSV file. This allows for easier data integration for automation books or import into power BI.

**JSON to CSV Conversion tool (Data format version)**
This tool is also a JSON to CSV conversion tool. This tool however is suited for data formatted json instead of table formatted.

**Azure Role Assignement Grabber Utility**
This tool is used to generate a summary csv list for all security group, and user role assignments for resources in Azure. This is useful when moving from one cloud environment to another as it automates the generation of a list and is able to update the UPN for the accounts so importing into the next environment is easier. 

**Git Repo Migration Tool.**
This tool migrated git repos from one Azure Devops instance to another using native REST API. This avoids having to use az devops extension. 

**Recover Repo Tool**
This tool recovers a deleted repositry by using the patch method ont the devops api native Azure devops. You will need to retrieve the ID from the repo that was deleted before running this. 

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Azure Devops Migrations**
This directory holds several scripts that can migrate azure devops work items over to a new instance of Azure devops. Functionally I created this script to allow users to migrate ADO work items in a step by step approach.
NOTE: You will need a field called legacyID that will get populated by old work item ID of the script. It will not work without this customer field created beforehand.

The workflow goes like this :

1. ADO_work_Item_migration_tool.ps1 - This script migrates a plain text (does not support rich text, it actually actively strips rich texts) version of the work items to a new Azure Devops instance.
2. Parent_finder-V3.ps1 - This tools maps previous parent child relationships from your previous instance into the new instance.
3. ADO_related_work_items_mapper - This script adds related links back to work items post migration.
4. ADO_Work_item_state_mapper.ps1 - This script updates the states for all work items to their states in the previous instance.

   
