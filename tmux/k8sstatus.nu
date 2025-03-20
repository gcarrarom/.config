#!/opt/homebrew/bin/nu

kubectl config get-contexts | from ssv | where current == '*' | get namespace | to text
