
$WindowsFeatures = @(
	 'Web-Common-Http' `
	,'Web-Security'`
	,'Web-Performance'`
	,'Web-Health'`
	,'Web-Net-Ext45'`
	,'Web-Asp-Net45'`
	,'Web-WebSockets'`
	,'Web-AppInit'`
	,'Web-ISAPI-Filter'`
	,'Web-ISAPI-Ext'`
	,'Web-Mgmt-Console');

$zipuri =  "http://mshandson.blob.core.windows.net/practice/webapp.zip"
$zipfilename = ".\temp\webapp.zip"
$applicationfolder = "C:\"
$applicationbindingfolder = "C:\webapp"

Configuration HandsonWebApp
{
	param
	(
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$AdminCreds,
		
		[parameter(Mandatory)]
        [String]$DatabaseName,

        [parameter(Mandatory)]
        [String]$DatabaseServerFQDN,

        [parameter(Mandatory)]
        [String]$DatabaseServer
	)

	$AdminName = $AdminCreds.GetNetworkCredential().UserName
	$AdminPassword = $AdminCreds.GetNetworkCredential().Password

	Import-DscResource -ModuleName xNetworking,xWebAdministration, NTFSPermission

	Node "localhost"
	{
		LocalConfigurationManager
		{
			ConfigurationMode = "ApplyAndAutoCorrect"
			RebootNodeIfNeeded = $true
		}

		#Install the IIS Role
		$WindowsFeatures | foreach {
			WindowsFeature "Installed-IIS-$PSItem"
			{
				Name = $PSItem
				Ensure = 'Present'
				IncludeAllSubFeature = $true
			}
		}

		# HTTPを許可する
		xFirewall 'Allow HTTP'
		{
			Name = 'Allow HTTP'
			DisplayName = 'Allow HTTP'
			DisplayGroup = 'Custom'
			Ensure = 'Present'
			Access = 'Allow'
			State = 'Enabled'
			Profile = ('Any')
			Direction = 'InBound'
			Protocol = 'TCP'
			LocalPort = '80'
			Description = ''
		}

		xWebsite DefaultSite
		{
			Ensure = "Present"
			Name = "Default Web Site"
			PhysicalPath = "C:\inetpub\wwwroot"
			State = "Stopped"
			DependsOn = "[WindowsFeature]Installed-IIS-Web-Common-Http"
		}

		Script DownloadResource {
			GetScript = @"
				@{
					Result = (Test-Path -Path '$($zipfilename)' -PathType Leaf)
				}
"@
			SetScript = @"
				If (-not(Test-Path -Path '.\temp' -PathType Container)) {
					New-Item -Path '.\temp' -ItemType Directory
				}
				Invoke-WebRequest -Uri '$($zipuri)' -OutFile '$($zipfilename)'
				Unblock-File -Path '$($zipfilename)'
"@
			TestScript = @"
				Test-Path -Path '$($zipfilename)' -PathType Leaf
"@
		}

		archive ZipFile {
			Path = $zipfilename
			Destination = $applicationfolder
			Ensure = 'Present'
			DependsOn = "[Script]DownloadResource"
		}

		NTFSPermission AppDataSecurity
		{
			Ensure = "Present"
			Account = "IIS AppPool\DefaultAppPool"
			Access = "Allow"
			Path = "$applicationfolder\webapp"
			Rights = "FullControl"
			DependsOn = "[archive]ZipFile"
		} 


		xWebsite TailspinToysSiteDev
		{
			Ensure = "Present"
			Name = "HandsOnApplication"
			PhysicalPath = "$applicationbindingfolder"
			State = "Started"
			BindingInfo     = MSFT_xWebBindingInformation  
			{  
				Protocol              = "HTTP" 
				Port                  = 80
			}  
 
			DependsOn = "[NTFSPermission]AppDataSecurity"
		}

		Script ChangeConnectionString 
		{
			SetScript =
			{    
				$xmlfile = "$using:applicationbindingfolder\Web.Config"
				$xml = [xml](Get-Content $xmlfile)
 
				$node = $xml.SelectSingleNode("//connectionStrings/add[@name='LogDataDbContext']")
				$node.Attributes["connectionString"].Value = "Server=tcp:$using:DatabaseServerFQDN;Initial Catalog=$using:DatabaseName;User ID=$using:AdminName@$using:DatabaseServer;pwd=$using:AdminPassword;Trusted_Connection=False;Encrypt=True;"
				$xml.Save($xmlfile)
			}
			TestScript = 
			{
				return $false
			}
			GetScript = 
			{
				return @{
					GetScript = $GetScript
					SetScript = $SetScript
					TestScript = $TestScript
					Result = false
				}
			} 
			DependsOn = "[NTFSPermission]AppDataSecurity"
		}

	}
}
