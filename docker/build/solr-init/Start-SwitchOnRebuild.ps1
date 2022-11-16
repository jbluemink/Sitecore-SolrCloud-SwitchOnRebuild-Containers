param(
    [Parameter(Mandatory)]
    [string]$SitecoreSolrConnectionString,

    [Parameter(Mandatory)]
    [string]$SolrSitecoreConfigsetSuffixName,

    [Parameter(Mandatory)]
    [string]$SolrCorePrefix,

    [Parameter(Mandatory)]
    [string]$SolrReplicationFactor,

    [Parameter(Mandatory)]
    [int]$SolrNumberOfShards,

    [Parameter(Mandatory)]
    [int]$SolrMaxShardsPerNodes,

    [string]$SolrXdbSchemaFile,

    [string]$SolrCollectionsToDeploy
)

Write-Host "Starting SwitchOnRebuild"

function GetCoreNames {
    param (
        [ValidateSet("sitecore", "xdb")]
        [string]$CoreType,

        [string]$SolrCollectionsToDeploy
    )

    $resultCoreNames = @()
    $SolrCollectionsToDeploy.Split(',') | ForEach-Object {
        $solrCollectionToDeploy = $_
        Get-ChildItem C:\data -Filter "cores*$solrCollectionToDeploy.json" | ForEach-Object {
            $coreNames = (Get-Content $_.FullName | Out-String | ConvertFrom-Json).$CoreType
            if ($coreNames) {
                $resultCoreNames += $coreNames
            }
        }
    }

    return $resultCoreNames
}

function CreateCores {
    param (
        [string[]]$SolrCoreNames,
        [string]$SolrConfigDir,
        [string]$SolrBaseConfigsetName,
        $SolrCollectionAliases,
        [bool]$SkipBaseConfigCreate,
        [switch]$SolrXdbCore
    )

    if ($SkipBaseConfigCreate -eq $false){

        .\New-SolrConfig.ps1 -SolrEndpoint $SolrEndpoint -SolrConfigName $SolrBaseConfigsetName -SolrConfigDir $SolrConfigDir
    }

    foreach ($solrCoreName in $SolrCoreNames) {
        $solrConfigsetName = ('{0}{1}{2}' -f $SolrCorePrefix, $solrCoreName, $SolrSitecoreConfigsetSuffixName)

        .\Copy-SolrConfig.ps1 -SolrEndpoint $SolrEndpoint -SolrConfigName $solrConfigsetName -SolrBaseConfigName $SolrBaseConfigsetName

        .\New-SolrCore.ps1 -SolrCoreNames $solrCoreName -SolrEndpoint $SolrEndpoint -SolrCorePrefix $SolrCorePrefix -SolrConfigsetName $solrConfigsetName -SolrReplicationFactor $SolrReplicationFactor -SolrNumberOfShards $SolrNumberOfShards -SolrMaxShardNumberPerNode $SolrMaxShardsPerNodes -SolrCollectionAliases $SolrCollectionAliases

        if ($SolrXdbCore) {
            $solrCollectionName = ('{0}{1}' -f $SolrCorePrefix, $solrCoreName)
            .\Update-Schema.ps1 -SolrCollectionName $solrCollectionName -SolrEndpoint $SolrEndpoint -SchemaPath $SolrXdbSchemaFile
        }
    }
}

. .\Get-SolrCredential.ps1

$solrContext = .\Parse-ConnectionString.ps1 -SitecoreSolrConnectionString $SitecoreSolrConnectionString

$SolrEndpoint = $solrContext.SolrEndpoint
$env:SOLR_USERNAME = $solrContext.SolrUsername
$env:SOLR_PASSWORD = $solrContext.SolrPassword

$solrSitecoreCoreNames = GetCoreNames -CoreType "sitecore" -SolrCollectionsToDeploy $SolrCollectionsToDeploy
$solrXdbCoreNames = GetCoreNames -CoreType "xdb" -SolrCollectionsToDeploy $SolrCollectionsToDeploy

$solrCollections = (Invoke-RestMethod -Uri "$SolrEndpoint/admin/collections?action=LIST&omitHeader=true" -Method Get -Credential (Get-SolrCredential)).collections
foreach ($solrCoreSetName in ($solrSitecoreCoreNames + $solrXdbCoreNames)) {
    foreach ($solrCoreName in $solrCoreSetName) {
	    if ($solrCollections -contains ('{0}{1}' -f $SolrCorePrefix, $solrCoreName)) {
		Write-Information -MessageData "Sitecore collection are already exist. '$SolrCorePrefix' '$solrCoreName'." -InformationAction:Continue
		exit
	    } else 
	    {
	    	Write-Host "$SolrCorePrefix $solrCoreName not found"
	    }
    }
}

$solrConfigDir = "C:\temp\sitecore_content_config"
$solrBaseConfigDir = "C:\temp\default"
.\Download-SolrConfig.ps1 -SolrEndpoint $SolrEndpoint -OutPath $solrBaseConfigDir
.\Patch-SolrConfig.ps1 -SolrConfigPath $solrBaseConfigDir -XsltPath "C:\data\xslt" -OutputPath $solrConfigDir

$SkipBaseConfigCreate = $true
CreateCores -SolrCoreNames $solrSitecoreCoreNames -SolrConfigDir $solrConfigDir -SolrBaseConfigsetName "$($SolrCorePrefix)_content_config" -SkipBaseConfigCreate $SkipBaseConfigCreate
