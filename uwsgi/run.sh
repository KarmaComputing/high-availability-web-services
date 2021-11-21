#!/bin/bash

set -x

uwsgi --master --fastrouter 127.0.0.1:3017 --fastrouter-subscription-server 127.0.0.1:7000 --emperor ./vassals/*/*.ini

