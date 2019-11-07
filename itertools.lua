--[[
  Lua Iteration Toolkit

  A library inspired by the functional programming paradigm found
  in Haskell and Lisp.

  This library is built around the idea that Lua has three ways of
  representing a 'list' -

  Tuples:
    Though they have no first-class representation, every lua program
    handles lists of function arguments, and lists of variables being
    assigned. We can 'interact' with them using varargs and the select
    function

  Tables:
    As sets of pairs of values, tables represent lists as indexable data.
    
  Iterators:
    Iterators are typically stored as tuples - an iterator, invariant,
    and control values. They provide the simplest interface for ordered
    values, and this library primaririly operates on them for the sake
    of efficiency.
]]
local _rawequal, _select = rawequal, select
local function map(fn, iterator, invariant, control)
    local mapped
    local function returner(...)
        if _rawequal(..., nil) then
            return mapped()
        end
        return ...
    end
    local function handler(...)
        control = ...
        if _rawequal(control, nil) then return end
        return returner(fn(...))
    end
    function mapped() return handler(iterator(invariant, control)) end
    return mapped
end
local function filter(fn, ...)
    return map(function(...)
        -- TODO: Find some way to make value a vararg.
        -- Using pack/unpack is too expensive so I'm leaving it at one for now
        local found, value = fn(...)
        if found then
            if _rawequal(value, nil) then
                return ...
            end
            return value
        end
    end, ...)
end
local spread
function spread(iterator, invariant, control)
    control = iterator(invariant, control)
    if _rawequal(control, nil) then return end
    return control, spread(iterator, invariant, control)
end
return {
    -- Iterator > Tuple
    spread = spread,
    -- Iterator > Table
    unpairs = function(...)
        local new = {}
        for k, v in ... do
            new[k] = v
        end
        return new
    end,
    -- Table > Iterator
    pairs = pairs,
    -- Table > Tuple
    unpack = unpack or table.unpack,
    -- Tuple > Iterator
    values = function(...)
        local values, n, i = {...}, _select('#', ...)
        return function()
            if n > i then
                i = i + 1
                return values[i]
            end
        end
    end,
    -- Tuple > Table
    pack = pack or table.pack,
    --[[
        Create a new iterator of the results of calling a
        given function on every element in the provided
        iterator.

        The new iterator is lazy, only consuming the wrapped
        iterator when it is invoked.

        If the function does not return a value on a given
        iteration, the next iteration will immediately be
        invoked, meaning the mapping also acts as a filter.

        Usage:

        spread(map(double, values(20, 4, 18, 6))))
          --> 40, 8, 36, 12
        
        unpairs(map(function(k, v)
            if type(k) == "string" then
                return k, v
            end
        end, pairs {
            foo = 45,
            bar = thing,
            55, 12, false, "Ahw"
        }))
          --> { foo = 45, bar = thing }
    ]]
    map = map,
    --[[
        Create a new iterator of all elements in the provided
        iterator that satisfy a given predicate.

        If a second value is returned by the predicate, it is
        considered the result.

        Usage:

        filter(function(k, v)
            return k:sub(1, 1) == initial, v
        end, pairs(people))
          --> The people whose names match the initial
    ]]
    filter = filter,
    --[[
        Find the first element in the provided iterator that
        satisfies a given predicate.

        Usage:

        find(function(c)
            return c.suit == "Hearts"
        end, df(ipairs(cards)))
          --> A card with the hearts suit
    ]]
    find = function(...)
        return filter(...)()
    end,
    --[[
        Test whether at least one element in the provided
        iterator satisfies a given predicate.

        Usage:

        if some(wordIsProfane, str:gmatch "%w*") then
            -- string contains profanity
        end
    ]]
    some = function(fn, ...)
        return map(function(...)
            if fn(...) then
                return true
            end
        end, ...)() or false
    end,
    --[[
        Test whether all elements in the provided
        iterator satisfy a given predicate.

        Usage:

        if every(isSeated, df(ipairs(Player.getPlayers()))) then
            -- Game can start
        end
    ]]
    every = function(fn, ...)
        return _rawequal(map(function(...)
            if not fn(...) then
                return false
            end
        end, ...)(), nil)
    end,
    --[[
        Wrap an iterator, dropping the first result
        of each iteration.
        
        Simplifies the common pattern of:

        consume(function(_, value)
            return like(value)
        end, ipairs(values))
        
        to:

        consume(like, df(ipairs(values)))
    ]]
    df = function(iterator, invariant, control)
        local function handler(ctrl, ...)
            control = ctrl
            return ...
        end
        return function()
            return handler(iterator(invariant, control))
        end
    end
}