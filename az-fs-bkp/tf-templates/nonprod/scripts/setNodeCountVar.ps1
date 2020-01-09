$csv = import-csv ..\..\docker\scripts\inputCSV.csv
[int]$nodeCount = ($csv|measure).Count
$nodeCount | Out-File /etc/node_count.txt
