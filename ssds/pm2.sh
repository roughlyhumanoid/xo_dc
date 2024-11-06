#!/bin/bash
aws cloudwatch put-metric-data --metric-name ssd-online --dimensions SSD_name=998 --namespace "XOCEAN_DC" --value 1
