# Configure the SharePoint site and target local folder
$siteUrl = "https://your-sharepoint-site-url"
$localFolder = "C:\Path\to\local\folder"

# Connect to SharePoint site
$context = New-Object Microsoft.SharePoint.Client.ClientContext($siteUrl)
$credentials = Get-Credential
$context.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($credentials.UserName, $credentials.Password)

# Get the files from the site
$web = $context.Web
$files = $web.Lists.GetByTitle("Documents").RootFolder.Files
$context.Load($files)
$context.ExecuteQuery()

# Download each file to the local folder
foreach ($file in $files) {
    $context.Load($file)
    $context.ExecuteQuery()

    $fileUrl = $siteUrl + "/" + $file.ServerRelativeUrl
    $targetPath = $localFolder + "\" + $file.Name
    $fileInfo = [System.IO.FileInfo]::new($targetPath)

    $fileStream = [System.IO.File]::Create($targetPath)
    $client = New-Object System.Net.WebClient
    $client.Credentials = $credentials
    $client.DownloadFile($fileUrl, $fileStream)
    $fileStream.Close()
    $fileStream.Dispose()
}

# Disconnect from SharePoint site
$context.Dispose()
