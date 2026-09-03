#!/bin/bash

rm -rf /tmp/maia-theme-test
cp -r ~/Documentos/maia-sddm /tmp/maia-theme-test

sddm-greeter-qt6 --test-mode --theme /tmp/maia-theme-test
