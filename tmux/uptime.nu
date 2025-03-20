#!/opt/homebrew/bin/nu

sysctl kern.boottime | cut -d ' ' -f 8 | $in + "sec" | into duration | format duration "day" 
