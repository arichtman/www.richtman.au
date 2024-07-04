+++
title = "Elastic/OpenSearch Cheat Sheet"
date = 2024-07-05T09:30:59+10:00
description = "When you're on call, you're on call"
[taxonomies]
categories = [ "Technical" ]
tags = [ "reference" ]
+++

# Open/ElasticSearch Cheat Sheet

## Discovery

Explains where ISM is at for indexes:
`GET /_opendistro/_ism/explain/$PATTERN`

`GET _opendistro/_security/authinfo`

`GET _plugins/_ism/explain/$PATTERN?show_policy`

`GET _cat/aliases/$PATTERN`

`GET _cat/indices?help`

Note: component templates supersede plain index templates

`GET _component_template/$PATTERN`

`GET _index_template/$PATTERN`

`GET _cat/templates/$PATTERN`

`GET _data_stream/$PATTERN/_stats?human=true`

Pull all records:
`GET $PATTERN/_search`

This bit optional:

```JSON
{
  "query": {
    "match_all": {}
  },
  "size": 1,
  "sort": [
    {
      "@timestamp": {
        "order": "desc"
      }
    }
  ]
}
```

## Search

Search query in url:
`GET $PATTERN/_search?q=field:value`
`GET _cat/indices/$PATTERN?s=creation.date:desc`

Search by time:

```
GET $PATTERN/_search
{ "query": { "range": {
  "@timestamp": {
    "gte": "2023-07-14T00:00:00.00+00:00",
    "lte": "2023-07-15T00:00:00.00+00:00"
  }
}} }
```

Index cross-reference:
`GET /$PATTERN1,$PATTERN2/_search?q=field:value`

Whole-of-cluster search:
`GET _all/_search?q=field:value`

## Manipulation

Add document:

```
POST $PATTERN/_doc
{
  "@timestamp": "135248027"
}
```

Move data into new index:

```
POST _reindex
{
  "source": {
    "index": "$PATTERN"
  },
  "dest": {
    "index": "$DESTINATION",
    "op_type":"create"
  }
}
```

Change index settings:

```
PUT $INDEX/_settings
{
  "index": {
    "number_of_replicas": 1
  }
}
```

Empty an index:

```
POST $PATTERN/_delete_by_query
{
  "query": {
    "match_all": {}
  }
}
```

Force compaction:
`POST $PATTERN/_forcemerge?only_expunge_deletes=true`
(Warning - spikes disk and blocks writes, may result in worse search depending on context)

## Cluster Administration

`GET _cluster/state`

`GET _cluster/stats`

Check what's under way:
`GET _cluster/pending_tasks`

See all settings upfront:
`GET _cluster/settings?flat_settings=true&include_defaults`

Amend shard settings:

```
PUT _cluster/settings
{
  "persistent": {
    "cluster.max_shards_per_node": "1000"
  }
}
```

```
PUT _cluster/settings
{
  "persistent": {"cluster.blocks.create_index.auto_release": "true"}
}
```

Disable index creation:

```
PUT _cluster/settings
{
  "persistent": {"cluster.blocks.create_index.enabled": "false"}
}
```

## Troubleshooting

Check shard settings:
`GET _cluster/settings?filter_path=persistent.cluster.max_shards_per_node`

Find phat indexes:
`GET _cat/indices/otel-v1-apm-span-000*?v&s=pri.store.size:desc`

Find unassigned shards:
`GET _cat/shards?v=true&h=index,shard,prirep,state,node,unassigned.reason&s=state`

Find why unassigned:
`GET _cluster/allocation/explain`

Check disk utilization:
`GET _cat/allocation?v`

## Something extra, sir?

Append ?v for verbose

Try ?filter_path= and then dot-accessed JSON keys

Append ?pretty for ... well, their best attempts

Append ?human=true for idk
