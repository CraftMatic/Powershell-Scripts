**COPY RG Role Assignment Script**
This powershell script is to copy role assignments that are not inherited from a subscription in Azure. 
When making copies of resource via ARM template deployments Uninherited role assignments are not copied over so this tool can be used to copy those role assignments over when making a new resource group that is suppoed to have permission of the original but doesnt. 


**Json to  CSV conversion tool**
This tool is used to pull data from an azure storage account and convert it to CSV format and reupload that data back into an azure storage account. This uses service principal auth to achieve this due to automation mechanism (non user interactions) that had to be adhered to.

** **VM OS Version tool**
This tool pulls all vms from a subscription and puts their Computername, OS Name, OS Version and source subscription into a CSV file. This allows for easier data integration for automation books or import into power BI.
