#!/bin/bash

# Load environment variables from .env file
set -a
source .env
set +a

# Execute the provided command (e.g., gleam build or gleam run)
exec "$@"
