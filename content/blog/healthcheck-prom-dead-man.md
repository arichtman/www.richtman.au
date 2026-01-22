+++
title = "Healthchecks.io Prometheus Dead Man's Switch"
description = "Handy!"
date = 2026-01-22T17:42:43+10:00
[taxonomies]
categories = [ "Technical" ]
tags = [ "prometheus", "monitoring", "o11y", "observability", ]
+++

# Healthchecks.io Prometheus Dead Man's Switch

Sharing cause it was a super quick and easy set up to finally put that sense of "it's _too_ quiet" to bed.
Not sponsored or affiliated, they have a generous free tier.

1. Hop to [Healthchecks.io](https://healthchecks.io/) and sign up.
1. On login, you'll find a "My First Check" - you can either edit this or create a different one.
   Either way, note the URL for your check.
1. Configure AlertManager as such:
   ```yaml
    receivers:
     - name: healthchecks-io
       webhook_configs:
       - send_resolved: false
         url_file: /var/lib/alertmanager/healthchecks-io-webhook-url
         <Alternatively, just straight `url` works, but my config is in Git publicly>
         url: https://hc-ping.com/934c4c09-70d3-4268-a823-943d14f03686
   route:
     ...
     routes:
     - receiver: healthchecks-io
       matchers:
       - alertname="PrometheusAlertmanagerE2eDeadManSwitch"
       continue: false
   ```
1. Review your Check's event log to confirm Alertmanager hit it.

## Notes:

- You'll probably want something other than email, you can add other integrations at account-level and then enable or disable per-check.
- Depending on criticality of this service, you may wish to tune AlertManager's `repeat_interval` and the Check's Period and Grace Time.
- You can alternatively have an account-wide ping key and then your URL paths become prettier and more well-known.
- You could possibly also get fancy by routing the "resolutions" to the Check's explicit `/fail` path,
  but given we're accounting for networking or AlertManager itself being broken I wouldn't rely on it.

## References:

- [AlertManager webhook config](https://prometheus.io/docs/alerting/latest/configuration/#webhook_config)
