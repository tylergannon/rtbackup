## Alternate configuration options

Alternatively you can put the file anywhere, and then specify the path to the file
using the `-c` parameter, or even pipe a config file in through stdin.

The latter option is useful if you'd like to keep passwords and keys in variables,
rather than saving them to the filesystem.

```bash
envsubst < back_conf.yml.tmpl | rtbackup daily -c -
```
