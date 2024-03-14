+++
title = "Python Stack Trace Suppression"
description = "Not every idea is a good one"
[taxonomies]
categories = [ "Technical" ]
tags = [ "nomicon", "python" ]
+++

# Python Stack Trace Suppression

Really it's just monkeypatching but a specific application.
Here's a sample where we disable stack traces for normal verbosity.

```python
@click.option(
    "--verbose",
    "-v",
    default=False,
    is_flag=True,
    help="Enable verbose logging, useful for debugging and CI systems",
)
def gll(**kwargs):
    logger = logging.getLogger(__name__)
    if kwargs.get("verbose"):
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.INFO)

        # Override stack trace prints if we're not verbose
        def on_crash(exctype, value, traceback):
            logger.error("Oops. Something went wrong.")

        sys.excepthook = on_crash
```

Reference: [Nobody has time for Python](https://www.bitecode.dev/p/why-and-how-to-hide-the-python-stack)
Application: [GitLab-Lint](https://github.com/arichtman/gitlab-lint)
