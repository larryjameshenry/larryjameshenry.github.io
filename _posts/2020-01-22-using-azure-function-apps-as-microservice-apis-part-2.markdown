---
layout: post
title: Using Azure Function Apps as Microservice APIs Part 2
date: 2020-01-22 08:00:00 +0400
author: larry
image: assets/images/posts/2020-01-22-using-azure-function-apps-as-microservice-apis-part-2/azure-function-main.jpg
tags: [Azure, API, AzureFunctions, Microservices]
---

In a previous post, [Using Azure Function Apps as Microservice APIs Part 1](/using-azure-function-apps-as-microservice-apis-part-1) I go over the thinking behind a payment microservice and method signatures that we will be working with in this post.  I am going to leave out the integration with a payment gateway.  Since this article would become massive and the point is to show Azure Functions providing a RESTful microservice implementation.  I do want to point out that I am using Azure Functions V3 .NET Core for this project.  Therefore, I am limited to accessing the Azure Storage Table using Microsoft.WindowsAzure.Storage.Table.CloudTable.  You may find other bindings to access a storage table in Azure, but it will no longer work.

Enough about the messy plumbing, let's create a payment by implementing the POST for payment.  As you can see by the below code example, we are triggering on the POST HTTP method for the route of payment.  Along with that we are including the bindings for the Azure Storage table and a logger, because everyone loves a good logger.  The method simply deserializes the HTTP body and wraps it in our PaymentAdapter, a class used for storing and retrieving our payment from the storage table.  If I didn't use the PaymentAdapter, my Payment class would have to have properties for the storage table which couples me to a particular data storage.  The adapter is then added to an InsertOrReplace operation and finally executed.  The output result then returned as the HTTP response.

```c#
[FunctionName("CreatePayment")]
public static async Task<IActionResult> CreatePayment(
  [HttpTrigger(AuthorizationLevel.Function, "post", Route = "payment")] HttpRequest req,
  [Table("Payment", Connection = "AzureWebJobsStorage")] CloudTable outputTable,
  ILogger log)
{
     string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
     var payment = JsonConvert.DeserializeObject<Payment>(requestBody);
     var adapter = new PaymentAdapter(payment);
     var insertOrMergeOperation = TableOperation.InsertOrReplace(adapter);
     TableResult result = await outputTable.ExecuteAsync(insertOrMergeOperation);
     var insertedPayment = result.Result as PaymentAdapter;
     return insertedPayment != null
          ? (ActionResult)new OkObjectResult(insertedPayment.Value)
          : new BadRequestObjectResult("Please check the payment you are trying to create.");
}
```
After we have created a payment, we can get the list of payments.  This is accomplished by triggering off the GET HTTP method and same route of payment.  The CloudTable binding is passed in again along with the logger.  Since we want all payments, it's a simple query for all PaymentAdapters.  We do utilize LINQ to allow us to extract a list of Payment objects to be returned instead of the PaymentAdapters.

```c#
[FunctionName("GetPaymentList")]
public static async Task<IActionResult> GetPaymentList(
  [HttpTrigger(AuthorizationLevel.Function, "get", Route = "payment")] HttpRequest req,
  [Table("Payment", Connection = "AzureWebJobsStorage")] CloudTable paymentTable,
  ILogger log)
{
     var querySegment = await paymentTable.ExecuteQuerySegmentedAsync(
                                           new TableQuery<PaymentAdapter>(), null);
     var payments = querySegment.Select(p => p.Value).ToList();
     return payments.Count > 0
          ? (ActionResult)new OkObjectResult(payments)
          : new NotFoundResult();
}
```
If we want just one payment, we can use GetPaymentDetails.  This takes a slightly different trigger using GET and the route now includes an id along with payment.  The CloudTable joins us again, as well as, the logger.  This is similar to the request for all payments, but does require a filter condition and using the provided id to be the rowKey that we want to filter.  The rest is a similar query and extracting the Payment object to return as the HTTP response.

```c#
[FunctionName("GetPaymentDetail")]
public static async Task<IActionResult> GetPaymentDetails(
  [HttpTrigger(AuthorizationLevel.Function, "get", Route = "payment/{id}")] HttpRequest req,
  [Table("Payment", Connection = "AzureWebJobsStorage")] CloudTable paymentTable,
  ILogger log,
  string id)
{
     var rowKey = PaymentAdapter.BuildRowKey(id);
     var rowKeyFilter = TableQuery.GenerateFilterCondition("RowKey", QueryComparisons.Equal, rowKey);
     var query = new TableQuery<PaymentAdapter>().Where(rowKeyFilter);
     TableContinuationToken token = null;
     var result = await paymentTable.ExecuteQuerySegmentedAsync<PaymentAdapter>(query, token);
     var payments = result.Select(p => p.Value).FirstOrDefault();
     return payments != null
          ? (ActionResult)new OkObjectResult(payments)
          : new NotFoundResult();
}
```
Updating a payment is definitely the hardest to implement of the REST methods.  This is mostly due to the CloudTable need of Replace versus a typical Update.  Most update commands only require the changed fields to be passed in, but the Replace method literally replaces the row with the updated row.  To allow for missing information in the HTTP body's payload, I query for the existing record. then I go through each property and assign either the updated or existing value.  This can become quite ridiculous if you have a large amount of fields.  I may do a future blog discussing improvements on this simple implementation.  After that, we are down to the replace operation and execution.  The result is again returned as the HTTP response.   

```c#
[FunctionName("UpdatePayment")]
public static async Task<IActionResult> UpdatePayment(
  [HttpTrigger(AuthorizationLevel.Function, "put", Route = "payment/{id}")] HttpRequest req,
  [Table("Payment", Connection = "AzureWebJobsStorage")] CloudTable outputTable,
  ILogger log,
  string id)
{
     string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
     var updated = JsonConvert.DeserializeObject<Payment>(requestBody);
     var findOperation = TableOperation.Retrieve<PaymentAdapter>(
                                         PaymentAdapter.BuildPartitionKey("Payment"), id);
     var findResult = await outputTable.ExecuteAsync(findOperation);
     if (findResult.Result == null)
     {
          return new NotFoundResult();
     }
     var existingRow = findResult.Result as PaymentAdapter;
     var existingPayment = existingRow.Value;
     existingPayment.Amount = updated.Amount ?? existingPayment.Amount;
     existingPayment.CustomerId = updated.CustomerId ?? existingPayment.CustomerId;
     existingPayment.PaymentId = updated.PaymentId ?? existingPayment.PaymentId;
     existingPayment.PaymentStatus = updated.PaymentStatus ?? existingPayment.PaymentStatus;
     existingPayment.PostedDate = updated.PostedDate ?? existingPayment.PostedDate;
     existingPayment.ScheduleId = updated.ScheduleId ?? existingPayment.ScheduleId;

     var replaceOperation = TableOperation.Replace(new PaymentAdapter(existingPayment));
     TableResult result = await outputTable.ExecuteAsync(replaceOperation);
     var updatedPayment = result.Result as PaymentAdapter;
     return updatedPayment != null
          ? (ActionResult)new OkObjectResult(updatedPayment.Value)
          : new BadRequestObjectResult("Please check the payment you are trying to update.");
}
```
Then we can finally delete the individual payment.  I did not implement a delete all, but you could easily do that in the route.  For this we are wanting to delete an individual Payment record.  The id is passed in and parsed to become the PaymentId Guid.  With the help of the PaymentAdapter, this gets added to a delete operation and executed much like the operations above.  The result of the delete execution is again returned as the HTTP response.

```c#
[FunctionName("DeletePayment")]
public static async Task<IActionResul> DeletePayment(
  [HttpTrigger(AuthorizationLevel.Function, "delete", Route = "payment/{id}")] HttpRequest req,
  [Table("Payment", Connection = "AzureWebJobsStorage")] CloudTable paymentTable,
  ILogger log,
  string id)
{
     var payment = new Payment() { PaymentId = Guid.Parse(id) };
     var adapter = new PaymentAdapter(payment);
     var operation = TableOperation.Delete(adapter);
     var result = await paymentTable.ExecuteAsync(operation);
     var payments = result.Result;
     return payments != null
          ? (ActionResult)new OkObjectResult(payments)
          : new NoContentResult();
}
```
That's it for a simple RESTful endpoint using Azure Functions.  The original problem where we needed one portion of the larger ball of mud replaced with a smaller limited service is satisfied.  Now the Customer can store the PaymentId, but everything else regarding the payment is in the Payment functions.  You could add to this service to respond to queries of CustomerId or ScheduleId.  Try to be careful not to move your big ball of mud into your new small service.
I would stabilize the service separation and add in the calls to the payment gateway.  We do still need to charge or refund the customer via the bank.  Afterward, I would research how I could move the schedule into its own microservice.  That would allow for the Customer to know about the Payment and Schedule perhaps by Id only and the three would interact via RESTful calls to one another.
Thank you so much for reading through this and the previous blog post about using Azure Functions Apps as microservice APIs.  Please follow the link to the GitHub repo where you can grab the entire solution.  <https://github.com/larryjameshenry/azure-function-app-microservice-example>