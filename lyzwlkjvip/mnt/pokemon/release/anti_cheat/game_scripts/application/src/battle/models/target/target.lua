-- chunkname: @src.battle.models.target.target

local FindBaseEnv = {}

function battleTarget.InitFindBaseEnv()
	local env = maptools.extend({
		battleTarget.input,
		battleTarget.input.decorator,
		battleTarget.process
	})

	for k, f in pairs(env) do
		if type(f) == "function" then
			setfenv(f, env)
		end
	end

	env.battle = battle
	env.assertInWindows = assertInWindows
	env.assertInWindowsNoReport = assertInWindowsNoReport
	FindBaseEnv = protectedEnv(env)
end

battleTarget.InitFindBaseEnv()

local function conv2funcStr(s, input)
	if s:sub(1, 1) == "|" then
		s = s:sub(2)
	end

	local segs = string.split(s, "|")
	local funcStr = input or ""

	for i, seg in ipairs(segs) do
		local nullInfo, _ = string.find(seg, "%(.+%)")
		local ps, _ = string.find(seg, "%(.*%)")
		local patten = ""
		local len = -2

		if not ps then
			seg = seg .. "()"
		end

		if funcStr == "" then
			funcStr = seg
		else
			seg = seg:sub(1, len) .. (nullInfo and ",%s)" or "%s)")
			funcStr = string.format(seg, funcStr)
		end
	end

	return funcStr
end

function battleTarget.targetFinder(caster, selectedObj, config, args)
	local funcStr = config.input

	if config.process and config.process ~= "" then
		funcStr = string.format("%s|%s", config.input, config.process)
	end

	funcStr = conv2funcStr(funcStr)

	local env = battleCsv.makeFindEnv(caster, selectedObj, args)

	FindBaseEnv:fillEnv(env)

	local ret = battleCsv.doFindFormula(funcStr, FindBaseEnv, env.csvEnv)

	FindBaseEnv:resetEnv()
	lazylog.battle.target.find({
		funcStr = funcStr,
		n = function()
			return itertools.size(ret)
		end
	})
	lazylog.battle.target.findDetails({
		n = function()
			return itertools.size(ret)
		end,
		targets = function()
			for k, obj in pairs(ret) do
				print(string.format("%s:\t%s %d", k, tostring(obj), obj.seat))
			end

			return ret
		end
	})

	return ret
end
