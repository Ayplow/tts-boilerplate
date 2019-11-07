loadfile "default_require.lua" ()
local itertools = require "itertools"
local data = io.open "data.json"
function onLoad()
    print("Hey", JSON.decode(data:read "*a")[1][1])
    for v in itertools.map(function(k, v)
        return v * 2
    end, ipairs { 5,7,2,76,4 }) do
        print(":", v)
    end
end