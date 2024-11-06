#!/bin/bash
function mount_test()
{
	sudo mount -t cifs -o username=xdata //192.168.168.1/data /tmp/test_mount/data
}

function umount_test()
{
	sudo umount /tmp/test_mount/data
}
