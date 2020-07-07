#!/usr/bin/env bash

export S6_KEEP_ENV=1
export S6_BEHAVIOUR_IF_STAGE2_FAILS=2
export S6_FIX_ATTRS_HIDDEN=1

exec /init $@