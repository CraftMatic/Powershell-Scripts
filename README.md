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
