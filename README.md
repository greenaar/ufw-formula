# ufw-formula

Install and configure [ufw](https://launchpad.net/ufw) (the Uncomplicated
Firewall), driving the whole ruleset from pillar.

Rules are expressed declaratively — by port/service, by ufw application
profile, by interface, or by source address — and this formula ships the
custom execution and state modules (`_modules/ufw.py`, `_states/ufw.py`)
that make `ufw.allow` / `ufw.deny` / `ufw.limit` / `ufw.allowed` /
`ufw.enabled` available as Salt states. They are synced to the minion
automatically on the first highstate; run `salt '<target>'
saltutil.sync_all` if you want them earlier.

## Safety note

`ufw:enabled` defaults to **false**. In that state the formula installs
the package and writes the config files but leaves the service dead, so
you can deploy the states fleet-wide before any packets get dropped. Only
flip it to `true` once your rules are in place — an incomplete ruleset
plus `DEFAULT_INPUT_POLICY: DROP` will lock you out of the box.

## Usage

```yaml
# top.sls
base:
  '*':
    - ufw
```

See `pillar.example` for the full set of options.

## Available states

| State | Description |
| --- | --- |
| `ufw` | Everything below. |
| `ufw.package` / `ufw.package.install` | Install the ufw package (plus any extras from `ufw:packages`). On Amazon Linux 2 this also sets up the EPEL repo. |
| `ufw.config` | All of the config states below. |
| `ufw.config.file` | Template `/etc/default/ufw` and `/etc/ufw/sysctl.conf` from `ufw:settings` / `ufw:sysctl`, and recurse `files/applications.d/` onto the minion. |
| `ufw.config.services` | Port- and service-based rules from `ufw:services`. |
| `ufw.config.applications` | Rules referencing ufw application profiles, from `ufw:applications`. |
| `ufw.config.interfaces` | Blanket allows per interface, from `ufw:interfaces`. |
| `ufw.config.open` | Blanket allows per source address, from `ufw:open`. |
| `ufw.service` | `ufw.service.enable` and `ufw.service.running`. |
| `ufw.service.enable` | Enable the firewall and set the log level. No-op unless `ufw:enabled` is true. |
| `ufw.service.running` | Run/enable the service when `ufw:enabled` is true; stop and disable it otherwise. |
| `ufw.service.reload` | `cmd.wait` hook the rule states fire via `listen_in`, so ufw is reloaded once at the end rather than after every rule. |

## Rule methods

Each entry under `services:` and `applications:` produces one rule per
`from_addr`. The method is chosen from the entry's flags:

- `deny: true` → `ufw.deny`
- `limit: true` → `ufw.limit` (rate-limited allow)
- neither → `ufw.allow`

`deny` wins if both are set.

## Application profiles

`ufw.config.file` recurses `files/applications.d/` into
`/etc/ufw/applications.d` with `clean: False`, so profiles you place
there are added without removing the distribution's own. The formula
ships profiles for Zabbix (server/proxy/agent), Munin, a Salt master, a
database server, and ssh on port 223. Reference them by their `[Section]`
title under `ufw:applications`.

## Supported platforms

Debian and RedHat families out of the box. Suse additionally pulls in
`iptables`; Gentoo uses the `net-firewall/ufw` package atom. Add your own
overrides to `osfamilymap.yaml`, `osmap.yaml`, or `osfingermap.yaml`.

## Testing

There is no test harness in this repo yet. Verify changes against a
throwaway VM with `ufw:enabled: false` first, then inspect the generated
rules with `ufw status verbose` after enabling.

## Relationship to upstream

**This is a heavily modified fork of
[`saltstack-formulas/ufw-formula`](https://github.com/saltstack-formulas/ufw-formula). Do not treat it as a drop-in
replacement for it.**

States have been renamed, split, merged, and removed; pillar keys have moved;
defaults differ; and behaviour has changed in ways that are not backward
compatible. Pointing an existing deployment at this formula without reading
`pillar.example` and the state list above will not do what you expect.

It is also not a newer version of upstream — it diverged and was maintained
separately, so upstream may well have fixes and platform support that this
does not. If you want the maintained original, use
[`saltstack-formulas/ufw-formula`](https://github.com/saltstack-formulas/ufw-formula).

### Credit

The foundation of this formula, and much of what still works well in it, is
the work of the [saltstack-formulas](https://github.com/saltstack-formulas) authors and contributors. Any
bugs introduced in the divergence are this fork's own.

Specific third-party files bundled here, with their own authors and
licenses, are itemised in [THIRD-PARTY.md](THIRD-PARTY.md).

## License

Dedicated to the public domain under [CC0 1.0 Universal](LICENSE), with the
exception of the third-party files listed in [THIRD-PARTY.md](THIRD-PARTY.md).
