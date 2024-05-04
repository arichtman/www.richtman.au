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

Instrumenting applications is the most time consuming and easy to overdo, leading to lopsided results.

### Agents and Automated Setup

Installing the SDK and all the libraries appropriate for the frameworks, database clients, common components etc is a lot.
Unfortunately, language support for automation is extremely varied, with some having basically none.

Installing the SDK and configuring manually involves:

1. Configuring a set of providers
1. Registering them with the OpenTelemetry API

Here is a listing of auto-instrumentation:

- Java: `javaagent`
- .NET: .NET instrumentation agent
- Node.js: `@opentelemetry/auto-instrumentations-node`
- PHP: OpenTelemetry PHP extension (PHP 8.0+)
- Python: Package _opentelemetery-instrumentation_ provides the `opentelemetry-instrument` command
- Ruby: _opentelemetry-instrumentation-all_ package will instrument, but SDK set up and config is manual
- Go: the OpenTelemetry Go Instrumentation package uses eBPF. Future work is planned to do the SDK.

### Registering Providers

The OpenTelemetry API is by default a `no-op`, you must register providers for anything to occur.

_Provider_: an implementation of the OpenTelemetry instrumentation API.
Providers handle all the API calls.
_TracerProvider_ creates traces and spans, _MeterProvider_ metrics and instruments, and `LoggerProvider` creates loggers.
Providers should be registered as early as possible in the application boot cycle, as any API calls prior will be `no-op`.

Why providers?

- Granular install control. Don't have to install anything you don't use/need/want.
- Loose coupling. Seperates API from implementationc and reduces library weight, dependencies.
- Flexibility. Can write and use custom providers.

### Providers

SDK, in this context, means a set of provider implementations.
Each provider is a framework that can be extended and configured through various types of plugins.
<!-- Approaching word salad here... -->

#### TracerProvider

Implements OpenTelemetry tracing API.
Consists of _Samplers_, _SpanProcessors_, and _Exporters_.

_Samplers_ choose whether a span is recorded or dropped.
Different sampling algorithms are available, selecting and configuring one can be confusing.
It's highly contextual to your application, use case, and visualization software.
If in doubt, consult an expert or don't sample at all.
It's better to add sampling later as a response to a specific cost or overhead.

Note: calling a span "sampled" is ambiguous.
Use "sampled in" to mean recorded, and "sampled out" to mean dropped.

_SpanProcessors_: allow you to collect and modify spans.
They intercept the span twice, once on commencement, and once on completion.
The default processor is the _BatchProcessor_.
This processor buffers span data and manages the exporter plugins.
_BatchProcessor_ should generally be the *last* _SpanProcessor_ in your processing pipeline.
Consult the documentation for specific configuration options.
While you can do quite a bit of processing, its recommended to offload this to the OpenTelemetry collector.

Key configurations: `exporter`, `maxQueueSize`, `scheduledDelayMillis`, `exportTimeoutMillis`, `maxBatchExportSize`

Note: processors are chained together and run in order of registration, linearly.

Note: processing in-application is a decision to make depending on how your application is deployed.
It may not be desirable to ship unprocessed data, such as PII or other sensitive information.

_Exporters_: plugins that define the format and destination of the telemetry.
Default is OTLP, which is recommended.
Primary reason for *not* OTLP is if your storage ingest doesn't support it.

Key configurations: `protocol`, `endpoint`, `headers`, `compression`, `timeout`, certificate files for [m]TLS

#### MeterProvider

Implements OpenTelemetry metrics API.
Consists of _MetricReaders_, _MetricProducers_, and _MetricExporters_.

_MetricReaders_: metric equivalent of _SpanProcessors_.
Collect and buffer metric data until export.
Default is `PeriodicExportingMetricReader`, which collects metric data, and pushes it to an exporter in batches.

Key configurations: `exportIntervalMillis`, `exportTimeoutMillis`

_MetricProducers_: connects existing instrumentation of some kind to the SDK.

_MetricExporters_: send batches of metrics over the network.
As before, OTLP is recommended.
If using Prometheus and no collector, you can set up a Prometheus exporter to be scraped.
If you are using push-based system writing data to the collector, use the standard OTLP exporter, and then expose the
Prometheus exporter from the collector.

_Views_: (not well defined)
You may never need to touch these, certainly not for getting started.
Don't have to create at the SDK level, can use OpenTelemetry collector as well.

_LoggerPRovider_: implements logging API.
Consists of _LogRecordProcessors_ and _LogRecordExporters_.

_LogRecordProcessors_: work like _SpanProcessors_.
Default is batch, which you use to register your exporters.
Recommended to lower `scheduledDelayMillis` config when shipping to a collector.

_LogRecordExporters_: emit the data in variety of formats, OTLP recommended.

#### Shutting Down Providers

Critical to _flush_ telemetry before an application terminates.
If not, data could be lost.
Every SDK provider includes a `Shutdown` method, use it.
Automated instrumentation, well, automates this.

_Flushing_: process of immediately exporting any remaining buffered telemetry in the SDK, while blocking shutdown.

#### Custom Providers

API-SDK separation allows for implementation of custom providers.
Highly unlikely you will need this.

One example: Envoy.
All their components must be single-threaded, which is impractical to make an option for the entire SDK.

### Configuration Best Practices

<!-- mmmhm, yes "best practices" -->

Three configuration options for the SDK:

- In code, using exporter, samplers, and processors
- Environment variables
- Config file (YAML)

Environment variables are most widely supported.
Better than hard-coding configuration because you can defer configuration until deployment time.
Which is crucial as often different environments/deployments have different needs.
<!-- just imagine hard-coding your export endpoints INTO your build artifacts. See? -->
You'll often have to tune parameters to handle the volume of data.

_Backpressure_: sending more data than the system can handle, results in dropped telemetry.

Configuration file format has recently been standardized across all implementations.
Settings may still be overwritten by environment variables.
Support for the new format is mixed but expected to increaase.

#### Remote Configuration

Open Agent Management Protocol (OAMP) is presently under development.
It's a remote configuration protocol which aims to allow collectors and SDKs to receive and transmit their configuration.
With OAMP, a control plane can manage an entire OpenTelemetry deployment without restart or redeploy.
Theoretically, this could mean dynamic adjustment of things like sampling, to manage cost and saturation.
<!-- Sampling is hard, and there's hope for an operator pattern here. -->

### Attaching Resources

_Resources_: set of attributes that define the environment in which telemetry is being collected.
E.g. service, VM, platform, region, cloud provider.
Things you need to correlate problems with a location or service.
If telemetry tells you the *what*, resources tells you the *where*.

#### Resource Detectors

Other than service-specific, most resources come from the environment of the application deployment.
Plug-ins that discover these are called _resource detectors_.

When setting up an environment, enumerate all the resources you want to capture, and seek out resource detectors for them.
Most resources can be discovered by the collector, and attached to telemetry that passes through it.
<!-- this could backfire with shared collectors -->
Accessing some resources to collect information requires API calls, so is not recommended in the application, use a collector instead.

#### Service Resources

Can't be gathered from environment so be sure to define them.
*Critical* to some analysis tools working at all.

- `service.name`: name of this class of service
- `service.namespace`: unique namespace of the service
- `service.instance.id`: unique id for this instance of the service
- `service.version`: service application version

#### Advanced Resource Annotations

Consider the eventual destination of your telemetry when selecting which collector to detect and add which resources.
It may make sense to keep local telemetry high fidelity, but longer-term telemetry less granular.

### Installing Instrumentation

Can't just use SDK, need instrumentation too.
Ideally automation handles this.
Check the `contrib` repository for each language to find automatic instrumentation for various libraries and frameworks.
Missing critical instrumentation is a fast and easy way to break traces.

An increasing number of OSS libraries are starting to include OenTelemetry instrumentation.
This obviates the need for manual or automatic addition.

#### Instrumenting Application Code

Aim to instrument in-house libraries with the same techniques as third-party ones.
Rewriting instrumentation for every application is undesirable.
<!-- read: your app devs will kill you -->

#### Decorating Spans

<!-- awww, got me all clucky, live, laugh, love -->

If you wish to add application-specific details to help track down and index spans, don't create new ones.
Your libraries already generate the correct spans, just get the current span and decorate it with attributes.
More attributes, less spans, better observability experience.

### How Much Is Too Much?

There's no clear-cut answer, but the rough pattern is:
unless it is a critical operation, don't worry until you need it.
Start breadth-first, not depth-first.

End-to-end tracing matters more than fine-grained detail.
Better to stand everything up with the default instrumentation and progressively add in specific areas where you need more detail.
Also, focus on smaller, self-contained areas, then broaden as needed.

For both of the above cases, a good proportion of the value is in instrumenting the business logic,
or other stuff that automatic instrumentation won't capture.
<!-- gee thanks guys -->

Don't obsess about "the correct amount".
Work iteratively.
Make sure you're asking and answering interesting and important questions with your results.

### Layering Spans and Metrics

Metrics can be useful for analyzing long-term trends.
Histogram metrics are helpful for this.
Combining exponential histograms across services with _exemplars_ yields highly accurate performance statistics
as well as contextual links to traces that demonstrate performance for a given bucket.

_Histograms_: specific type of metric stream that _buckets_ values and displays the count of bucketed values.
Buckets can be standard, pre-defined, or _exponential_.

_Exponential buckets_: automatically adjust for scale and range of inputs.
This means you can add across histograms, even if their scales and ranges differ.

### Browser and Mobile Clients

Determining impacts to user experience in resource-constrained environments demands telmetry.

_Real User Monitoring_: specific term for client telemetry, currently under active development for browsers, iOS, and Android.

_Signals_: specialized types of telemetry data used in techniques like _RUM_ and _continuous profiling_.
Currently not stable in OpenTelemetry but under way.

### The Complete Setup Checklist

- Instrumentation available for every important library?
- SDK has providers for tracing, metrics, and logs?
- Exporter correctly installed?
- Correct propagators installed?
- SDK sending data to the collector?
- Correct resources emitted?
- All traces complete.
- No broken traces.

### Packaging it All Up

Instrumenting an application requires interacting with every part of OpenTelemetry and is not easy.
After you've completed your first application, write internal docs, and make a package for others.
One good way is to instrument directly in common libraries and frameworks.

### Conclusion

Due to the amount of work, instrumenting a large system is it's own form of vendor lock-in.
With OpenTelemetry, it's do-once *only*, since you can use any system atop it.

## Intrumenting Libraries

_Shared Libraries_: ones widely adopted across many applications.
Notable proprietary ones; Cocoa and SwifUI frameworks from Apple.

_Native Instrumentation_: instrumentation actually in-library and maintained there.
As opposed to instrumentation being maintained by a third party.
<!-- I'm not really sure how that would even be possible with some languages but eh -->

### The Importance of Libraries

> Most production problems don't originate from simple bugs in application logic:
they come from large numbers of concurrent user requests to access shared resources interacting in ways
that cause unexpected behaviours and cascading failures that do not appear in development.

Most resource utilization occurs in library code, application code merely _directs_ the utilization.
Of course, there's good and bad directions.
Bad directions tend to compound ill effects under load.
This leads to cascading failures.

(The proceed to explain resource contention and deadlocking)

<!-- pyml disable-next-line no-trailing-punctuation -->
#### Why Provide Native Instrumentation?

##### Observability works by default in native instrumentation

Observability systems are notoriously difficult to set up.
A good part of that is having to install and instrument plug-ins for every library.
Doing the hard work ahead lowers barriers to adoption.
<!-- I mean yea, and the abstraction of a library is about putting the complexity and hard work on one side,
and utility on the other, so this tracks fundamentatlly -->

##### What's Wrong with Plug-ins?

Delegating features out makes you dependent on another party.
You won't be able to ship new versions until the plug-in has been updated.
Plug-ins push instrumentation to security boundaries where you're comfortable executing someone else's code.
Plugins require hooks, which is another API to support and maintain.
Architectural changes often impact which hooks are available, which breaks compatibility.
The more hooks, the worse this all is.
Plugins and hooks are another layer of indirection, which can cost in performance and mental load.

##### Native Instrumentation Lets You Communicate with Your Users

Owning the telmetry story of your library is both a statement and a creative expression.
Just as you communicate with documentation and playbooks, so too you can with dashboards and alerts.
<!-- oh brother, gimmie a break -->

Owning observability means you have a precise schema you can use to explain how your library works.
Your observability data can highlight incorrect or suboptimal use of the library.
Also possible to write playbooks for various warnings and errors and how to fix them.
Finally, you can base tuning instructions on the common telemetry information.

##### Dashboards and Alerts

Anything that emits metrics should ship with default dashboards.

If you don't work observaility into your library, you may accidentally design it so it's impossible,
similar to how that happens with testing.

##### Native Instrumentation Shows That You Care About Performance

Observability is the _only_ form of testing for production systems.
<!-- fans of Charity Majors, I see -->
Alerts are tests, e.g. "I expect that X will not exceed Y for more than Z minutes".
This is also useful as testing during development.

### Why Aren't Libraries Already Instrumented?

Basically noone does it right now.
They blame _composition_ and _tracing_.

Previously, observability systems didn't compose well.
Addint observability meant committing to a client and data format.
This meant that if two libraries chose differently, anyone running them both would have to run two observability systems.
More likely they ran some kind of additional agent, translation layer, or other integration.

Tracing is particularly poor with heterogeneous library instrumentation, since traces propagate between application boundaries.

#### How OpenTelemetry is Designed to Support Libraries

Instrumentation is a _cross-cutting concern_.

_Cross-cutting concern_: a subsystem that ends up everywhere, has to interact with every part of an application.
As such, interfaces to these need to be handled with extreme care.
Examples include; security, and exception handling.

#### OpenTelemetry Separates the Instrumentation API and the Implementation

This divide creates two areas of concern, with clear owners.
Library maintainers handle instrumentation, and application developers configure the entire application pipeline.
The API has almost no dependencies, to reduce conflicts.
The SDK and all dependencies are referenced only once, by the applicaiton developer, during startup.
Any conflicts can be dealt with here in one place, by swapping out plugins or implementations.

#### Otel Maintains Backward Compatibility

API/implementation separation isn't enough.
The API also must maintain compatibility across all libraries that use it.
Breaking the API frequently would, even with major version changes, create transitive dependency conflicts.
This is why all OpenTelemetry APIs are backwards-compatible.
The assumption is that instrumentation may be written once and never updated again.
`v1.0` of OpenTelemetry is, and will remain, the only major version.

#### Otel Keeps Instrumentation Off by Default

OpenTelemetry API calls are always safe, they never throw an exception.
If the library is instrumented, and the application does not use Otel, it does nothing.
Natively, i.e. without wrappers or indirection, the Otel API has zero overhead.
This means it can be embedded to work out-the-box at no cost.
Removing the need to do *literally any* individual configuration helps developers and adoption.

### Shared Libraries Checklist

- Enabled OpenTelemetry by default.
- API isn't wrapped.
- Using existing semantic conventions?
- Created new semantic conventions?
- Import only the API packages.
- Library pinned to major version.
- Comprehensive documentation.
- Performance tested and results published.

### Shared Services Checklist

_Shared Services: entirely self-contained standalone applications e.g. databases, proxies, messaging systems.

Shared services should follow all the same best practices as shared libraries.

In addition:

- Use Otel config file?
- OTLP output by default.
- Bundle a local collector.

## Observing Infrastructure

Infrastructure encompasses not just hardware, but the abstractions built atop it, including managed services.

_Monitoring_ is not _infrastructure observability_.

_Infrastructure Observability_: two primary concerns; _infrastructure providers_ and _infrastructure platforms_.

_Infrastructure Providers_: actual "source" of infra, e.g. data centre, AWS, GCP, Azure etc.

_Infrastructure Platforms_: higher-level abstractions over the _providers_,
usually some kind of managed service, very varied in size, complexity, and purpose.
Examples include; Kubernetes, Functions as a Service (FaaS), CICD like Jenkins, VCS like CodeCommit.

Platforms and infra are often shared between applications, which makes correlating stuff difficult.
Can you establish context (hard _or_ soft) between specific infra and application signals?
Does understanding these systems through observability actually contribute to business goals?
If no on both counts, don't incorporate infrastructure into your observability.
You will still be monitoring the infrastructure anyway.

### Observing Cloud Providers

Usually offer a large variety and volume of data.
Your job is to retrieve and store only what you need.

Cloud services are broadly two categories.

_Bare Infrastructure_: compute, storage, networking, API gateways, managed databases.
<!-- not sure about managed databases being in this one... -->

_Managed Services_: Kubernetes clusters, machine learning, stream processors, serverless platforms.

#### Collecting Cloud Metrics and Logs

Cloud Telemetry "iceberg":

Above: CPU/API disk util, instance status, network throughput.
Below: I/O stats, PID count, file handler, control group, kernel logs, mount status, IPv4/6 unicast, interrupt costs.

Example of "instance status", for a distributed system, one node up or down doesn't actually matter that much,
and isn't enough to resolve an issue.
Thinking about it for observability though, it's very important for correlate to say, a wrongly-routed request, or a timeout.
No signal can be considered individually or without the overall strategy.

Foundational principals for determining what signals are important to collect and how to use them:

- Semantic conventions to build soft context between metric signals and application telemetry.
  That is, infra and applications should use the same keys and values.
- Leverage existing integrations and formats.
  Lots of plug-ins that will handle conversion to OTLP.
- Be purposeful with data, really consider what you need and how long to collect it.
  Ensure observability costs and overhead isn't proportionally high.

OpenTelemetry collector configuration and usage best practices.

- Production deployments should use the Collector Builder, not kitchen-sink public Docker images.
  You can include only components you need and add custom ones where it makes sense.
- Start off with too many metric attributes at the start.
  It's easier to drop the data than to add what doesn't exist.
  Adding a new dimension can cause cardinality explosion, control this by allow-listing metrics in the pipeline.
- Avoid remapping, find a handful of attributes you'd like shared across preexisting metrics and logs.
  Then add _them_ to your trace and application metric signals, rather than the other way around.
  If starting from scratch, start with the collector and SDK to capture system and process telemetry.

OpenTelemetry is agnosting on push/pull metrics.
OTLP, however, has no notion of pull-based metrics.
If you use OTLP, your metrics will be pushed.

Note: The OpenTelemetry collector is not intended to be public.
Apply security measures as necessary.

#### Metamonitoring

Of course, we have to monitor the collector too!

_Ballast_: chunk of memory pre-allocated to the heap.

_Scrape Collision_: when the next scrape is scheduled to start before the current one has completed.

Rough rules for planning collector capacity:

- Experiment per-host or per-workload to determine the size of the ballast for each type of collector.
  Stress tests can help find the upper bound.
- Avoid scrape collisions for metrics.
- Heavier transformations should be later in the pipeline.
  This is particularly true to avoid overburdening agents and sidecars alongside applications.
- Better to overprovision than lose data.

NB: the balast extension may be deprecated, see current docs for details.

#### Collectors in Containers

<!-- are you thinking what I'm thinking b1? -->

Good rule is factors of 2 for memory limits and ballast.
E.g. balast 40% of container memory, limit 80%.
This shoud improve performance by reducing churn.
This is because it now cleans up memory by returning it to the heap, and allows the collector to signal producers to back off,
without crashes or restarts due to running out of memory.
<!-- not sure I follow the detail here but i get the core idea of letting the collector itself handle memory -->

### Observing Platforms

Cloud native applications are often built for managed platforms, which use different abstractions than bare infrastructure.

#### Kubernetes Platforms

Two broad approaches to integration here;
monitoring and profiling tooling for applications running *on* the cluster,
and telemetry data on the Kubernetes components themselves.
The OpenTelemetry operator handles both of these by managing collector instances, and auto-instrumenting applications.

Applications designed for Kubernetes will often interact directly with the API, making both sets of signals helpful.

#### Kubernetes Telemetry

Recent Kubernetes releases have begun addint tracing for components like the kubelet and API server.
Depending on size/scale/complexity, you may wish to create separate collector deployments for system and application signals.
The operator includes a service discovery mechanism called the _Target Allocator_ that allows collectors
to discover and scrape Prometheus endpoints, evenly distributing the scrape jobs across multiple collectors.

Another option is dedicated receivers.
There are three receivers available to listen for cluster metrics and logs.

- `k8sclusterreceiver`
- `k8seventsreceiver`
- `k8sobjectsreceiver`

There is also `kubeletstatsreceiver`, which can pull pod-level metrics.
None of the above are mutually exclusive with the TA-based approach of the operator, but you shouldn't double-up either.
Eventually, the community is expected to settle on one approach or the other, it's just not clear at the time of writing.

The *OpenTelemetry* community generally agrees that _receivers_ are the best way to monitor a cluster.
However, many things are already set up for Prometheus, including `kube-state-metrics` and `node-exporter` plugins in cluster installs.
<!-- can confirm, kube-prometheus-stack is a huge amount of value, very standard, and easy to deploy -->
Long and short of it - they recommend _receivers_ for greenfield clusters, and Operator/TA is acceptable for brownfields.

#### Kubernetes Applications

The operator does automatic detection using TA, sure, but it has other tricks.
You can use a CRD to configure injecting instrumentation automatically into a pod.
This adds racing, metrics, or logs to axisting applications.
One catch is that you can't mix automatic and proprietary/custom instrumentation, they'll conflict.

Personal notes on this:
- Auto-instrumentation is useful where you don't own the app and don't want to fork it.
- Auto-instrumentation is apparently _very_ noisy out-the-box, though I suppose the solution is to drop fields in the pipeline.

Production collector architecture deployment tips:

- Start with sidecar collectors.
  Flushing telemetry out of the process pod relieves memory pressure on the application.
  It'll also make development and deployment smoother and easier.
  It allows for cleaner shutdowns and evictions as the main process isn't stuck waiting for busy collector services.
- Split collectors by signal type so they can scale independently.
  Create pools per application, per service, based on utilization...
  Log, trace, and metrics processing all have different resource consumption profiles and constraints.
- Cleanly separate concerns of telemetry creation and configuration.
  Redaction and sampling in collectors, not in-process.
  (essentially) Hard-coding configuration in the process makes it impossible to adjust things in production without redeployment.
  Adjusting configuration on the fly is far easier.

#### Serverless Platforms

Serverless is on-demand and ephemeral, as well as a bit black-box.

Additional considerations for serverless observability:

- Invokation time? How long did the function run for?
- Resource usage. How much memory and compute did the function use?
- Cold start time. Does the function take time to start up when not recently used?

Getting these can be tricky, but OpenTelemtry Lambda Layer (and similar) can help.
Though they do incur a performance overhead.

If unable to use Lambda Layer etc:

- Ensure the function waits on the export of telemetry
- Stop recording spans or measurements before returning control to the function invokation library.
- Try to precompute strings or complex attribute values that won't change from run-to-run so they can be cached.
- To avoid queueing telemetry and waiting for export, place a collector "close" to them, dedicated to receiving function telemetry.

#### Queues, Service Busses, and Other Async Workflows

Tracing transactions that cross less traditional request/response architectures can be less useful.
It's unclear whena  given transaction actually ends.
You'll need to make decisions based on your goals and what you can reasonably optimise.
What kind of indicators do you want to track?
Do you want to know how many steps were completed, or the median time for a certain step to run?
Are you interested in how long it took for a service to process a record and for that record to be handled?

Checks to see if you're in this space:

- Draw architecture and process diagrams
- Do you have many services operating on a single record?
- Do the services require human intervention to proceed?
- Does your workflow start and end at the same place?
- Does your workflow diagram look less like a tree and more a "tree of trees"?

If so, you probably have an asynchronous workflow.

_Custom Correlation ID_: a unique attribute you ensure is on each parent span by baggage propagation

_Span Links_: allow causal relationship between spans _without_ an explicit parent-child relationship.
The advantage here is that you can calculate interesting features, like amount of time waiting in queue.

Highly async workflows don't work conceptually as one, single trace.
Rather it's many subtraces, linked to an origin by either a custom correlation ID or a shared trace ID propagated through span links.
Discovering these relationships, correlating, and visualizing them is difficult to generalise for.
So there's not much available in the way of tooling currently.

Finally, not all subtraces in asynchronous transactions have the same utility.
Use collector filters and samples to say, convert spans to metrics, or filter out specific subtraces and replace them with histograms.

### Conclusion

Infra observability works best when you start with clear and concise goals before implementation.
<!-- easier said than done -->
Comparatively, application and service observability are easy.
Generally, instrumentation strategies for applications don't apply to infrastructure.

**Infrastructure observability strategy needs to be driven by your overall observability goals,
and aligned to organizational incentives.**

## Designing Telemetry Pipelines

Telemetry is a sustained, high-throughput operation, coupled to the load of the system.
The collector is better overall at complex operations than any individual language SDK.
The collector is also a more logical place to perform normalizing or standardizing transformations, as it crosses applications and is centrally configured.
Mixing telemetry configuration with application configuration couples unrelated changes and neccessitates coordination between teams.
Telemetry is better treated as it's own service.

The following section progresses upwards in complexity.

### No Collector

Direct SDK connection to backend.
Misses host metrics and it's inadvisable to collect these via application.

### Local Collector

Most common reason for this is to collect host metrics.
Additional advantages:

- Gathering environment resources.
  Usually very useful for observability but opten require API calls.
  Collector offloads this delay from the application.
- Avoiding data loss from crashes.
  Batch export is efficient but suffers during crashes.
  Local collector allows tuning application batch size down and frequency up, then tune the collector batches separately.
- Simplified SDK configuration.
  Default OTLP-over-HTTP to `localhost` "just-works" without additional exporters or plugins.
  This can be as little as one-line code setup, easy to package, distribute, and keep up-to-date.

### Collector Pools

_Collector Pool_: a set of collectors, each running on its own machine, using a load balancer to manage and distribute traffic.

Advantages:

- Load balancer-managed _backpressure_.
  Smooth out spikes in data inbound without pressuring the collectors' memory.
  OTLP itself is stateless, making this distributed memory buffer feasible and managable.

#### Resource Management

Local collectors still consume resources, which are then unavailable to the application itself.

Local collectors have two main purposes; quick application evacuation, and host metric collection.
Any additional processing beyond this can be handed off to a collector pool, which does not compete for resources.

Collector pools are load balanced, which has two advantages:

- Right-sizing resources.
  Without conflation of application utilization, resource specification optimization.
- Pool scaling.
  Throughput over time can be used to scale the pool horizontally.

#### Deployment and Configuration

Local collectors are always entangled with applications.
Collector pools are a full and clean and perfect and excellent separation of concerns.

_Open Agent Management Protocol_: an in-development ~dream~ control plane for collector fleets.
Sampling configuration decisions depend on analysis being performed.
Every form of analysis has an optimal sampling configuration, providing maximum value with minimal data.
Finding this point is difficult for humans, so instead we just let the analysis tool control sampling.

#### Gateways and Specialized Workloads

Mostly it's fine to mix pushed telemetry and pulled metrics (Prometheus) via a single collector.
Specialized collector pools handle scaling size and complexity, though they might look complicated, they are easier to maintain and observe.

Advantages of specialized collector pools:

- Reduced binary size.
  Normally a non-issue, but in limited environments like embedded, IoT, edge, or FaaS, it matters.
  Specialized collectors can be custom-compiled to only include plugins required for that environment.
- Reduced resource consumption.
  Different pipelines can have very different resource consumption profiles.
  When these are conflated cumulatively, unpredictability means you need more headroom to mitigate.
  It's not cut-and-dried though, weigh the network cost of separate pools against slack in machine provisioning.
  Typically the scale of the system needs to be large to make the savings significant.
- Tail-based sampling.
  Tail sampling generally requires all spans for a given trace in order to make a decision.
  Currently this means all spans for the trace need to land on the same collector.
  To achieve this, a gateway collector with the load balancing exporter is required.
  Then the separate processing pool can perform sampling.
  Notes on tail sampling:
  Resource requirements can be very high, depending on span throughput, attribute count, and sampling window.
  Processor defaults assume maximum 50,000 spans per 30-second window.
  This sounds high but verbose or complex systems can vastly surpass it.

#### Backend-specific Workloads

Different telemetry requires different processing, e.g. Pormetheus for metrics and Jaeger for traces, they both go to different collector pools.
Prom-specific collector plugins for metrics can live in a pool of collectors that operate after metrics and traces have been separated, and right before the metrics are sent to Prometheus.
<!-- I think they're talking about Prom the GUI/TSDB, though I'm not sure why one would Otel export then dump it in a limited system -->
This prevents crossing streams of resource contention.

#### Reducing Egress Costs

<!-- what a world we've come to, where it takes cloud provider charges for network bandwidth to be a consideration -->
Most analysis tools run in a separate network to the applications under monitoring.
This can result in high egress costs.
Data compression is recommended beyong OTLP-standard `gzip`.
Otel Arrow protocol solves this, though it's only in beta they expect high levels of vendor and OSS support.

Ed. 🤦‍♂️
<!-- Apache? Existing protocols? Parqet? AVRO? unbridled optimism about support. -->

Arrow limitations

- Throughput.
  Requires sustained transmission of large amounts of data.
- Stateful.
  Doesn't play nicely with load balancers, collector pools, unstable connections, or small amounts of data.

## Pipeline Operations
