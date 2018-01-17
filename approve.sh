#!/bin/bash
while : ; do kubectl get csr --watch | stdbuf -o0 grep Pending | stdbuf -o0 cut -d" " -f 1 | while read l ; do kubectl certificate approve $l ; done; sleep 1; done
