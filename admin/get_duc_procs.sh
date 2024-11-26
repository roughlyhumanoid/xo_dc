#!/bin/bash
/usr/bin/ps -eo user,pid,ppid,stime,etime,command | grep '\/usr\/bin\/duc'
