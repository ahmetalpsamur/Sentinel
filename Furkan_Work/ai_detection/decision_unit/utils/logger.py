import logging
import os

def setup_logger(module_name=None, log_dir=None):

    module_name = module_name or "decision_unit"
    log_dir = log_dir or "DU_Logs"
    log_file = os.path.join(log_dir, f"{module_name}.log")

    os.makedirs(os.path.dirname(log_file), exist_ok=True)

    logger = logging.getLogger(module_name)
    logger.setLevel(logging.INFO)

    formatter = logging.Formatter('%(asctime)s — %(levelname)s — %(message)s')

    file_handler = logging.FileHandler(log_file)
    file_handler.setFormatter(formatter)

    if not logger.hasHandlers():
        logger.addHandler(file_handler)

    return logger
