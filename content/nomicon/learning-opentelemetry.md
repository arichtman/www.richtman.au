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

Two primary solutions OpenTelemetry adds:
Single solution for built-in, native instrumentation, and broad compatibility of telemetry with wider observability ecosystem.

_Built-in_ or _Native_ instrumentation: creates signals directly from the code.

_White Box_ approach to telemetry: directly adding telemetry code to the service or library.

_Black Box_ appraoch to telmetry: use external agents or libraries to generate telemetry.
Requires no code changes.

Signal importance order (approximate); traces, metrics, logs.
<!-- disagree here, entirely depends on what you're seeking and authors noted before that because you
can't infer one type from another you need all of them -->
Importance is based on goals of; capturing empiric relationships between services, enriching with metadata,
definitively identifying correlations, efficient measurement of events.

### Traces

One way to model work in a distributed system.
Can be thought of as consistently structured logs sharing a primary identifier.
Collections of related logs are collated into _Spans_, which comprise a _Trace_.

Benfits of traces:

- One trace represents one transaction, suits modeling end-user experience.
- Groups of traces, aggregated by dimensions, reveal tricky performance characteristics.
- Can be transformed/downsampled into metrics or the _Golden Signals_.

_Golden Signals: latency, traffic, errors, and saturation.
<!-- I'm surprised it took this long for a mention -->

_Latency_: time it takes to service a request.

_Traffic_: number of requests.

_Errors_: rate of failing requests.

_Saturation_: utilization of resources.

### Metrics

Numeric measurements and recordings of system state.
E.g. count of logged in users, disk free, RAM utilization.

Pros:

- Good "big picture" of system
- Cheap to create and store
- Good entry point for anaysis
- Ubiquitous
- Fast

Challenges include:

- Lacking hard context
- Difficult-to-impossible to correlate to specific transactions
- Can be difficult to modify if in third-party libraries or frameworks
- Can be inconsistent in how or when things are reported

### Logs

OpenTelemetry aims mostly to support existing logging APIs rather than create something new.
Existing solutions are weakly coupled to other signals though.
Its solution to this is enriching logs with trace context, and links to relevant metrics and traces.

Reasons to use logs in OpenTelemetry:

- Perceived as more flexible and easier to use
- Get signals out of untraceable services (legacy, mainframe, etc)
- Correlate infrastructure resources (load balancers, managed databases)
- Observe behaviour not tied to user interaction (cron jobs, batch processes, system noise)
- Transform them into other signals

### Observability context

Three types of context; time, attributes, and the context object itself.

Time, while obvious, is woeful for thinking about telemetry in distributed systems.
Clocks are unreliable, processes pause, systems lose or gain time, and so forth.

_Execution Unit_: thread, coroutine, or other sequential code execution construct.

Contexts carry information across the gap between services, servers, threads, procedure calls etc.
The goal is to provide a clean interfact to existing language context managers.
Context is required and holds one or more _Propagators_.

_Propagators_: how values are actually sent from one process to the next.

On request instantiation OpenTelemetry creates a unique identifier for that request, based on registered propagators.
The identifier is added to context, serialized, and sent to the next service, which then deserializes it and adds it to the local context.
<!-- Very fancy way of saying generate UUIDv4 if none, pass it along -->

Propagators also carry _baggag_ aka _soft context_.
This is to transmit additional values that you may wish to put on other signals.
Baggage is additive and cannot be removed.
As it's maintained for the rest of the transaction, it will be made available to any involved service, including external ones.
Be cautious about what baggage you add.

OpenTelemetry project maintains semantic conventions for context data.
This is in part thanks to merging with Elastic Common Schema project.

### Attributes and Resources

All telemetry emitted contains _attributes_, known elsewhere as _tags_ or _fields_.

_Attribute_: key-value pair that describes dimension that's useful or of interest.
OpenTelemetry flavor allow for values of types; string, boolean, floating point, signed integer, or a homogenous array of the former.
Keys may not be duplicated and there is a maximum of 128 unique attributes, but no limit on value length.

Attribute dangers include; memory exhaustion (PITA to debug cause no telemetry!), _cardinality explosion_ in a time-series database.

_Resource Attributes_: attributes that remain static for the entire transaction.

_Cardinality explosion_: basically when you blow out the number of ways you can slice the data and get a unique time series.
High amounts of cardinality casue the TSDB to struggle.

Methods to manage cardinality:

- Drop cardinality before storage
- Avoid attributes on metrics and enrich spans or logs instead

### Semantic Conventions

Standardise key names and value types/syntax.
Save a *lot* of headache and litigating details.
Just use it.

Two main sources; OpenTelemetry standard, internally developed.

### OpenTelemetry Protocol

OTLP is a wire format for telemetry signals.

Just sales fluff about how wonderful and compatible it is.

### Compatibility and Future-Proofing

Standard hubris that everything will be versioned and stable and v1.x will live forever.
I appreciate the enthusiasm though.

- APIS: 3-year support
- Plug-in interfaces: 1-year support
- Constructors: 1-year support

Everything is schema-aware, which is nice.

## The OpenTelemetry Architecture

OpenTelemetry components; instrumentation in applications, exporters for infrastructure, and pipeline componenets for shipping.

### Application Telemety

Must be in _every_ application to work properly.
<!-- Side note, what do about upstream/external service dependencies? -->
Can be explicit in code or automatic from agent.

### Library Instrumentation

Presently not baked-in to most libraries but can be installed separately.

### OpenTelemetry API

Both application telemetry and library instrumentation use the same API.
The API is safe to call even when OpenTelemetry is not installed.
<!-- not sure how that works but ok -->
Upshot of this is that a library can be instrumented at no cost if OpenTelemetry is not used in the main application.

### OpenTelemetry SDK

The SDK is synonymous with the OpenTelemetry client.
The SDK is a plug-in frmaework composed of; sampling algorithms, lifecycle hooks, and exporters.
Configuration is done using environment variables or a YAML file.

### Infrastructure Telemetry

Infrastructure visibility is crucial.
Slow but measurable progress is being made to integrate OpenTelemetry to the infrastructure layer.
Some OpenTelemetry components exist to work with existing data options and add it to the pipeline.

### Telemetry Pipelines

Large, distributed systems, properly instrumented and under load, can produce sufficient amounts of data to create a problem of its own.
Sufficiently large and nature enough systems are often older and more patchwork.
OpenTelemetry employs two things to address these challenges; OTLP, and the collector.

### Exclusions

Long-term storage, analysis, GUIs, and any front-end components are not and will not be included.
The aim is standardization, such that all storage and analysis tools may interoperate with OpenTelemetry.
Producing an "official" or de facto observability backend would undermine competition and the ecosystem.

### Summary

Excluded as this document is already a summary.

### Demo section

Excluded, ibid.
<!-- holy cannoli that demo is complicated across services -->

### New Observability Model

Observability tools are used out of necessity, more than anything else.
Rarely do they have a large day-to-day impact.
Most have been vertically integrated until now.
This was a fine trade-off but not so for more homogenous, distributed, and complex systems.
Breaking the vertical integration allows greater pipeline and storage control.
This leads to better clustering, reaggregation, compaction, and other efficiencies.

Future observability platforms will offer universal query APIs, as well as a variety of anaylsis tools.

Existing tools like Prometheus and Jaeger don't fully support the high cardinality, highly contextual workflows of OpenTelemetry.
To maximise value tools need to support; high-cardinality data, correlation across hard and soft contexts, and unified telemetry.
There is promising indication of this coming.

## Instrumenting Applications

OpenTelemetry setup has two parts; installing the SDK, and installing instrumentation.
The _SDK_ is the OpenTelemetry client, and the _Instrumentation_ is code written using the OpenTelemetry API to generate telmetry.
