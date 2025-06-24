Import-Module Az.ResourceGraph -Force

# PARAMETERS
$StorageAccountName = "stanttdevlinvuc01np"
$ContainerName = "everlake-azure-inventory"
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmm"
$ReportFile = "Everlake_Inventory_Report_$timestamp.csv"
$ReportPath = "$env:TEMP\$ReportFile"

# LOGIN
Connect-AzAccount -Identity

# CACHE ALL SUBSCRIPTIONS ONCE
$subscriptionLookup = @{}
Get-AzSubscription | ForEach-Object {
    $subscriptionLookup[$_.Id.ToLower()] = $_.Name
}

# GROUPING FUNCTION
function Get-Group {
    param ($resourceType)

    switch ($resourceType.ToLower()) {
        "microsoft.network/privateendpoints" { return "Core Services" }
        "microsoft.network/networkinterfaces" { return "Core Services" }
        "microsoft.compute/virtualmachines" { return "IaaS" }
        "microsoft.compute/disks" { return "IaaS" }
        "microsoft.insights/workbooks" { return "Core Services" }
        "microsoft.operationalinsights/workspaces" { return "Core Services" }
        "microsoft.portal/dashboards" { return "Core Services" }
        "microsoft.databricks/accessconnectors" { return "PaaS" }
        "microsoft.datafactory/factories" { return "PaaS" }
        "microsoft.search/searchservices" { return "PaaS" }
        "microsoft.insights/activitylogalerts" { return "Core Services" }
        "microsoft.automation/automationaccounts" { return "Core Services" }
        "microsoft.insights/actiongroups" { return "Core Services" }
        "microsoft.apimanagement/service" { return "PaaS" }
        "microsoft.insights/webtests" { return "PaaS" }
        "microsoft.insights/components" { return "Core Services" }
        "microsoft.web/sites" { return "PaaS" }
        "microsoft.insights/metricalerts" { return "Core Services" }
        "microsoft.web/sites/slots" { return "PaaS" }
        "microsoft.appconfiguration/configurationstores" { return "PaaS" }
        "microsoft.network/applicationgateways" { return "Core Services" }
        "microsoft.insights/scheduledqueryrules" { return "Core Services" }
        "microsoft.sql/servers/databases" { return "PaaS" }
        "microsoft.web/serverfarms" { return "PaaS" }
        "microsoft.compute/availabilitysets" { return "IaaS" }
        "microsoft.sqlvirtualmachine/sqlvirtualmachines" { return "IaaS" }
        "microsoft.saas/resources" { return "SaaS" }
        "microsoft.automation/automationaccounts/runbooks" { return "Core Services" }
        "microsoft.compute/restorepointcollections" { return "IaaS" }
        "microsoft.web/connections" { return "PaaS" }
        "microsoft.network/bastionhosts" { return "Core Services" }
        "microsoft.app/containerapps" { return "PaaS" }
        "microsoft.network/loadbalancers" { return "Core Services" }
        "microsoft.network/publicipaddresses" { return "Core Services" }
        "microsoft.cdn/profiles" { return "PaaS" }
        "microsoft.cdn/profiles/endpoints" { return "PaaS" }
        "microsoft.documentdb/databaseaccounts" { return "PaaS" }
        "microsoft.dbforpostgresql/servergroupsv2" { return "PaaS" }
        "microsoft.containerregistry/registries" { return "PaaS" }
        "microsoft.network/networksecuritygroups" { return "Core Services" }
        "microsoft.managedidentity/userassignedidentities" { return "Core Services" }
        "microsoft.sql/servers" { return "PaaS" }
        "microsoft.databricks/workspaces" { return "PaaS" }
        "microsoft.storage/storageaccounts" { return "PaaS" }
        "microsoft.operationalinsights/querypacks" { return "PaaS" }
        "microsoft.insights/datacollectionrules" { return "Core Services" }
        "microsoft.cognitiveservices/accounts" { return "PaaS" }
        "microsoft.eventgrid/systemtopics" { return "PaaS" }
        "microsoft.servicebus/namespaces" { return "PaaS" }
        "microsoft.eventhub/namespaces" { return "PaaS" }
        "microsoft.keyvault/vaults" { return "PaaS" }
        "microsoft.maintenance/maintenanceconfigurations" { return "Core Services" }
        "microsoft.alertsmanagement/smartdetectoralertrules" { return "Core Services" }
        "microsoft.visualstudio/account" { return "PaaS" }
        "microsoft.streamanalytics/streamingjobs" { return "PaaS" }
        "microsoft.certificateregistration/certificateorders" { return "PaaS" }
        "microsoft.recoveryservices/vaults" { return "PaaS" }
        "microsoft.operationsmanagement/solutions" { return "Core Services" }
        "microsoft.eventgrid/namespaces" { return "PaaS" }
        "microsoft.logic/workflows" { return "PaaS" }
        "microsoft.app/managedenvironments" { return "PaaS" }
        "microsoft.network/networkwatchers" { return "Core Services" }
        "microsoft.network/natgateways" { return "Core Services" }
        "microsoft.network/networkwatchers/flowlogs" { return "Core Services" }
        "microsoft.network/privatednszones" { return "Core Services" }
        "microsoft.domainregistration/domains" { return "Core Services" }
        "microsoft.network/dnszones" { return "Core Services" }
        "microsoft.powerbidedicated/capacities" { return "PaaS" }
        "microsoft.dbforpostgresql/flexibleservers" { return "PaaS" }
        "microsoft.compute/sshpublickeys" { return "IaaS" }
        "microsoft.network/routetables" { return "Core Services" }
        "microsoft.network/serviceendpointpolicies" { return "Core Services" }
        "microsoft.compute/snapshots" { return "IaaS" }
        "microsoft.storagesync/storagesyncservices" { return "PaaS" }
        "microsoft.network/trafficmanagerprofiles" { return "Core Services" }
        "microsoft.network/virtualnetworks" { return "Core Services" }
        "microsoft.network/applicationgatewaywebapplicationfirewallpolicies" { return "Core Services" }
        default { return "Other" }
    }
}

# RESOURCE GRAPH QUERY
$query = @"
Resources
| project name, type, location, resourceGroup, subscriptionId, id, tags, properties
"@

$inventory = @()
$skipToken = $null

do {
    $result = if ($skipToken) {
        Search-AzGraph -Query $query -First 1000 -SkipToken $skipToken
    } else {
        Search-AzGraph -Query $query -First 1000
    }

    foreach ($res in $result.Data) {
        $group = Get-Group -resourceType $res.type

        # Tags
        $tagStr = "N/A"
        try {
            if ($res.tags -and ($res.tags.PSObject.Properties.Count -gt 0)) {
                $tagStr = ($res.tags.PSObject.Properties | ForEach-Object {
                    "$($_.Name)=$($_.Value)"
                }) -join "; "
            }
        } catch { $tagStr = "N/A" }

        # Subscription Name
        $subObj = Get-AzSubscription -SubscriptionId $res.subscriptionId
        $subName = if ($subObj) { $subObj.Name } else { "Unknown" }

        # Creation time & provisioning state
        # $creationTime = "N/A"
        # $provisioningState = "N/A"
        if ($res.properties) {
            if ($res.properties.PSObject.Properties["creationTime"]) {
                $rawTime = $res.properties.creationTime
                $creationTime = try {
                    ([datetime]$rawTime).ToString("yyyy-MM-dd HH:mm:ss")
                }
                catch   {
                    "Invalid"
                }                
            }
            else    {
                $creationTime = "N/A"
            }
            # if ($res.properties.PSObject.Properties["provisioningState"]) {
            #     $provisioningState = $res.properties.provisioningState
            # }
            # else {
            #    $provisioningState = "N/A"
            # }
        }

        $inventory += [PSCustomObject]@{
            SubscriptionName  = $subName
            SubscriptionId    = $res.subscriptionId
            ResourceGroup     = $res.resourceGroup
            ResourceName      = $res.name
            ResourceType      = $res.type
            Group             = $group
            Location          = $res.location
            ResourceId        = $res.id
            CreationTime      = $creationTime
            # ProvisioningState = $provisioningState
            Tags              = $tagStr
        }
    }

    $skipToken = $result.SkipToken
} while ($skipToken)

# EXPORT TO CSV
$inventory | Export-Csv -Path $ReportPath -NoTypeInformation
Write-Output "✅ Report saved to: $ReportPath"

# UPLOAD TO BLOB
$context = New-AzStorageContext -StorageAccountName $StorageAccountName -UseConnectedAccount
Set-AzStorageBlobContent -File $ReportPath -Container $ContainerName -Blob $ReportFile -Context $context -Force
Write-Output "✅ CSV uploaded to https://$StorageAccountName.blob.core.windows.net/$ContainerName/$ReportFile"
