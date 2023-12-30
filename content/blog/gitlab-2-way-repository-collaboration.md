+++
title = "GitLab 2-way Repository Collaboration"
date = 2023-05-11T15:55:34+10:00
description = "Code mirroring for fun and profit"
[taxonomies]
#categories = [ "Technical" ]
tags = [ "gitlab", "git" ]
+++

## Problem

We need to collaborate on a single code base.
At least one team works on a different Git server.

## Solution

Our GitLab server will serve as the primary code location.
An arbitrary number of other Git servers will operate as secondary locations.
For the purposes of this article we will configure one secondary server.

We will leverage _Push_ mirroring from the primary to ensure swift distribution of changes.
To reduce code sprawl and keep collaboration tight, we only return changes on specific branches to the primary.

### Prerequisites/assumptions

- The primary GitLab has either SSH or HTTPS outbound access to the secondary.
- We possess a service account that has both read and write permissions to the secondary repository.

### Procedure

1. Clone a copy of the repository you wish to distribute.
1. Push this copy up to the secondary.
1. Using GitLab's Web GUI, navigate to the repository you wish to distribute.
1. Select _Settings_ > _Repository_ > _Mirroring Repositories_.
1. Fill out the URL of the secondary, as well as any authentication requirements.
   Set the _Mirror direction_ to `Push`, do not keep divergent refs.
   Save these settings.
   Confirm the sync is functional by pressing the manual sync button.
1. Add another mirror repository, this time in a `Pull` configuration.
   Complete the URL and authentication options as for the `Push` configuration.
   Enable `Mirror only protected branches`.
   _Trigger pipeline updates_ is optional but recommended.
   Leave _Overwrite diverged branches_ as disabled.
   Save and confirm as prior.

### Notes

- As the rate of commits or secondary count raises, so does the chance for conflicts.

## References

- [Vendor documentation](https://docs.gitlab.com/ee/user/project/repository/mirror/)
- Personal suffering
