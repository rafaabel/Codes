#interating through the arguments
#and performing an operations on each
$args | foreach-object { $_ * 2 }

"Argument count:$($args.count)"
"First argument: $($args[0])"
"Second argument $($args[1])"
"Last argument $($args[-1])"

$args.GetType()