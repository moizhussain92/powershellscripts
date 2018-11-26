Login-AzureRmAccount 
Select-AzureRmSubscription -SubscriptionName "<subscriptionName>"

#Creating array to store Location Ids as String.
$LocationId = @("id1","id2","id3","id4","id5","id6")

#creating 6 location objects to store the location Ids from the Array.
$loc1 = @()
$loc1 += new-object psobject
$loc1 | add-member -type Noteproperty -Name Id -Value $LocationId[0]

$loc2 = @()
$loc2 += new-object psobject
$loc2 | add-member -type Noteproperty -Name Id -Value $LocationId[1]

$loc3 = @()
$loc3 += new-object psobject
$loc3 | add-member -type Noteproperty -Name Id -Value $LocationId[2]

$loc4 = @()
$loc4 += new-object psobject
$loc4 | add-member -type Noteproperty -Name Id -Value $LocationId[3]

$loc5 = @()
$loc5 += new-object psobject
$loc5 | add-member -type Noteproperty -Name Id -Value $LocationId[4]

$loc6 = @()
$loc6 += new-object psobject
$loc6 | add-member -type Noteproperty -Name Id -Value $LocationId[5]

#Creating an array containing all the location Id objects.
$LocationList += $loc1
$LocationList += $loc2
$LocationList += $loc3
$LocationList += $loc4
$LocationList += $loc5
$LocationList += $loc6

#Getting all the Web test Resource IDs belonging to the subscription.
$webTestList = Get-AzureRmResource -Verbose | select -Property resourcetype, resourceid | where -property resourcetype -like "*webtest*" | select -property resourceid -ExpandProperty resourceid

#Storing the Properties of each Resource in the variable
$Properties = $webTestList | foreach { Get-AzureRmResource -ResourceId $_ }

#Chaning the Location setting using the custom created variable $LocationList.
$Properties | foreach {$_.properties.locations = $LocationList}

#Setting the Updated location to the Resource.
$Properties | foreach {$_ | Set-AzureRmResource -Force}