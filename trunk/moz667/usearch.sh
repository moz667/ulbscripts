#!/bin/sh

# Busca las uses que le pasamos como parametro

for arg in $*
do
	grep "$arg - " /usr/portage/profiles/use.desc
done
