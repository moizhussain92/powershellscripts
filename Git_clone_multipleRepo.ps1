# import multiple remote git repositories to local Source dir

 param (
  [string]$localFolder = "D:\repos\",
  [array]$repos = @("EC.MBS.Channel", "EC.MBS.ExternalBilling","EC.MBS.Foundation","EC.MBS.Ordering","EC.MBS.Packages","EC.MBS.SSIS.Database","EC.MBS.Transaction.Database","EC.MBS.Core","EC.MBS.Core")
 )
$repoLocation = "https://microsoft.visualstudio.com/DefaultCollection/Universal%20Store/_git/"

# for each repo found remotely, check if it exists locally
# if dir exists, skip, if not, clone the remote git repo into it
foreach ($gitRepo in $repos) {
	If (Test-Path $localFolder\$gitRepo) {
		echo "repo $gitRepo already exists"
	}
	Else {
		echo "git clone $repoLocation$gitRepo $localFolder\$gitRepo"
		git clone $repoLocation$gitRepo $localFolder\$gitRepo
	}
}