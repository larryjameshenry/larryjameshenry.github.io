---
layout: post
title: Using Azure Function Apps as Microservice APIs Part 1
date: 2019-11-30 08:00:00 +0400
img: assets/images/posts/2019-11-30-using-azure-function-apps-as-microservice-apis-part-1/azure-function-main.jpg
tags: [Azure, API, AzureFunctions, Microservices]
---

When you look through all the hoopla microservices brings software design back to single responsibility and simple boundaries.  It provides the flexibility in management, support and advancement of the product.  Whether your product is simple or complex.  You need to take a high level view and identify it's current boundaries and where you may be missing boundaries.  Even if you don't  reduce it to a microservice, your software will be better for it.
I have found that it works well to take a couple of those boundaries and see if you can separate the code and data.  Don't forget a microservice needs to store and maintain its own data, not share it in large complex database.  This doesn't mean that other systems will have no information from processes performed by the microservice.  A publish/subscribe messaging system will get information to those other systems.
For this article, I want to separate out the concerns of our payment software.  We currently have all customer, payment schedules and payment processing in our CRM system.  This, of course, makes it hard to change the software and I have even found code for the payment processing next to other CRM related code.  At some point, you can't tell why or where code is firing during the CRM's processing.
So we can first look at the coupling in the current system.  The customer knows everything about the schedule and payments.  If we need to change to another payment gateway, then a thorough inspection of the entire system is needed.

![Coupled customer schedule and payment data](/assets/images/posts/2019-11-30-using-azure-function-apps-as-microservice-apis-part-1/Coupled customer schedule and payment data.jpg "Coupled customer schedule and payment data")

It does help customer service to know when and what the customer will be charged, as well as, how much we have collected from the customer.  This data need does not warrant keeping all the schedule and payment data with the customer data to perform the scheduling and payment processing.  It's often helpful to to write down what data is needed in each area.

![entities with needed data](/assets/images/posts/using-azure-function-apps-as-microservice-apis-part-1/entities with needed data.jpg "entities with needed data")

Since I don't want to turn this article into a book and want to get to using Azure Functions, I am going to focus on payment.  It is easier to peel off the last part of a coupled process instead of the beginning or middle.  So we are going to leave the customer and schedule alone.  Looking at Payment we will need a service to sit in front of the data, as well as, communicate with the external payment gateway and publish events.

![Payment Service and dependencies](/assets/images/posts/2019-11-30-using-azure-function-apps-as-microservice-apis-part-1/Payment Service and dependencies.jpg "Payment Service and dependencies")

Sorry for all the post-it notes, but they work well to express what we are doing.  Now onto the Function app.  As you can probably guess, I like function apps for their serverless (no server to managed) nature and the fact that I can use a consumption plan (only pay for what you use) to get started.  This function app will accept restful commands of GET, POST, PUT and DELETE to read, create, update and delete respectively.  You may be wondering what purpose we have with update?  I have decided it will be used for refunds.  Your company may need to create a negative payment instead and use update for minor adjustments.  This data requirement will depend on your business and reporting needs.
Along side the restful commands of this service, it will also manage at least one payment gateway and publish events.  You may be thinking isn't that too much for a microservice?  It is micro after all.  You could extract the payment gateway portion into a Charge service, but since I have no other processes that take a dependency on it.  It is best to manage it as part of the Payment service.
So to create the Azure Function, I will launch Visual Studio and choose to create a new project specifying Azure Function C# using .Net Core.  I like to also create a Domain project to hold classes that are specific to this implementation and which might need to be shared with other solutions in the enterprise.  The Solution window looks like this.

![SolutionProjectList1](/assets/images/posts/2019-11-30-using-azure-function-apps-as-microservice-apis-part-1/SolutionProjectList1.jpg "SolutionProjectList1")

Inside the PaymentFunction.cs file, I have create five methods two that respond to GET and then POST, PUT and Delete.  I am going to leave the bodies of these methods empty for this article and will go more in depth in a part 2.  Below you will see the five methods of the PaymentFunction class with HttpTrigger and Azure Table storage as input.  Don't forget to add a using statement for Microsoft.WindowsAzure.Storage.Table or you'll see red squiggles.

```c#
public static class PaymentFunction
  {
    [FunctionName("GetPaymentList")]
    public static async Task<IActionResult> GetPaymentList(
        [HttpTrigger(AuthorizationLevel.Function, "get", Route = "payment")] HttpRequest req,
        [Table("Payment", Connection = "AzureWebJobsStorage")] CloudTable paymentTable, ILogger log)
        {
                //TODO Add GetPaymentList funtionality
        }
    [FunctionName("GetPaymentDetail")]
    public static async Task<IActionResult> GetPaymentDetail(
        [HttpTrigger(AuthorizationLevel.Function, "get", Route = "payment/{id}")] HttpRequest req,
        [Table("Payment", Connection = "AzureWebJobsStorage")] CloudTable paymentTable, ILogger log,
        string id)
        {
            //TODO Add GetPaymentDetail funtionality
        }
    [FunctionName("CreatePayment")]
    public static async Task<IActionResult> CreatePayment(
        [HttpTrigger(AuthorizationLevel.Function, "post", Route = "payment")] HttpRequest req,
        [Table("Payment", Connection = "AzureWebJobsStorage")] CloudTable paymentTable, ILogger log)
        {
          //TODO Add CreatePayment funtionality
        }
    [FunctionName("UpdatePayment")]
    public static async Task<IActionResult> UpdatePayment(
        [HttpTrigger(AuthorizationLevel.Function, "put", Route = "payment")] HttpRequest req,
        [Table("Payment", Connection = "AzureWebJobsStorage")] CloudTable paymentTable, ILogger log)
        {
          //TODO Add UpdatePayment funtionality
        }
    [FunctionName("DeletePayment")]
    public static async Task<IActionResult> DeletePayment(
        [HttpTrigger(AuthorizationLevel.Function, "delete", Route = "payment")] HttpRequest req,
        [Table("Payment", Connection = "AzureWebJobsStorage")] CloudTable paymentTable, ILogger log)
        {
          //TODO Add DeletePaymentfuntionality
        }
  }
```

Even with this you can run the Azure Function from within Visual Studio and use a tool such as Postman to send HTTP requests to it.  This is a great way of debugging your Function app without deploying it to Azure.  Just pay attention to the URLs displayed in the debug console window.  I hope this article helps you on the way of using Azure Functions for a simple serverless API option.  It has been fun for me.  In the next installment we'll wire up these methods and the payment gateway.  Later, we'll see about publishing events and discuss how the Schedule and Customer will subscribe to receive updates for the information they need.

If you would like to follow along, I will be updating my Github repository <https://github.com/larryjameshenry/azure-function-app-microservice-example>.