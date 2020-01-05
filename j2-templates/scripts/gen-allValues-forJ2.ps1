#This script reads the CSV file and generates the cronjob-template-values.yml file. 
#Ansible playbook uses this values file and generates cronjob template file using cronjob-template.j2 template.
$buildid = $env:buildid
if((Get-Module powershell-yaml |measure).count -eq 0)
{
    #Install-PackageProvider -Name NuGet -Force -Scope CurrentUser | Out-Null
    Install-Module -Name powershell-yaml -Force  -Scope CurrentUser | Out-Null

}
$csv = import-csv docker/scripts/inputCSV.csv
[int]$nodeCount = ($csv|measure).Count

[string[]]$fileContent = get-content j2-templates/cronjob-values-base.yml

$yamlcontent = ''
foreach ($line in $fileContent)
{
         $yamlcontent = $yamlcontent + "`n" + $line
}

$finalyamlcontentArr = $yamlcontent -split "---"
$yamlitem = $finalyamlcontentArr[1] | ConvertFrom-Yaml
for($i=1;$i -le $nodecount-1;$i+=1)
{
    $yamlitem.cronjob_names += "cronjob-node$i"
}
$yamlitem.cron_image_latest = "azfsbkpacr.azurecr.io/az-fs-bkp:"+"$buildid"
$stringYaml = $yamlitem | ConvertTo-Yaml
$stringYaml = "---" + "`n" + $stringYaml
$yamlitem = $stringYaml|ConvertTo-Yaml  | ConvertFrom-Yaml
#$yamlitem | out-file cronjob-actual-values.yml
$yamlitem | out-file ansible-templates/dynamic-cronjob-actual-values.yml -Force
$yamlitem

