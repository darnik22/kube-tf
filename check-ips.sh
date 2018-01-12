#!/bin/bash
cat instance-ips.out | xargs -d' ' -I{} ssh-keygen -R {}
#cat instance-ips.out | xargs -d' ' -I{} ssh-keyscan {} >> ~/.ssh/known_hosts
cat instance-ips.out | xargs -d' ' -I{} ssh -o StrictHostKeyChecking=no {} hostname
