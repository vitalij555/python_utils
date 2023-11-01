
from .logging.logging_init import load_logging_config

DEFAULT_LOGGING_CONFIG_FILE = "../configuration/logging_config.json"
logger = load_logging_config(DEFAULT_LOGGING_CONFIG_FILE)