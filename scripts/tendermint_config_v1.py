#!/usr/bin/env python3
import json
import re
import sys
from base64 import b64decode

(TENDERMINT_USER,  # str
 GENESIS_TIME,  # str
 CHAIN_ID,  # str
 B64_VALIDATORS,  # base64 encoded json string
 VALIDATOR_POWERS,  # comma separated string of ints or `default`
 NODE_IDS,  # comma separated list of node ids
 NODE_IPS  # comma separated list of node ips
 ) = sys.argv[1:]

#GENESIS_FILE = ('/home/{tu}/.tendermint/config/genesis.json'
#                .format(tu=TENDERMINT_USER))
#TM_CONFIG_FILE = ('/home/{tu}/.tendermint/config/config.toml'
#                  .format(tu=TENDERMINT_USER))
GENESIS_FILE = '/root/.tendermint/config/genesis.json'
TM_CONFIG_FILE = '/root/.tendermint/config/config.toml'

def edit_genesis() -> None:
    """Insert validators genesis time and chain_id to genesis file."""

    validators = json.loads('[{}]'.format(b64decode(B64_VALIDATORS).decode()))

    # Update validators powers
    for v, p in zip(validators, VALIDATOR_POWERS.split(',')):
        if p != 'default':
            v['power'] = p

    with open(GENESIS_FILE, 'r') as gf:
        genesis_conf = json.load(gf)
        genesis_conf['validators'] = validators
        genesis_conf['genesis_time'] = GENESIS_TIME
        genesis_conf['chain_id'] = CHAIN_ID

    with open(GENESIS_FILE, 'w') as gf:
        json.dump(genesis_conf, gf, indent=True)

    return None


def edit_config() -> None:
    """Insert peers ids and addresses to tendermint config file."""

    ips = NODE_IPS.split(',')
    ids = NODE_IDS.split(',')

    persistent_peers = ',\\\n'.join([
        '{}@{}:26656'.format(nid, nip) for nid, nip in zip(ids, ips)
    ])

    with open(TM_CONFIG_FILE, 'r') as f:
        tm_config_toml = f.read()

    with open(TM_CONFIG_FILE, 'w') as f:
        f.write(
            re.sub(
                r'^persistent_peers\s*=\s*".*"',
                r'persistent_peers="{pp}"'.format(pp=persistent_peers),
                tm_config_toml,
                flags=re.MULTILINE
            )
        )

    with open(TM_CONFIG_FILE, 'r') as f:
        tm_config_toml = f.read()

    s1 = re.sub(
                'addr_book_strict = true',
                'addr_book_strict = false',
                tm_config_toml
            )

    s2 = re.sub(
                'size = 5000',
                'size = 100000',
                s1
            )

    s3 = re.sub(
                'max-packet-msg-payload-size = 1400',
                'max-packet-msg-payload-size = 4096',
                s2
            )

    s4 = re.sub(
                'send-rate = 5120000',
                'send-rate = 20000000',
                s3
            )

    s5 = re.sub(
                'recv-rate = 5120000',
                'recv-rate = 20000000',
                s4
            )
            
    s4 = re.sub(
               'log_level = "main:info,state:info,\*:error"',
               'log_level = "*:info"',
               s3
            )

    with open(TM_CONFIG_FILE, 'w') as f:
        f.write(s2)

    return None


if __name__ == '__main__':
    edit_genesis()
    edit_config()
