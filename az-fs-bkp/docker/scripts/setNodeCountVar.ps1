$csv = import-csv C:\repos\az-fs-bkp\docker\scripts\inputCSV.csv
$nodeCount = ($csv|measure).Count