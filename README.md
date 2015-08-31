What?
=====

Pushover notifier for new Eve Online events. Currently it can check for new
Emails and let you know of PI extractors due to end

All characters on an account gets checked and a single message gets per monitor.

Tested with Ruby 2.0.0, you need a Pushover client and subscription to use this.

It's a bit hacky but does what I need.  It started off as a mail notifier only
but have since evolved into a general notifier due to some scope creep.

Config?
-------

You run it from cron on a Linux machine, it needs a config file:

      ---
      :max_notifications: 5

      :eve:
        :key_id: xxxx
        :verification_code: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

      :pushover:
        :user_token: xxxxxxxxxx
        :app_token: xxxxxxxxxxxx

The Eve API Key need at least ```MailMessages``` enabled.

```:max_notifications``` is how many emails per character will be listed in the message.

By default this config lives in ```~/.emn``` but you can run with ```--config``` to set a custom
one, like maybe 1 file per account

It tracks what items have been seen and you can safely use the same file for many accounts but
this is also configurable, see ```--help```.

Using?
------

I run mine from a local user crontab:

```
*/10 * * * * emn --mail --pi
```

You can run it frequently like this as it caches the API outputs, there's not really any reason
to run it more frequently than this though

Contact?
--------

R.I.Pienaar / rip@devco.net / @ripienaar / http://devco.net/
