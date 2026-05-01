#!/usr/bin/python3
import os
import sys
import re
import logging
from typing import Any
import requests
import json
from copy import deepcopy

__apps = {
    'git_sync': {
        'type': 'github_tag',
        'github': 'kubernetes/git-sync'
    },
    'gosu': {
        'type': 'github_tag',
        'github': 'tianon/gosu'
    },
    'go': {
        'type': 'go',
    },
    'alpine': {
        'type': 'alpine',
    },
}

__dockerfile = os.path.join(os.path.dirname(__file__), 'Dockerfile')


def version_github_tag(github: str, **kvargs: dict[str, Any]) -> str | None:
    response = requests.get(
        url=f'https://api.github.com/repos/{github}/tags?per_page=10',
    )
    response.raise_for_status()
    tags = response.json()
    if tags:
        return tags[0]['name'].strip(' v')

    return None


def version_go(**kvargs: dict[str, Any]) -> str | None:
    response = requests.get(
        url=f'https://go.dev/dl/',
        params={'mode': 'json'},
        allow_redirects=True,
    )
    response.raise_for_status()
    for header in response.headers.keys():
        if header.lower() == 'content-type':
            if response.headers.get(header) == 'application/json':
                break
            else:
                return None

    versions = []
    try:
        versions = json.loads(response.text)
    except:
        return None

    for version in versions:
        if version['stable']:
            return re.sub(r'^go', '', version['version'])

    return None


def version_alpine(**kvargs: dict[str, Any]) -> str | None:
    response = requests.get(
        url=f'https://dl-cdn.alpinelinux.org/alpine/',
        allow_redirects=True,
    )
    response.raise_for_status()
    html = response.text

    links = re.findall(r'<a href="([^"]+)">([^<]+)</a>', html)
    links = [(href, text) for href, text in links if href == text]

    pattern = re.compile(r'^v?[0-9._-]+[a-zA-Z0-9._-]*$')

    versions = []
    for href, _ in links:
        name = href.strip(' /')
        if pattern.match(name):
            versions.append(name)

    if len(versions) == 0:
        return None

    def key(v):
        nums = re.findall(r'\d+', v)
        return tuple(map(int, nums))

    latest = max(versions, key=key)

    return latest.strip(' v')


def main() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s,%(msecs)03d [%(levelname)s]: %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S',
    )

    debug = False
    if '--debug' in sys.argv or '-d' in sys.argv:
        debug = True

    upgrades = []
    lines = []

    search = re.compile(r'^ARG[ ]+(?P<name>[^=]+)=(?P<value>[^#]+)(?P<comment>|#.+)$')
    with open(__dockerfile, 'r') as fd:
        for line in fd.readlines():
            lines.append(line.rstrip(' \n'))

            groups = search.match(line)
            if groups is not None:
                name = groups.group('name').strip(' \n')
                value = groups.group('value').strip(' \n')
                comment = groups.group('comment').strip(' \n')

                if not name.endswith('_VERSION'):
                    continue

                appname = name.replace('_VERSION', '').lower()

                if appname not in __apps.keys():
                    logging.warning(f"Found {name} variable ({value}), but the method of detecting the latest version hasn't been defined")
                    continue

                func = globals()[f"version_{__apps[appname]['type']}"]
                args = deepcopy(__apps[appname])
                del args['type']

                old_version = value
                new_version = func(**args)

                if old_version != new_version:
                    upgrades.append({
                        'name': name,
                        'value': value,
                        'comment': comment,
                        'appname': appname,
                        'old_version': old_version,
                        'new_version': new_version,
                    })

    for i in range(len(lines)):
        groups = search.match(lines[i])
        if groups is None:
            continue

        name = groups.group('name').strip(' \n')
        value = groups.group('value').strip(' \n')
        comment = groups.group('comment').strip(' \n')
        appname = name.replace('_VERSION', '').lower()
        old_version = ''
        new_version = ''

        if not name.endswith('_VERSION'):
            continue

        for item in upgrades:
            if item['name'] == name and item['value'] == value:
                old_version = item['old_version']
                new_version = item['new_version']
                break

        if old_version == '' and new_version == '':
            continue

        logging.info(f'Upgradeing "{name}" from {old_version} to {new_version}')

        if item['comment'] != '':
            lines[i] = f'ARG {name}={new_version} # {comment}'
        else:
            lines[i] = f'ARG {name}={new_version}'

    if debug:
        for line in lines:
            print(line)
    else:
        with open(__dockerfile, 'w') as fd:
            for line in lines:
                fd.write(f'{line}\n')

if __name__ == '__main__':
    main()
