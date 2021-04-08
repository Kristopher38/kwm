local sides = require("sides")
local computer = require("computer")
local event = require("event")
local filesystem = require("filesystem")

local utils = {}

-- checks if element already exists in a table
function utils.hasValue(tab, value)
	for k, v in pairs(tab) do
		if v == value then
			return true
		end
	end
	return false
end

function utils.hasKey(tab, key)
	return tab[key] ~= nil
end

function utils.keys(tab)
	local ks = {}
	for k, v in pairs(tab) do
		table.insert(ks, k)
	end
	return ks
end

function utils.values(tab)
	local vs = {}
	for k, v in pairs(tab) do
		table.insert(vs, v)
	end
	return vs
end

function utils.findIndex(tab, value)
	for i, v in ipairs(tab) do
		if v == value then
			return i
		end
	end
end

function utils.round(x)
	return x >= 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)
end

--[[ measures how much time execution of a function took, returns
function return value, real execution time and cpu execution time,
and additionally prints execution times --]]
function utils.timeIt(doPrint, func, ...)
	local args = {...}
	if type(doPrint) == "function" then
		table.insert(args, 1, func)
		func = doPrint
	end
	local realBefore, cpuBefore = computer.uptime(), os.clock()
	local returnVals = table.pack(func(table.unpack(args)))
	local realAfter, cpuAfter = computer.uptime(), os.clock()

	local realDiff = realAfter - realBefore
	local cpuDiff = cpuAfter - cpuBefore

	if doPrint then
		print(string.format('real%5dm%.3fs', math.floor(realDiff/60), realDiff%60))
		print(string.format('cpu %5dm%.3fs', math.floor(cpuDiff/60), cpuDiff%60))
	end

	return returnVals, realDiff, cpuDiff
end

--[[ measures how much energy execution of a function took, returns
function return value, energy difference, and additionally prints
execution times --]]
function utils.energyIt(doPrint, func, ...)
	local args = {...}
	if type(doPrint) == "function" then
		table.insert(args, 1, func)
		func = doPrint
	end
	local before = computer.energy()
	local returnVal = func(table.unpack(args))
	local after = computer.energy()

	local diff = after - before
	if doPrint then
		print(string.format("Energy difference: %f", diff))
	end

	return returnVal, diff
end

--[[ force Lua garbage collector to run, credits to Akuukis and Sangar,
check https://oc.cil.li/topic/243-memory-management/ --]]
function utils.freeMemory()
	local result = 0
	for i = 1, 10 do
	  result = math.max(result, computer.freeMemory())
	  os.sleep(0)
	end
	return result
end

-- waits for a keypress
function utils.waitForInput()
	event.pull("key_down")
end

-- checks if object is an instance of class by comparing metatables
function utils.isInstance(instance, class)
	return class ~= nil and getmetatable(instance) == class
end

--[[ deepcopy a table, credits to tylerneylon,
check https://gist.github.com/tylerneylon/81333721109155b2d244 --]]
function utils.deepCopy(obj, seen)
	-- Handle non-tables and previously-seen tables.
	if type(obj) ~= 'table' then
		return obj
	end
	if seen and seen[obj] then
		return seen[obj]
	end

	-- New table; mark it as seen an copy recursively.
	local s = seen or {}
	local res = {}
	s[obj] = res
	for k, v in next, obj do
		res[utils.deepCopy(k, s)] = utils.deepCopy(v, s)
	end
	setmetatable(res, getmetatable(obj))
	return res
end

function utils.shallowCompare(obj1, obj2, ignoreKeys)
	ignoreKeys = ignoreKeys or {}
	for k, v in pairs(obj1) do
		if not utils.hasValue(ignoreKeys, k) and (obj2[k] == nil or obj2[k] ~= v) then
			return false
		end
	end
	for i, v in ipairs(obj1) do
		if obj2[i] == nil or obj2[i] ~= v then
			return false
		end
	end
	return true
end

function utils.merge(t, ...)
    local tables = table.pack(...)
    for i = 1, #tables do
        for k, v in pairs(tables[i]) do
            if type(v) == "table" and type(rawget(t, k)) == "table" then
                utils.merge(rawget(t, k), v)
            else
                rawset(t, k, v)
            end
        end
        if getmetatable(t) and getmetatable(tables[i]) then
            --utils.merge(getmetatable(t), getmetatable(tables[i]))
        end
    end
    return t
end

function utils.makeClass(constructor)
    assert(type(constructor) == "function", "Class constructor has to be a function")
    local class = {}
    class.__index = class

    local mt = {}
    -- set up calling the constructor when () operator is used
    mt.__call = function(cls, ...)
        local self = {}
        setmetatable(self, cls)
        constructor(self, ...)
        return self
    end

    class.__initBase = function(self, ...)
        local parents = table.pack(...)
        if #parents > 0 then
            -- set up inheritance - in case of single inheritance it uses __index pointing to another table
            -- in case of multiple inheritance it uses __index pointing to a function which searches for a valid key in base classes
            mt.__index = #parents == 1 and getmetatable(parents[1]) or function(cls, k)
                for i = 1, #parents do
                    local parentClass = getmetatable(parents[i])
                    if parentClass and parentClass[k] then
                        return parentClass[k]
                    end
                end
            end
            for i = 1, #parents do
                for member, value in pairs(parents[i]) do
                    self[member] = value
                end
            end
        end
    end

    setmetatable(class, mt)
    return class
end

--[[ compares two item tables, only by name and label fields if they exist in both tables describing an item --]]
function utils.compareItems(first, second)
    return ((first.name and second.name) and first.name == second.name or not (first.name and second.name)) and
           ((first.label and second.label) and first.label == second.label or not (first.label and second.label)) and
           ((first.damage and second.damage) and first.damage == second.damage or not (first.damage and second.damage))
end

function utils.realTime()
    local tmpName = os.tmpname()
    -- make sure we have space in /tmp first
    for file in filesystem.list("/tmp") do
        filesystem.remove(filesystem.concat("/tmp", file))
    end
    local tmpFile = filesystem.open(tmpName, "a") -- touch file
    if tmpFile then
        tmpFile:close()
        local timestamp = filesystem.lastModified(tmpName) / 1000
        filesystem.remove(tmpName)
        return timestamp
    else
        return 0
    end
end

return utils