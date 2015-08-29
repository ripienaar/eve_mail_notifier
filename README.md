What?
=====

Pushover notifier for new Eve Online emails.  All characters on an account gets checked and a single message gets sent.

Tested with Ruby 2.0.0, you need a Pushover client and subscription to use this.

It's a bit hacky but does what I need

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

It tracks what mail has been seen and you can safely use the same file for many accounts but
this is also configurable, see ```--help```.

Contact?
--------

R.I.Pienaar / rip@devco.net / @ripienaar / http://devco.net/
