"""
The dataset is not downloadable via the here function from r.
Instead we can use the kagglehub python api to do it or other methods
(see data/raw/LICENCE.txt Source).
Note: This only works if data/raw is empty. You may set force_download=True,
      but this will delete all other files in data/raw.

Run this file with these steps in your terminal (check if python and pip are installed):

# Create your python venv
python -m venv venv

# Activate the venv
venv/Scripts/activate

# Install kagglehub to the venv
pip install kagglehub

# Execute this file
python code/01_download.py
"""

import kagglehub  # type: ignore

# Download latest version
kagglehub.dataset_download("laveshjadon/ai-impact-on-students", output_dir="data/raw")
