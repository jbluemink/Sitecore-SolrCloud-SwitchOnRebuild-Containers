# escape=`

ARG BASE_IMAGE
ARG SXA_IMAGE

FROM ${SXA_IMAGE} as sxa
FROM ${BASE_IMAGE}

# Add SXA module
COPY --from=sxa C:\module\solr\cores-sxa.json C:\data\cores-sxa.json

# Add rebuild cores, on existing installation run the solr-int with SOLR_COLLECTIONS_TO_DEPLOY SwitchOnRebuild, similar to SXA
COPY .\cores-SwitchOnRebuild.json C:\data\cores-SwitchOnRebuild.json

# Add aliases
COPY .\aliases-SwitchOnRebuild.json C:\data\aliases-SwitchOnRebuild.json

# Add scripts
COPY .\Start-Custom.ps1 C:\Start-Custom.ps1
COPY .\Start-SwitchOnRebuild.ps1 C:\Start-SwitchOnRebuild.ps1

# Add custom entry point
ENTRYPOINT [ "powershell.exe", ".\\Start-CustomRai.ps1",`
                               "-SitecoreSolrConnectionString $env:SITECORE_SOLR_CONNECTION_STRING",`
                               "-SolrCorePrefix $env:SOLR_CORE_PREFIX_NAME", `
                               "-SolrSitecoreConfigsetSuffixName $env:SOLR_SITECORE_CONFIGSET_SUFFIX_NAME",`
                               "-SolrReplicationFactor $env:SOLR_REPLICATION_FACTOR",`
                               "-SolrNumberOfShards $env:SOLR_NUMBER_OF_SHARDS",`
                               "-SolrMaxShardsPerNodes $env:SOLR_MAX_SHARDS_NUMBER_PER_NODES",`
                               "-SolrXdbSchemaFile .\\data\\schema.json",`
                               "-SolrCollectionsToDeploy $env:SOLR_COLLECTIONS_TO_DEPLOY"]