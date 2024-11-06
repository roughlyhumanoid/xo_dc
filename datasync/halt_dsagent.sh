#!/bin/bash
# virsh list --all | grep datasync | awk '{print $3}'
virsh shutdown datasync

