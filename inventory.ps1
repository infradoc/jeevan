microsoft.sql/servers/databases - working
microsoft.compute/virtualmachines - working
microsoft.web/sites - Need to fix


# PARAMETERS
$StorageAccountName = "storageaccount"
$ContainerName = "azure-inventory"
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmm"
$ReportFile = "Test_Inventory_SKU_$timestamp.csv"
$ReportPath = "$env:TEMP\$ReportFile"

# Group and PaaS Categorization Mapping
$ResourceMapping = @{
    "microsoft.network/privateendpoints"                                 = @{ Group = "Core Services"; PaaSCategorization = "Medium" }
    "microsoft.network/networkinterfaces"                                = @{ Group = "Core Services"; PaaSCategorization = "Medium" }
    "microsoft.compute/virtualmachines"                                  = @{ Group = "IaaS"; PaaSCategorization = "N/A" }
    "microsoft.compute/disks"                                            = @{ Group = "IaaS"; PaaSCategorization = "N/A" }
    "microsoft.insights/workbooks"                                       = @{ Group = "Core Services"; PaaSCategorization = "Low" }
    "microsoft.operationalinsights/workspaces"                           = @{ Group = "Core Services"; PaaSCategorization = "Medium" }
    "microsoft.portal/dashboards"                                        = @{ Group = "Core Services"; PaaSCategorization = "Low" }
    "microsoft.databricks/accessconnectors"                              = @{ Group = "PaaS"; PaaSCategorization = "Complex" }
    "microsoft.datafactory/factories"                                    = @{ Group = "PaaS"; PaaSCategorization = "Complex" }
    "microsoft.search/searchservices"                                    = @{ Group = "PaaS"; PaaSCategorization = "Complex" }
    "microsoft.insights/activitylogalerts"                               = @{ Group = "Core Services"; PaaSCategorization = "Low" }
    "microsoft.automation/automationaccounts"                            = @{ Group = "Core Services"; PaaSCategorization = "Medium" }
    "microsoft.insights/actiongroups"                                    = @{ Group = "Core Services"; PaaSCategorization = "Low" }
    "microsoft.apimanagement/service"                                    = @{ Group = "PaaS"; PaaSCategorization = "Complex" }
    "microsoft.insights/webtests"                                        = @{ Group = "PaaS"; PaaSCategorization = "Medium" }
    "microsoft.insights/components"                                      = @{ Group = "Core Services"; PaaSCategorization = "Medium" }
    "microsoft.web/sites"                                                = @{ Group = "PaaS"; PaaSCategorization = "Medium" }
    "microsoft.insights/metricalerts"                                    = @{ Group = "Core Services"; PaaSCategorization = "Low" }
    "microsoft.web/sites/slots"                                          = @{ Group = "PaaS"; PaaSCategorization = "Medium" }
    "microsoft.appconfiguration/configurationstores"                     = @{ Group = "PaaS"; PaaSCategorization = "Low" }
    "microsoft.network/applicationgateways"                              = @{ Group = "Core Services"; PaaSCategorization = "Complex" }
    "microsoft.insights/scheduledqueryrules"                             = @{ Group = "Core Services"; PaaSCategorization = "Low" }
    "microsoft.sql/servers/databases"                                    = @{ Group = "PaaS"; PaaSCategorization = "Complex" }
    "microsoft.web/serverfarms"                                          = @{ Group = "PaaS"; PaaSCategorization = "Medium" }
    "microsoft.compute/availabilitysets"                                 = @{ Group = "IaaS"; PaaSCategorization = "N/A" }
    "microsoft.sqlvirtualmachine/sqlvirtualmachines"                     = @{ Group = "IaaS"; PaaSCategorization = "N/A" }
    "microsoft.saas/resources"                                           = @{ Group = "SaaS"; PaaSCategorization = "N/A" }
    "microsoft.automation/automationaccounts/runbooks"                   = @{ Group = "Core Services"; PaaSCategorization = "Medium" }
    "microsoft.compute/restorepointcollections"                          = @{ Group = "IaaS"; PaaSCategorization = "N/A" }
    "microsoft.web/connections"                                          = @{ Group = "PaaS"; PaaSCategorization = "Low" }
    "microsoft.network/bastionhosts"                                     = @{ Group = "Core Services"; PaaSCategorization = "Medium" }
    "microsoft.app/containerapps"                                        = @{ Group = "PaaS"; PaaSCategorization = "Medium" }
    "microsoft.network/loadbalancers"                                    = @{ Group = "Core Services"; PaaSCategorization = "Medium" }
    "microsoft.network/publicipaddresses"                                = @{ Group = "Core Services"; PaaSCategorization = "Low" }
    "microsoft.cdn/profiles"                                             = @{ Group = "PaaS"; PaaSCategorization = "Medium" }
    "microsoft.cdn/profiles/endpoints"                                   = @{ Group = "PaaS"; PaaSCategorization = "Medium" }
    "microsoft.documentdb/databaseaccounts"                              = @{ Group = "PaaS"; PaaSCategorization = "Complex" }
    "microsoft.dbforpostgresql/servergroupsv2"                           = @{ Group = "PaaS"; PaaSCategorization = "Complex" }
    "microsoft.containerregistry/registries"                             = @{ Group = "PaaS"; PaaSCategorization = "Medium" }
    "microsoft.network/networksecuritygroups"                            = @{ Group = "Core Services"; PaaSCategorization = "Low" }
    "microsoft.managedidentity/userassignedidentities"                   = @{ Group = "Core Services"; PaaSCategorization = "Medium" }
    "microsoft.sql/servers"                                              = @{ Group = "PaaS"; PaaSCategorization = "Complex" }
    "microsoft.databricks/workspaces"                                    = @{ Group = "PaaS"; PaaSCategorization = "Complex" }
    "microsoft.storage/storageaccounts"                                  = @{ Group = "PaaS"; PaaSCategorization = "Medium" }
    "microsoft.operationalinsights/querypacks"                           = @{ Group = "PaaS"; PaaSCategorization = "Low" }
    "microsoft.insights/datacollectionrules"                             = @{ Group = "Core Services"; PaaSCategorization = "Low" }
    "microsoft.cognitiveservices/accounts"                               = @{ Group = "PaaS"; PaaSCategorization = "Complex" }
    "microsoft.eventgrid/systemtopics"                                   = @{ Group = "PaaS"; PaaSCategorization = "Low" }
    "microsoft.servicebus/namespaces"                                    = @{ Group = "PaaS"; PaaSCategorization = "Medium" }
    "microsoft.eventhub/namespaces"                                      = @{ Group = "PaaS"; PaaSCategorization = "Medium" }
    "microsoft.keyvault/vaults"                                          = @{ Group = "PaaS"; PaaSCategorization = "Medium" }
    "microsoft.maintenance/maintenanceconfigurations"                    = @{ Group = "Core Services"; PaaSCategorization = "Low" }
    "microsoft.alertsmanagement/smartdetectoralertrules"                 = @{ Group = "Core Services"; PaaSCategorization = "Low" }
    "microsoft.visualstudio/account"                                     = @{ Group = "PaaS"; PaaSCategorization = "Low" }
    "microsoft.streamanalytics/streamingjobs"                            = @{ Group = "PaaS"; PaaSCategorization = "Complex" }
    "microsoft.certificateregistration/certificateorders"                = @{ Group = "PaaS"; PaaSCategorization = "Low" }
    "microsoft.recoveryservices/vaults"                                  = @{ Group = "PaaS"; PaaSCategorization = "Medium" }
    "microsoft.operationsmanagement/solutions"                           = @{ Group = "Core Services"; PaaSCategorization = "Medium" }
    "microsoft.eventgrid/namespaces"                                     = @{ Group = "PaaS"; PaaSCategorization = "Medium" }
    "microsoft.logic/workflows"                                          = @{ Group = "PaaS"; PaaSCategorization = "Medium" }
    "microsoft.app/managedenvironments"                                  = @{ Group = "PaaS"; PaaSCategorization = "Complex" }
    "microsoft.network/networkwatchers"                                  = @{ Group = "Core Services"; PaaSCategorization = "Low" }
    "microsoft.network/natgateways"                                      = @{ Group = "Core Services"; PaaSCategorization = "Medium" }
    "microsoft.network/networkwatchers/flowlogs"                         = @{ Group = "Core Services"; PaaSCategorization = "Low" }
    "microsoft.network/privatednszones"                                  = @{ Group = "Core Services"; PaaSCategorization = "Low" }
    "microsoft.domainregistration/domains"                               = @{ Group = "Core Services"; PaaSCategorization = "Low" }
    "microsoft.network/dnszones"                                         = @{ Group = "Core Services"; PaaSCategorization = "Low" }
    "microsoft.powerbidedicated/capacities"                              = @{ Group = "PaaS"; PaaSCategorization = "Complex" }
    "microsoft.dbforpostgresql/flexibleservers"                          = @{ Group = "PaaS"; PaaSCategorization = "Complex" }
    "microsoft.compute/sshpublickeys"                                    = @{ Group = "IaaS"; PaaSCategorization = "N/A" }
    "microsoft.network/routetables"                                      = @{ Group = "Core Services"; PaaSCategorization = "Low" }
    "microsoft.network/serviceendpointpolicies"                          = @{ Group = "Core Services"; PaaSCategorization = "Low" }
    "microsoft.compute/snapshots"                                        = @{ Group = "IaaS"; PaaSCategorization = "N/A" }
    "microsoft.storagesync/storagesyncservices"                          = @{ Group = "PaaS"; PaaSCategorization = "Medium" }
    "microsoft.network/trafficmanagerprofiles"                           = @{ Group = "Core Services"; PaaSCategorization = "Medium" }
    "microsoft.network/virtualnetworks"                                  = @{ Group = "Core Services"; PaaSCategorization = "Low" }
    "microsoft.network/applicationgatewaywebapplicationfirewallpolicies" = @{ Group = "Core Services"; PaaSCategorization = "Medium" }
}

# Creation Time Property Mapping (Retained for fallback)
$CreationPathMapping = @{
    "microsoft.compute/virtualmachines"         = "properties.timeCreated"
    "microsoft.web/sites"                       = "properties.createdTimeUtc"
    "microsoft.web/sites/slots"                 = "properties.createdTimeUtc"
    "microsoft.web/serverfarms"                 = "properties.createdTimeUtc"
    "microsoft.sql/servers/databases"           = "properties.creationDate"
    "microsoft.logic/workflows"                 = "properties.createdTime"
    "microsoft.containerregistry/registries"    = "properties.creationDate"
    "microsoft.dbforpostgresql/flexibleservers" = "properties.creationDate"
    "microsoft.dbforpostgresql/servergroupsv2"  = "properties.creationDate"
    "microsoft.dbformysql/flexibleservers"      = "properties.creationDate"
    "microsoft.dbformysql/servers"              = "properties.creationDate"
    "microsoft.documentdb/databaseaccounts"     = "properties.createTime"
    "microsoft.keyvault/vaults"                 = "properties.attributes.created"
    "microsoft.synapse/workspaces"              = "properties.createdDate"
    "microsoft.operationalinsights/workspaces"  = "properties.createdDate"
    "microsoft.cognitiveservices/accounts"      = "properties.created"
    "microsoft.kusto/clusters"                  = "properties.creationDate"
    "microsoft.kusto/databases"                 = "properties.creationDate"
}

# Common fallback paths for creation time (for unmapped resources)
$FallbackCreationPaths = @(
    "properties.createdTime",
    "properties.creationDate",
    "properties.created",
    "properties.attributes.created",
    "properties.createTime"
)

# Function to extract creation time
function Get-CreationTime {
    param (
        [object]$resource,
        [string]$resourceType,
        [string]$subId,
        [string]$resourceGroup,
        [string]$resourceName,
        [hashtable]$mapping,
        [hashtable]$headers
    )

    $typeKey = $resourceType.ToLower()

    # Step 1: Try the top-level createdTime field from $expand=createdTime
    if ($resource.createdTime) {
        try {
            $dateValue = [datetime]$resource.createdTime
            return $dateValue.ToString("yyyy-MM-dd HH:mm:ss")
        }
        catch {
            Write-Host "Failed to parse top-level createdTime '$($resource.createdTime)' for $typeKey $resourceName`: $_"
            # Continue to next steps if parsing fails
        }
    }
    else {
        Write-Host "Top-level createdTime not available for $typeKey $resourceName"
    }

    # Step 2: If resource type is in $CreationPathMapping, try the mapped path
    if ($mapping.ContainsKey($typeKey)) {
        $path = $mapping[$typeKey]
        try {
            $value = $resource
            foreach ($part in $path -split '\.') {
                if ($value.PSObject.Properties.Name -contains $part) {
                    $value = $value.$part
                }
                else {
                    Write-Host "Property $part not found in $typeKey response for $resourceName"
                    break
                }
            }
            if ($null -ne $value) {
                try {
                    $dateValue = [datetime]$value
                    return $dateValue.ToString("yyyy-MM-dd HH:mm:ss")
                }
                catch {
                    Write-Host "Failed to parse creation time '$value' for $typeKey $resourceName`: $_"
                    # Continue to next steps if parsing fails
                }
            }
            else {
                Write-Host "Creation time is null for $typeKey $resourceName using path $path"
            }
        }
        catch {
            Write-Host "Error extracting creation time for $typeKey $resourceName using path $path`: $_"
        }
    }

    # Step 3: Fallback to common creation time paths for unmapped resources
    foreach ($fallbackPath in $FallbackCreationPaths) {
        try {
            $value = $resource
            foreach ($part in $fallbackPath -split '\.') {
                if ($value.PSObject.Properties.Name -contains $part) {
                    $value = $value.$part
                }
                else {
                    break
                }
            }
            if ($null -ne $value) {
                try {
                    $dateValue = [datetime]$value
                    return $dateValue.ToString("yyyy-MM-dd HH:mm:ss")
                }
                catch {
                    Write-Host "Failed to parse creation time '$value' for $typeKey $resourceName using fallback path $fallbackPath`: $_"
                    continue
                }
            }
        }
        catch {
            Write-Host "Error extracting creation time for $typeKey $resourceName using fallback path $fallbackPath`: $_"
            continue
        }
    }

    # Step 4: If all attempts fail, return N/A
    Write-Host "No creation time found for $typeKey $resourceName"
    return "N/A"
}

# Auth
    Connect-AzAccount -Identity

# Get token
try {
    # $token = (Get-AzAccessToken -ResourceUrl 'https://management.azure.com/').Token
    # $headers = @{ Authorization = "Bearer $token" }
    # Write-Output "$header"

$secureToken = (Get-AzAccessToken -ResourceUrl 'https://management.azure.com/').Token
$ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
$token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr)
Write-Output "Token is:  $($token)"
$headers = @{ Authorization = "Bearer $token" }
}
catch {
    Write-Output "❌ Token fetch failed: $_"
    exit 1
}

# Subscriptions
$inventory = @()
$subsUri = "https://management.azure.com/subscriptions?api-version=2020-01-01"
$subs = (Invoke-RestMethod -Uri $subsUri -Headers $headers -Method Get).value

foreach ($sub in $subs) {
    $subId = $sub.subscriptionId
    $subName = $sub.displayName
    Write-Host "\n🔎 Subscription: $($subName)"

    try {
        # Use $expand=createdTime,instanceView to fetch creation times and VM details
        $resUri = "https://management.azure.com/subscriptions/$subId/resources?api-version=2021-04-01&`$expand=createdTime,instanceView"
        $resList = (Invoke-RestMethod -Uri $resUri -Headers $headers -Method Get).value
    }
    catch {
        Write-Host "⚠️ Error fetching resources: $_"
        continue
    }

    foreach ($res in $resList) {
        $typeKey = $res.type.ToLower()
        $resourceGroup = if ($res.id -match "/resourcegroups/([^/]+)") { $matches[1] } else { "N/A" }
        $group = if ($ResourceMapping[$typeKey]) { $ResourceMapping[$typeKey].Group } else { "Other" }
        $paasCat = if ($ResourceMapping[$typeKey]) { $ResourceMapping[$typeKey].PaaSCategorization } else { "N/A" }
        $sku = try {
            switch ($typeKey) {
                "microsoft.compute/virtualmachines" {
                    if ($res.properties.hardwareProfile.vmSize) {
                        $res.properties.hardwareProfile.vmSize
                    }
                    else {
                        $vmUrl = "https://management.azure.com$($res.id)?api-version=2024-11-01"
                        $vmDetail = Invoke-RestMethod -Uri $vmUrl -Headers $headers -Method Get
                        $vmDetail.properties.hardwareProfile.vmSize
                    }
                }

                "microsoft.web/serverfarms" {
                    if ($res.sku.tier -and $res.sku.name) {
                        "$($res.sku.tier)_$($res.sku.name)"
                    }
                    elseif ($res.sku.name) {
                        $res.sku.name
                    }
                    else {
                        "N/A"
                    }
                }

                "microsoft.web/sites" {
                    try {
                        $serverFarmId = $res.properties.serverFarmId
                        Write-Host "🔎 ServerFarmId: $serverFarmId"

                        if ($serverFarmId -and ($serverFarmId -match "/subscriptions/[^/]+/resourceGroups/([^/]+)/providers/Microsoft.Web/serverfarms/([^/]+)")) {
                            $planRG = $matches[1]
                            $planName = $matches[2]
                            $planUrl = "https://management.azure.com/subscriptions/$subId/resourceGroups/$planRG/providers/Microsoft.Web/serverfarms/$($planName)?api-version=2023-12-01"
                            Write-Host "➡️ Fetching App Service Plan SKU: $planUrl"

                            $plan = Invoke-RestMethod -Uri $planUrl -Headers $headers -Method Get
                            if ($plan.sku.tier -and $plan.sku.name) {
                                "$($plan.sku.tier)_$($plan.sku.name)"
                            }
                            elseif ($plan.sku.name) {
                                $plan.sku.name
                            }
                            else {
                                Write-Host "⚠️ No SKU found in App Service Plan response for $($res.name)"
                                "N/A"
                            }
                        }
                        else {
                            Write-Host "⚠️ Invalid or missing serverFarmId: $serverFarmId for $($res.name)"
                            "N/A"
                        }
                    }
                    catch {
                        Write-Host "❌ App Service Plan SKU fetch failed for $($res.name): $_"
                        "N/A"
                    }
                }

                "microsoft.sql/servers/databases" {
                    try {
                        if ($res.id -match "/subscriptions/[^/]+/resourceGroups/([^/]+)/providers/Microsoft.Sql/servers/([^/]+)/databases/([^/]+)") {
                            $rg = $matches[1]
                            $serverName = $matches[2]
                            $dbName = $matches[3]

                            $dbUrl = "https://management.azure.com/subscriptions/$subId/resourceGroups/$rg/providers/Microsoft.Sql/servers/$serverName/databases/$($dbName)?api-version=2017-10-01-preview"
                            Write-Host "➡️ Fetching SQL DB SKU: $dbUrl"

                            $dbDetail = Invoke-RestMethod -Uri $dbUrl -Headers $headers -Method Get
                            if ($dbDetail.sku.tier -and $dbDetail.sku.name) {
                                "$($dbDetail.sku.tier)_$($dbDetail.sku.name)"
                            }
                            elseif ($dbDetail.sku.name) {
                                $dbDetail.sku.name
                            }
                            else {
                                Write-Host "⚠️ No SKU found in SQL DB response for $dbName"
                                "N/A"
                            }
                        }
                        else {
                            Write-Host "⚠️ Could not parse SQL DB resource ID: $($res.id)"
                            "N/A"
                        }
                    }
                    catch {
                        Write-Host "❌ SQL DB SKU fetch failed for $($res.name): $_"
                        "N/A"
                    }
                }

                default {
                    if ($res.sku.name) {
                        $res.sku.name
                    }
                    else {
                        "N/A"
                    }
                }
            }
        }
        catch {
            Write-Host "⚠️ SKU error for $typeKey $($res.name): $_"
            "N/A"
        }

        $creationTime = Get-CreationTime -resource $res -resourceType $res.type -subId $subId -resourceGroup $resourceGroup -resourceName $res.name -mapping $CreationPathMapping -headers $headers
        $tags = try {
            if ($res.tags.PSObject.Properties.Count -gt 0) {
                ($res.tags.PSObject.Properties | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join "; "
            }
            else { "N/A" }
        }
        catch { "N/A" }

        $inventory += [PSCustomObject]@{
            ResourceName       = $res.name
            ResourceType       = $res.type
            SKU                = $sku
            ResourceGroup      = $resourceGroup
            SubscriptionName   = $subName
            SubscriptionId     = $subId
            Group              = $group
            PaaSCategorization = $paasCat
            Location           = $res.location
            ResourceId         = $res.id
            CreationTime       = $creationTime
            Tags               = $tags
        }
    }
}

# Export
try {
    $inventory | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8
    Write-Host "✅ Report saved to: $ReportPath"
}
catch {
    Write-Host "❌ Export failed: $_"
}


# UPLOAD TO BLOB
$context = New-AzStorageContext -StorageAccountName $StorageAccountName -UseConnectedAccount
Set-AzStorageBlobContent -File $ReportPath -Container $ContainerName -Blob $ReportFile -Context $context -Force
Write-Output "✅ CSV uploaded to https://$StorageAccountName.blob.core.windows.net/$ContainerName/$ReportFile"
