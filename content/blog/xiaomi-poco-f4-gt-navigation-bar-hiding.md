+++
title = "Xiaomi Poco F4 GT Navigation Bar Hiding"
date = 2023-01-24T21:55:18+10:00
description = "In which David wrestles with Goliath for control"
draft = false
[taxonomies]
categories = [ "Technical" ]
tags = [ "mobile", "xaiomi", "android", "troubleshooting" ]
+++

## Problem

The latest MIUI update forces the navigation bar up unless you use their launcher.
We've got Nova Pro and are quite dedicated to maintaining control of our devices.

[Just take me to the fix!](#solution)

## Analysis

The first information I locate makes it look easy, `adb shell` something about _overscan_ and call it a day.
This does not go according to plan as the overscan feature was deprecated suddenly some time ago.
Google further locked down their Android bug tracker so they couldn't get complaints. Hrm.
Digging a little deeper it seems it's moved to settings, let's try the more recent advice.

```shell
255|ingres:/ $ settings put global policy_control immersive.status=apps

Exception occurred while executing 'put':
java.lang.SecurityException: Permission denial: writing to settings requires:android.permission.WRITE_SECURE_SETTINGS
        at com.android.providers.settings.SettingsProvider.enforceWritePermission(SettingsProvider.java:2326)
        at com.android.providers.settings.SettingsProvider.mutateGlobalSetting(SettingsProvider.java:1475)
        at com.android.providers.settings.SettingsProvider.insertGlobalSetting(SettingsProvider.java:1429)
        at com.android.providers.settings.SettingsProvider.call(SettingsProvider.java:457)
        at android.content.ContentProvider.call(ContentProvider.java:2533)
        at android.content.ContentProvider$Transport.call(ContentProvider.java:530)
        at com.android.providers.settings.SettingsService$MyShellCommand.putForUser(SettingsService.java:382)
        at com.android.providers.settings.SettingsService$MyShellCommand.onCommand(SettingsService.java:278)
        at com.android.modules.utils.BasicShellCommandHandler.exec(BasicShellCommandHandler.java:97)
        at android.os.ShellCommand.exec(ShellCommand.java:38)
        at com.android.providers.settings.SettingsService.onShellCommand(SettingsService.java:50)
        at android.os.Binder.shellCommand(Binder.java:1054)
        at android.os.Binder.onTransact(Binder.java:882)
        at android.os.Binder.execTransactInternal(Binder.java:1290)
        at android.os.Binder.execTransact(Binder.java:1249)
```

Ok so we're missing permissions to set settings.
Looks like `pm` is the permissions managment convenience wrapper for `cmd`.
`pm help` shows how to grant in the help text.
But I have to grant permission to a package or component?
Also online says I have to disable permission monitoring in developer tools but I can't see that option.
Looks like it really has to be done on device.
It was saying I had to sign in and flashing an icon for security app.
However I checked the security app thoroughly and there was no sign in option.
Trying to toggle install via USB opened a xiaomi login dialogue, so I used that.
They say you can use throwaway accounts.
That prompted me three times, each with timer before I could enable it.
Let's try it.

```shell
$ adb shell pm grant com.fb.fluid android.permission.WRITE_SECURE_SETTINGS
$ # Success!
$ settings put global policy_control immersive.status=apps
$ # Success!
```

It succeeded! buuut the nav bar is still there...
Let's try locking and unlocking...
Aha! So it _is_ removed when firing up the screen but something is putting it back...
Let's find a package listing and see what we can temporarily disable.

```shell
$ pm list packages
< 434 packages >
$ # After inspecting these a bit I'm willing to gamble that overlay \
$ #  means something specific in Android dev land
$ pm list packages | grep -v overlay
< 358 packages >
$ # OoOkay then, how about we look for com.mi* 
$ pm list packages | grep -v overlay | grep '\.mi'
< 52 packages >
$ # Muuuch better. I'll use the magic of editing to shortlist some suspects here
package:android.miui.poco.launcher.res
package:com.mi.globallayout
package:com.miui.analytics
package:com.miui.miwallpaper
package:com.mi.android.globallauncher
package:com.xiaomi.micloud.sdk
package:com.xiaomi.mipicks
package:com.xiaomi.misettings
$ # Ok let's find 
```

I'm thinking maybe we could limit the permissions of the settings app so it can't reset the immersive.status setting.
Ok but how to granularly block that setting?
Surface-level it looks like `pm revoke` is too broad a tool...

```shell
$ pm revoke android.miui.poco.launcher.res android.permission.WRITE_SECURE_SETTINGS

Exception occurred while executing 'revoke':
java.lang.SecurityException: Package android.miui.poco.launcher.res has not requested permission android.permission.WRITE_SECURE_SETTINGS
< Stack trace >
$ pm list packages | grep -i setting
package:com.android.settings.intelligence
package:com.android.overlay.gmssettings
package:com.android.settings.overlay.common
package:com.miui.settings.rro.device.hide.statusbar.overlay
package:com.android.settings.overlay.miui
package:com.miui.settings.rro.device.type.overlay
package:com.android.settings
package:com.miui.settings.rro.device.config.overlay
package:com.android.providers.settings
package:com.android.overlay.gmssettingprovider
package:com.android.providers.settings.overlay
package:com.xiaomi.misettings
```

Let's try a rando's comment.
This should be totally safe and not a problem at all.

```shell
settings put global force_fsg_nav_bar 1
```

No error but not working either :/
Seems MIUI has moved on past this one.
Let's dig into what `force_fsg_nav_bar` actually does.
Aha! Something about FNG settings and lock screen!

## Solution

Disclaimer, one step of this must be repeated on reboot.
It is possible to automate this or do it wirelessly but that's out of scope for now.

Three-step solution

1. Enable full debugging on your phone.
   Follow any set of instructions you like to enable developer tools and disable permissions monitoring.
   If you get stuck check the referenced StackOverflow page.
1. Configure Fluid Navigation Guestures (FNG)
   - Set it to hide the navigation bar
   - Advanced > Rules per app > Pause on lock screen = untoggled
1. Use ADB to configure Android
   - Grant FNG permissions permanently `adb shell pm grant com.fb.fluid android.permission.WRITE_SECURE_SETTINGS`
   - Force full screen navigation `adb shellsettings put global force_fsg_nav_bar 1`

Note that only the last step must be repeated if the bar comes back.
The rest should persist though I make no promises about system updates.
There's probably some logic behind resetting the force FSG setting on reboot as otherwise you wouldn't be able to get back to settings to change anything.

## References

- [StackOverflow about Xiaomi login](https://android.stackexchange.com/questions/185116/enable-install-via-usb-without-creating-mi-account#186052)
- [XDA Developers about hiding navigation bar](https://forum.xda-developers.com/t/guide-no-root-required-hide-the-status-bar-or-nav-bar-with-adb.3654807/)
- [General debloat tips](https://www.getdroidtips.com/debloat-poco-f4-gt-bloatware-remove-ads/)
- [Video using system app revert and side-load](https://www.youtube.com/watch?v=HCG-xQhnsEM)
- [/r/Xiaomi post covering FNG settings](https://www.reddit.com/r/Xiaomi/comments/ogad6z/anybody_found_a_way_to_use_miui_fullscreen/)

### Package manager help

```shell
$ pm help

Package manager (package) commands:
  help
    Print this help text.

  path [--user USER_ID] PACKAGE
    Print the path to the .apk of the given PACKAGE.

  dump PACKAGE
    Print various system state associated with the given PACKAGE.

  has-feature FEATURE_NAME [version]
    Prints true and returns exit status 0 when system has a FEATURE_NAME,
    otherwise prints false and returns exit status 1

  list features
    Prints all features of the system.

  list instrumentation [-f] [TARGET-PACKAGE]
    Prints all test packages; optionally only those targeting TARGET-PACKAGE
    Options:
      -f: dump the name of the .apk file containing the test package

  list libraries
    Prints all system libraries.

  list packages [-f] [-d] [-e] [-s] [-3] [-i] [-l] [-u] [-U]
      [--show-versioncode] [--apex-only] [--uid UID] [--user USER_ID] [FILTER]
    Prints all packages; optionally only those whose name contains
    the text in FILTER.  Options are:
      -f: see their associated file
      -a: all known packages (but excluding APEXes)
      -d: filter to only show disabled packages
      -e: filter to only show enabled packages
      -s: filter to only show system packages
      -3: filter to only show third party packages
      -i: see the installer for the packages
      -l: ignored (used for compatibility with older releases)
      -U: also show the package UID
      -u: also include uninstalled packages
      --show-versioncode: also show the version code
      --apex-only: only show APEX packages
      --uid UID: filter to only show packages with the given UID
      --user USER_ID: only list packages belonging to the given user

  list permission-groups
    Prints all known permission groups.

  list permissions [-g] [-f] [-d] [-u] [GROUP]
    Prints all known permissions; optionally only those in GROUP.  Options are:
      -g: organize by group
      -f: print all information
      -s: short summary
      -d: only list dangerous permissions
      -u: list only the permissions users will see

  list staged-sessions [--only-ready] [--only-sessionid] [--only-parent]
    Prints all staged sessions.
      --only-ready: show only staged sessions that are ready
      --only-sessionid: show only sessionId of each session
      --only-parent: hide all children sessions

  list users
    Prints all users.

  resolve-activity [--brief] [--components] [--query-flags FLAGS]
       [--user USER_ID] INTENT
    Prints the activity that resolves to the given INTENT.

  query-activities [--brief] [--components] [--query-flags FLAGS]
       [--user USER_ID] INTENT
    Prints all activities that can handle the given INTENT.

  query-services [--brief] [--components] [--query-flags FLAGS]
       [--user USER_ID] INTENT
    Prints all services that can handle the given INTENT.

  query-receivers [--brief] [--components] [--query-flags FLAGS]
       [--user USER_ID] INTENT
    Prints all broadcast receivers that can handle the given INTENT.

  install [-rtfdg] [-i PACKAGE] [--user USER_ID|all|current]
       [-p INHERIT_PACKAGE] [--install-location 0/1/2]
       [--install-reason 0/1/2/3/4] [--originating-uri URI]
       [--referrer URI] [--abi ABI_NAME] [--force-sdk]
       [--preload] [--instant] [--full] [--dont-kill]
       [--enable-rollback]
       [--force-uuid internal|UUID] [--pkg PACKAGE] [-S BYTES]
       [--apex] [--staged-ready-timeout TIMEOUT]
       [PATH [SPLIT...]|-]
    Install an application.  Must provide the apk data to install, either as
    file path(s) or '-' to read from stdin.  Options are:
      -R: disallow replacement of existing application
      -t: allow test packages
      -i: specify package name of installer owning the app
      -f: install application on internal flash
      -d: allow version code downgrade (debuggable packages only)
      -p: partial application install (new split on top of existing pkg)
      -g: grant all runtime permissions
      -S: size in bytes of package, required for stdin
      --user: install under the given user.
      --dont-kill: installing a new feature split, don't kill running app
      --restrict-permissions: don't whitelist restricted permissions at install
      --originating-uri: set URI where app was downloaded from
      --referrer: set URI that instigated the install of the app
      --pkg: specify expected package name of app being installed
      --abi: override the default ABI of the platform
      --instant: cause the app to be installed as an ephemeral install app
      --full: cause the app to be installed as a non-ephemeral full app
      --install-location: force the install location:
          0=auto, 1=internal only, 2=prefer external
      --install-reason: indicates why the app is being installed:
          0=unknown, 1=admin policy, 2=device restore,
          3=device setup, 4=user request
      --force-uuid: force install on to disk volume with given UUID
      --apex: install an .apex file, not an .apk
      --staged-ready-timeout: By default, staged sessions wait 60000
          milliseconds for pre-reboot verification to complete when
          performing staged install. This flag is used to alter the waiting
          time. You can skip the waiting time by specifying a TIMEOUT of '0'

  install-existing [--user USER_ID|all|current]
       [--instant] [--full] [--wait] [--restrict-permissions] PACKAGE
    Installs an existing application for a new user.  Options are:
      --user: install for the given user.
      --instant: install as an instant app
      --full: install as a full app
      --wait: wait until the package is installed
      --restrict-permissions: don't whitelist restricted permissions

  install-create [-lrtsfdg] [-i PACKAGE] [--user USER_ID|all|current]
       [-p INHERIT_PACKAGE] [--install-location 0/1/2]
       [--install-reason 0/1/2/3/4] [--originating-uri URI]
       [--referrer URI] [--abi ABI_NAME] [--force-sdk]
       [--preload] [--instant] [--full] [--dont-kill]
       [--force-uuid internal|UUID] [--pkg PACKAGE] [--apex] [-S BYTES]
       [--multi-package] [--staged]
    Like "install", but starts an install session.  Use "install-write"
    to push data into the session, and "install-commit" to finish.

  install-write [-S BYTES] SESSION_ID SPLIT_NAME [PATH|-]
    Write an apk into the given install session.  If the path is '-', data
    will be read from stdin.  Options are:
      -S: size in bytes of package, required for stdin

  install-remove SESSION_ID SPLIT...
    Mark SPLIT(s) as removed in the given install session.

  install-add-session MULTI_PACKAGE_SESSION_ID CHILD_SESSION_IDs
    Add one or more session IDs to a multi-package session.

  install-commit SESSION_ID
    Commit the given active install session, installing the app.

  install-abandon SESSION_ID
    Delete the given active install session.

  set-install-location LOCATION
    Changes the default install location.  NOTE this is only intended for debugging;
    using this can cause applications to break and other undersireable behavior.
    LOCATION is one of:
    0 [auto]: Let system decide the best location
    1 [internal]: Install on internal device storage
    2 [external]: Install on external media

  get-install-location
    Returns the current install location: 0, 1 or 2 as per set-install-location.

  move-package PACKAGE [internal|UUID]

  move-primary-storage [internal|UUID]

  uninstall [-k] [--user USER_ID] [--versionCode VERSION_CODE]
       PACKAGE [SPLIT...]
    Remove the given package name from the system.  May remove an entire app
    if no SPLIT names specified, otherwise will remove only the splits of the
    given app.  Options are:
      -k: keep the data and cache directories around after package removal.
      --user: remove the app from the given user.
      --versionCode: only uninstall if the app has the given version code.

  clear [--user USER_ID] [--cache-only] PACKAGE
    Deletes data associated with a package. Options are:
    --user: specifies the user for which we need to clear data
    --cache-only: a flag which tells if we only need to clear cache data

  enable [--user USER_ID] PACKAGE_OR_COMPONENT
  disable [--user USER_ID] PACKAGE_OR_COMPONENT
  disable-user [--user USER_ID] PACKAGE_OR_COMPONENT
  disable-until-used [--user USER_ID] PACKAGE_OR_COMPONENT
  default-state [--user USER_ID] PACKAGE_OR_COMPONENT
    These commands change the enabled state of a given package or
    component (written as "package/class").

  hide [--user USER_ID] PACKAGE_OR_COMPONENT
  unhide [--user USER_ID] PACKAGE_OR_COMPONENT

  suspend [--user USER_ID] PACKAGE [PACKAGE...]
    Suspends the specified package(s) (as user).

  unsuspend [--user USER_ID] PACKAGE [PACKAGE...]
    Unsuspends the specified package(s) (as user).

  set-distracting-restriction [--user USER_ID] [--flag FLAG ...]
      PACKAGE [PACKAGE...]
    Sets the specified restriction flags to given package(s) (for user).
    Flags are:
      hide-notifications: Hides notifications from this package
      hide-from-suggestions: Hides this package from suggestions
        (by the launcher, etc.)
    Any existing flags are overwritten, which also means that if no flags are
    specified then all existing flags will be cleared.

  grant [--user USER_ID] PACKAGE PERMISSION
  revoke [--user USER_ID] PACKAGE PERMISSION
    These commands either grant or revoke permissions to apps.  The permissions
    must be declared as used in the app's manifest, be runtime permissions
    (protection level dangerous), and the app targeting SDK greater than Lollipop MR1.

  set-permission-flags [--user USER_ID] PACKAGE PERMISSION [FLAGS..]
  clear-permission-flags [--user USER_ID] PACKAGE PERMISSION [FLAGS..]
    These commands either set or clear permission flags on apps.  The permissions
    must be declared as used in the app's manifest, be runtime permissions
    (protection level dangerous), and the app targeting SDK greater than Lollipop MR1.
    The flags must be one or more of [review-required, revoked-compat, revoke-when-requested, user-fixed, user-set]

  reset-permissions
    Revert all runtime permissions to their default state.

  set-permission-enforced PERMISSION [true|false]

  get-privapp-permissions TARGET-PACKAGE
    Prints all privileged permissions for a package.

  get-privapp-deny-permissions TARGET-PACKAGE
    Prints all privileged permissions that are denied for a package.

  get-oem-permissions TARGET-PACKAGE
    Prints all OEM permissions for a package.

  trim-caches DESIRED_FREE_SPACE [internal|UUID]
    Trim cache files to reach the given free space.

  list users
    Lists the current users.

  create-user [--profileOf USER_ID] [--managed] [--restricted] [--ephemeral]
      [--guest] [--pre-create-only] [--user-type USER_TYPE] USER_NAME
    Create a new user with the given USER_NAME, printing the new user identifier
    of the user.
    USER_TYPE is the name of a user type, e.g. android.os.usertype.profile.MANAGED.
      If not specified, the default user type is android.os.usertype.full.SECONDARY.
      --managed is shorthand for '--user-type android.os.usertype.profile.MANAGED'.
      --restricted is shorthand for '--user-type android.os.usertype.full.RESTRICTED'.
      --guest is shorthand for '--user-type android.os.usertype.full.GUEST'.

  remove-user [--set-ephemeral-if-in-use | --wait] USER_ID
    Remove the user with the given USER_IDENTIFIER, deleting all data
    associated with that user.
      --set-ephemeral-if-in-use: If the user is currently running and
        therefore cannot be removed immediately, mark the user as ephemeral
        so that it will be automatically removed when possible (after user
        switch or reboot)
      --wait: Wait until user is removed. Ignored if set-ephemeral-if-in-use

  set-user-restriction [--user USER_ID] RESTRICTION VALUE

  get-max-users

  get-max-running-users

  compile [-m MODE | -r REASON] [-f] [-c] [--split SPLIT_NAME]
          [--reset] [--check-prof (true | false)] (-a | TARGET-PACKAGE)
    Trigger compilation of TARGET-PACKAGE or all packages if "-a".  Options are:
      -a: compile all packages
      -c: clear profile data before compiling
      -f: force compilation even if not needed
      -m: select compilation mode
          MODE is one of the dex2oat compiler filters:
            assume-verified
            extract
            verify
            quicken
            space-profile
            space
            speed-profile
            speed
            everything
      -r: select compilation reason
          REASON is one of:
            first-boot
            boot-after-ota
            post-boot
            install
            install-fast
            install-bulk
            install-bulk-secondary
            install-bulk-downgraded
            install-bulk-secondary-downgraded
            bg-dexopt
            ab-ota
            inactive
            cmdline
            shared
            first-use
      --reset: restore package to its post-install state
      --check-prof (true | false): look at profiles when doing dexopt?
      --secondary-dex: compile app secondary dex files
      --split SPLIT: compile only the given split name
      --compile-layouts: compile layout resources for faster inflation

  force-dex-opt PACKAGE
    Force immediate execution of dex opt for the given PACKAGE.

  delete-dexopt PACKAGE
    Delete dex optimization results for the given PACKAGE.

  bg-dexopt-job
    Execute the background optimizations immediately.
    Note that the command only runs the background optimizer logic. It may
    overlap with the actual job but the job scheduler will not be able to
    cancel it. It will also run even if the device is not in the idle
    maintenance mode.
  cancel-bg-dexopt-job
    Cancels currently running background optimizations immediately.
    This cancels optimizations run from bg-dexopt-job or from JobScjeduler.
    Note that cancelling currently running bg-dexopt-job command requires
    running this command from separate adb shell.

  reconcile-secondary-dex-files TARGET-PACKAGE
    Reconciles the package secondary dex files with the generated oat files.

  dump-profiles [--dump-classes-and-methods] TARGET-PACKAGE
    Dumps method/class profile files to
    /data/misc/profman/TARGET-PACKAGE-primary.prof.txt.
      --dump-classes-and-methods: passed along to the profman binary to
        switch to the format used by 'profman --create-profile-from'.

  snapshot-profile TARGET-PACKAGE [--code-path path]
    Take a snapshot of the package profiles to
    /data/misc/profman/TARGET-PACKAGE[-code-path].prof
    If TARGET-PACKAGE=android it will take a snapshot of the boot image

  set-home-activity [--user USER_ID] TARGET-COMPONENT
    Set the default home activity (aka launcher).
    TARGET-COMPONENT can be a package name (com.package.my) or a full
    component (com.package.my/component.name). However, only the package name
    matters: the actual component used will be determined automatically from
    the package.

  set-installer PACKAGE INSTALLER
    Set installer package name

  get-instantapp-resolver
    Return the name of the component that is the current instant app installer.

  set-harmful-app-warning [--user <USER_ID>] <PACKAGE> [<WARNING>]
    Mark the app as harmful with the given warning message.

  get-harmful-app-warning [--user <USER_ID>] <PACKAGE>
    Return the harmful app warning message for the given app, if present

  uninstall-system-updates [<PACKAGE>]
    Removes updates to the given system application and falls back to its
    /system version. Does nothing if the given package is not a system app.
    If no package is specified, removes updates to all system applications.

  get-moduleinfo [--all | --installed] [module-name]
    Displays module info. If module-name is specified only that info is shown
    By default, without any argument only installed modules are shown.
      --all: show all module info
      --installed: show only installed modules

  log-visibility [--enable|--disable] <PACKAGE>
    Turns on debug logging when visibility is blocked for the given package.
      --enable: turn on debug logging (default)
      --disable: turn off debug logging

  set-silent-updates-policy [--allow-unlimited-silent-updates <INSTALLER>]
                            [--throttle-time <SECONDS>] [--reset]
    Sets the policies of the silent updates.
      --allow-unlimited-silent-updates: allows unlimited silent updated
        installation requests from the installer without the throttle time.
      --throttle-time: update the silent updates throttle time in seconds.
      --reset: restore the installer and throttle time to the default, and
        clear tracks of silent updates in the system.

  get-app-links [--user <USER_ID>] [<PACKAGE>]
    Prints the domain verification state for the given package, or for all
    packages if none is specified. State codes are defined as follows:
        - none: nothing has been recorded for this domain
        - verified: the domain has been successfully verified
        - approved: force approved, usually through shell
        - denied: force denied, usually through shell
        - migrated: preserved verification from a legacy response
        - restored: preserved verification from a user data restore
        - legacy_failure: rejected by a legacy verifier, unknown reason
        - system_configured: automatically approved by the device config
        - >= 1024: Custom error code which is specific to the device verifier
      --user <USER_ID>: include user selections (includes all domains, not
        just autoVerify ones)
  reset-app-links [--user <USER_ID>] [<PACKAGE>]
    Resets domain verification state for the given package, or for all
    packages if none is specified.
      --user <USER_ID>: clear user selection state instead; note this means
        domain verification state will NOT be cleared
      <PACKAGE>: the package to reset, or "all" to reset all packages
  verify-app-links [--re-verify] [<PACKAGE>]
    Broadcasts a verification request for the given package, or for all
    packages if none is specified. Only sends if the package has previously
    not recorded a response.
      --re-verify: send even if the package has recorded a response
  set-app-links [--package <PACKAGE>] <STATE> <DOMAINS>...
    Manually set the state of a domain for a package. The domain must be
    declared by the package as autoVerify for this to work. This command
    will not report a failure for domains that could not be applied.
      --package <PACKAGE>: the package to set, or "all" to set all packages
      <STATE>: the code to set the domains to, valid values are:
        STATE_NO_RESPONSE (0): reset as if no response was ever recorded.
        STATE_SUCCESS (1): treat domain as successfully verified by domain.
          verification agent. Note that the domain verification agent can
          override this.
        STATE_APPROVED (2): treat domain as always approved, preventing the
           domain verification agent from changing it.
        STATE_DENIED (3): treat domain as always denied, preveting the domain
          verification agent from changing it.
      <DOMAINS>: space separated list of domains to change, or "all" to
        change every domain.
  set-app-links-user-selection --user <USER_ID> [--package <PACKAGE>]
      <ENABLED> <DOMAINS>...
    Manually set the state of a host user selection for a package. The domain
    must be declared by the package for this to work. This command will not
    report a failure for domains that could not be applied.
      --user <USER_ID>: the user to change selections for
      --package <PACKAGE>: the package to set
      <ENABLED>: whether or not to approve the domain
      <DOMAINS>: space separated list of domains to change, or "all" to
        change every domain.
  set-app-links-allowed --user <USER_ID> [--package <PACKAGE>] <ALLOWED>
      <ENABLED> <DOMAINS>...
    Toggle the auto verified link handling setting for a package.
      --user <USER_ID>: the user to change selections for
      --package <PACKAGE>: the package to set, or "all" to set all packages
        packages will be reset if no one package is specified.
      <ALLOWED>: true to allow the package to open auto verified links, false
        to disable
  get-app-link-owners [--user <USER_ID>] [--package <PACKAGE>] [<DOMAINS>]
    Print the owners for a specific domain for a given user in low to high
    priority order.
      --user <USER_ID>: the user to query for
      --package <PACKAGE>: optionally also print for all web domains declared
        by a package, or "all" to print all packages
      --<DOMAINS>: space separated list of domains to query for

<INTENT> specifications include these flags and arguments:
    [-a <ACTION>] [-d <DATA_URI>] [-t <MIME_TYPE>] [-i <IDENTIFIER>]
    [-c <CATEGORY> [-c <CATEGORY>] ...]
    [-n <COMPONENT_NAME>]
    [-e|--es <EXTRA_KEY> <EXTRA_STRING_VALUE> ...]
    [--esn <EXTRA_KEY> ...]
    [--ez <EXTRA_KEY> <EXTRA_BOOLEAN_VALUE> ...]
    [--ei <EXTRA_KEY> <EXTRA_INT_VALUE> ...]
    [--el <EXTRA_KEY> <EXTRA_LONG_VALUE> ...]
    [--ef <EXTRA_KEY> <EXTRA_FLOAT_VALUE> ...]
    [--ed <EXTRA_KEY> <EXTRA_DOUBLE_VALUE> ...]
    [--eu <EXTRA_KEY> <EXTRA_URI_VALUE> ...]
    [--ecn <EXTRA_KEY> <EXTRA_COMPONENT_NAME_VALUE>]
    [--eia <EXTRA_KEY> <EXTRA_INT_VALUE>[,<EXTRA_INT_VALUE...]]
        (multiple extras passed as Integer[])
    [--eial <EXTRA_KEY> <EXTRA_INT_VALUE>[,<EXTRA_INT_VALUE...]]
        (multiple extras passed as List<Integer>)
    [--ela <EXTRA_KEY> <EXTRA_LONG_VALUE>[,<EXTRA_LONG_VALUE...]]
        (multiple extras passed as Long[])
    [--elal <EXTRA_KEY> <EXTRA_LONG_VALUE>[,<EXTRA_LONG_VALUE...]]
        (multiple extras passed as List<Long>)
    [--efa <EXTRA_KEY> <EXTRA_FLOAT_VALUE>[,<EXTRA_FLOAT_VALUE...]]
        (multiple extras passed as Float[])
    [--efal <EXTRA_KEY> <EXTRA_FLOAT_VALUE>[,<EXTRA_FLOAT_VALUE...]]
        (multiple extras passed as List<Float>)
    [--eda <EXTRA_KEY> <EXTRA_DOUBLE_VALUE>[,<EXTRA_DOUBLE_VALUE...]]
        (multiple extras passed as Double[])
    [--edal <EXTRA_KEY> <EXTRA_DOUBLE_VALUE>[,<EXTRA_DOUBLE_VALUE...]]
        (multiple extras passed as List<Double>)
    [--esa <EXTRA_KEY> <EXTRA_STRING_VALUE>[,<EXTRA_STRING_VALUE...]]
        (multiple extras passed as String[]; to embed a comma into a string,
         escape it using "\,")
    [--esal <EXTRA_KEY> <EXTRA_STRING_VALUE>[,<EXTRA_STRING_VALUE...]]
        (multiple extras passed as List<String>; to embed a comma into a string,
         escape it using "\,")
    [-f <FLAG>]
    [--grant-read-uri-permission] [--grant-write-uri-permission]
    [--grant-persistable-uri-permission] [--grant-prefix-uri-permission]
    [--debug-log-resolution] [--exclude-stopped-packages]
    [--include-stopped-packages]
    [--activity-brought-to-front] [--activity-clear-top]
    [--activity-clear-when-task-reset] [--activity-exclude-from-recents]
    [--activity-launched-from-history] [--activity-multiple-task]
    [--activity-no-animation] [--activity-no-history]
    [--activity-no-user-action] [--activity-previous-is-top]
    [--activity-reorder-to-front] [--activity-reset-task-if-needed]
    [--activity-single-top] [--activity-clear-task]
    [--activity-task-on-home] [--activity-match-external]
    [--receiver-registered-only] [--receiver-replace-pending]
    [--receiver-foreground] [--receiver-no-abort]
    [--receiver-include-background]
    [--selector]
    [<URI> | <PACKAGE> | <COMPONENT>]
```

### Full package listing

- de.luhmer.owncloudnewsreader
- com.android.updater
- com.miui.powerkeeper
- com.qti.phone
- com.miui.miservice
- com.google.android.overlay.modules.permissioncontroller.forframework
- com.miui.miwallpaper.overlay.customize
- com.mi.android.globalFileexplorer
- android.miui.overlay
- au.com.solus.BrisbaneCityCouncilLibraries
- com.goodix.gftest
- com.qualcomm.qti.cne
- com.android.dreams.phototable
- com.android.overlay.gmscontactprovider
- com.miui.face
- com.niksoftware.snapseed
- com.android.providers.contacts
- com.mi.android.globalminusscreen
- com.qualcomm.uimremoteserver
- com.android.companiondevicemanager
- com.android.cts.priv.ctsshim
- com.android.providers.downloads
- com.android.bluetoothmidiservice
- com.ustwo.monumentvalley2
- com.xiaomi.xmsf
- com.google.android.printservice.recommendation
- com.google.android.captiveportallogin
- com.google.android.networkstack
- com.alphainventor.filemanager
- com.miui.phone.carriers.overlay.vodafone
- com.android.keychain
- com.google.android.overlay.gmsconfig.asi
- com.miui.global.packageinstaller
- com.qti.service.colorservice
- com.qualcomm.qti.confdialer
- com.android.shell
- org.thoughtcrime.securesms
- com.google.android.ims
- com.google.android.ondevicepersonalization.services
- com.wdstechnology.android.kryten
- com.android.bookmarkprovider
- com.miui.rom
- com.duosecurity.duomobile
- com.mi.global.pocobbs
- com.miui.core.internal.services
- com.miui.touchassistant
- com.android.sharedstoragebackup
- com.qualcomm.qti.uimGbaApp
- com.android.providers.media
- com.android.providers.calendar
- com.bendigobank.mobile.AdelaideBank
- com.android.providers.blockednumber
- com.google.android.documentsui
- com.android.statementservice
- com.miui.audiomonitor
- com.android.proxyhandler
- com.google.android.overlay.modules.permissioncontroller
- com.android.emergency
- com.google.android.gms.location.history
- com.android.systemui.deviceconfig.config.overlay
- com.miui.aod
- com.portableandroid.classicboyLite
- com.google.android.apps.googleassistant
- com.qualcomm.qti.gpudrivers.taro.api31
- com.fb.fluid
- com.qualcomm.location
- com.google.android.gm
- com.android.carrierdefaultapp
- com.android.backupconfirm
- com.android.server.telecom.overlay.miui
- com.android.mtp
- com.miui.screenrecorder
- com.google.android.apps.magazines
- com.android.theme.font.notoserifsource
- com.qualcomm.qti.remoteSimlockAuth
- com.f2zentertainment.pandemic
- com.stronglifts.app
- com.bandcamp.android
- org.videolan.vlc
- com.qualcomm.qti.xrcb
- com.miui.guardprovider
- com.android.wallpapercropper
- com.gamedevltd.modernstrike
- com.xiaomi.glgm
- android.miui.poco.launcher.res
- com.google.android.overlay.gmsconfig.geotz
- com.android.internal.systemui.navbar.gestural
- com.android.soundrecorder
- fr.gouv.etalab.mastodon
- com.miui.systemui.overlay.devices.android
- com.android.settings.intelligence
- com.qualcomm.timeservice
- com.lbe.security.miui
- com.xiaomi.midrop
- at.bitfire.davdroid
- com.teslacoilsw.launcher.prime
- com.google.android.overlay.gmsconfig.personalsafety
- com.qualcomm.wfd.service
- com.android.overlay.gmssettings
- au.gov.bom.metview
- vendor.qti.imsrcs
- com.google.android.webview
- com.google.android.sdksandbox
- com.miui.securityadd
- com.google.android.cellbroadcastservice
- com.android.internal.systemui.navbar.threebutton
- com.android.egg
- com.google.android.overlay.modules.modulemetadata.forframework
- com.miui.gallery
- com.google.android.packageinstaller
- com.android.se
- com.practicalearning.minidoroclock
- com.ubercab
- com.android.stk
- com.android.overlay.systemui
- ru.elron.gamepadtester
- com.miui.calculator
- com.android.bips
- com.qualcomm.qti.telephonyservice
- ch.protonmail.android
- com.google.android.partnersetup
- com.xiaomi.bluetooth
- com.google.android.projection.gearhead
- org.dslul.openboard.inputmethod.latin
- com.android.overlay.gmstelephony
- com.xiaomi.finddevice
- com.vanced.manager
- com.google.android.feedback
- com.miui.notification
- org.codeaurora.ims
- au.com.auspost.android
- com.android.incallui.overlay
- android.autoinstalls.config.Xiaomi.model
- com.google.android.inputmethod.latin
- miui.systemui.plugin
- com.miui.bugreport
- com.android.smspush
- su.xash.husky
- cn.wps.xiaomi.abroad.lite
- com.mcdonalds.au.gma
- com.xiaomi.cameratools
- com.sony.songpal.mdr
- com.android.providers.downloads.ui
- com.qualcomm.qti.performancemode
- com.android.ons
- com.mi.globallayout
- com.google.android.nearby.halfsheet
- com.miui.mediaeditor
- com.google.android.setupwizard
- com.miui.system
- com.android.wifi.resources
- com.fastemulator.gba
- org.fdroid.fdroid
- com.qualcomm.qti.server.qtiwifi
- com.urbandroid.sleep
- com.miui.securitycenter
- com.android.simappdialog
- com.android.wallpaper.livepicker
- com.android.systemui.overlay.common
- com.fido.asm
- com.qualcomm.qti.poweroffalarm
- com.android.internal.display.cutout.emulation.waterfall
- com.vanced.android.youtube
- com.miui.qr
- com.google.android.overlay.modules.ext.services
- com.android.systemui.gesture.line.overlay
- org.mozilla.fennec_fdroid
- com.android.traceur
- com.gameloft.android.ANMP.GloftM5HM
- com.google.android.apps.messaging
- com.android.location.fused
- com.android.cellbroadcastreceiver
- com.google.android.googlequicksearchbox
- com.keylesspalace.tusky
- com.google.android.modulemetadata
- com.android.settings.overlay.common
- com.google.android.ext.services
- org.joinmastodon.android
- com.google.android.configupdater
- android.qvaoverlay.common
- de.syss.MifareClassicTool
- com.miui.wmsvc
- com.qti.qcc
- org.ifaa.aidl.manager
- com.google.android.gms.supervision
- com.nxp.taginfolite
- com.google.android.apps.photos
- com.qualcomm.qti.workloadclassifier
- com.android.internal.display.cutout.emulation.corner
- com.google.android.gms
- com.xiaomi.mtb
- com.android.systemui.overlay.miui
- com.milink.service
- com.android.thememanager
- com.textra
- com.android.printspooler
- com.miui.systemui.devices.overlay
- com.miui.misound
- com.google.android.apps.setupwizard.searchselector
- com.qualcomm.qti.uim
- com.android.soundpicker
- com.google.mainline.telemetry
- com.miui.wallpaper.overlay.customize
- org.mipay.android.manager
- com.tencent.soter.soterserver
- com.nordvpn.android
- com.google.android.cellbroadcastservice.overlay.miui
- com.android.externalstorage
- com.android.server.telecom
- com.yubico.yubioath
- com.android.camera
- com.miui.daemon
- com.google.android.providers.media.module
- com.nxp.nfc.tagwriter
- com.android.calllogbackup
- com.google.android.apps.paidtasks
- com.qti.diagservices
- com.qualcomm.qti.lpa
- com.qualcomm.atfwd
- com.sonelli.juicessh
- com.digidiced.pxwrelease
- com.miui.videoplayer
- com.NightSchool.Oxenfree
- com.google.android.overlay.gmsconfig.comms
- com.miui.securitycore
- com.android.dreams.basic
- com.google.android.calendar
- com.google.android.contacts
- com.android.mms.service
- com.google.android.cellbroadcastreceiver
- com.lojugames.games.transmission
- com.android.networkstack.overlay
- net.dinglisch.android.taskerm
- com.google.android.play.games
- com.xiaomi.bluetooth.rro.device.config.overlay
- com.xiaomi.micloud.sdk
- com.google.android.apps.wellbeing
- com.qualcomm.qti.devicestatisticsservice
- com.google.android.adservices.api
- com.android.wifi.resources.xiaomi
- com.miuix.editor
- com.xiaomi.scanner
- com.android.inputdevices
- com.x8bit.bitwarden
- com.qti.qualcomm.datastatusnotification
- com.miui.weather2
- com.google.android.onetimeinitializer
- com.google.android.permissioncontroller
- com.android.carrierconfig.overlay.miui
- com.android.apps.tag
- com.xiaomi.mipicks
- com.qualcomm.qti.ridemodeaudio
- com.android.wifi.resources.overlay.taro
- com.miui.analytics
- com.google.android.overlay.modules.documentsui
- com.google.android.keep
- jp.naver.line.android
- com.miui.android.fashiongallery
- com.miui.settings.rro.device.hide.statusbar.overlay
- com.xiaomi.account
- com.hhyu.neuron
- com.android.cellbroadcastreceiver.overlay.common
- com.ventismedia.android.mediamonkey
- com.android.managedprovisioning
- com.miui.mishare.connectivity
- com.teslacoilsw.launcher
- com.android.nfc
- com.kiarygames.tinyroom
- com.android.carrierconfig.overlay.common
- com.google.android.gsf
- com.android.systemui.navigation.bar.overlay
- com.czechgames.tta
- com.android.internal.display.cutout.emulation.double
- com.xiaomi.simactivate.service
- com.android.server.telecom.overlay.common
- com.tranzmate
- com.android.managedprovisioning.overlay
- com.android.systemui
- im.vector.app
- com.google.ar.core
- com.google.android.dialer
- com.qualcomm.qti.uceShimService
- com.google.android.apps.translate
- com.qti.xdivert
- com.google.mainline.adservices
- com.calm.android
- com.qualcomm.qti.qcolor
- com.android.settings.overlay.miui
- com.android.hotwordenrollment.okgoogle
- com.miui.player
- com.miui.cleaner
- com.miui.phrase
- com.miui.extraphoto
- com.bsp.catchlog
- org.mozilla.firefox
- com.android.deskclock
- com.android.wallpaperbackup
- com.miui.wallpaper.overlay
- com.starrealms.starrealmsapp
- com.miui.core
- us.spotco.ir_remote
- com.miui.settings.rro.device.type.overlay
- com.android.localtransport
- android
- com.miui.compass
- com.android.hotwordenrollment.xgoogle
- com.qualcomm.qti.dynamicddsservice
- com.miui.face.overlay.miui
- com.google.android.apps.walletnfcrel
- io.keybase.ossifrage
- com.android.pacprocessor
- com.miui.freeform
- com.qualcomm.embms
- com.miui.phone.carriers.overlay.h3g
- com.google.android.safetycenter.resources
- free.reddit.news
- com.android.internal.display.cutout.emulation.hole
- com.android.settings
- com.micredit.in
- com.android.internal.systemui.navbar.gestural_narrow_back
- com.android.internal.display.cutout.emulation.tall
- com.google.android.networkstack.tethering
- com.xiaomi.discover
- com.android.cameraextensions
- com.miui.notes
- com.android.carrierconfig
- com.android.internal.systemui.navbar.gestural_wide_back
- com.nextcloud.client
- com.google.android.ext.shared
- com.xiaomi.xmsfkeeper
- com.android.chrome
- com.qualcomm.qcrilmsgtunnel
- android.overlay.common
- com.kfcaus.ordering
- com.google.android.apps.maps
- com.google.android.as
- com.android.musicfx
- au.gov.ato.mygovid.droid
- com.modemdebug
- com.google.android.marvin.talkback
- vendor.qti.hardware.cacert.server
- com.brave.browser
- com.katiearose.sobriety
- com.miui.miwallpaper
- com.mi.android.globallauncher
- com.google.android.apps.docs
- com.miui.cit
- com.android.certinstaller
- com.google.android.apps.safetyhub
- com.qualcomm.uimremoteclient
- com.miHoYo.GenshinImpact
- com.android.wifi.dialog
- com.google.android.apps.restore
- com.qti.snapdragon.qdcm_ff
- com.miui.systemui.carriers.overlay
- com.android.thememanager.gliobal_config.config.overlay
- com.miui.backup
- com.qualcomm.qti.powersavemode
- com.android.providers.telephony
- com.slothwerks.meteorfall
- com.miui.settings.rro.device.config.overlay
- com.xiaomi.barrage
- com.quicinc.voice.activation
- com.android.providers.settings
- com.android.overlay.gmssettingprovider
- vendor.qti.iwlan
- com.android.phone
- com.android.internal.systemui.navbar.gestural_extra_wide_back
- com.google.android.apps.subscriptions.red
- android.aosp.overlay
- com.escooterapp
- com.google.android.as.oss
- au.com.up.money
- com.android.overlay.gmstelecomm
- com.xiaomi.entitlement.o2
- com.android.vpndialogs
- com.android.uwb.resources
- com.miui.screenshot
- com.google.android.tts
- com.android.wifi.resources.overlay.common
- com.qualcomm.qtil.btdsda
- com.google.android.cellbroadcastreceiver.overlay.miui
- com.android.phone.overlay.common
- org.schabi.newpipe
- com.android.htmlviewer
- com.qti.qualcomm.deviceinfo
- com.android.vending
- com.google.android.overlay.modules.captiveportallogin.forframework
- android.overlay.target
- com.miui.system.overlay
- com.google.android.apps.turbo
- com.valvesoftware.android.steam.community
- com.miui.miinput
- com.android.providers.settings.overlay
- com.google.android.overlay.gmsconfig.gsa
- com.android.providers.userdictionary
- com.google.android.overlay.gmsconfig.common
- com.android.cts.ctsshim
- com.android.bluetooth
- com.mgoogle.android.gms
- com.discord
- com.android.storagemanager
- com.fingerprints.sensortesttool
- com.ventismedia.android.mediamonkeypro
- com.miui.miwallpaper.overlay
- com.miui.miwallpaper.wallpaperoverlay.config.overlay
- com.xiaomi.NetworkBoost
- com.android.phone.overlay.miui
- com.xiaomi.misettings
- com.android.wifi.resources.overlay.target
- com.adobe.scan.android
- com.android.providers.partnerbookmarks
- com.amazon.appmanager
- com.android.provision
- com.qualcomm.qti.qms.service.trustzoneaccess
- com.android.dynsystem
- au.com.bank86400
- com.android.hotspot2.osulogin
- com.google.android.apps.adm
- com.google.android.connectivity.resources
- com.mi.global.pocostore

### Auth context

```shell
255|ingres:/ $ pm list permission-groups
permission group:com.google.android.gms.permission.CAR_INFORMATION
permission group:android.permission-group.CONTACTS
permission group:android.permission-group.PHONE
permission group:android.permission-group.CALENDAR
permission group:android.permission-group.CALL_LOG
permission group:android.permission-group.CAMERA
permission group:android.permission-group.READ_MEDIA_VISUAL
permission group:android.permission-group.READ_MEDIA_AURAL
permission group:android.permission-group.UNDEFINED
permission group:android.permission-group.ACTIVITY_RECOGNITION
permission group:android.permission-group.SENSORS
permission group:android.permission-group.LOCATION
permission group:android.permission-group.STORAGE
permission group:android.permission-group.NOTIFICATIONS
permission group:android.permission-group.MICROPHONE
permission group:android.permission-group.NEARBY_DEVICES
permission group:android.permission-group.SMS
ingres:/ $ pm list users
Users:
        UserInfo{0:Owner:c13} running
ingres:/ $ id
uid=2000(shell) gid=2000(shell) groups=2000(shell),1004(input),1007(log),1011(adb),1015(sdcard_rw),1028(sdcard_r),1078(ext_data_rw),1079(ext_obb_rw),3001(net_bt_admin),3002(net_bt),3003(inet),3006(net_bw_stats),3009(readproc),3011(uhid),3012(readtracefs) context=u:r:shell:s0
```
