---
layout: post
title: "A Serverless ToDo List"
categories: Serverless
excerpt: "A simple application that illustrates how to use Azure Storage, Azure Functions, CosmostDB and Azure Active Directly "
---
*The code referenced in this article can be found here: [https://github.com/ssemyan/TodoServerless](https://github.com/ssemyan/TodoServerless)*

With the move to the cloud, DevOps has become an important part of software development. With DevOps the same people who write the software are in charge of deploying it. However, many development teams are realizing that building and maintaining pools of VMs and their associated networking, storage, backups, etc. is a lot of work. Therefore, there is much interest in creating applications that no longer rely on VMs, but instead use a cloud-based framework. This is also known as Serverless Computing.

From [Wikipedia](https://en.wikipedia.org/wiki/Serverless_computing): 

> Serverless computing is a cloud-computing execution model in which the cloud provider acts as the server, dynamically managing the allocation of machine resources. Pricing is based on the actual amount of resources consumed by an application, rather than on pre-purchased units of capacity.

With serverless, you rely on the cloud provider to ensure the platform is highly available and performant under load. Because the cost model is based on actual usage, you don’t worry about over or under provisioning, instead you let the platform expand and contract resources as needed. [^1]

There are many ways to do [serverless in Azure](https://azure.microsoft.com/en-us/overview/serverless-computing/). One common pattern is to use [Azure Functions](https://azure.microsoft.com/en-us/services/functions/) for compute and [CosmosDB](https://azure.microsoft.com/en-us/services/cosmos-db/) for data storage. Combined with [Azure Storage](https://azure.microsoft.com/en-us/services/storage/) for static web hosting and [Azure Active Directory](https://azure.microsoft.com/en-us/services/active-directory/) for authentication, you can easily build an application with high availability and that will scale as needed. 

To illustrate this pattern, I developed an example that takes advantage of some of the Azure serverless products. The application is a simple ToDo list – a user logs in, sees a list of their ToDo items, and can create new items or mark existing items as complete (by deleting them). A user can only see (and work with) their items. A screenshot is below: 

![Serverless Todo UI](/assets/images/serverless-todo-list-1.png)

The architecture is a single page web application (SPA) for the front end with the HTML and JavaScript hosted in Azure Blob Storage. Data is stored in CosmosDB (using the SQL API). The backend is composed of C# compiled Azure Functions using the 1.x SDK. Azure Active Directory is used to provide authentication. The simple diagram below illustrates this. 

![Serverless Todo Architecture Diagram](/assets/images/serverless-todo-list-2.png)

The proxy feature of Azure Functions allows you to host your web content in blob storage but make it appear as if the content is all being served from the same URL. This also allows you to enable authentication on the entire site. You can read more about the proxy functionality [here](https://docs.microsoft.com/en-us/azure/azure-functions/functions-proxies).

It is important to be able to work locally to develop and debug the application without the need to connect to cloud resources. In Azure this is made possible by using the [CosmosDB Emulator](https://docs.microsoft.com/en-us/azure/cosmos-db/local-emulator) and the [Azure Functions CLI](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local) (command line interface). When developing locally, authentication is disabled. Thus, you can work completely disconnected from the internet. 

This sample does not include scripts to create the necessary resources in Azure or to deploy the application. The [Github project](https://github.com/ssemyan/TodoServerless) includes instructions on how to set up for local development and how to deploy to Azure. To deploy the project from Visual Studio, simply right click on the api project and choose deploy, then either create a new functions project or choose an existing one. 

Hopefully this simple project illustrates how you can easily create an application that has high scalability and high availability right out of the box without the need to manage VMs or other compute or data resources. 

[^1]: Note: not all serverless applications are appropriate for a pay as you go model. In some cases you want to limit the amount you may potentially spend (e.g. when you don’t know how heavily an API will be used.) In this case you would use a normal App Service Plan sized to your expected load and price point. More info on pricing can be found [here](https://azure.microsoft.com/en-us/pricing/details/functions/). 