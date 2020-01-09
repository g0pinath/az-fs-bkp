$allfolders = (Get-ChildItem c:\temp | select Name).Name  
Foreach($folder in $allfolders)
{
    for ($i=0;$i -le "10000";$i=$i+2)
    {
    #remove-item -Path C:\temp -LiteralPath test$i.txt -Force
    new-item -Path c:\temp\$folder\even-number  -Name test$i.txt -Force |Out-Null
    "testfile -- $i" | out-file c:\temp\$folder\even-number\test$i.txt
    }
}

Foreach($folder in $allfolders)
{
    for ($i=1;$i -le "10000";$i=$i+2)
    {
    #remove-item -Path C:\temp -LiteralPath test$i.txt -Force
    new-item -Path c:\temp\$folder\odd-number -Name test$i.txt -Force |Out-Null
    "testfile -- $i" | out-file c:\temp\$folder\odd-number\test$i.txt 
    }
}