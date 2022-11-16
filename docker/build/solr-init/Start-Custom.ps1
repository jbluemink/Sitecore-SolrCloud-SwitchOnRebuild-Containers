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

$contextPath = "C:\data"
Write-Host "Starting Custom, First run Start.ps1"

.\Start.ps1 -SitecoreSolrConnectionString $SitecoreSolrConnectionString -SolrCorePrefix $SolrCorePrefix -SolrSitecoreConfigsetSuffixName $SolrSitecoreConfigsetSuffixName -SolrReplicationFactor $SolrReplicationFactor -SolrNumberOfShards $SolrNumberOfShards -SolrMaxShardsPerNodes $SolrMaxShardsPerNodes -SolrXdbSchemaFile $SolrXdbSchemaFile -SolrCollectionsToDeploy $SolrCollectionsToDeploy

#start with SolrCollectionsToDeploy = SwitchOnRebuild
.\Start-SwitchOnRebuildRai.ps1 -SitecoreSolrConnectionString $SitecoreSolrConnectionString -SolrCorePrefix $SolrCorePrefix -SolrSitecoreConfigsetSuffixName $SolrSitecoreConfigsetSuffixName -SolrReplicationFactor $SolrReplicationFactor -SolrNumberOfShards $SolrNumberOfShards -SolrMaxShardsPerNodes $SolrMaxShardsPerNodes -SolrXdbSchemaFile $SolrXdbSchemaFile -SolrCollectionsToDeploy SwitchOnRebuild

Write-Host "Starting Custom - Create Aliases from C:\data\aliases-rebuild.json"

. .\Get-SolrCredential.ps1

$solrContext = .\Parse-ConnectionString.ps1 -SitecoreSolrConnectionString $SitecoreSolrConnectionString

$SolrEndpoint = $solrContext.SolrEndpoint
$env:SOLR_USERNAME = $solrContext.SolrUsername
$env:SOLR_PASSWORD = $solrContext.SolrPassword


if(Test-Path -Path "C:\data\aliases-SwitchOnRebuild.json") {
    $collectionAliases = [ordered]@{}
    $collectionAliases = ((Get-Content C:\data\aliases-SwitchOnRebuild.json | Out-String | ConvertFrom-Json ) )
    $solrAliasCollections = (Invoke-RestMethod -Uri "$SolrEndpoint/admin/collections?action=LISTALIASES&omitHeader=true" -Method Get -Credential (Get-SolrCredential)).collections
    $solrCollections = (Invoke-RestMethod -Uri "$SolrEndpoint/admin/collections?action=LIST&omitHeader=true" -Method Get -Credential (Get-SolrCredential)).collections

    $hash = @{}
    $collectionAliases.psobject.properties | foreach{$hash[$_.Name]= $_.Value}

    foreach ($h in $hash.GetEnumerator()) {
    	Write-Host "$($h.Name): $($h.Value)"
        if ($solrAliasCollections -contains ('{0}{1}' -f  $SolrCorePrefix, $h.Value)) {
	        Write-Information -MessageData "Aliase are already exist. '$h.Value'." -InformationAction:Continue
    	} else {
    		if ($solrCollections -notcontains  ('{0}{1}' -f $SolrCorePrefix, $h.Name)) {
		        Write-Information -MessageData "before creating Aliase '$($h.Value)' we need first create index '$($h.Name)'  with prefix '$SolrCorePrefix'" -InformationAction:Continue
    		} else 
    		{
    			.\New-SolrAlias.ps1 -SolrEndpoint $SolrEndpoint -SolrCollectionName $($SolrCorePrefix + $h.Name) -AliasName $($SolrCorePrefix + $h.Value)
    		}
    	}
    }
}
Write-Host "End Custom - Create Aliases"
