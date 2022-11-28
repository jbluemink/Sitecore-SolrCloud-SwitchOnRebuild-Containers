# Sitecore-SolrCloud-SwitchOnRebuild-Containers
Sitecore SwitchOnRebuild Container Solr Cloud Example config also usable for Sitecore Managed Cloud with SearchStack

[Read more on : switch solr indexes strategy on searchstax](https://uxbee.nl/actueel/switch-solr-indexes-strategy-on-searchstax)

Tested with the sitecore-xp0-solr-init container for Sitecore 10.2 and SXA
this example include the 2 web databases.
 - sitecore-web-index_rebuild
 - sitecore-sxa-web-index-rebuild
 
easy to adjust in the .json and .config files

Include code that add aliases,
note: you can also use the setting name="ContentSearch.Solr.EnforceAliasCreation" value="true" in the Sitecore config.

The Start-SwitchOnRebuild.ps1 solves the behaviour that it is now possible to add indexes when there already indexen on Solr in the sitecoreCoreSetName.
With a extra foreach it check the actual index instead of the setname named sitecore.
new code to check

```
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
```
Code to check as in the Start.ps1. from the sitecore-xp0-solr-init

```
foreach ($solrCoreName in ($solrSitecoreCoreNames + $solrXdbCoreNames)) {
    if ($solrCollections -contains ('{0}{1}' -f $SolrCorePrefix, $solrCoreName)) {
        Write-Information -MessageData "Sitecore collections are already exist. Use collection name prefix different from '$SolrCorePrefix'." -InformationAction:Continue
        exit
    }
}
```

note: the code is specific for SwitchOnRebuild, hardcode in naming and SolrCollectionsToDeploy parameter, but easy to adjust

