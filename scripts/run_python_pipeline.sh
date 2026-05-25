#!/usr/bin/env bash
set -e
python scripts/python/01_raw_to_interim.py
python scripts/python/02_construct_variables.py
python scripts/python/03_sbm_gml.py
python scripts/python/04_export_for_stata.py
