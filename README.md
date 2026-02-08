# Albuminum - an app for scrapbooking and managing photos

# 🤖 Prototype

The prototype section is where I try out new features and experimental stuff; usually with some heavy help from AI. In addition to trying out new ideas, I also use this as a playground for learning some new technologies and techniques. 😁

Currently, it's a distributed system that explores a side-by-side comparison of **.Net** and **Node.js** backends and a **React** frontend, all routed through a **YARP (Yet Another Reverse Proxy)** Gateway.

## File Structure

* **/apphost.cs** - The Aspire orchestrator script
* **/Gateway/** - YARP configuration and Reverse Proxy logic
* **/client/** - The React frontend application
* **/server-dotnet/** - The .Net version of the backend
* **/server/** - The Node.js version of the backend

## Getting Started

### **Prerequisites**

* [.NET SDK (v10.0)](https://dotnet.microsoft.com/download)
* [Node.js (v22)](https://nodejs.org/)
* [.NET Aspire Workload](https://learn.microsoft.com/en-us/dotnet/aspire/fundamentals/setup-tooling)
* [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Required for Aspire container orchestration)

### **Running the Project**

The root directory contains the Aspire orchestrator, which is configured to install dependencies (e.g., run `npm install`, etc.) automatically on startup. If you prefer to do it manually, though, or run into any issues you can manually install them:
```bash
cd server && npm i
cd 
cd client && npm i
```

1. Install Aspire:
   ```bash
    dotnet workload install aspire
   ```
1. Navigate to the root directory, where the Aspire orchestrator lives: 
   ```Bash
    cd albuminum/prototype
   ```

1. Run the Aspire orchestrator:
   ```Bash
    dotnet run
   ```

1. By default, the orchestrator is configured to automatically start browser windows for both the app (http://localhost:5001) and for the Aspire dashboard (dynamically chosen port)

### Things I'm Trying Out

#### Road Movie to .Net

It'd been a while since I worked with .Net (I left around .Net 5, and the start of the Core/Framework evolution), so I wanted to revisit it and see what's all changed. The answer is: a whooooole lot. 😂💚

I started this prototype out as a React frontend on top of a Node.js backend, and used npm scripts to start them up together. When I found out about .Net Aspire I immediately wanted to try it out; so I used it to orchestrate my FE and BE, even tho there wasn't any .Net code. Honestly, as soon as I had the Aspire dashboard in front of me with my FE and BE running, I was sold.

In addition to Aspire, I've set up a [YARP server](https://github.com/dotnet/yarp) to act as a gateway on top of my FE and multiple BEs.

To help get re-acquainted with .Net, I've introduced an alternative backend written in C#. The backend has feature parity with the Node backend, and requests can be dynamically routed to a specific backend by specifying `dotnet` or `node` at the beginning of the URL path.

| Entry Path | Target Service | API Prefix (Internal) |
| :---- | :---- | :---- |
| `localhost:5001/dotnet/*` | React Frontend | .Net Backend (`/api/dotnet/*`) |
| `localhost:5001/node/*` | React Frontend | Node.js Backend (`/api/node/*`) |
| `localhost:5001/` | Redirects to `localhost:5001/dotnet/` | Default Backend (.Net) |


