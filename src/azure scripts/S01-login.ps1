
#login to azure and set your az context to the appropriate subscription

$subscription="0d13d072-64ed-4c78-b54a-31a7fab3ad01"

Connect-AzAccount
Get-AzSubscription -SubscriptionId $subscription | Set-AzContext