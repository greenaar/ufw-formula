# -*- coding: utf-8 -*-
# vim: ft=sls

{#- Get the `tplroot` from `tpldir` #}
{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import ufw with context %}

{%- if ufw.get('enabled', False) %}
{#- ufw is a plain dict, so a colon-path string like 'settings:loglevel'
   isn't parsed as a nested lookup here the way it would be with
   salt['pillar.get'] - it just looks for one literal key named
   "settings:loglevel", never finds it, and always falls back to 'low'.
   Any loglevel set via pillar (ufw:settings:loglevel) was silently
   ignored. #}
{%- set loglevel = ufw.get('settings', {}).get('loglevel', 'low') %}

enable-ufw:
  ufw.enabled

set-logging:
  cmd.run:
    - name: ufw logging {{ loglevel }}
    - unless: "grep 'LOGLEVEL={{ loglevel }}' /etc/ufw/ufw.conf"
{%- endif %}
