+++
title = "Azure Mailboxes"
description = "How to set up a shared mailbox, alerts, and enabling external mail"
[taxonomies]
#categories = [ "Technical" ]
tags = [ "nomicon", "azure" ]
+++

# Mailboxes

This guide covers creating and enabling Azure mailboxes.
This procedure was developed in support of AWS account creation.
Modify as required for your use case.

## Creation

1. Log in to [Azure portal](https://portal.azure.com)
1. Select _Azure AD_ and then your organization's directory
1. Select _Groups_ and then _New group_
1. Enter details
   - Group type: Microsoft 365
   - Group name: according to your organization's convention
   - Group description: according to your heart
   - Membership type: Assigned
1. Assign at least two owners for redundancy.
   Members may be added later.
   In cases of delegation, it's often better to let the owner manage membership from the start.

## Configuration

1. Log in to [Outlook o365](https://outlook.office365.com)
1. In the navigation pane, head to _Groups_, then click on the group.
1. Optionally, you can favorite this group to pin it, click the star.
1. In the primary inbox pane ribbon, click the elipsis, then _Settings_.
1. Optionally, you may follow this inbox, which spawns a copy of inbound mail in your personal inbox.
1. Click _Edit group_ and enable external mail.
1. Optionally, send an email from an external account to verify.
   If changing an existing AWS account's email you **MUST** verify.
   AWS **does not** require the new email to prove it's valid before switching.
   You **can** lose the account.
