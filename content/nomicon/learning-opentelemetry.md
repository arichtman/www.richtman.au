+++
title = "Learning OpenTelemetry"
description = "Summary of the book"
draft = true
[taxonomies]
categories = [ "Personal", "Meta" ]
tags = [ "reference", "book", "professional-development", "summary" ]
+++

# Learning OpenTelemetry

## State of Modern Observability

_Distributed System_: a system whose components are located on different networked computers that communicate and coordinate their actions by passing messages to one another.
Includes monolithic SOA, client-server, mobile and more.
Comprised of resources and transactions.

_Resources_: physical and logical components that make up a system.
Logical includes clients, applciations, API endpoints, databases, load balancers etc.

_Transactions_: requests that orchestrate and utilize the system's resources to achieve some task.

_Telemetry_: umbrella term for data that describes what the system is doing.
Comprised of user and performance telemetry.

_User Telemetry_: data about how a user is interacting with the system.
Button clicks, session duration, user agent etc.

_Performance Telemetry_: statistical information about the behavious and performance of system components.

All types of telemetry are comprised of _signals_.
_Signals_ come in 3 pillars; _logs_, _metrics_, and _traces_.
You cannot derive system information from user telemetry, nor vice versa.
Similarly, you cannot understand system behaviour from only one or two of the signal types.
To fully understand one side of a system you must correlate at minimum the three signals on that side.

Each _signal_ is comprised of two components; _instrumentation_ and _transmission_.
_Instrumentation_ is responsible for emitting the data.
_Transmission_ is responsible for sending the data.

_Telemetry_ is concerned with the data itself.
_Analysis_ is about what you do _with_ the data.
_Telemetry_ data that has undergone _Analysis_ creates _Observability_.

_Observability_ is an organizational practice.
<!--disagree here, property of a system-->

Origins of _telmetry_ are phone line transmission of signals of power plants and power grids to manage them.
_Logging_ one of the first and longest-running forms of telemetry.

Signal _vertical integration_ is about a full stack of instrumentation, data format, transmission, storage, and analysis.
But just one signal isn't enough, so don't use the three pillars as an architectural approach.
Instead, create a _braid of data_ by sending the three key signals.

## Why OpenTelemetry?

Systems now are so complext and fast-changing that it exceeds human capacity to reason about or metally map accurately.
Hence, observability.

Two approaches to finding correlations; human investigation and computer investigation.

Three challenges are common to organizations:
Quantity of data, quality of data, how the data fits together.
Managed platforms can help with this but suffer high costs, vendor lock-in, and particular feature sets with strengths and weaknesses.

_Context_: metadata that helps describe the relationship between system operations and telemetry.
Term is overloaded but comes in two flavors; hard and soft.

_Hard Context_: unique, per-request identifier that distributed applications can propagate and collate on.
Also referred to as the _logical context_ of the system as it maps to a single end-user interaction with the system.
The overall shape of a system by it's relationships between services and signals.

_Soft context_: metadata that each instrument attaches to measurements from services and infrastructure.
E.g. hostname, node name, timestamp.
Allows creation of unique dimensions across telemetry signals that help explain what it represents.

**Hard contexts DIRECTLY and EXPLICITLY links measurements with causal relationship.
Soft contexts MAY do so but are not GUARANTEED to.**

Soft context is acceptable for low scale and concurrency, but loses value quickly after that.
Most popular soft context is time, though even this loses efficacy as complexity rises.

Hard context simplifies the exploratory process.
This is because it allows the association of telemetry measurements with each other,
but also linking different types of instruments.
E.g. confidently corrrelating logs with spans.
Hard contexts also support visualizations better, including _Service Maps_.

Converting one signal type into another is costly, lossy, brittle, and inefficient.
_Layering_ telemetry signals atop on another is better.

_Monitoring_ is passive, _Obesrvability_ is active.
Reactive dashboards are not enough, we need continuous analysis.
This all costs so so there's an element of cost-optimization as well as cost-benefit.

_Portable telemetry_: can use with any observability frontend.

_Semantic telemetry_: self-describing.

The rest of this was just more sales talk for OpenTelmetry :yawn:.

## OpenTelemetry Overview
