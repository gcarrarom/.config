#!/opt/homebrew/bin/nu

kubectl config get-contexts | from ssv | where CURRENT == '*' | get NAMESPACE | to text
