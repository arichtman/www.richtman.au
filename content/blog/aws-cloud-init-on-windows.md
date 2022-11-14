+++
title = "AWS cloud-init on Windows"
date = 2022-11-14T06:56:37Z
description = "Avoiding race conditions on instance initialization"
[taxonomies]
categories = [ "Technical", "Troubleshooting" ]
tags = [ "aws", "ec2", "windows", "user-data", "cloud-init" ]
+++

## Problem

With Linux EC2 instances we can ensure `user-data` has completed by calling `cloud-init status --wait`.
How do we do this for Windows instances?

[Just take me to the fix!](#solution)

## Analysis

First I'll spin up an instance, and try to locate any cloudy binaries

```ps1
> Get-Command '*cloud*'
CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Alias           Get-CFCloudFrontOriginAccessIdentities             4.1.180    AWSPowerShell
Cmdlet          Add-KINA2ApplicationCloudWatchLoggingOption        4.1.180    AWSPowerShell
Cmdlet          Add-KINAApplicationCloudWatchLoggingOption         4.1.180    AWSPowerShell
Cmdlet          Get-CFCloudFrontOriginAccessIdentity               4.1.180    AWSPowerShell
Cmdlet          Get-CFCloudFrontOriginAccessIdentityConfig         4.1.180    AWSPowerShell
Cmdlet          Get-CFCloudFrontOriginAccessIdentityList           4.1.180    AWSPowerShell
Cmdlet          Get-LSCloudFormationStackRecord                    4.1.180    AWSPowerShell
Cmdlet          Get-SARCloudFormationTemplate                      4.1.180    AWSPowerShell
Cmdlet          New-CFCloudFrontOriginAccessIdentity               4.1.180    AWSPowerShell
Cmdlet          New-LSCloudFormationStack                          4.1.180    AWSPowerShell
Cmdlet          New-ORGGovCloudAccount                             4.1.180    AWSPowerShell
Cmdlet          New-SARCloudFormationChangeSet                     4.1.180    AWSPowerShell
Cmdlet          New-SARCloudFormationTemplate                      4.1.180    AWSPowerShell
Cmdlet          Remove-CFCloudFrontOriginAccessIdentity            4.1.180    AWSPowerShell
Cmdlet          Remove-KINA2ApplicationCloudWatchLoggingOption     4.1.180    AWSPowerShell
Cmdlet          Remove-KINAApplicationCloudWatchLoggingOption      4.1.180    AWSPowerShell
Cmdlet          Update-CFCloudFrontOriginAccessIdentity            4.1.180    AWSPowerShell
Application     CloudExperienceHostBroker.exe                      10.0.14... C:\Windows\system32\CloudExperienceHostBrok...
Application     CloudNotifications.exe                             10.0.14... C:\Windows\system32\CloudNotifications.exe
Application     CloudStorageWizard.exe                             10.0.14... C:\Windows\system32\CloudStorageWizard.exe
```

None of these look great, let's try though.

```ps1
> CloudExperienceHostBroker

> CloudExperienceHostBroker /?

> CloudExperienceHostBroker --help

> CloudExperienceHostBroker -?

> CloudNotifications

> CloudNotifications /?

> CloudNotifications --help

> CloudNotifications -?
```

Ok this is fruitless.
I'll have a poke around and see what I can find that might be initializing this instance.

```ps1
> get-service -name '*cloud*'

> get-service -name '*aws*'
Status   Name               DisplayName
------   ----               -----------
Stopped  AWSLiteAgent       AWS Lite Guest Agent
> Get-ScheduledTask -TaskName '*aws*'

> Get-ScheduledTask -TaskName '*cloud*'

> Get-ScheduledTask -TaskName '*amazon*'
TaskPath                                       TaskName                          State
--------                                       --------                          -----
\                                              Amazon Ec2 Launch - Instance I... Disabled

> $(Get-ScheduledTask -TaskName '*amazon*').Actions

Id               :
Arguments        : /C C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -NonInteractive -NoLogo
                   -ExecutionPolicy Unrestricted -File
                   "C:\ProgramData\Amazon\EC2-Windows\Launch\Scripts\InitializeInstance.ps1"
Execute          : C:\Windows\System32\cmd.exe
WorkingDirectory :
PSComputerName   :

> Get-Content "C:\ProgramData\Amazon\EC2-Windows\Launch\Scripts\InitializeInstance.ps1"
~ snip ~
```

Aha, we've located the thread, now to pull and make yarn...
The more you look at this setup the more you realise, someone's put a lot of time into this.
It's reasonably well laid out and documented, everything's quite consistent...
It's a shame it's still kinda nasty.
Anywho, the key points...
We can see that the order of precedence sets Windows as being ready **before** launching the user-data.
That's kindof our core problem, though we can see from the notes that this is to allow the user-data to be a long-lived process.

> User data scripts are optional. They can be long-running, and are not part of the windows-is-ready condition logic.

Not sure what the use case is there but there we have it.
Trundle down to the bottom and we locate a late-script call to `Invoke-Userdata`
We've had some issues recently with race conditions so I better check how this is actually done.
I poked around and located it under `C:\ProgramData\Amazon\EC2-Windows\Launch\Module\Scripts`.
The crucial thing is that the `Start-Process` call it uses has the `-Wait` flag set, which it does.
Great! So this is a synchronous call and we should be A-OK to look for some condition set after it.
Looks like the immediate next line of code is what finally starts the SSM agent service.
It's a bit surprising to see it so late in the process but I guess it doesn't jive well with all the moving sytem config.
Can't imagine what it would think of NixOS!

## Solution

Since SSM agent is only started _after_ we invoke and wait for user-data, we can use it as a proxy for user-data having concluded.

```ps1
While ( $(Get-Service AmazonSSMAgent).Status -ne 'Running' ){ Start-Sleep -Seconds 1 }
```

## References

- [AWS docs on user-data](https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/ec2-windows-user-data.html)
