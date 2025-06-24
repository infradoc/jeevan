"microsoft.sql/servers/databases" {
    try {
        if ($res.id -match "/subscriptions/[^/]+/resourceGroups/([^/]+)/providers/Microsoft.Sql/servers/([^/]+)/databases/([^/]+)") {
            $rg = $matches[1]
            $serverName = $matches[2]
            $dbName = $matches[3]

            $dbUrl = "https://management.azure.com/subscriptions/$subId/resourceGroups/$rg/providers/Microsoft.Sql/servers/$serverName/databases/$($dbName)?api-version=2023-08-01"
            Write-Output "➡️ Fetching SQL DB SKU: $dbUrl"

            $dbDetail = Invoke-RestMethod -Uri $dbUrl -Headers $headers -Method Get
            Write-Output "🔎 Raw SKU data: $($dbDetail.sku | ConvertTo-Json -Depth 2)"  # Debug the SKU structure

            if ($dbDetail.sku) {
                $skuItems = @()
                if ($dbDetail.sku -is [array]) {
                    foreach ($sku in $dbDetail.sku) {
                        if ($sku.tier -and $sku.name) {
                            $skuItems += "$($sku.tier.ToString())_$($sku.name.ToString())"
                        }
                        elseif ($sku.name) {
                            $skuItems += $sku.name.ToString()
                        }
                    }
                    if ($skuItems.Count -gt 0) {
                        $skuItems -join "; "
                    }
                    else {
                        Write-Output "⚠️ No valid SKU properties found in array for $dbName"
                        "N/A"
                    }
                }
                else {
                    if ($dbDetail.sku.tier -and $dbDetail.sku.name) {
                        "$($dbDetail.sku.tier.ToString())_$($dbDetail.sku.name.ToString())"
                    }
                    elseif ($dbDetail.sku.name) {
                        $dbDetail.sku.name.ToString()
                    }
                    else {
                        Write-Output "⚠️ SKU is present but missing expected properties for $dbName"
                        "N/A"
                    }
                }
            }
            else {
                Write-Output "⚠️ SKU property is null for SQL DB: $dbName"
                "N/A"
            }
        }
        else {
            Write-Output "⚠️ Could not parse SQL DB resource ID: $($res.id)"
            "N/A"
        }
    }
    catch {
        Write-Output "❌ SQL DB SKU fetch failed for $($res.name): $_"
        "N/A"
    }
}
