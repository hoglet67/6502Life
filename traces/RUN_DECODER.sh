#!/bin/bash
decode6502 --cpu=65c02 --phi2= --quiet --mem=00f --trigger=2a91,2995,1 --labels=../BLIFE42.labels  --profile=instr  run1.bin > run1.instr
decode6502 --cpu=65c02 --phi2= --quiet --mem=00f --trigger=2a91,2995,1 --labels=../BLIFE42.labels  --profile=call  run1.bin > run1.call
