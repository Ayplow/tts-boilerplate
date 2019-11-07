#!/bin/sh
find -name "*.lua" | entr -s "lua-vfs --preload | ttscli set-script"