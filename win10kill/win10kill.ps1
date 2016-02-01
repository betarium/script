$targetKb = "3035583"

$Session = New-Object -com "Microsoft.Update.Session"
$Search = $Session.CreateUpdateSearcher()
$SearchResults = $Search.Search("IsInstalled=0 and IsHidden=0")
$AvailableUpdates = $SearchResults.Updates
$AvailableUpdates | ForEach-Object { if($_.Title.IndexOf($targetKb) -ge 0){ $_.IsHidden=1; echo ("Disable:" + $_.Title); }}

