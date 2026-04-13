#!/bin/bash

script_dir=$(dirname "$(realpath "$0")")

result=$(pip list | grep psutil)
if [ -z "$result" ]; then
    echo "psutil is not installed, installing..."
    pip install psutil
else
    echo "psutil is already installed"
fi

python3 "$script_dir/install.py"
