This powershell script is to copy role assignments that are not inherited from a subscription in Azure. 
When making copies of resource via ARM template deployments Uninherited role assignments are not copied over so this tool can be used to copy those role assignments over when making a new resource group that is suppoed to have permission of the original but doesnt. 
