-- chunkname: @src.battle.models.target.include

local battleTarget = {}

globals.battleTarget = battleTarget

require("battle.models.target.target2")
require("battle.models.target.target")

local skillChooseTypeTb

function globals.newTargetFinder(caster, selectedObj, chooseType, args, cfg)
	local easyCfg = {}

	if cfg and next(cfg) then
		easyCfg = cfg

		if args and args.allProcessesTargets then
			args.inputUseOtherProcess = functools.partial(battleTarget.inputUseOtherProcessByIds, args.allProcessesTargets)
			args.processUseOtherProcess = functools.partial(battleTarget.processUseOtherProcessBySeats, args.allProcessesTargets)
		end
	else
		if skillChooseTypeTb[chooseType] == nil then
			printWarn("chooseType %d no implement in skillChooseTypeTb", chooseType)
		end

		easyCfg = skillChooseTypeTb[chooseType](args, caster)

		if args and args.specialChoose and easyCfg.process then
			local attrFuncStr = battle.specialChooseAttrTb[args.specialChoose]
			local pstr = string.format("%s|%s", easyCfg.process, attrFuncStr)

			if easyCfg.process == "" then
				pstr = attrFuncStr
			end

			easyCfg.process = pstr
		end

		if args and args.targetLimit and easyCfg.process then
			local pstr = string.format("%s|random(%s)", easyCfg.process, args.targetLimit)

			easyCfg.process = pstr
		end
	end

	if easyCfg.input and args then
		if args.outside then
			local processStr = easyCfg.process and easyCfg.process or ""

			easyCfg.process = processStr .. "|" .. args.outside
		end

		if args.skillType == battle.SkillType.PassiveSkill and caster and battleEasy.isCompleteLeave(caster) and chooseType ~= battle.skillTargetChooseType.ObjectEx then
			args.inputExtraStr = string.format("leaveExtraDeal({casterId=%s})", caster.id)
		end

		if args.inputExtraStr then
			easyCfg.input = easyCfg.input .. "|" .. args.inputExtraStr
		end
	end

	if not easyCfg.input and not easyCfg.process then
		return {}
	end

	return battleTarget.targetFinder(caster, selectedObj, easyCfg, args)
end

function globals.newTargetTypeFinder(chooseType, parms)
	return skillChooseTypeTb[chooseType](parms)
end

function battleTarget.inputUseOtherProcessByIds(allTargets, ...)
	local processIds = {
		...
	}
	local ret = {}

	for _, processId in ipairs(processIds) do
		if allTargets[processId] then
			for _, obj in ipairs(allTargets[processId].targets) do
				if not obj:isAlreadyDead() then
					table.insert(ret, obj)
				end
			end
		end
	end

	return ret
end

function battleTarget.processUseOtherProcessBySeats(allTargets, func, preTargets, ...)
	local processIds = {
		...
	}
	local seats = {}

	for _, processId in ipairs(processIds) do
		if allTargets[processId] then
			for _, obj in ipairs(allTargets[processId].targets) do
				table.insert(seats, obj.seat)
			end
		end
	end

	local targets = battleTarget.process[func](seats, preTargets)

	return targets
end

function battleTarget.findOtherProcessParams(src, ctrl)
	src = string.trim(src)

	local _, otherProcessStart = string.find(src, ctrl)

	if otherProcessStart then
		local otherProcessEnd = string.find(src, "%)")
		local nums = src:sub(otherProcessStart + 1, otherProcessEnd - 1)
		local numSegs = string.split(nums, ",")

		return numSegs
	else
		return nil
	end
end

local function makeExpectTargets(otherProcessTb, allTargets, key)
	local expectTarget = {}

	for _, v in ipairs(otherProcessTb) do
		local processId = tonumber(v)

		if allTargets[processId] then
			for _, obj in ipairs(allTargets[processId].targets) do
				table.insert(expectTarget, obj[key])
			end
		end
	end

	return expectTarget
end

function battleTarget.otherProcessFinder(process, allTargets)
	local s = process

	if not s or s == "" then
		return ""
	end

	s = string.trim(s)

	if s:sub(1, 1) == "|" then
		s = s:sub(2)
	end

	local segs = string.split(s, "|")
	local result = {}

	for i, seg in ipairs(segs) do
		local expectTarget = {}
		local hasOtherExcept = battleTarget.findOtherProcessParams(seg, "otherProcessExcept%(")

		if hasOtherExcept then
			expectTarget = makeExpectTargets(hasOtherExcept, allTargets, "seat")

			table.insert(result, string.format("exclude({%s})", table.concat(expectTarget, ",")))
		else
			local useOtherProcess = battleTarget.findOtherProcessParams(seg, "useOtherProcess%(")

			if useOtherProcess then
				expectTarget = makeExpectTargets(useOtherProcess, allTargets, "seat")

				table.insert(result, string.format("include({%s})", table.concat(expectTarget, ",")))
			else
				table.insert(result, seg)
			end
		end
	end

	return table.concat(result, "|")
end

local targetSingleTb1 = {
	true,
	[19] = true,
	[13] = true,
	[14] = true
}
local targetSingleTb2 = {
	[20] = true,
	[21] = true,
	[22] = true
}

function globals.isProcessTargetSingle(processCfg)
	if targetSingleTb1[processCfg.skillTarget] then
		return true
	elseif targetSingleTb2[processCfg.skillTarget] and processCfg.targetLimit <= 1 then
		return true
	end

	return false
end

local forceNoDead = {
	[0] = "enemyForce|nodead",
	"selfForce|nodead",
	"all|nodead"
}

skillChooseTypeTb = {
	function(args)
		local easyCfg = {
			input = "selected"
		}

		return easyCfg
	end,
	function(args)
		local str = args and forceNoDead[args.friendOrEnemy] or ""
		local easyCfg = {
			process = "rowfront",
			input = str
		}

		return easyCfg
	end,
	function(args)
		local str = args and forceNoDead[args.friendOrEnemy] or ""
		local easyCfg = {
			process = "rowback",
			input = str
		}

		return easyCfg
	end,
	function(args)
		local str = args and forceNoDead[args.friendOrEnemy] or ""
		local easyCfg = {
			process = "column",
			input = str
		}

		return easyCfg
	end,
	[11] = function(args)
		local str = args and forceNoDead[args.friendOrEnemy] or ""
		local easyCfg = {
			process = "",
			input = str
		}

		return easyCfg
	end,
	[12] = function(args)
		local easyCfg = {
			input = "enemyForce|nodead",
			process = "near"
		}

		return easyCfg
	end,
	[13] = function(args)
		local easyCfg = {
			input = string.format("object(%d)", args.specialChoose)
		}

		return easyCfg
	end,
	[14] = function(args)
		local easyCfg = {
			input = "myself"
		}

		return easyCfg
	end,
	[15] = function(args)
		local easyCfg = {
			input = "myself|selfForce",
			process = "near"
		}

		return easyCfg
	end,
	[16] = function(args)
		local easyCfg = {
			input = "selfForce",
			process = "selfColumn"
		}

		return easyCfg
	end,
	[17] = function(args)
		local easyCfg = {
			input = "selfForce()|nodead",
			process = "selfRow"
		}

		return easyCfg
	end,
	[18] = function(args)
		local easyCfg = {
			input = "selected|nodead",
			process = "near"
		}

		return easyCfg
	end,
	[19] = function()
		local easyCfg = {
			input = "whokill|nodead"
		}

		return easyCfg
	end,
	[20] = function(args)
		local str = args and forceNoDead[args.friendOrEnemy] or ""
		local limit = 1

		if args and args.targetLimit then
			limit = args.targetLimit
		end

		local easyCfg = {
			input = str,
			process = "random(" .. limit .. ")"
		}

		return easyCfg
	end,
	[21] = function(args)
		local str = args and forceNoDead[args.friendOrEnemy] or ""
		local limit = 1

		if args and args.targetLimit then
			limit = args.targetLimit
		end

		local easyCfg = {
			input = str,
			process = "frontRowRandom(" .. limit .. ")"
		}

		return easyCfg
	end,
	[22] = function(args)
		local str = args and forceNoDead[args.friendOrEnemy] or ""
		local limit = 1

		if args and args.targetLimit then
			limit = args.targetLimit
		end

		local easyCfg = {
			input = str,
			process = "backRowRandom(" .. limit .. ")"
		}

		return easyCfg
	end,
	[23] = function(args, caster)
		local force = args.friendOrEnemy == 1 and caster.force or 3 - caster.force
		local easyCfg = {
			input = string.format("objectEx(%d,%d)", force, args.specialChoose)
		}

		return easyCfg
	end,
	[24] = function(args)
		return {}
	end,
	[25] = function(args)
		local input1 = "selfForce()"
		local input2 = "enemyRow(1, true)"
		local easyCfg = {
			input = "And(" .. input1 .. "," .. input2 .. ")"
		}

		return easyCfg
	end
}
