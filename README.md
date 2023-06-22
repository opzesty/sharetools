# sharetools
the files are IN the computer....

but you want them to be in the other computer.  This is the project for you.


## configuration
### Credentials
Set the __$username__ and __$password__ variables in the script (or uncomment the line __$credentials = Get-Credential__)

### Other variables
| Variable | Explanation |
| -------- | ----------- |
|$siteUrl | sharepoint site url e.x. https://sharepoint.com/sites/YOURSITE|
| $localFolder | path to a folder you've created to drop all the files into |


## usage
Open a PowerShell and navigate to the folder you've stored this script in.  Then type

``` <!-- language: powershell -->
.\download_sharepoint_iwr.ps1
```