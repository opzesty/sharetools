# Configure the SharePoint site and target local folder
$siteUrl = "http://ahil_portal/sites/WAREX_87th"
$localFolder = "C:\Users\ZACHARY.RAMIREZ\Documents\sharesaver\files"


# Prompt for SharePoint credentials
#$credentials = Get-Credential

# dev accept creds
$username = "zachary.ramirez@dsc.army.mil"
$password = "fakepassword"
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credentials = New-Object System.Management.Automation.PSCredential ($username, $securePassword)

function Search-SharePointLinks {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Url
    )

    # Function to retrieve SharePoint API response
    function Invoke-SharePointAPI {
        param (
            [string]$RequestUrl
        )

        $response = Invoke-WebRequest -Uri $RequestUrl -Method Get -ContentType "application/xml" -Credential $credentials
        return $response
    }

    # Function to search for links using regex pattern
    function Search-Links {
        param (
            [string]$PageUrl
        )

        $response = Invoke-SharePointAPI -RequestUrl $PageUrl

        $pattern = "decodedurl='(\S+)'\)[^/]"
        $matches = [Regex]::Matches($response.Content, $pattern)

        $linkUrls = @()

        foreach ($match in $matches) {
            $linkUrl = $match.Groups[1].Value
            $linkUrls += $linkUrl
        }

        if ($linkUrls.Count -gt 0) {
            foreach ($link in $linkUrls) {
                $folderApiUrl = "/_api/web/GetFolderbyServerRelativeUrl('$link')/Folders"
                $folderApiUrl = [uri]::EscapeUriString($folderApiUrl)

                $linkUrls += Search-Links -PageUrl $siteUrl$folderApiUrl
            }
        }

        return $linkUrls
    }

    # Start the recursive search
    $processedUrls = @()
    $urlsToProcess = @($Url)

    while ($urlsToProcess.Count -gt 0) {
        $currentUrl = $urlsToProcess[0]
        $urlsToProcess = $urlsToProcess | Select-Object -Skip 1

        if ($processedUrls -contains $currentUrl) {
            continue
        }

        $processedUrls += $currentUrl

        $links = Search-Links -PageUrl $currentUrl
        $urlsToProcess += $links
    }

    return $processedUrls
}

### Main Script Start

$foldersUrl = "$siteUrl/_api/web/GetFolderByServerRelativeUrl('Shared%20Documents')/Folders"

$linkUrls = Search-SharePointLinks -Url $foldersUrl


# Display the list of SharePoint links
foreach ($linkUrl in $linkUrls) {
    Write-Host $linkUrl
}

# Get the files from the SharePoint site
$filesUrl = "Shared%20Documents"
$linkUrls += $filesUrl


foreach ($folder in $linkUrls) {
	
	$fileApiUrl = "/_api/web/GetFolderbyServerRelativeUrl('$folder')/Files"
	$fullUrl = "$siteUrl$fileApiUrl"
	
	Write-Host "Trying this folder: $fullUrl"
	$filesResponse = Invoke-WebRequest -Uri $fullUrl -Method Get -ContentType "application/xml" -Credential $credentials 

	# Extract file names from the XML response
	$files = $filesResponse.Content

	$matches = [regex]::Matches($files, "decodedurl='(\S+)'\)[^/]")

	$files_to_download = New-Object System.Collections.ArrayList

	foreach ($match in $matches) {
		$fileUrl = "$siteUrl/_api/web/GetFileByServerRelativeUrl('" + $match.Groups[1].Value + "')/OpenBinaryStream()"
		$fileName = $(Split-Path -Path $match.Groups[1].Value -Leaf)

		$pair = $filename, $fileUrl
		$files_to_download.Add($pair)
		
		Write-Host "Downloading file: $fileName"
	}

	# Download each file to the local folder
	foreach ($file in $files_to_download) {
		$fileName, $fileUrl = $file
		
		$targetPath = Join-Path -Path $localFolder -ChildPath $fileName

		Invoke-WebRequest -Uri $fileUrl -Credential $credentials -OutFile $targetPath
	}
}

Write-Host "File download complete."
