---
layout: post
title: Dynamics 365 CRM Plugins Sending Custom Messages Azure Service Bus
date: 2020-04-17 08:00:00 +0500
author: larry
featured-img: 2020-04-17-dynamics-365-crm-plugins-sending-custom-messages-azure-service-bus/dynamics-crm-service-bus-main
imageshadow: true
categories: [Dynamics365, Azure, ServiceBus]
---

In the dream world of event driven computing, we often wish for small points in processes to release such events.  Fortunately, Dynamics 365 CRM has several software solutions to invoke custom demand during a change pipeline.  One such one is creating an [Azure-aware Plugin](https://docs.microsoft.com/en-us/dynamics365/customerengagement/on-premises/developer/write-custom-azure-aware-plugin) and registering it to fire it during a particular event. Even thought Dynamics 365 CRM provides the IServiceEndpointNotificationService for Azure-aware Plugins to send the Plugin context to [Azure Service Bus](https://azure.microsoft.com/en-us/services/service-bus/).  This limits you to only sending the data in IPluginExecutionContext.  I have seen examples of adding extra information into the context before sending to the registered service endpoint (i.e. Service Bus), but this still required the receiver/subscriber to know about the IPluginExecutionContext and how to unpack the data it stores.  Wouldn't it be nice to just send an agreed upon message body that could be processed without all the CRM/Xrm assemblies?  Well, there is a possibility.

Dynamics Plugins do allow outbound HTTP access even in sandboxed/isolated mode.  Azure Service Bus allows for messages to be sent via REST (i.e. HTTP), so what happens when you put the two together?  You get the best of both worlds, an event driven message that you can consume without all the CRM assembly baggage.  In this example, I'm sending an object that is an IMessage.  IMessage is nothing more than an inteface I created to distinguish the message classes from all other classes.  The interface is empty of behaviors and is more of a decoration. If this is confusing just change IMessage to object.

The connection with Service Bus requires the URI to your Service Bus namespace, Shared Access Key (Name and Value) and the Topic or Queue name.  This was the most confusing part of all the examples I found elsewhere.  I can say this example works.

```c#
string baseUri = "https://your-sb-namespace.servicebus.windows.net";
string keyName = "YourSharedAccessKeyName";
string key = "******KEYVALUE******";
string queueOrTopic = "your-topic-or-queue-name";
```

The main method takes the message and the four other variables.  In it a HTTPClient will post the serialized message using a token generated from tke shared access key.  In this case, the message was serialized into xml. You can of course change that to JSON if that fits your needs.  After the PostAsync command, the response is checked for failure using the IsSeccessStatusCode and if nothing is wrong we are done or a exception is reported.

```c#
public void SendServiceBus(IMessage message, string baseUri, string keyName, string key, string queueOrTopic)
{
    using (System.Net.Http.HttpClient client = new System.Net.Http.HttpClient())
    {
        client.BaseAddress = new Uri(baseUri);
        client.DefaultRequestHeaders.Accept.Clear();

        string token = createToken($"{baseUri}/{queueOrTopic}", keyName, key);
        client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("SharedAccessSignature", token);

        System.Net.Http.HttpContent content = new System.Net.Http.ByteArrayContent(serializeMessageBody(message));
        content.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue("application/xml");

        var response = client.PostAsync($"/{queueOrTopic}/messages", content).Result;
        if (response.IsSuccessStatusCode == false)
        {
            throw new System.Net.WebException($"Error Posting {message.GetType()} to {baseUri} with code {response.StatusCode} and reason {response.ReasonPhrase}");
        }
    }
}
```

The createToken method uses the Service Bus URI and Key to generate a security token that expires in five minutes.

```c#
private string createToken(string resourceUri, string keyName, string key)
{
    var epoch = new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc);
    var offset = (long)(DateTime.Now.ToUniversalTime() - epoch).TotalSeconds; //since this is .Net 45, I couldn't use ToUnixTimeSeconds()
    var expiry = offset + 300;
    string stringToSign = System.Web.HttpUtility.UrlEncode(resourceUri) + "\n" + expiry;
    System.Security.Cryptography.HMACSHA256 hmac = new System.Security.Cryptography.HMACSHA256(Encoding.UTF8.GetBytes(key));
    var signature = Convert.ToBase64String(hmac.ComputeHash(Encoding.UTF8.GetBytes(stringToSign)));
    var sasToken = String.Format("sr={0}&sig={1}&se={2}&skn={3}", System.Web.HttpUtility.UrlEncode(resourceUri), System.Web.HttpUtility.UrlEncode(signature), expiry, keyName);
    return sasToken;
}
```

This simple serializer uses the XML serialzer, which again can be changed out for any needed serialized version.

```c#
private byte[] serializeMessageBody(object message)
{
    var serializer = new System.Xml.Serialization.XmlSerializer(message.GetType());
    using (var stream = new System.IO.MemoryStream())
    {
        serializer.Serialize(stream, message);
        return stream.ToArray();
    }
}
```

Hopefully, this will help anyone wanting more control over what data is sent from CRM and not requiring the receiver to reference the Xrm assemblies.  Be sure to get all the variables correct and try not to get too confused when looking over other articles about communication with Azure Service Bus. 
