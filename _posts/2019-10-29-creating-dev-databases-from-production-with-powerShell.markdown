---
layout: post
title: Creating Dev Databases from Production with PowerShell
date: 2019-10-29 08:00:00 +0500
img: assets/images/posts/2019-10-29-creating-dev-databases-from-production-with-powerShell/dev-database-image-main.jpg
tags: [DevOps, PowerShell, Database]
---

I've had the pleasure of dealing with some extremely customized applications.  Ones that you can not simply install the app in a development environment and deploy the changes to it.  I am not a fan of testing in production and often copying a large database for a developer sandbox isn't an option either.  One trick I have is to use PowerShell and Microsoft.SqlServer.Management.Smo to build a Dev database copying all the domain data, but none of the customer data.

The PowerShell script starts by importing the SQL PowerShell module and setting up a few varaibles.

```powershell
Import-Module SQLPS -DisableNameChecking
$DBName = "MY_DATABASE"
$SourceServer = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList "PRODUCTION"
$DestServer = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList "localhost"
I then create an array of table names that I want to copy the data from production.  I made the list of tables by querying the database for all table names.  To keep the list in order I simply comment out the tables that I don't want.
$TableNames=@(
#'dbo.AccountBase'
#'dbo.ActivityPointerBase'
'dbo.AdvancedSimilarityRuleBase'
'dbo.AdvancedSimilarityRuleBaseIds'
... List truncated for brevity
)
```

Now that we have all this defined it is time to create the database and then copy the data that we want.  First, it's always a good idea to remove the existing database.  Your application may have connections still open to your dev database, so the first line is optional depending on your environment.

```powershell
#$DestServer.KillAllProcesses($DBName)
$DestServer.KillDatabase($DBName)
```

Let's get in the actual database copying.  As you can guess copying a database isn't just a script and run script.  Normally there are differences between the production and development environment.  In the script portion below we setup the copy object, but then loop through each SQL file group to apply settings of drive letter and growth size.  As well as, setting the collation, recovery model and trustworthy of the database.

```powershell
$CopyDB = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Database -ArgumentList $DestServer.Name , $DBName
$SourceServer.Databases[$DBName].FileGroups |
ForEach-Object {
        $filegrp = New-Object -TypeName Microsoft.SqlServer.Management.Smo.FileGroup -ArgumentList $CopyDB , $_.Name
        $CopyDB.FileGroups.Add($filegrp)
        For ($i=0; $i -lt $_.Files.Count; $i++)  {
            $filename = $_.Files[$i].FileName -replace "^[A-Z]:", "E:"  #Change All The Drive Letters to E
            $filename = $filename -replace "^E:\\Program Files\\Microsoft SQL Server\\MSSQL.1\\MSSQL\\FTData", "E:\MSSQL\DATA" #Change the Full Text Index to E:\MSSQL\DATA
            $datafile = New-Object -TypeName Microsoft.SqlServer.Management.Smo.DataFile -ArgumentList $filegrp, $_.Files[$i].Name, $filename
            $datafile.Growth = 10.00
            $datafile.GrowthType = [Microsoft.SqlServer.Management.Smo.FileGrowthType]::Percent
            $datafile.MaxSize = $_.Files[$i].MaxSize
            $CopyDb.FileGroups[$filegrp.Name].Files.Add($datafile)
        }
    }
    $CopyDB.Collation = $SourceServer.Databases[$DBName].Collation
    $CopyDB.RecoveryModel = [Microsoft.SqlServer.Management.Smo.RecoveryModel]::Simple
    $CopyDB.Trustworthy = $true
    $CopyDB.Create()
```

Did I mention that we have just created an empty database.  I know you must be thinking where does the tables, views and stored procedures get copied to the dev database?  Well, that's next, we use another SQL management object Microsoft.SqlServer.Management.SMO.Transfer.  There are many options to use with this object.  In the full script I turned on all of them.  I only show a few here for brevity.  I then script out the database creation scripts and execute them in order using a foreach loop.

```powershell
$Transfer   = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Transfer -ArgumentList $SourceServer.Databases[$DBName]
$Transfer.CopyAllDatabaseTriggers = $true
$Transfer.CopyAllDefaults = $true
$Transfer.CopyAllLogins = $true
$Transfer.CopyAllObjects = $true
$SQLQueryCollection = $Transfer.ScriptTransfer()
$SQLQueryCollection | ForEach-Object { Invoke-Sqlcmd -ServerInstance $DestServer.Name -Database $DBName -Query $_ }
At this point, we have full yet empty database.  You should see all database objects just no data.  There is an option in the Microsoft.SqlServer.Management.SMO.Transfer to TransferData.  I was not able to use in with the database I was copying, but you may have more luck.  Instead, I chose good old SQL bulk copy, but I did use the PowerShell version.  This loops through the above list of table names and bulk copies all the data.
$SrcConn  = New-Object System.Data.SqlClient.SQLConnection("Data Source=$Source;Initial Catalog=$DBName;Integrated Security=True;")
  $bulkCopy = New-Object Data.SqlClient.SqlBulkCopy("Data Source=$Dest;Initial Catalog=$DBName;Integrated Security=True;", [System.Data.SqlClient.SqlBulkCopyOptions]::KeepIdentity)
  $bulkCopy.BulkCopyTimeout = 0
  $SrcConn.Open()
  $TableNames | ForEach-Object {
    $CmdText = "SELECT * FROM " + $_
    $SqlCommand = New-Object system.Data.SqlClient.SqlCommand($CmdText, $SrcConn)
    [System.Data.SqlClient.SqlDataReader] $SqlReader = $SqlCommand.ExecuteReader()
    $bulkCopy.DestinationTableName = $_
    $bulkCopy.WriteToServer($sqlReader)
    $SqlReader.close()
  }
    $SrcConn.Close()
    $SrcConn.Dispose()
    $bulkCopy.Close()
```

Now you have as full of a copy of the production database as you wanted in your development database.  I typically take this time to do some housekeeping.  I'll execute a few SQL command to update the production values into development values.

```powershell
$query = "UPDATE [$DBName].[dbo].[SdkMessageProcessingStepBase] SET Configuration = Replace(Configuration, 'PROD', 'localhost') WHERE Configuration like '%PROD%' AND plugintypeid in (Select plugintypeid from [$DBName].[dbo].[PluginTypeBase] WHERE PluginAssemblyId  in (SELECT [PluginAssemblyId] FROM [$DBName].[dbo].[PluginAssemblyBase] WHERE Name = 'Merged.PROD.Plugins'))"
Invoke-Sqlcmd -ServerInstance $DestServer.Name -Database $DBName -querytimeout 1200 -Query $query
```

After a few commands like the one above, I can happily use the database in my development efforts.  In case I want to share this new version of the database with my developer friends.  I generally will back up the version and save it to the network.  I'll use PowerShell and Microsoft.SqlServer.Management.Smo.Backup this time.  Providing it a few parameters I can easily kick off a backup on my development server.