---
layout: post
title: Using SSL for Free in Dev Test Environments
date: 2019-05-28 08:00:00 +0500
author: larry
featured-img: /2019-05-28-using-SSL-for-free-in-dev-test-environments/ssl-main-image
categories: [DevOps, SSL]
---

I have always taken the responsibility for setting up our Dev and Test systems.  I have to admit I am a glutton for punishment.  Whether it be a VMWare or Hyper-V image running on my desktop or an Azure VM, I have scripted them all.  One quirk that I have never liked is having to use a self-signed cert.  I know I just have to do this and then a little that and the everything will be okay, but isn't there an easier way to get a secured Dev/Test environment?

An alternative is to use a free cert from sslforfree.com.  This website will create a valid public cert via the Let's Encrypt Certificate Authority.  The main draw back is that you have to renew the cert every ninety days.  Which would drive production admins crazy, but what about test systems?  Here's are the steps I used to create an SSL cert and register it with an on-premise Dynamics CRM using ADFS for connectivity.

### How to
First navigate to <https://sslforfree.com> and either create a free account or just get started by typing in your website address or wildcard (*.example.com).  When you generate a cert you will have to manually verify by entering a TXT record with the provided value into the DNS settings.  I'm using Azure for this example and the DNS zone is located in the corresponding resource group.   Below is an screen shot of what it looks like.

![DNS Entry](/assets/img/posts/2019-05-28-using-SSL-for-free-in-dev-test-environments/DNS Entry.jpg "DNS Entry")

After you enter the value provided from sslforfree, you can continue the manual verification. 

It will take some time, but then you will be presented with the results, there is an option to DOWNLOAD all files.  You will want choose that to download a zip file containing three files that are the cert, the private key and the CA bundle.  It would be great that ended the situation, but I needed the cert in a PFX format.  Thankfully, I received the help I needed by going to <https://decoder.link/converter/> and find the PEM to PKCS#12 convert.  Fill out the form with the three files you just downloaded.  Also make up a PFX Password to use when importing the cert into the Windows certificate store, then just choose Convert and Download to get the newly combined PFX file.

![Convert PEM to PKCS12](/assets/img/posts/2019-05-28-using-SSL-for-free-in-dev-test-environments/Convert PEM to PKCS12.jpg "Convert PEM to PKCS12")

Once you have the combined PFX file copy it to the ADFS and CRM servers.  Unfortunately, ADFS, doesn't support the new cryptographic provider used to make these wonderful free certs, but that won't stop us.  You just have to use the following certutil parameters to properly import the SSL cert for ADFS to work correctly. 

On CRM and AD Servers run 
certutil.exe -csp "Microsoft Enhanced RSA and AES Cryptographic Provider" -importpfx wildcard-ssl-cert-file.pfx 

On the ADFS server, AD FS Management needs to know about the new cert.  After you launch AD FS Management go to Service -> Certificates -> Set Service Communication Certificate and pick the New SSL Cert 

On CRM Server, the website needs to be using the cert.  Launch IIS management and find the Dynamics website, then update the bindings to the new SSL cert.  We are not done yet with Dynamics.  The deployment also needs to know about the cert.  Launch Dynamics 365 Deployment manager and run the "Configure Claims-based Authentication Wizard" again keeping all the defaults.  After that then run the "Configure Internet-Facing Deployment Wizard" again keeping all the defaults, as well. 

 We're almost there, on the AD Server launch AD FS management and navigate under Trust Relationships -> Relying Party Trusts.  Right click on CRM Claims Relying Party and choose Update Federation Metadata.  Followed by right clicking on Dynamics 365 IFD Relying Party and choosing Update Federation Metadata.  The ADFS service needs to be restarted to take in the newly installed cert and metadata.

### Summary
In this article, we created a free valid public SSL cert and installed it our dev test servers.  It may seem like a lot of tasks, but standing up an on-premise Dynamics CRM installation is a lot of steps.  The SSL cert is only one of the pieces to the whole puzzle.  Hopefully this helps you either in the Dev Test world of CRM or any other IIS system that just needs a SSL cert from a certificate authority.

