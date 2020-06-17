---
layout: post
title: Azure Logic Apps Working with Form Encoded Data
date: 2019-08-26 08:00:00 +0500
author: larry
image: assets/images/posts/2019-08-26-azure-logic-apps-working-with-form-encoded-data/logic-app-main.jpg
imageshadow: true
tags: [Azure, LogicApps]
---

I have been designing Azure Logic apps for some time now and really enjoy the overall experience be it with Visual Studio using Azure DevOps or spinning up a quick workflow in the Azure Portal. They offer a very nice assortment of tools from the API connectors to process management for each execution.  One thing I have noticed is that not all vendors are able to post JSON documents to communicate.  They are still posting form data and Logic apps are capable when you know how.

This first thing is you need a simple HTTP trigger to accept the form data post.  You can leave the schema empty since we'll be using an expression to get the the form values.  For demonstration purposes, I'll add a Compose action to the Logic App.  In the Compose action, we can create a JSON output and map in the form data.  Next we need to learn about the triggerFormDataValue() function to access the form post data.

![Logic App HTTP Request Form Variables](/assets/images/posts/2019-08-26-azure-logic-apps-working-with-form-encoded-data/Logic App HTTP Request Form Variables.jpg "Logic App HTTP Request Form Variables")

The triggerFormDataValue() expression needs to be used for each form value you want.  You will need to type in the form data name to return that specific value.  To test out this Logic App, I'm going to use Postman, a free application that will let us POST to the Logic Apps webhook URL.

![Postman Triggering Logic App](/assets/images/posts/2019-08-26-azure-logic-apps-working-with-form-encoded-data/Postman Triggering Logic App.jpg "Postman Triggering Logic App")

We can then go into the Logic App's run history to view the outcome.

![Logic App Form Variables](/assets/images/posts/2019-08-26-azure-logic-apps-working-with-form-encoded-data/Logic App Form Variables.jpg "Logic App Form Variables")

You will see the HTTP trigger with the output body of what we submitted via Postman.  You will also see the input and output of the Compose action.  In there the new JSON payload has our form data.

Even though JSON rules the REST based messaging world, form data is here to stay.  It is often necessary when integrating with older legacy services.  It can also give you a quick solution without having to rewrite many different interfaces.  Remember you don't have to specify a schema on the HTTP trigger and Compose is a nice way to debug your expressions.

Even though this is a pretty simple project, I've shared the code on my Github site at <https://github.com/larryjameshenry/5-minutes-with-azure>.

Enjoy Coding!