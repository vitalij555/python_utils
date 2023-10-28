import json
import logging.config
from pathlib import Path


def load_logging_config(logging_file: Path):
    with open(logging_file, 'r') as config_file:
        config = json.load(config_file)

    logging.config.dictConfig(config['logging'])

