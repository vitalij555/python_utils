import json

import os.path
from pathlib import Path

import importlib

# Dynamically import the original logging module
original_logging = importlib.import_module('logging')
original_logging_config = importlib.import_module('logging.config')

def load_logging_config(logging_file: Path):
    config = None
    print(f"Logging config file is {os.path.abspath(logging_file)}")
    with open(logging_file, 'r') as config_file:
        config = json.load(config_file)

    original_logging_config.dictConfig(config['logging'])
    logger = original_logging.getLogger(__name__)

    return logger