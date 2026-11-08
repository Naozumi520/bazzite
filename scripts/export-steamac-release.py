#!/usr/bin/env python3
"""Make a versioned GitHub release bundle from a fresh, never-booted bootc disk.

Run with a raw disk plus boot partition mounted read-only by Linux. Never feed a
personal/test disk to this exporter. The download manifest is consumed by the
steamac fork and stores the bootc deployment's actual UUIDs and ostree path.
"""
import argparse
import gzip
import hashlib
import json
from pathlib import Path
import shutil

p = argparse.ArgumentParser()
p.add_argument('--disk', type=Path, required=True)
p.add_argument('--boot', type=Path, required=True)
p.add_argument('--kernel', type=Path, required=True)
p.add_argument('--output', type=Path, required=True)
p.add_argument('--build', required=True)
p.add_argument('--revision', required=True)
a = p.parse_args()
a.output.mkdir(parents=True, exist_ok=False)
entries = sorted((a.boot / 'loader/entries').glob('*.conf'))
if len(entries) != 1:
    raise SystemExit(f'Expected one fresh deployment, found {len(entries)}')
fields = dict(line.split(None, 1) for line in entries[0].read_text().splitlines() if ' ' in line)
words = fields['options'].split()
# The libkrun kernel currently has no SELinux support. Generic UEFI validation
# uses the Fedora kernel with enforcing SELinux; this exception is steamac-only.
words = [w for w in words if not w.startswith(('console=', 'selinux='))]
words += ['console=hvc0', 'loglevel=4', 'selinux=0']
if not any(w.startswith('ostree=/ostree/') for w in words):
    raise SystemExit('Not a bootc/ostree deployment')
initrd = a.boot / fields['initrd'].lstrip('/')
if not initrd.is_file():
    raise SystemExit(f'Missing deployment initramfs {initrd}')

def asset(path):
    h = hashlib.sha256()
    with path.open('rb') as f:
        while block := f.read(1024 * 1024):
            h.update(block)
    size = path.stat().st_size
    if size > 2_147_483_647:
        raise SystemExit(f'{path.name} exceeds the supported GitHub asset limit')
    return {'name': path.name, 'sha256': h.hexdigest(), 'bytes': size}

shutil.copyfile(a.kernel, a.output / 'Image')
shutil.copyfile(initrd, a.output / 'initramfs.img')
with a.disk.open('rb') as source, (a.output / 'bazzite-steamac.img.gz').open('wb') as destination:
    with gzip.GzipFile(filename='', mode='wb', fileobj=destination, compresslevel=6, mtime=0) as compressed:
        shutil.copyfileobj(source, compressed, 1024 * 1024)
manifest = {
    'schema': 1, 'build': a.build, 'sourceRevision': a.revision,
    'diskBytes': a.disk.stat().st_size, 'commandLine': ' '.join(words),
    'disk': asset(a.output / 'bazzite-steamac.img.gz'),
    'kernel': asset(a.output / 'Image'), 'initrd': asset(a.output / 'initramfs.img'),
}
(a.output / 'bazzite-steamac.json').write_text(json.dumps(manifest, indent=2) + '\n')
(a.output / 'SHA256SUMS').write_text(''.join(f"{v['sha256']}  {v['name']}\n" for v in (manifest['disk'], manifest['kernel'], manifest['initrd'])))
print(json.dumps(manifest, indent=2))
