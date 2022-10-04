---
layout: post
title:  "The curious case of missing stack traces"
date:   2022-10-04 10:45:01 +0530
description: This post explains how to build Postgres from Source code and debug it using VS Code.
tags: java
excerpt_separator: <!--more-->
---
In this post, we will see about a weird issue that I came across with missing Java stack traces, how I overcame it, and the learnings from it.
<!--more-->
### The issue
A few days back, a co-worker came to me with a strange issue; While debugging an issue using logs, he came across a few logs where Exceptions were printed but there was no stack trace.

So to be clear, the exception messages were there but the stack traces with the call tree, file name, line number, etc were all missing.

### Debugging
At first, I thought it must be a cause of erroneous logging, Log4j has many overloaded methods to log messages and it is easy to miss the correct method to log exceptions with the stack trace.

But in this case, we checked the code and it was using the [correct method](https://logging.apache.org/log4j/2.x/log4j-api/apidocs/org/apache/logging/log4j/Logger.html#info-org.apache.logging.log4j.Marker-java.lang.Object-java.lang.Throwable-) and passing the exception object as a parameter.

Then I vaguely remembered reading about something similar in a [Java Specialists](https://www.javaspecialists.eu/archive/) Newsletter. After a quick Google search, we found this [article](https://www.javaspecialists.eu/archive/Issue187-Cost-of-Causing-Exceptions.html) that speaks about this behavior.

To quote from the article,
>  After a relatively short while, it began returning the same exception instance, with an empty stack trace. You might have seen empty stack traces in your logs. **This is why they occur. Too many exceptions are happening too closely together and eventually the server HotSpot compiler optimizes the code** to deliver a single instance back to the user.

### The fix
Hotspot VM removes the stack trace for performance optimization when too many exceptions occur in a short period. Now that we know this, we need to find a way to get the original trace.

As per JDK 5 [release notes](https://www.oracle.com/java/technologies/javase/release-notes-introduction.html#vm), We can pass the flag `-XX:-OmitStackTraceInFastThrow` to the JVM to disable this optimization, but we didn't have the choice of changing the flag and restarting the JVM. 

JVM prints the trace for the first few exceptions, the optimization kicks in only when the exceptions are frequent, so we filtered the logs for the particular machine and sorted the exception logs from old to new, and there it was! the complete trace with the call tree and source line info etc.

### Learnings
The issue was fixed, but I became curious about why this optimization was done by Hotspot and how it was done.
Going back to that article from JavaSpecialists Newsletter, we can understand that creating Throwable objects and filling them with stack traces is expensive, especially when these exceptions occur at a high rate.

So Hotspot bypasses this expensive operation and returns a preallocated Exception object for all the calls, but this optimization is only applicable for 'known' exceptions like `NullPointerException`, `ArrayIndexOutOfBoundsException`, etc.

If we need to optimize the object creation for custom Exceptions, we have to override [fillInStackTrace()](https://docs.oracle.com/en/java/javase/19/docs/api/java.base/java/lang/Throwable.html#fillInStackTrace()) method in Throwable class. This method looks at the thread's stack trace and fills it in the exception object. Since this might be expensive, for cases where we don't need stack traces we can override this method and set stack trace to be empty.

Norman Maurer, one of the developers of Netty, has written a blog post analyzing the performance improvement of removing the stack trace - [The hidden cost of instantiating throwables](http://normanmaurer.me/blog/2013/11/09/The-hidden-performance-costs-of-instantiating-Throwables/)

Even though there are performance benefits to skipping the stack trace when instantiating Exceptions, we must keep in mind that Exceptions are for indicating an error or exceptional occurrence and should not be used for control flow. As such Exceptions may not be as useful without stack traces.

### References
1. [Cost of Causing Exceptions - JavaSpecialists](https://www.javaspecialists.eu/archive/Issue187-Cost-of-Causing-Exceptions.html)
1. [The hidden cost of instantiating throwables - Norman Maurer's Blog](http://normanmaurer.me/blog/2013/11/09/The-hidden-performance-costs-of-instantiating-Throwables/)
1. [Fast Exceptions in RIFE - JavaSpecialists](https://www.javaspecialists.eu/archive/Issue129-Fast-Exceptions-in-RIFE.html)