local function isAddAttackRangeObjs(env, obj)
	if env.addAttackRangeObjs and env.addAttackRangeObjs[obj.id] then
		return true
	end

	return false
end

local input = {}

battleTarget.input = input

function input.myself()
	env.force = self.force
	env.selectObj = self

	return {
		self
	}
end

function input.selected()
	env.force = selectObj and selectObj.force or env.force

	return {
		selectObj
	}
end

function input.secSelected()
	return env.secSelectObjs
end

function input.object(id)
	local object = self.scene:getObjectBySeatExcludeDead(id)

	env.force = object and object.force or env.force
	env.selectObj = object

	return {
		object
	}
end

function input.objectEx(force, id)
	local object = self.scene:getGroupObj(force, id)

	env.force = object and object.force or env.force
	env.selectObj = object

	return {
		object
	}
end

local function addNormalSelectExobjs(env, ret, force)
	if env.getSelectableExObj then
		local exObjs = env.self.scene:getAllNormalSelectExobjs(force)

		for _, exObj in ipairs(exObjs) do
			table.insert(ret, exObj)
		end
	end
end

function input.all()
	env.force = selectObj and selectObj.force or env.force

	local iter1 = itertools.iter(self.scene:getHerosMap(1):pairs())
	local iter2 = itertools.iter(self.scene:getHerosMap(2):pairs())
	local ret = itertools.values(itertools.chain({
		iter1,
		iter2
	}))

	addNormalSelectExobjs(env, ret)
	table.sort(ret, function(o1, o2)
		return o1.id < o2.id
	end)

	return ret
end

function input.allEx(followMarks)
	env.force = selectObj and selectObj.force or env.force

	local ret = {}

	for _, exObj in self.scene.extraHeros:order_pairs() do
		if not followMarks or itertools.include(followMarks, exObj.followMark) then
			table.insert(ret, exObj)
		end
	end

	return ret
end

function input.allBack()
	env.force = selectObj and selectObj.force or env.force

	local ret = {}

	for _, obj in self.scene.backHeros:order_pairs() do
		table.insert(ret, obj)
	end

	return ret
end

local function alterSelfForce(self)
	for _, data in self:ipairsOverlaySpecBuffTo("confusion") do
		if data.alterSelfForce then
			return true
		end
	end

	return false
end

function input.selfForce(alterForce)
	env.force = self.force

	local isSpellTo = self.curSkill and self.curSkill.isSpellTo
	local needAlterForce = not alterForce and isSpellTo and alterSelfForce(self)
	local realForce = needAlterForce and 3 - self.force or self.force

	env.force = realForce

	local map = self.scene:getHerosMap(realForce)
	local ret = itertools.values(map:order_pairs())

	addNormalSelectExobjs(env, ret, realForce)

	return arraytools.filter(ret, function(_, obj)
		return not isAddAttackRangeObjs(env, obj)
	end)
end

function input.selfForceEx(followMarks)
	env.force = self.force

	local ret = {}

	for _, exObj in self.scene.extraHeros:order_pairs() do
		if exObj.force == env.force and (not followMarks or itertools.include(followMarks, exObj.followMark)) then
			table.insert(ret, exObj)
		end
	end

	return ret
end

function input.selfForceBack()
	env.force = self.force

	local ret = {}

	for _, obj in self.scene.backHeros:order_pairs() do
		if obj.force == env.force then
			table.insert(ret, obj)
		end
	end

	return ret
end

local function needAlterForce(self)
	if not self.curSkill then
		return false
	end

	local target = self:getCurTarget()

	if target and self:isSameForce(target.force) and (self:isBeInConfusion() or self:isBeInSneer()) and self.curSkill:isSameType(battle.SkillFormulaType.damage) then
		return true
	end

	return false
end

function input.enemyForce(noAlterForce)
	env.force = 3 - self.force

	local enemyForce = 3 - self.force
	local isSpellTo = self.curSkill and self.curSkill.isSpellTo
	local needAlterForce = not noAlterForce and needAlterForce(self) and isSpellTo

	if needAlterForce then
		enemyForce = self.force
	end

	env.force = enemyForce

	local map = self.scene:getHerosMap(enemyForce)
	local ret = itertools.values(map:order_pairs())

	addNormalSelectExobjs(env, ret, enemyForce)

	if needAlterForce then
		ret = arraytools.filter(ret, function(_, obj)
			return obj.id ~= self.id
		end)
	end

	return attackRangeExtension(env, ret)
end

function input.enemyForceEx(followMarks)
	env.force = 3 - self.force

	local ret = {}

	for _, exObj in self.scene.extraHeros:order_pairs() do
		if exObj.force == env.force and (not followMarks or itertools.include(followMarks, exObj.followMark)) then
			table.insert(ret, exObj)
		end
	end

	return ret
end

function input.enemyForceBack()
	env.force = 3 - self.force

	local ret = {}

	for _, obj in self.scene.backHeros:order_pairs() do
		if obj.force == env.force then
			table.insert(ret, obj)
		end
	end

	return ret
end

function input.enemyRow(front, recursion)
	local force = self.force == 1 and 2 or 1
	local cnt, ret = self.scene:getRowRemain(force, front, env.getSelectableExObj)

	if cnt == 0 and recursion then
		front = front == 1 and 2 or 1
		cnt, ret = self.scene:getRowRemain(force, front, env.getSelectableExObj)
	end

	return ret
end

function input.And(input1, input2)
	local ret = {}
	local map = {}

	for _, target in ipairs(input1) do
		table.insert(ret, target)

		map[target.id] = true
	end

	for _, target in ipairs(input2) do
		if not map[target.id] then
			table.insert(ret, target)

			map[target.id] = true
		end
	end

	table.sort(ret, function(o1, o2)
		return o1.id < o2.id
	end)

	return ret
end

function input.selectedTwoColumn(isAllAround)
	env.force = selectObj and selectObj.force or env.force

	local _, baseColumn = getRowAndColumn(selectObj)
	local map = self.scene:getHerosMap(env.force)
	local objs = {}

	objs[baseColumn], objs[baseColumn - 1], objs[baseColumn + 1] = {}, {}, {}

	local function sortObjs(obj)
		local __, curColumn = getRowAndColumn(obj)

		if objs[curColumn] then
			table.insert(objs[curColumn], obj)
		end
	end

	for _, obj in map:order_pairs() do
		sortObjs(obj)
	end

	local exObjs = {}

	addNormalSelectExobjs(env, exObjs, env.force)

	for _, exObj in ipairs(exObjs) do
		sortObjs(exObj)
	end

	if not isAllAround and table.length(objs[baseColumn - 1]) > 0 and table.length(objs[baseColumn + 1]) > 0 then
		local rand = ymrand.random(1, 2)

		if rand == 1 then
			objs[baseColumn - 1] = {}
		else
			objs[baseColumn + 1] = {}
		end
	end

	local ret = arraytools.merge({
		objs[baseColumn - 1],
		objs[baseColumn],
		objs[baseColumn + 1]
	})

	return ret
end

function input.surroundTargets(target)
	if not target then
		return {}
	end

	local baseRow, baseCol = getRowAndColumn(target)
	local heroMap = target.scene:getHerosMap(target.force)
	local ret = {}

	local function sortObjs(obj)
		if obj and not obj:isDeath() then
			local row, col = getRowAndColumn(obj)

			if row == baseRow or col == baseCol then
				table.insert(ret, obj)
			end
		end
	end

	for id, obj in heroMap:order_pairs() do
		sortObjs(obj)
	end

	local exObjs = {}

	addNormalSelectExobjs(env, exObjs, target.force)

	for _, exObj in ipairs(exObjs) do
		sortObjs(exObj)
	end

	ret = arraytools.filter(ret, function(id, obj)
		return obj.id ~= target.id
	end)

	return ret
end

function input.casterForce()
	env.force = self.force

	local map = self.scene:getHerosMap(env.force)
	local ret = itertools.values(map:order_pairs())

	addNormalSelectExobjs(env, ret, env.force)

	return ret
end

function input.holderForce()
	env.force = selectObj.force

	local map = self.scene:getHerosMap(env.force)
	local ret = itertools.values(map:order_pairs())

	addNormalSelectExobjs(env, ret, env.force)

	return ret
end

function input.surroundHolder()
	return input.surroundTargets(selectObj)
end

function input.surroundCaster()
	return input.surroundTargets(self)
end

function input.lastProcessTargets()
	return env.extraTargets and env.extraTargets[battle.BuffExtraTargetType.lastProcessTargets] or {}
end

function input.whoAttackHolder()
	local obj = selectObj and selectObj.curAttackMeObj

	return obj and {
		obj
	} or {}
end

function input.holderDamageTargets()
	local runSkill = selectObj.curSkill

	if runSkill then
		return runSkill.allDamagedOrder
	end

	return {}
end

function input.holderEnemyForce()
	env.force = 3 - selectObj.force

	local map = selectObj.scene:getHerosMap(env.force)
	local ret = itertools.values(map:order_pairs())

	addNormalSelectExobjs(env, ret, env.force)

	return ret
end

function input.casterEnemyForce()
	env.force = 3 - self.force

	local map = self.scene:getHerosMap(env.force)
	local ret = itertools.values(map:order_pairs())

	addNormalSelectExobjs(env, ret, env.force)

	return ret
end

function input.skillOwner()
	local skill = env.trigger and env.trigger.skill

	if skill then
		return skill.model and {
			skill.model.owner
		} or {}
	end

	return {}
end

function input.whoKillHolder()
	return {
		selectObj.attackMeDeadObj
	}
end

function input.segProcessTargets()
	return env.extraTargets and env.extraTargets[battle.BuffExtraTargetType.segProcessTargets] or {}
end

function input.surroundHolderKill()
	return input.surroundTargets(env.trigger)
end

function input.triggerObject()
	return env.trigger and {
		env.trigger.obj
	} or {}
end

function input.segProcessTargetsRandom()
	local target = selectObj and selectObj:getCurTarget()

	if target then
		return {
			target
		}
	end

	local targets = input.segProcessTargets()
	local ret = process.random(1, targets)

	return ret
end

local function lastRoundActOrder(self, force, checkObjFunc)
	local ret = {}
	local play = self.scene.play

	for _, v in ipairs(play.lastRoundAttackedHistory) do
		local obj = self.scene:getFieldObject(v.id)

		if checkObjFunc(force, obj, self) then
			table.insert(ret, obj)
		end
	end

	return ret
end

local function actionOrderArray(self, force, checkObjFunc)
	local ret = {}
	local play = self.scene.play
	local selfIndex = 0

	for k, v in ipairs(play.roundHasAttackedHistory) do
		local obj = self.scene:getFieldObject(v.id)

		if checkObjFunc(force, obj, self) then
			table.insert(ret, obj)

			selfIndex = obj.id == self.id and table.length(ret) or selfIndex
		end
	end

	for k, obj in ipairs(play.attackerArray) do
		if checkObjFunc(force, obj, self) then
			table.insert(ret, obj)

			selfIndex = obj.id == self.id and table.length(ret) or selfIndex
		end
	end

	return ret, selfIndex
end

function input.absoluteActionOrder(camp, orders)
	local added, ret = {}, {}
	local actionArray = actionOrderArray(self, camp, function(force, obj, fromObj)
		if not obj or obj:isRealDeath() then
			return false
		end

		if obj.force ~= force then
			return false
		end

		if obj:isLogicStateExit(battle.ObjectLogicState.cantBeSelect, {
			fromObj = fromObj
		}) then
			return false
		end

		return true
	end)
	local ordersMap = itertools.map(orders or {}, function(k, v)
		return v, true
	end)

	for k, obj in ipairs(actionArray) do
		if ordersMap[k] and not added[obj.id] then
			added[obj.id] = true

			table.insert(ret, obj)
		end
	end

	return ret
end

local function filterRealDeath(force, obj, fromObj)
	if not obj or obj:isRealDeath() then
		return false
	end

	return true
end

local function _relativeActionOrder(caster, camp, front, nums, idHash, checkArgs)
	local added, ret = {}, {}
	local actionArray, selfIndex = actionOrderArray(caster, camp, filterRealDeath)
	local lastRoundActArray = lastRoundActOrder(caster, camp, filterRealDeath)

	checkArgs = checkArgs or {
		checkCantBeSelect = true
	}
	actionArray = arraytools.merge({
		lastRoundActArray,
		actionArray,
		actionArray
	})
	selfIndex = selfIndex + table.length(lastRoundActArray)

	local delta = front and -1 or 1
	local border = front and 1 or table.length(actionArray)
	local curHero = caster.scene.play.curHero or selectObj

	local function canBeSelected(obj, _idHash)
		if obj.id == caster.id or added[obj.id] then
			return false
		end

		if camp > 0 and obj.force ~= camp then
			return false
		end

		if _idHash and not _idHash[obj.id] then
			return false
		end

		if checkArgs.checkCantBeSelect and curHero and obj:isLogicStateExit(battle.ObjectLogicState.cantBeSelect, {
			fromObj = caster,
			skillFormulaType = curHero.curSkill and curHero.curSkill.skillFormulaType
		}) then
			return false
		end

		return true
	end

	for k = selfIndex + delta, border, delta do
		local obj = actionArray[k]

		if canBeSelected(obj, idHash) then
			added[obj.id] = true

			table.insert(ret, obj)

			nums = nums - 1
		end

		if nums == 0 then
			break
		end
	end

	return ret
end

function input.relativeActionOrder(camp, front, nums, idHash)
	return _relativeActionOrder(self, camp, front, nums, idHash)
end

function input.whokill()
	return {
		self.attackMeDeadObj
	}
end

function input.whoattack()
	return {
		self.curAttackMeObj
	}
end

function input.whohatred()
	return {
		self.attackMeDeadObjHatred
	}
end

function input.mainTarget()
	return {
		self:getCurTarget()
	}
end

function input.curHeroMainTarget()
	local curHero = self.scene.play.curHero

	assertInWindowsNoReport(curHero, "curHero is nil !!!")

	return {
		curHero and curHero:getCurTarget()
	}
end

function input.curHeroNowTarget()
	local curHero = self.scene.play.curHero

	assertInWindowsNoReport(curHero, "curHero is nil !!!")
	assertInWindowsNoReport(curHero.curSkill, "curHero.curSkill is nil !!!")

	return {
		curHero and curHero.curSkill and curHero.curSkill:getNowTarget()
	}
end

function input.allDamageTargets()
	local ret = {}

	if self.curSkill then
		ret = self.curSkill:targetsMap2Array(self.curSkill.allDamageTargets)
	end

	return ret
end

function input.selectObjectMainTarget()
	return {
		selectObj:getCurTarget()
	}
end

function input.chargeTarget()
	return {
		self:getChargeTarget()
	}
end

function input.brawlDuelist()
	local lastInfo = self.scene:getSpecialSceneInfo()
	local ret = {}

	if lastInfo then
		for _, obj in self.scene:ipairsHeros() do
			if obj.id ~= lastInfo.ownerID then
				table.insert(ret, obj)
			end
		end
	end

	return ret
end

function input.useOtherProcessInput(...)
	if env.inputUseOtherProcess then
		return env.inputUseOtherProcess(...)
	end

	return {}
end

function input.inputIfElse(condition, input1, args1, input2, args2)
	if condition then
		return input[input1](table.unpack(args1))
	else
		return input[input2](table.unpack(args2))
	end
end

input.decorator = {}

function input.decorator.summoner(targets)
	local ret = {}

	for _, target in ipairs(targets) do
		local summoner = target:getEventByKey(battle.ExRecordEvent.summoner)

		if summoner then
			table.insert(ret, summoner)
		end
	end

	return ret
end

function input.decorator.nodead(targets)
	return arraytools.filter_inplace(targets, function(_, o)
		return not o:isAlreadyDead()
	end)
end

function input.decorator.nodeath(targets)
	return arraytools.filter_inplace(targets, function(_, o)
		return not o:isDeath()
	end)
end

function input.decorator.leaveExtraDeal(args, targets)
	for _, obj in ipairs(targets) do
		if obj.id == args.casterId then
			return {
				obj
			}
		end
	end

	return {}
end

function input.decorator.nobeskillselectedhint(targets)
	local args = {
		fromObj = self
	}

	if skill then
		args.ignoreBuff = skill.targetIgnoreBuff or {}
		args.skillFormulaType = skill.skillFormulaType
	end

	return arraytools.filter_inplace(targets, function(_, o)
		return not o:isLogicStateExit(battle.ObjectLogicState.cantBeSelect, args)
	end)
end

function input.decorator.filterCantBeAddBuff(targets)
	return arraytools.filter_inplace(targets, function(_, o)
		return not o:isLogicStateExit(battle.ObjectLogicState.cantBeAddBuff, {
			fromObj = self
		})
	end)
end

function input.decorator.sortByBuffOverlayLimit(cfgID, targets)
	table.sort(targets, function(o1, o2)
		local count1 = o1:getBuffOverlayCount(cfgID)
		local count2 = o2:getBuffOverlayCount(cfgID)

		if count1 == count2 then
			return false
		end

		local buff = o1:getBuff(cfgID) or o2:getBuff(cfgID)
		local overlayLimit = buff:getOverlayLimit()

		if count1 < overlayLimit and count2 == overlayLimit then
			return true
		end

		return false
	end)

	return targets
end

function input.decorator.nobeskillselected(targets)
	local args = {
		fromObj = self
	}

	if skill then
		args.ignoreBuff = skill.targetIgnoreBuff or {}
		args.skillFormulaType = skill.skillFormulaType
	end

	return arraytools.filter_inplace(targets, function(_, o)
		if o.id == self.id then
			return true
		end

		return not o:isLogicStateExit(battle.ObjectLogicState.cantBeAttack, args) and not o:extraBattleRoundCantAttack()
	end)
end

function input.decorator.ignoreStealth(ignoreData, targets)
	env.targetIgnoreBuff = {
		stealth = ignoreData
	}

	return targets
end

local process = {}

battleTarget.process = process

function process.limit(num, targets)
	return arraytools.slice(targets, 1, num or 1)
end

function process.single(targets)
	return {
		targets[1]
	}
end

process.first = process.single

function process.tail(num, targets)
	local tarLen = table.length(targets)

	if tarLen <= num then
		return targets
	end

	num = num or 1

	local ret = {}

	for i = tarLen - num + 1, tarLen do
		table.insert(ret, targets[i])
	end

	return ret
end

function process.curSelected(targets)
	return {
		selectObj
	}
end

function process.curAttackMeObj(targets)
	return {
		self.curAttackMeObj
	}
end

function process.shuffle(targets)
	for i = 1, table.length(targets) do
		local j = ymrand.random(0, table.length(targets) - i) + i

		targets[i], targets[j] = targets[j], targets[i]
	end

	return targets
end

function process.random(num, targets)
	num = num or 1

	if num < 1 then
		return {}
	end

	if num >= table.length(targets) then
		return targets
	end

	if num == 1 then
		return {
			targets[ymrand.random(1, table.length(targets))]
		}
	end

	for i = 0, table.length(targets) - num - 1 do
		local tail = table.length(targets)
		local j = ymrand.random(1, tail)

		targets[j] = targets[tail]

		arraytools.pop(targets)
	end

	return targets
end

function process.exclude(idArray, targets)
	env.unfilterTargets = targets

	local hash = arraytools.hash(idArray)

	return arraytools.filter(targets, function(_, o)
		return not hash[o.seat]
	end)
end

function process.excludeSelf(targets)
	env.unfilterTargets = targets

	return arraytools.filter(targets, function(_, o)
		return o.id ~= self.id
	end)
end

function process.include(idArray, targets)
	env.unfilterTargets = targets

	local hash = arraytools.hash(idArray)

	return arraytools.filter(targets, function(_, o)
		return hash[o.seat]
	end)
end

local function searchTarget(targets, getF, greaterF, count)
	local tmpSortTb, ret = {}, {}

	for id, target in ipairs(targets) do
		local sortData = {
			val = getF(target),
			id = id
		}

		table.insert(tmpSortTb, sortData)
	end

	table.sort(tmpSortTb, function(a, b)
		return greaterF(a.val, b.val)
	end)

	for i = 1, count do
		if tmpSortTb[i] then
			table.insert(ret, targets[tmpSortTb[i].id])
		end
	end

	return ret
end

local function filtercantBeSelect(self, targets, env)
	local ignoreBuff = {}

	if env.skill then
		ignoreBuff = env.skill.targetIgnoreBuff
	end

	if env.targetIgnoreBuff then
		ignoreBuff = env.targetIgnoreBuff
	end

	local ret = itertools.filter(targets, function(id, obj)
		for _, data in obj:ipairsOverlaySpecBuffTo("leave", self, env) do
			return false
		end

		local skillFormulaType = self.curSkill and self.curSkill.skillFormulaType

		skillFormulaType = env.skillFixType or skillFormulaType

		for _, data in obj:ipairsOverlaySpecBuffTo("stealth", self, env) do
			local continue = false

			if ignoreBuff.stealth and battleEasy.buffFilter(data.group, ignoreBuff.stealth[1], data.buff.csvCfg.buffFlag, ignoreBuff.stealth[2], data.cfgId, ignoreBuff.stealth[3]) then
				continue = true
			end

			if continue == false then
				if not data.cantBeHealHintSwitch and (battleEasy.isSameSkillType(env.skillSegType, battle.SkillFormulaType.resumeHp) or battleEasy.isSameSkillType(skillFormulaType, battle.SkillFormulaType.resumeHp)) then
					return true
				end

				return false
			end
		end

		for _, data in obj:ipairsOverlaySpecBuffTo("depart", self, env) do
			if not data.cantBeHealHintSwitch and (battleEasy.isSameSkillType(env.skillSegType, battle.SkillFormulaType.resumeHp) or battleEasy.isSameSkillType(skillFormulaType, battle.SkillFormulaType.resumeHp)) then
				return true
			end

			return false
		end

		return true
	end)

	return ret
end

local function valLess(v, vmax)
	return v < vmax
end

local function valBigger(v, vmax)
	return vmax < v
end

local function tupleBigger(v, vmax)
	if v[1] > vmax[1] then
		return true
	elseif v[1] < vmax[1] then
		return false
	elseif v[2] > vmax[2] then
		return true
	else
		return false
	end
end

local ProcessAttrObjCache = setmetatable({}, {
	__mode = "kv"
})

local function processAttrObj(obj)
	local processObj = ProcessAttrObjCache[obj]

	if processObj then
		return processObj
	end

	processObj = {
		hp = function()
			return obj:hp()
		end,
		mp1 = function()
			return obj:mp1()
		end
	}

	for attr, _ in pairs(obj.attrs.AttrsTable) do
		processObj["B" .. attr] = function()
			return obj:getBaseAttr(attr)
		end
		processObj["A" .. attr] = function()
			return obj:getBuffAttr(attr)
		end
		processObj[attr] = function()
			return obj[attr](obj)
		end
	end

	ProcessAttrObjCache[obj] = processObj

	return processObj
end

function process.attr(typs, comp, count, targets)
	return process.attrWitOutFilter(typs, comp, count, filtercantBeSelect(self, targets, env))
end

function process.attrWitOutFilter(typs, comp, count, targets)
	env.unfilterTargets = targets

	local sign = comp == "max" and 1 or -1
	local count = count or 1

	if typs == "selectAttr" then
		typs = selectObj[typs]
		selectObj[typs] = nil
	end

	return searchTarget(targets, function(target)
		local typ = typs
		local processTarget = processAttrObj(target)

		if type(typs) == "table" then
			typ = searchTarget(typs, function(_typ)
				return sign * processTarget[_typ]()
			end, valBigger, 1)[1]
		end

		return sign * processTarget[typ]()
	end, valBigger, count)
end

function process.unitCardFilter(ids, targets)
	local filter = arraytools.hash(ids)

	return arraytools.filter(targets, function(_, target)
		return filter[target.unitCfg.cardID]
	end)
end

function process.attrRatio(typ, comp, count, targets)
	env.unfilterTargets = targets

	local sign = comp == "max" and 1 or -1

	if typ ~= "hp" and typ ~= "mp" then
		error("process.attrRatio can only use hp and mp1 attr")
	end

	local typMax = typ .. "Max"
	local filteredTargets = filtercantBeSelect(self, targets, env)

	return searchTarget(filteredTargets, function(target)
		local v1 = sign * target[typ](target)

		return {
			v1 / target[typMax](target),
			v1
		}
	end, tupleBigger, count)
end

function process.setSelectAttr(typs, comp, targets)
	selectObj.selectAttr = typs

	return targets
end

function process.buffOverlayCount(typ, ids, comp, count, targets)
	env.unfilterTargets = targets

	local count = count or 1
	local sign = comp == "max" and 1 or -1

	if type(ids) == "number" then
		ids = {
			ids
		}
	end

	return searchTarget(targets, function(target)
		local sum = 0

		for _, id in pairs(ids) do
			if typ == "id" then
				sum = sum + target:getBuffOverlayCount(id)
			elseif typ == "group" then
				sum = sum + target:getBuffGroupArgSum("overlayCount", id)
			end
		end

		return sign * sum
	end, valBigger, count)
end

function process.sortBuffRecord(cfgId, sortFunc, count, targets)
	env.unfilterTargets = targets

	local buff = self:getBuff(cfgId)
	local recordList = buff and buff:getEventByKey(battle.ExRecordEvent.buffRecord) or {}
	local ret = arraytools.filter(targets, function(_, obj)
		return recordList[obj.id]
	end)

	return searchTarget(ret, function(target)
		return recordList[target.id]
	end, sortFunc, count)
end

function process.buffValue(ids, comp, count, targets)
	env.unfilterTargets = targets

	local count = count or 1
	local sign = comp == "max" and 1 or -1

	if type(ids) == "number" then
		ids = {
			ids
		}
	end

	return searchTarget(targets, function(target)
		local sum = 0

		for _, id in ipairs(ids) do
			local buff = target:getBuff(id)

			if buff then
				sum = sum + buff.value
			end
		end

		return sign * sum
	end, valBigger, count)
end

process.hpMax = functools.partial(process.attr, "hp", "max", 1)
process.hpMin = functools.partial(process.attr, "hp", "min", 1)
process.hpRatioMax = functools.partial(process.attrRatio, "hp", "max", 1)
process.hpRatioMin = functools.partial(process.attrRatio, "hp", "min", 1)
process.attackDamageMax = functools.partial(process.attr, "damage", "max", 1)
process.attackDamageMin = functools.partial(process.attr, "damage", "min", 1)
process.defenceMax = functools.partial(process.attr, "defence", "max", 1)
process.defenceMin = functools.partial(process.attr, "defence", "min", 1)
process.mp1Max = functools.partial(process.attr, "mp1", "max", 1)
process.mp1Min = functools.partial(process.attr, "mp1", "min", 1)
process.mp1RatioMax = functools.partial(process.attrRatio, "mp1", "max", 1)
process.mp1RatioMin = functools.partial(process.attrRatio, "mp1", "min", 1)
process.specialDamageMax = functools.partial(process.attr, "specialDamage", "max", 1)
process.specialDamageMin = functools.partial(process.attr, "specialDamage", "min", 1)
process.speedMax = functools.partial(process.attr, "speed", "max", 1)
process.speedMin = functools.partial(process.attr, "speed", "min", 1)
process.specialDefenceMax = functools.partial(process.attr, "specialDefence", "max", 1)
process.specialDefenceMin = functools.partial(process.attr, "specialDefence", "min", 1)

local function getAttrValue(target, typ, rate)
	if rate then
		return target[typ](target) / target[typ .. "Max"](target)
	end

	return target[typ](target)
end

function process.attrBiggerThanValue(typ, rate, comp, gVal, targets)
	local tars = {}

	for _, target in ipairs(targets) do
		local val = getAttrValue(target, typ, rate)

		if env[comp](val, gVal) then
			table.insert(tars, target)
		end
	end

	return tars
end

process.hpBiggerThan = functools.partial(process.attrBiggerThanValue, "hp", nil, "moreThan")
process.hpLessThan = functools.partial(process.attrBiggerThanValue, "hp", nil, "lessThan")
process.hpPerBiggerThan = functools.partial(process.attrBiggerThanValue, "hp", "per", "moreThan")
process.hpPerLessThan = functools.partial(process.attrBiggerThanValue, "hp", "per", "lessThan")

function process.getTargetsInSkillCdRange(typ, baseVal, targets)
	local rets = {}
	local checkTab = {
		max = env.moreThan,
		min = env.lessThan,
		moreE = env.moreE,
		lessE = env.lessE,
		equal = function(a, b)
			return a == b
		end
	}
	local curVal, targetVal, atLeastOne = 0, 0, true

	local function addFunc1(target)
		if checkTab[typ](curVal, targetVal) then
			rets[1] = target
			targetVal = curVal
		end
	end

	local function addFunc2(target)
		if checkTab[typ](curVal, targetVal) then
			table.insert(rets, target)
		end
	end

	local addFunc

	if typ == "max" or typ == "min" then
		atLeastOne = true
		addFunc = addFunc1
	else
		atLeastOne = false
		targetVal = baseVal
		addFunc = addFunc2
	end

	for _, target in ipairs(targets) do
		for _, skill in target:iterSkills() do
			if skill.skillType2 == 1 then
				curVal = skill:getLeftCDRound()

				if atLeastOne then
					table.insert(rets, target)

					targetVal = curVal
					atLeastOne = false
				else
					addFunc(target)
				end
			end
		end
	end

	return rets
end

local function getTargetByCharacterType(attrs, targets)
	return
end

local function getTargetsByNatureType(natureTypes, targets)
	local natureTypeMap = arraytools.hash(natureTypes)
	local tarHash = {}
	local retT = {}

	for _, target in ipairs(targets) do
		tarHash[target.id] = true
	end

	local function filterAndAdd(target)
		for _, nature in target:ipairsNature() do
			if natureTypeMap[nature] then
				table.insert(retT, target)

				break
			end
		end
	end

	for _, target in ipairs(targets) do
		filterAndAdd(target)

		for _, data in target:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.followObject) do
			if data.caster.extraObjectCsvCfg.natureIncluded and not tarHash[data.caster.id] then
				filterAndAdd(data.caster)
			end
		end
	end

	return retT
end

local function getTargetsByBattleFlag(battleFlags, targets)
	local battleFlagMap = arraytools.hash(battleFlags)
	local retT = {}

	for _, target in ipairs(targets) do
		local unitBattleFlags = target.unitCfg.battleFlag

		if unitBattleFlags then
			for _, battleFlag in ipairs(unitBattleFlags) do
				if battleFlagMap[battleFlag] then
					table.insert(retT, target)

					break
				end
			end
		end
	end

	return retT
end

local function getTargetsByBuff(ids, buffFunc, targets)
	if itertools.isempty(targets) or itertools.isempty(ids) then
		return {}
	end

	local scene = targets[1].scene

	assert(scene, "scene is nil")

	local ret = scene:getTargetsByBuff(ids, buffFunc, targets)

	return ret
end

local function filterTargetsByBuff(filter, targets)
	local retT = {}

	for _, target in ipairs(targets) do
		for __, buff in target:iterBuffs() do
			if filter(buff) then
				table.insert(retT, target)

				break
			end
		end
	end

	return retT
end

function process.attrDiffer(typ, natureTypes, targets)
	env.unfilterTargets = targets

	local retT = {}

	if typ == "natureType" then
		retT = getTargetsByNatureType(natureTypes, targets)
	elseif typ == "characterType" then
		-- block empty
	end

	return retT
end

function process.battleFlagDiffer(typ, battleFlags, targets)
	env.unfilterTargets = targets

	local retT = {}

	if typ == "battleFlag" then
		retT = getTargetsByBattleFlag(battleFlags, targets)
	end

	return retT
end

function process.buffDifferByGroupFilter(ids, _, targets)
	local powersIds = ids[1]
	local groups = ids[2]

	return filterTargetsByBuff(function(buff)
		if itertools.include(groups, buff:group()) then
			for _power, v in pairs(powersIds) do
				if buff.csvPower[_power] ~= v then
					return false
				end
			end

			return true
		end

		return false
	end, targets)
end

function process.buffDiffer(typ, ids, targets)
	env.unfilterTargets = targets

	local retT = {}

	if typ == "id" then
		retT = getTargetsByBuff(ids, "hasBuff", targets)
	elseif typ == "group" then
		retT = getTargetsByBuff(ids, "hasBuffGroup", targets)
	elseif typ == "flag" then
		retT = getTargetsByBuff(ids, "hasBuffFlag", targets)
	elseif typ == "groupFilter" then
		return process.buffDifferByGroupFilter(ids, nil, targets)
	elseif typ == "type" then
		retT = getTargetsByBuff(ids, "hasTypeBuff", targets)
	end

	return retT
end

function process.unNecessary(retT)
	if itertools.isempty(retT) then
		assertInWindows(env.unfilterTargets, "The target doesn't exist")

		return env.unfilterTargets
	else
		return retT
	end
end

function process.objectDiffer(func, targets)
	env.unfilterTargets = targets

	local ret = arraytools.filter(targets, function(_, target)
		return target[func](target)
	end)

	return ret
end

function process.randomSpec(num, func, args, targets)
	if num >= table.length(targets) then
		return targets
	end

	local condiStack = {}
	local ret = {}

	if func == "buffGrpProIn2Ary" then
		for _, groups in ipairs(args) do
			table.insert(condiStack, function(tar)
				return table.length(getTargetsByBuff(groups, "hasBuffGroup", {
					tar
				})) > 0
			end)
		end
	end

	while table.length(condiStack) > 0 do
		for _, tar in ipairs(targets) do
			if condiStack[1](tar) then
				table.insert(ret, tar)
			end
		end

		if num <= table.length(ret) then
			return process.random(num, ret)
		end

		table.remove(condiStack, 1)
	end

	return ret
end

function process.natureTypeExcept(natureTypes, targets)
	return
end

function process.rowFirst(backFirst, targets)
	local firstSeat = env.force == 1 and 1 or forceNumber + 1
	local rowNext = rowNumber

	if backFirst then
		firstSeat = firstSeat + rowNext
		rowNext = -rowNext
	end

	local seatIndexTargets = {}

	for _, target in pairs(targets) do
		seatIndexTargets[target.seat] = target
	end

	local ret = {}

	for curSeat = firstSeat, firstSeat + rowNumber - 1 do
		local obj = seatIndexTargets[curSeat] or seatIndexTargets[curSeat + rowNext]

		if obj then
			table.insert(ret, obj)
		end
	end

	return ret
end

process.rowFrontFirst = functools.partial(process.rowFirst, false)
process.rowBackFirst = functools.partial(process.rowFirst, true)

local function getShiftedPos(obj)
	return obj.seat
end

function process.row(front, recursion, enemyForce, targets)
	local force = enemyForce and 3 - env.force or env.force
	local s, e = 1, forceNumber

	if force ~= 1 then
		s, e = s + forceNumber, e + forceNumber
	end

	if front then
		e = e - rowNumber
	else
		s = s + rowNumber
	end

	local ret = arraytools.filter(targets, function(_, o)
		return s <= getShiftedPos(o) and getShiftedPos(o) <= e or isAddAttackRangeObjs(env, o)
	end)
	local filteredRetNum = table.length(filtercantBeSelect(self, ret, env))

	if filteredRetNum == 0 and recursion then
		ret = process.row(not front, false, enemyForce, targets)
	end

	return ret
end

process.rowback = functools.partial(process.row, false, true, false)
process.rowfront = functools.partial(process.row, true, true, false)
process.rowbackor = functools.partial(process.row, false, false, false)
process.rowfrontor = functools.partial(process.row, true, false, false)

function process.column(targets)
	if not selectObj then
		return {}
	end

	local force = env.force
	local s = 1

	if force ~= 1 then
		s = s + forceNumber
	end

	local seat = selectObj.seat - 1

	if seat >= forceNumber then
		seat = seat - forceNumber
	end

	if seat >= rowNumber then
		seat = seat - rowNumber
	end

	s = s + seat

	return arraytools.filter(targets, function(_, o)
		return getShiftedPos(o) == s or getShiftedPos(o) == s + rowNumber
	end)
end

local NeighbourXY = {
	{
		0,
		1
	},
	{
		1,
		0
	},
	{
		0,
		-1
	},
	{
		-1,
		0
	}
}

local function idx2xy(idx, rowSize, rectSize)
	idx = (idx - 1) % rectSize

	return math.floor(idx / rowSize), idx % rowSize
end

local function xy2idx(x, y, rowSize, colSize)
	if x < 0 or colSize <= x then
		return nil
	end

	if y < 0 or rowSize <= y then
		return nil
	end

	return x * rowSize + y + 1
end

local pos = {
	left = {
		{
			4,
			5,
			6
		},
		{
			1,
			2,
			3
		}
	},
	right = {
		{
			7,
			8,
			9
		},
		{
			10,
			11,
			12
		}
	}
}
local posMap = {
	left = {
		{
			y = 1,
			x = 2
		},
		{
			y = 2,
			x = 2
		},
		{
			y = 3,
			x = 2
		},
		{
			y = 1,
			x = 1
		},
		{
			y = 2,
			x = 1
		},
		{
			y = 3,
			x = 1
		}
	},
	right = {
		[7] = {
			y = 1,
			x = 1
		},
		[8] = {
			y = 2,
			x = 1
		},
		[9] = {
			y = 3,
			x = 1
		},
		[10] = {
			y = 1,
			x = 2
		},
		[11] = {
			y = 2,
			x = 2
		},
		[12] = {
			y = 3,
			x = 2
		}
	}
}

local function getNear(targets, targetObj)
	local isLeft = getShiftedPos(targetObj) <= 6
	local positionMap = isLeft and posMap.left or posMap.right
	local position = isLeft and pos.left or pos.right
	local selfIdx = positionMap[getShiftedPos(targetObj)]
	local idMap = {}

	if not selfIdx then
		return {}
	end

	idMap[position[selfIdx.x][selfIdx.y]] = true

	for _, xy in ipairs(NeighbourXY) do
		local x = xy[1] + selfIdx.x
		local y = xy[2] + selfIdx.y

		if x > 0 and x <= 2 and y > 0 and y <= 3 then
			idMap[position[x][y]] = true
		end
	end

	return arraytools.filter(targets, function(_, o)
		return idMap[getShiftedPos(o)]
	end)
end

function process.near(targets)
	return getNear(targets, selectObj)
end

function process.targetNear(targets)
	local target = targets[1]

	if not target then
		return {}
	end

	local map = self.scene:getHerosMap(target.force)
	local ret = itertools.values(map:order_pairs())

	return getNear(ret, target)
end

function process.sputtering(rate, func, targets)
	for idx, target in ipairs(targets) do
		target:addExRecord(battle.ExRecordEvent.sputtering, {
			rate = rate,
			func = func
		})
	end

	return targets
end

function process.ignoreReplaceTarget(buffFlags, targets)
	if env.ignoreReplaceData then
		local ignoreReplaceData = env.ignoreReplaceData

		ignoreReplaceData.buffFlags = buffFlags
		ignoreReplaceData.flag = true

		for _, target in ipairs(targets) do
			if not ignoreReplaceData.objIds[target.id] then
				ignoreReplaceData.objIds[target.id] = true
			end
		end
	end

	return targets
end

function process.penetrate(rate, targets)
	for _, target in ipairs(targets) do
		target:addExRecord(battle.ExRecordEvent.penetrate, {
			rate = rate
		})
	end

	return targets
end

local function serachTargetsByRowColumn(targets, row, column, useOriginPos)
	local retT = {}
	local posIdInfoTb = {}
	local rowTb = {}
	local colTb = {}

	for _, target in ipairs(targets) do
		local scene = target.scene

		posIdInfoTb[getShiftedPos(target)] = scene.placeIdInfoTb[getShiftedPos(target)]
	end

	if row and (row == 1 or row == 2) then
		itertools.each(posIdInfoTb, function(id, _)
			if posIdInfoTb[id]["row" .. row] then
				rowTb[id] = true
			end
		end)
	end

	if column and (column == 1 or column == 2 or column == 3) then
		itertools.each(posIdInfoTb, function(id, _)
			if posIdInfoTb[id]["column" .. column] then
				colTb[id] = true
			end
		end)
	end

	local emptyRowTb = next(rowTb)
	local emptyColTb = next(colTb)

	if emptyRowTb or emptyColTb then
		for _, target in ipairs(targets) do
			local i = getShiftedPos(target)

			if rowTb[i] and colTb[i] or rowTb[i] and not emptyColTb or not emptyRowTb and colTb[i] then
				table.insert(retT, target)
			end
		end
	end

	return retT
end

function process.targetRow(targets)
	local row, _ = getRowAndColumn(selectObj)

	row = math.max(1, math.min(row, 2))

	return serachTargetsByRowColumn(targets, row, column)
end

function process.targetFront(targets)
	local row, column = getRowAndColumn(selectObj)

	row = math.max(1, math.min(-1 + row, 2))

	return serachTargetsByRowColumn(targets, row, column)
end

function process.targetBack(targets)
	local row, column = getRowAndColumn(selectObj)

	row = math.max(1, math.min(1 + row, 2))

	return serachTargetsByRowColumn(targets, row, column)
end

function process.targetColumn(targets)
	local _, column = getRowAndColumn(selectObj)

	return serachTargetsByRowColumn(targets, row, column)
end

function process.selfRow(targets)
	local row, _ = getRowAndColumn(self)

	row = math.max(1, math.min(row, 2))

	return serachTargetsByRowColumn(targets, row, column)
end

function process.selfFront(targets)
	local row, column = getRowAndColumn(self)

	row = math.max(1, math.min(-1 + row, 2))

	return serachTargetsByRowColumn(targets, row, column)
end

function process.selfBack(targets)
	local row, column = getRowAndColumn(self)

	row = math.max(1, math.min(1 + row, 2))

	return serachTargetsByRowColumn(targets, row, column)
end

function process.selfColumn(targets)
	local _, column = getRowAndColumn(self)

	return serachTargetsByRowColumn(targets, row, column)
end

function process.frontRowRandom(limit, targets)
	local targets2 = process.row(true, true, false, targets)

	return process.random(limit, targets2)
end

function process.backRowRandom(limit, targets)
	local targets2 = process.row(false, true, false, targets)

	return process.random(limit, targets2)
end

local function searchPriorTargets(self, targets, priorValFunc)
	if table.length(targets) == 0 then
		return targets
	end

	local tmpTargets, vals = {}, {}
	local selfVal = priorValFunc(self)

	for _, target in ipairs(targets) do
		local curVal = priorValFunc(target)

		if not tmpTargets[curVal] then
			tmpTargets[curVal] = {}

			if curVal ~= selfVal then
				table.insert(vals, curVal)
			end
		end

		table.insert(tmpTargets[curVal], target)
	end

	if tmpTargets[selfVal] then
		return tmpTargets[selfVal]
	else
		local val = vals[ymrand.random(1, table.length(vals))]

		return tmpTargets[val]
	end
end

function process.selfColumnPrior(targets)
	local function getPriorValue(target)
		local _, column = getRowAndColumn(target)

		return column
	end

	return searchPriorTargets(self, targets, getPriorValue)
end

function process.targetAnd(func1, args1, func2, args2, targets)
	local ret = {}
	local map = {}

	args1[#args1 + 1] = targets

	for _, target in ipairs(process[func1](table.unpack(args1))) do
		table.insert(ret, target)

		map[target.id] = true
	end

	args2[#args2 + 1] = targets

	for _, target in ipairs(process[func2](table.unpack(args2))) do
		if not map[target.id] then
			table.insert(ret, target)

			map[target.id] = true
		end
	end

	table.sort(ret, function(o1, o2)
		return o1.id < o2.id
	end)

	return ret
end

function process.processIfElse(condition, input1, args1, input2, args2, targets)
	if condition then
		args1[#args1 + 1] = targets

		return process[input1](table.unpack(args1))
	else
		args2[#args2 + 1] = targets

		return process[input1](table.unpack(args2))
	end
end

local function doProcess(rule, env, targets)
	local ret = {}

	if type(rule) == "table" then
		ret = targets

		for _, v in ipairs(rule) do
			ret = doProcess(v, env, ret)
		end
	else
		env.env.targets = targets

		if string.sub(rule, -2, -1) == "()" then
			ret = env.doFormula(string.sub(rule, 1, -2) .. "env.targets)", env)
		else
			ret = env.doFormula(string.sub(rule, 1, -2) .. ", env.targets)", env)
		end

		env.env.targets = nil
	end

	return ret
end

function process.filterByRules(rules, count, targets)
	local ret = {}
	local exitMap = {}

	for _, rule in ipairs(rules) do
		local tars = doProcess(rule, env.getfenv(), targets)

		if table.length(tars) > 0 then
			for _, tar in ipairs(tars) do
				if not exitMap[tar.id] then
					table.insert(ret, tar)

					exitMap[tar.id] = true

					if table.length(ret) == count then
						return ret
					end
				end
			end
		end
	end

	return ret
end

function process.relativeActionOrderProcess(front, nums, targets)
	local idHash = {}

	for _, target in ipairs(targets) do
		idHash[target.id] = true
	end

	return _relativeActionOrder(self, 0, front, nums, idHash)
end

function process.relativeActionOrderProcessEx(front, nums, targets)
	local idHash = {}

	for _, target in ipairs(targets) do
		idHash[target.id] = true
	end

	return _relativeActionOrder(self, 0, front, nums, idHash, {
		checkCantBeSelect = false
	})
end

function process.paintFlagNum(targets)
	local sn = 10000

	for _, target in ipairs(targets) do
		sn = sn + 1
		target.paintFlagNum = sn
	end

	return targets
end

function process.ignoreBuffGroup(ids, targets)
	env.ignoreBuffGroup = ids

	return targets
end

function process.selfSeat(targets)
	for _, target in ipairs(targets) do
		if target.seat == self.seat then
			return {
				target
			}
		end
	end

	return {}
end

function process.selectObjSeat(targets)
	for _, target in ipairs(targets) do
		if target.seat == selectObj.seat then
			return {
				target
			}
		end
	end

	return {}
end

function process.converged(condition, targets)
	if table.length(targets) == 1 or not condition then
		return targets
	end

	local force = {
		0,
		0
	}

	for _, target in ipairs(targets) do
		force[target.force] = 1
	end

	local tempTargets

	if self.curSkill then
		tempTargets = self:doOverlaySpecBuffFunc(condition, "getTargets", force, self.curSkill.id)
	end

	if tempTargets and table.length(tempTargets) > 0 then
		local finalTargets = {}

		for _, obj1 in ipairs(tempTargets) do
			for _, obj2 in ipairs(targets) do
				if obj1.id == obj2.id then
					table.insert(finalTargets, obj2)
				end
			end
		end

		targets = finalTargets
	end

	return targets
end

function process.mirrorPos(seat, targets)
	local ret = {}
	local mirrorSeat = mirrorSeat(seat)

	for _, target in ipairs(targets) do
		if target.seat == mirrorSeat then
			table.insert(ret, target)
		end
	end

	return ret
end

function process.useOtherProcess(...)
	local args = {
		...
	}
	local oriTargets = table.remove(args)

	if env.processUseOtherProcess then
		return env.processUseOtherProcess("include", oriTargets, table.unpack(args))
	end

	return oriTargets
end

function process.otherProcessExcept(...)
	local args = {
		...
	}
	local oriTargets = table.remove(args)

	if env.processUseOtherProcess then
		return env.processUseOtherProcess("exclude", oriTargets, table.unpack(args))
	end

	return oriTargets
end

function process.roundNoAttacked(targets)
	local ret = {}

	for _, obj in ipairs(targets) do
		local lastAttackRound = obj:getEventByKey(battle.ExRecordEvent.attackedRoundRecord) or 0

		if lastAttackRound < self.scene.play.totalRound then
			table.insert(ret, obj)
		end
	end

	return ret
end

function process.speedRankWithRoundLeftHeros(targets)
	local scene = self.scene
	local gate = scene.play
	local curLefts = gate:getRoundLeftHeros()
	local normalRoundMark = {}

	itertools.each(curLefts, function(idx, data)
		if not data.reset and not data.atOnce and not data.prophet then
			normalRoundMark[data.obj.id] = true
		end
	end)
	itertools.each(targets, function(idx, obj)
		if normalRoundMark[obj.id] then
			return
		end

		table.insert(curLefts, {
			obj = obj
		})
	end)

	if table.length(curLefts) == 0 then
		return {}
	end

	local tbForSort = gate:createTbForSort(curLefts)

	gate:speedRankSortWithRule(tbForSort)

	local ret = {}

	for idx, data in ipairs(tbForSort) do
		local obj = curLefts[data.key].obj

		table.insert(ret, obj)
	end

	return ret
end

function process.attrPercentFilter(attr, comp, percent, targets)
	local compFunc = {
		greater = valBigger,
		less = valLess
	}
	local maxAttrName = attr .. "Max"
	local func = compFunc[comp]
	local ret = {}

	for _, obj in ipairs(targets) do
		if func(obj[attr](obj) / obj[maxAttrName](obj), percent) then
			table.insert(ret, obj)
		end
	end

	return ret
end

process.hpPercentGreaterFilter = functools.partial(process.attrPercentFilter, "hp", "greater")
process.hpPercentLessFilter = functools.partial(process.attrPercentFilter, "hp", "less")
process.mp1PercentGreaterFilter = functools.partial(process.attrPercentFilter, "mp1", "greater")
process.mp1PercentLessFilter = functools.partial(process.attrPercentFilter, "mp1", "less")

local newChooseProcess = {}

battleTarget.newChooseProcess = newChooseProcess

local exportExcludeFunc = {
	"attrDiffer",
	"buffDiffer",
	"row",
	"battleFlagDiffer"
}
local canIgnoreFunc = {
	"limit",
	"single",
	"first",
	"curSelected",
	"shuffle",
	"random",
	"exclude",
	"excludeSelf",
	"include",
	"attr",
	"attrRatio",
	"setSelectAttr",
	"buffOverlayCount",
	"sortBuffRecord",
	"buffValue",
	"attrBiggerThanValue",
	"getTargetsInSkillCdRange",
	"attrDiffer",
	"battleFlagDiffer",
	"battleFlagDifferExclude",
	"buffDiffer",
	"buffDifferExclude",
	"row",
	"rowback",
	"rowfront",
	"rowbackor",
	"rowfrontor",
	"rowExclude",
	"column",
	"near",
	"sputtering",
	"penetrate",
	"targetRow",
	"targetFront",
	"targetBack",
	"targetColumn",
	"selfRow",
	"selfFront",
	"selfBack",
	"selfColumn",
	"frontRowRandom",
	"backRowRandom",
	"objectDiffer",
	"mirrorPos"
}
local sortFunc = {
	"attrDiffer",
	"battleFlagDiffer",
	"battleFlagDifferExclude"
}

for _, funcName in ipairs(exportExcludeFunc) do
	process[funcName .. "Exclude"] = function(...)
		local n = select("#", ...)
		local targets = select(n, ...)
		local ret = process[funcName](...)

		return arraytools.filter(targets, function(_, obj)
			for k, v in ipairs(ret) do
				if v.id == obj.id then
					return false
				end
			end

			return true
		end)
	end
end

for _, funcName in ipairs(canIgnoreFunc) do
	process[funcName .. "Optional"] = function(...)
		local n = select("#", ...)
		local targets = select(n, ...)
		local ret = process[funcName](...)

		if itertools.isempty(ret) then
			assertInWindows(targets, "The target doesn't exist")

			return targets
		else
			return ret
		end
	end
end

for _, funcName in ipairs(sortFunc) do
	process[funcName .. "Sort"] = function(...)
		local n = select("#", ...)
		local targets = select(n, ...)
		local ret = process[funcName](...)

		arraytools.filter(targets, function(_, obj)
			local flag = true

			for k, v in ipairs(ret) do
				if v.id == obj.id then
					flag = false

					break
				end
			end

			if flag then
				table.insert(ret, obj)
			end
		end)

		return ret
	end
end

function process.sortByProcess(func, args, targets)
	args[#args + 1] = targets

	local ret = process[func](table.unpack(args))

	for _, obj in ipairs(targets) do
		local flag = true

		for k, v in ipairs(ret) do
			if v.id == obj.id then
				flag = false

				break
			end
		end

		if flag then
			table.insert(ret, obj)
		end
	end

	return ret
end

function process.excludeByProcess(func, args, targets)
	args[#args + 1] = targets

	local ret = process[func](table.unpack(args))

	return arraytools.filter(targets, function(_, obj)
		for k, v in ipairs(ret) do
			if v.id == obj.id then
				return false
			end
		end

		return true
	end)
end
