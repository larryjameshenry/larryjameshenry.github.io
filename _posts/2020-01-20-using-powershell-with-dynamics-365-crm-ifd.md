---
layout: post
title: Using PowerShell with Dynamics 365 CRM IFD
date: 2020-01-20 08:00:00 +0400
author: larry
featured-img: 2020-01-20-using-powershell-with-dynamics-365-crm-ifd/powershell-main
imageshadow: true
categories: [PowerShell, OData, Dynamics365]
---

Sometimes you want to create full blown application to work with your Dynamics installation and sometimes you just need to run a script.  I have found myself needing to pull a small bit of data or run an action through the Web API and that really feels like a script to me.  It is easy if your Dynamics doesn't require claims or ADFS, you can POST and GET and let your network credentials be used.  When times get more complicated (i.e. claims and internet facing deployment), the PowerShell does get longer but it is still possible.

I'm sharing a snippet below of a common PowerShell script that I use to get the Accounts in CRM.  You could, of course, ask Web API for any entity and pass OData filters if you need.  I'll let you complicate that part of the script.  You will also need to change the AppliesTo, UserName, Password, ADFS server URL along with the REST GET URL.  Which is quite a lot, feel free to change this to your liking and ease of reuse.  This is just a snippet from me to you.

First we have the assemblies, you need Service Model and Identity Model for the bindings.  I'm sure your thinking, "Why not just do a GET request and let the ADFS magic happen"?  We'll there is no web browser realm for that magic to be cast in, so we have to fashion the realm for ourselves.  This is why we create a Security Token Request and a trusted channel before we try our Web API query.  After we get the token we have to add it to our Authorization headers as a Bearer token.  Once we have that we should be able to query our Dynamics CRM based on permissions provided in the Bearer token.  If you cannot access a particular entity or record, first check the user's security roles.
My version of PowerShell prefers async calls, so I'm using task to wait and check for completion.  Once you have your result you use it just like any other PowerShell object and continue on with you scripting needs.  For this article, I just printed it to the console.

This is one way to access your CRM data, as you can see it uses a lot of .NET assembly calls.  So if you are more comfortable in C# or ASP.NET feel free to implement it that way.  I was able to do just that with the .NET Framework.  I was unable to with .NET Core, so be warned if you wish to try that route.  I will also disclose that our ADFS server is Windows 2012 R2 and only supports authentication code.  You may have easier luck if your ADFS is newer and supports all four federated schemes.

Best of luck and happy querying.

```powershell
Add-Type -AssemblyName "System.ServiceModel"
Add-Type -AssemblyName "System.IdentityModel"

$requestSecurityToken = New-Object System.IdentityModel.Protocols.WSTrust.RequestSecurityToken;
$requestSecurityToken.RequestType = [System.IdentityModel.Protocols.WSTrust.RequestTypes]::Issue;
$requestSecurityToken.AppliesTo = "https://YourDynamicsURL.com";
$requestSecurityToken.KeyType = [System.IdentityModel.Protocols.WSTrust.KeyTypes]::Bearer;

$binding = New-Object System.ServiceModel.WS2007HttpBinding;
$binding.Security.Message.EstablishSecurityContext = $false;
$binding.Security.Transport.ClientCredentialType = [System.ServiceModel.HttpClientCredentialType]::None;
$binding.Security.Message.ClientCredentialType = [System.ServiceModel.MessageCredentialType]::UserName;
$binding.Security.Mode = [System.ServiceModel.SecurityMode]::TransportWithMessageCredential;

$factory = New-Object System.ServiceModel.Security.WSTrustChannelFactory($binding,
            "https://YourADFSServer.com/adfs/services/trust/13/usernamemixed");
$factory.TrustVersion = [System.ServiceModel.Security.TrustVersion]::WSTrust13;
$factory.Credentials.UserName.UserName= "YourDomain\YourSecuredUsername";
$factory.Credentials.UserName.Password= "YourSecuredPassword";

$channel =[System.ServiceModel.Security.WSTrustChannel]$factory.CreateChannel();
$token = $channel.Issue($requestSecurityToken);

$client = New-Object System.Net.Http.HttpClient;
$client.DefaultRequestHeaders.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue
            -ArgumentList "Bearer", $token.TokenXml.OuterXml;

$task = $client.GetStringAsync("https://YourDynamicsURL.com/api/data/v8.2/accounts")
$task.wait();
if ($task.IsCompleted) {
  # Do your thing here.  We are just going to print out the result
  echo $task.Result
} else {
  echo "Sorry, something went wrong: " + $task.Exception.Message
}
```