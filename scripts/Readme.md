

# Create topic cluster with proper article counting
.\scripts\New-TopicCluster.ps1 -Topic "PowerShell Automation for DevOps" -MinArticles 8 -MaxArticles 12

# Plan now has explicit article count metadata
# Output shows: "Article Count: 10 supporting articles + 1 pillar"

# Generate outlines - will automatically detect count from plan
.\scripts\Generate-Outlines.ps1 -SeriesName "powershell-automation-for-devops"

# Or generate with pillar article included
.\scripts\Generate-Outlines.ps1 -SeriesName "powershell-automation-for-devops" -IncludePillar

# Or manually specify count if detection fails
.\scripts\Generate-Outlines.ps1 -SeriesName "powershell-automation-for-devops" -Count 10
