#!/usr/bin/env bash
set -ex

VENV_DIR="emr-cost-reporter-venvs"
mkdir -p $VENV_DIR

rm -rf $VENV_DIR/*
VENV="$VENV_DIR/venv_$BUILD_ID"
virtualenv $VENV
. $VENV/bin/activate

cd emr-cost-calculator
pip install -r requirements.txt

# Calculate costs for all clusters that were created in the last 24 hours
COST=$(python emr_cost_calculator.py total --output cloudwatch --output text)

# If today is Tuesday, then we are analyzing clusters from Monday, when we run weekly jobs, so we raise the threshold accordingly
if [ "x$(date +%u)" = "x2" ]
then
    echo "Today is tuesday, adjusting the threshold up by \$${WEEKLY_JOB_THRESHOLD_ADJUSTMENT} to account for weekly jobs that run on Monday."
    THRESHOLD=$((${THRESHOLD} + ${WEEKLY_JOB_THRESHOLD_ADJUSTMENT}))
fi

if [ "$(echo "${COST}>${THRESHOLD}" | bc)" = "1" ]
then
    echo "Actual cost \$${COST} exceeded the adjusted threshold of \$${THRESHOLD}, failing."
    exit 1
else
    exit 0
fi
