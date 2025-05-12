local XPokemonMonster = require("XEntity/XPokemon/XPokemonMonster")
local XPokemonTeamPosData = require("XEntity/XPokemon/XPokemonTeamPosData")
local NORMAL_SPEED = 1
local DOUBLE_SPEED = 2
XPokemonManagerCreator = function()
    local tableInsert = table.insert
    local pairs = pairs
    local tonumber = tonumber

    local XPokemonManager = {}
    function XPokemonManager.GetSpeedUpSaveKey()
        return string.format("%s_%s","PokemonSpeedUp",XPlayer.Id)
    end

    function XPokemonManager.IsSpeedUp()
        return XSaveTool.GetData(XPokemonManager.GetSpeedUpSaveKey()) == 1
    end

    function XPokemonManager.SetSpeedUp(isSpeedUp)
        if isSpeedUp then
            XSaveTool.SaveData(XPokemonManager.GetSpeedUpSaveKey(),1)
        else
            XSaveTool.SaveData(XPokemonManager.GetSpeedUpSaveKey(),0)
        end
    end

    function XPokemonManager.ChangeSpeed()
        CS.UnityEngine.Time.timeScale = DOUBLE_SPEED
    end

    function XPokemonManager.ResetSpeed()
        if CS.UnityEngine.Time.timeScale ~= NORMAL_SPEED then
            CS.UnityEngine.Time.timeScale = NORMAL_SPEED
        end
    end

    function XPokemonManager.CloseFightLoading()
        XDataCenter.FubenManager.CloseFightLoading()
        if XPokemonManager.IsSpeedUp() then
            XPokemonManager.ChangeSpeed()
        end
    end

    function XPokemonManager.CallFinishFight()
        XPokemonManager.ResetSpeed()
        XDataCenter.FubenManager.CallFinishFight()
    end

    -----------------怪物相关 begin----------------
    local _Monsters = {}
    local _NewMonsterIds = {}

    local function GetMonster(monsterId)
        return _Monsters[monsterId]
    end

    local function UpdateMonster(data, checkNew)
        if not data then return end

        local monsterId = data.Id

        local monster = GetMonster(monsterId)
        if not monster then
            monster = XPokemonMonster.New(monsterId)
            _Monsters[monsterId] = monster
            local newMonsterId = checkNew and monsterId
            if newMonsterId then
                tableInsert(_NewMonsterIds, newMonsterId)
            end
        end

        monster:UpdateData(data)
    end

    local function UpdateMonsters(datas, checkNew)
        if not datas then return end

        for _, data in pairs(datas) do
            UpdateMonster(data, checkNew)
        end

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_POKEMON_MONSTERS_DATA_CHANGE)
    end

    function XPokemonManager.NotifyPokemonMonster(data)
        UpdateMonsters(data.MonsterList, true)
    end

    function XPokemonManager.CheckNewMonsterIds()
        if XTool.IsTableEmpty(_NewMonsterIds) then return end

        local monsterIds = XTool.Clone(_NewMonsterIds)
        XLuaUiManager.Open("UiPokemonMonsterObtain", monsterIds)

        _NewMonsterIds = {}
    end

    function XPokemonManager.GetOwnMonsterIds(monsterType)
        local monsterIdList = {}
        for monsterId in pairs(_Monsters) do
            if monsterType then
                if XPokemonConfigs.CheckMonsterType(monsterId, monsterType) then
                    tableInsert(monsterIdList, monsterId)
                end
            else
                tableInsert(monsterIdList, monsterId)
            end
        end
        return monsterIdList
    end

    function XPokemonManager.GetOwnMonsterIdsByCareer(career)
        local monsterIdList = {}
        for monsterId in pairs(_Monsters) do
            if career then
                if XPokemonConfigs.CheckMonsterCareer(monsterId, career) then
                    tableInsert(monsterIdList, monsterId)
                end
            else
                tableInsert(monsterIdList, monsterId)
            end
        end
        return monsterIdList
    end

    function XPokemonManager.CheckOwnMonsterEmptyByCareer(career)
        local isEmpty = true
        for monsterId in pairs(_Monsters) do
            if career then
                if XPokemonConfigs.CheckMonsterCareer(monsterId, career) then
                    isEmpty = false
                    break
                end
            else
                isEmpty = false
                break
            end
        end

        return isEmpty
    end

    function XPokemonManager.CheckBagMonsterEmptyByCareer(career)
        local isEmpty = true
        local teamMonsterDic = XPokemonManager.GetTeamMonstersIdDic()
        for monsterId in pairs(_Monsters) do
            if career then
                if XPokemonConfigs.CheckMonsterCareer(monsterId, career) and not teamMonsterDic[monsterId]  then
                    isEmpty = false
                    break
                end
            else
                isEmpty = false
                break
            end
        end

        return isEmpty
    end

    function XPokemonManager.CheckOwnMonsterEmpty(monsterType)
        local isEmpty = true
        for monsterId in pairs(_Monsters) do
            if monsterType then
                if XPokemonConfigs.CheckMonsterType(monsterId, monsterType) then
                    isEmpty = false
                    break
                end
            else
                isEmpty = false
                break
            end
        end
        return isEmpty
    end

    function XPokemonManager.CheckBagMonsterEmpty(monsterType)
        local isEmpty = true
        local teamMonsterDic = XPokemonManager.GetTeamMonstersIdDic()
        for monsterId in pairs(_Monsters) do
            if monsterType then
                if XPokemonConfigs.CheckMonsterType(monsterId, monsterType) and not teamMonsterDic[monsterId] then
                    isEmpty = false
                    break
                end
            else
                isEmpty = false
                break
            end
        end
        return isEmpty
    end

    function XPokemonManager.GetMonsterStar(monsterId)
        local monster = GetMonster(monsterId)
        return monster and monster:GetStar() or 0
    end

    function XPokemonManager.GetMonsterLevel(monsterId)
        local monster = GetMonster(monsterId)
        return monster and monster:GetLevel() or 0
    end

    function XPokemonManager.GetMonsterAbility(monsterId)
        local monster = GetMonster(monsterId)
        return monster and monster:GetAbility() or 0
    end

    function XPokemonManager.GetMonsterHp(monsterId)
        local monster = GetMonster(monsterId)
        return monster and monster:GetHp() or 0
    end

    function XPokemonManager.GetMonsterAttack(monsterId)
        local monster = GetMonster(monsterId)
        return monster and monster:GetAttack() or 0
    end

    --获取升级后预览属性
    ---@param 预览等级
    ---@return 生命, 攻击
    function XPokemonManager.GetMonsterPreHpAndPreAttack(monsterId, preLevel)
        local monster = GetMonster(monsterId)
        if not monster then
            return 0, 0
        end
        return monster:GetPreHpAndPreAttack(preLevel)
    end

    function XPokemonManager.IsMonsterMaxLevel(monsterId)
        local monster = GetMonster(monsterId)
        return monster and monster:IsMaxLevel() or false
    end

    function XPokemonManager.GetMonsterMaxLevel(monsterId)
        local monster = GetMonster(monsterId)
        return monster and monster:GetMaxLevel() or 0
    end

    function XPokemonManager.IsMonsterMaxStar(monsterId)
        local monster = GetMonster(monsterId)
        return monster and monster:IsMaxStar() or false
    end

    function XPokemonManager.GetMonsterLevelUpCostItemInfo(monsterId)
        local monster = GetMonster(monsterId)
        if not monster then
            return XPokemonConfigs.GetMonsterLevelCostItemInfo(monsterId, 1)
        end
        return monster:GetLevelUpCostItemInfo()
    end

    function XPokemonManager.GetMonsterStarUpCostItemInfo(monsterId)
        local monster = GetMonster(monsterId)
        if not monster then
            return XPokemonConfigs.GetMonsterStarCostItemInfo(monsterId, 1)
        end
        return monster:GetStarUpCostItemInfo()
    end

    function XPokemonManager.GetMonsterUsingSkillIdList(monsterId)
        local monster = GetMonster(monsterId)
        return monster and monster:GetUsingSkillIdList() or {}
    end

    function XPokemonManager.GetMonsterCanSwitchSkillIdList(monsterId, skillId)
        local monster = GetMonster(monsterId)
        return monster and monster:GetCanSwitchSkillIds(skillId) or {}
    end

    function XPokemonManager.IsMonsterSkillUnlock(monsterId, skillId)
        local monster = GetMonster(monsterId)
        return monster and monster:IsSkillUnlock(skillId) or false
    end

    function XPokemonManager.IsMonsterSkillUsing(monsterId, skillId)
        local monster = GetMonster(monsterId)
        return monster and monster:IsSkillUsing(skillId) or false
    end

    function XPokemonManager.IsMonsterSkillCanSwitch(monsterId, skillId)
        local monster = GetMonster(monsterId)
        return monster and monster:IsSkillCanSwitch(skillId) or false
    end

    --获取该星级可解锁技能Id列表
    function XPokemonManager.GetMonsterStarUnlockSkillIds(monsterId, star)
        local monster = GetMonster(monsterId)
        return monster and monster:GetStarUnlockSkillIds(star) or {}
    end

    --获取当前拥有道具足够升级的最大次数
    function XPokemonManager.GetMonsterCanLevelUpTimes(monsterId)
        local times = 0
        local costItemDic = {}

        local bagItemDic = {}
        local curLevel = XPokemonManager.GetMonsterLevel(monsterId)
        local maxLevel = XPokemonManager.GetMonsterMaxLevel(monsterId)
        for level = curLevel, maxLevel - 1 do

            local costItemId, costItemCount = XPokemonConfigs.GetMonsterLevelCostItemInfo(monsterId, level)
            local haveItemCount = bagItemDic[costItemId] or XDataCenter.ItemManager.GetCount(costItemId)

            haveItemCount = haveItemCount - costItemCount
            if haveItemCount < 0 then
                break
            end

            bagItemDic[costItemId] = haveItemCount
            costItemDic[costItemId] = costItemDic[costItemId] and costItemDic[costItemId] + costItemCount or costItemCount
            times = times + 1

        end

        return times, costItemDic
    end

    function XPokemonManager.OpenMonsterUi()
        if XDataCenter.PokemonManager.CheckOwnMonsterEmpty() then
            XLog.Error("XPokemonManager.OpenMonsterUi error: 尚未获得怪物，不能打开怪物培养UI")
            return
        end
        XLuaUiManager.Open("UiPokemonMonster")
    end

    --怪物升级
    function XPokemonManager.PokemonLevelUpRequest(monsterId, times, cb)
        times = times or 1
        local req = { MonsterId = monsterId, Times = times }
        XNetwork.Call("PokemonLevelUpRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local monster = GetMonster(monsterId)
            monster:UpLevel(times)

            CsXGameEventManager.Instance:Notify(XEventId.EVENT_POKEMON_MONSTERS_LEVEL_UP)
            XEventManager.DispatchEvent(XEventId.EVENT_POKEMON_MONSTERS_LEVEL_UP, monsterId)

            if cb then cb() end
        end)
    end

    --怪物升星
    function XPokemonManager.PokemonStarUpRequest(monsterId, cb)
        local req = { MonsterId = monsterId }
        XNetwork.Call("PokemonStarUpRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local monster = GetMonster(monsterId)
            local addStar = 1
            monster:UpStar(addStar)

            CsXGameEventManager.Instance:Notify(XEventId.EVENT_POKEMON_MONSTERS_STAR_UP)
            XEventManager.DispatchEvent(XEventId.EVENT_POKEMON_MONSTERS_STAR_UP, monsterId)

            if cb then cb() end
        end)
    end

    --怪物技能切换
    function XPokemonManager.PokemonSetSkillRequest(monsterId, skillId, cb)
        local req = { MonsterId = monsterId, SkillId = skillId }
        XNetwork.Call("PokemonSetSkillRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local monster = GetMonster(monsterId)
            monster:SwitchSkill(skillId)

            CsXGameEventManager.Instance:Notify(XEventId.EVENT_POKEMON_MONSTERS_SKILL_SWITCH)

            if cb then cb() end
        end)
    end

    function XPokemonManager.PokemonResetUpgradeRequest(monsterId,cb)
        local req = {MonsterId = monsterId}
        local monster = _Monsters[monsterId]
        if monster then
            monster:InitSkillGroups()
        end
        XNetwork.Call("PokemonResetUpgradeRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            CsXGameEventManager.Instance:Notify(XEventId.EVENT_POKEMON_MONSTERS_DATA_CHANGE)

            if cb then cb(res.RewardGoods) end
        end)
    end
    -----------------怪物相关 end----------------
    -----------------队伍相关 begin----------------
    local _MaxEnergy = 0
    local _Team = {}
    local TEAM_MEMBER_NUM = XPokemonConfigs.TeamNum
    local _RandomMonsterList = {}
    local _RandomStageId = 1

    local function GetTeamPosData(pos)
        return _Team[pos]
    end

    local function UpdateRandomMonsterData(randomStageData)
        if not randomStageData then return end
        _RandomMonsterList = {}
        _RandomStageId = randomStageData.StageId
        for _, npcGroupList in pairs(randomStageData.NpcGroupList) do
            if not npcGroupList.NpcList then break end
            for _, npcInfo in pairs(npcGroupList.NpcList) do
                table.insert(_RandomMonsterList, XPokemonConfigs.GetMonsterIdByNpcId(npcInfo.Id))
            end
        end
    end

    local function UpdateMaxEnergy(maxEnergy)
        _MaxEnergy = maxEnergy or _MaxEnergy
    end

    local function UpdateUnlockedPositionList(unlockedPositionList)
        if not unlockedPositionList then return end
        for _, pos in pairs(unlockedPositionList) do
            local posData = GetTeamPosData(pos)
            posData:Unlock()
        end
    end

    local function UpdateTeam(mosnterIdDic)
        if not mosnterIdDic then return end
        for pos, monsterId in pairs(mosnterIdDic) do
            local posData = GetTeamPosData(pos)
            posData:SetMonsterId(monsterId)
        end
    end

    function XPokemonManager.InitTeam()
        _Team = {}
        for pos = 1, TEAM_MEMBER_NUM do
            _Team[pos] = XPokemonTeamPosData.New(pos)
        end
    end

    function XPokemonManager.IsTeamPosLock(pos)
        local posData = GetTeamPosData(pos)
        return posData and posData:IsLock()
    end

    function XPokemonManager.GetTeamMonsterIds()
        local monsterIds = {}

        for pos = 1, TEAM_MEMBER_NUM do
            local posData = GetTeamPosData(pos)
            local monsterId = posData and posData:GetMonsterId() or 0
            monsterIds[pos] = monsterId
        end

        return monsterIds
    end

    function XPokemonManager.GetTeamMonstersIdDic()
        local monstersIdDic = {}
        for _, v in pairs(_Team) do
            monstersIdDic[v:GetMonsterId()] = v:GetMonsterId()
        end
        return monstersIdDic
    end

    function XPokemonManager.CheckMonsterIsInTeam(monsterId)
        local monsterDic = XPokemonManager.GetTeamMonstersIdDic()
        local monster = monsterDic[monsterId] or 0
        return monster > 0
    end

    function XPokemonManager.NotifyPokemonUnlock(data)
        UpdateMaxEnergy(data.MaxEnergy)
        UpdateUnlockedPositionList(data.UnlockedPositionList)
        UpdateRandomMonsterData(data.RandomStageData)
    end

    function XPokemonManager.GetMaxEnergy()
        return _MaxEnergy
    end

    function XPokemonManager.GetRandomMonsters()
        return _RandomMonsterList or {}
    end

    function XPokemonManager.GetRandomStageId()
        return _RandomStageId
    end


    --队伍信息同步
    function XPokemonManager.PokemonSetFormationRequest(monsterIdList, cb)
        local req = { MonsterIdList = monsterIdList }
        XNetwork.Call("PokemonSetFormationRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            UpdateTeam(monsterIdList)

            if cb then cb() end
        end)
    end
    -----------------队伍相关 end----------------
    -----------------章节相关 begin--------------
    function XPokemonManager.GetChapters()
        return XPokemonConfigs.GetChapters(XPokemonManager.GetCurrActivityId())
    end

    function XPokemonManager.GetSelectChapterName()
        return XPokemonConfigs.GetChapterName(XPokemonManager.GetSelectChapter())
    end

    function XPokemonManager.GetSelectChapterDesc()
        return XPokemonConfigs.GetChapterDesc(XPokemonManager.GetSelectChapter())
    end

    function XPokemonManager.GetSelectChapterType()
        return XPokemonConfigs.GetChapterType(XPokemonManager.GetSelectChapter())
    end

    function XPokemonManager.GetSelectChapterTitleImage()
        return XPokemonConfigs.GetChapterTitleImage(XPokemonManager.GetSelectChapter())
    end

    function XPokemonManager.GetChapterScrollBg()
        return XPokemonConfigs.GetChapterScrollBg(XPokemonManager.GetSelectChapter())
    end
    -----------------章节相关 end----------------
    -----------------关卡相关 begin----------------
    local _PassedStageDic = {}
    local _SkipStageInfo = {}
    local _RemainingTimes = XPokemonConfigs.GetDefaultStageTimes()
    local _IsSwitchToInfinity = false
    local _NextRecoverTime = 0
    local _StageSkipTimes = 0
    local _SelectChapter = 31

    local function UpdateStageSkipTimes(data)
        if not data then return end
        _StageSkipTimes = data
    end

    function XPokemonManager.GetStageSkipTimes()
        return _StageSkipTimes
    end

    function XPokemonManager.CheckCanSkip()
        return _StageSkipTimes > 0
    end

    local function UpdateSkipStageInfo(data)
        if not data then return end
        _SkipStageInfo = data
    end

    function XPokemonManager.GetSkipStageInfo()
        return _SkipStageInfo
    end

    function XPokemonManager.CheckIsSkip(stageId)
        for _,skipId in ipairs(_SkipStageInfo) do
            if skipId == stageId then
                return true
            end
        end
        return false
    end

    local function UpdateNextRecoverTime(time)
        _NextRecoverTime = time or 0
    end

    function XPokemonManager.GetNextRecoverTime()
        return _NextRecoverTime
    end

    function XPokemonManager.SetSelectChapter(data)
        local chapters = XPokemonManager.GetChapters()
        _SelectChapter = chapters[data].Id
    end

    function XPokemonManager.GetSelectChapter()
        return _SelectChapter
    end

    local function UpdatePassedStage(data)
        data = data or {}
        for i = 1, #data do
            local value = data[i]
            if not _PassedStageDic[value] then
                _PassedStageDic[value] = value
            end
        end
    end

    local function UpdateRemainingTimes(times)
        if not times then return end
        _RemainingTimes = times
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_POKEMON_REMAINING_TIMES_CHANGE)
    end

    function XPokemonManager.GetIsSwitchToInfinity()
        return _IsSwitchToInfinity
    end

    function XPokemonManager.SetIsSwitchToInfinity(v)
        _IsSwitchToInfinity = v
    end

    function XPokemonManager.NotifyPokemonStagePassed(data)
        if data and data.StageId then
            _PassedStageDic[data.StageId] = data.StageId
            --if XPokemonManager.GetPassedCount() == XPokemonManager.GetStageCountByType(XPokemonConfigs.StageType.Normal) then
            --    XPokemonManager.SetIsSwitchToInfinity(true)
            --end
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_POKEMON_PASSED_STAGE_CHANGE)
        end
    end

    function XPokemonManager.NotifyPokemonRemainingTimesChange(data)
        if not data then return end
        _RemainingTimes = data.StageTimes or _RemainingTimes
        _NextRecoverTime = data.StageTimesNextRecoverTime or 0
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_POKEMON_REMAINING_TIMES_CHANGE)
    end

    function XPokemonManager.CheckStageIsPassed(stageId)
        return _PassedStageDic[stageId] and true
    end

    function XPokemonManager.GetPassedCount()
        local count = 0
        for k, v in pairs(_PassedStageDic) do
            count = count + 1
        end
        return count
    end

    function XPokemonManager.GetPassedCountByChapterId(chapterId)
        local count = 0
        for k, v in pairs(_PassedStageDic) do
            local cId = XPokemonConfigs.GetStageChapterIdByFightStageId(XDataCenter.PokemonManager.GetCurrActivityId(),k)
            if cId == chapterId then
                count = count + 1
            end
        end
        for _,fightStageId in pairs(_SkipStageInfo) do
            local cId = XPokemonConfigs.GetStageChapterIdByFightStageId(XDataCenter.PokemonManager.GetCurrActivityId(),fightStageId)
            if cId == chapterId then
                count = count + 1
            end
        end
        return count
    end

    function XPokemonManager.GetNextStage()
        local nextIndex = XPokemonManager.GetPassedCount() + 1
        local totalCount = XPokemonManager.GetStageCountByType(XPokemonConfigs.StageType.Normal) + XPokemonManager.GetStageCountByType(XPokemonConfigs.StageType.Skip)
        nextIndex = XMath.Clamp(nextIndex, 1, totalCount)
        return nextIndex
    end

    function XPokemonManager.GetStageTotalCount()
        return XPokemonManager.GetStageCountByType(XPokemonConfigs.StageType.Normal) + XPokemonManager.GetStageCountByType(XPokemonConfigs.StageType.Skip)
    end

    function XPokemonManager.GetRemainingTimes()
        return _RemainingTimes
    end

    function XPokemonManager.CheckRemainingTimes()
        return true
        --return XPokemonManager.GetRemainingTimes() > 0
    end

    function XPokemonManager.IsInfinity()
        return XPokemonManager.GetPassedCount() >= XPokemonManager.GetStageCountByType(XPokemonConfigs.StageType.Normal)
    end

    function XPokemonManager.GetPokemonStageId(index)
        return XPokemonConfigs.GetPokemonStageId(index, XPokemonManager.GetCurrActivityId(), XPokemonManager.GetSelectChapter())
    end

    function XPokemonManager.GetStageUnlockDesc(stageId)
        return XPokemonConfigs.GetStageUnlockDesc(stageId, XPokemonManager.GetCurrActivityId(),XPokemonManager.GetSelectChapter())
    end

    function XPokemonManager.GetStageFightStageId(stageId)
        return XPokemonConfigs.GetStageFightStageId(stageId, XPokemonManager.GetCurrActivityId(),XPokemonManager.GetSelectChapter())
    end

    function XPokemonManager.GetStageMonsterIds(stageId)
        return XPokemonConfigs.GetStageMonsterIds(stageId, XPokemonManager.GetCurrActivityId(),XPokemonManager.GetSelectChapter())
    end

    function XPokemonManager.GetStageIcon(stageId)
        return XPokemonConfigs.GetStageIcon(stageId, XPokemonManager.GetCurrActivityId(),XPokemonManager.GetSelectChapter())
    end

    function XPokemonManager.GetStageName(stageId)
        return XPokemonConfigs.GetStageName(stageId, XPokemonManager.GetCurrActivityId(),XPokemonManager.GetSelectChapter())
    end

    function XPokemonManager.GetStageBg(stageId)
        return XPokemonConfigs.GetStageBg(stageId, XPokemonManager.GetCurrActivityId(),XPokemonManager.GetSelectChapter())
    end

    function XPokemonManager.GetStageBossHeadIcon(stageId)
        return XPokemonConfigs.GetStageBossHeadIcon(stageId, XPokemonManager.GetCurrActivityId(),XPokemonManager.GetSelectChapter())
    end

    function XPokemonManager.IsBossStage(stageId)
        return XPokemonConfigs.IsBossStage(stageId, XPokemonManager.GetCurrActivityId(),XPokemonManager.GetSelectChapter())
    end

    function XPokemonManager.IsInfinityStage(stageId)
        return XPokemonConfigs.IsInfinityStage(stageId, XPokemonManager.GetCurrActivityId(),XPokemonManager.GetSelectChapter())
    end

    function XPokemonManager.IsCanSkipStage(stageId)
        return XPokemonConfigs.IsCanSkipStage(stageId, XPokemonManager.GetCurrActivityId(),XPokemonManager.GetSelectChapter())
    end


    function XPokemonManager.GetStageCountByType(type)
        return XPokemonConfigs.GetStageCountByType(type, XPokemonManager.GetCurrActivityId(),XPokemonManager.GetSelectChapter())
    end

    function XPokemonManager.GetStageCountByChapter()
        return XPokemonConfigs.GetStageCountByChapter(XPokemonManager.GetCurrActivityId(),XPokemonManager.GetSelectChapter())
    end

    function XPokemonManager.GetShowAbility(stageId, pos)
        return XPokemonConfigs.GetShowAbility(stageId, XPokemonManager.GetCurrActivityId(), pos,XPokemonManager.GetSelectChapter())
    end

    function XPokemonManager.GetChapterPerPageStageCount()
        return XPokemonConfigs.GetChapterPerPageStageCount(XPokemonManager.GetSelectChapter())
    end

    function XPokemonManager.GetChapterUiTemplateCount()
        return XPokemonConfigs.GetUiTemplateCountByChapter(XPokemonManager.GetSelectChapter())
    end

    function XPokemonManager.GetUiTemplate(index,type)
        return XPokemonConfigs.GetUiTemplate(XPokemonManager.GetSelectChapter(), index, type)
    end

    function XPokemonManager.PokemonSkipStageRequest(stageId,cb)
        local req = {StageId = stageId}
        XNetwork.Call("PokemonSkipStageRequest",req,function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_POKEMON_PASSED_STAGE_CHANGE)
            if cb then
                cb(res.RewardGoods)
            end
        end)
    end

    function XPokemonManager.NotifyPokemonStageSkipInfo(data)
        if not data then return end
        UpdateSkipStageInfo(data.SkipedStageIdList)
        UpdateStageSkipTimes(data.StageSkipTimes)
    end

    function XPokemonManager.NotifyPokemonRemoveStageSkiped(data)
        if not data then return end
        for i = #_SkipStageInfo, 1, -1 do
            if _SkipStageInfo[i] == data then
                table.remove(_SkipStageInfo, i)
            end
        end
    end

    -----------------关卡相关 end----------------
    -----------------其他部分XXX begin----------------
    local _TimeSupplyLastGetTime = 0
    local _CurrActivityId = XPokemonConfigs.GetDefaultActivityId()

    function XPokemonManager.GetCurrActivityId()
        return _CurrActivityId
    end

    local function UpdateActivityId(activityId)
        if not XTool.IsNumberValid(activityId) then return end
        _CurrActivityId = activityId or XPokemonConfigs.GetDefaultActivityId()
    end

    function XPokemonManager.GetCurrTaskTimeLimitId()
        return XPokemonConfigs.GetActivityTaskTimeLimitId(XPokemonManager.GetCurrActivityId())
    end

    function XPokemonManager.GetPokemonTimeLimitTask()
        local groupId = XPokemonManager.GetCurrTaskTimeLimitId()
        if groupId == 0 then return {} end
        return XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(groupId)
    end

    function XPokemonManager.GetActivityChapters()
        local chapters = {}
        if XPokemonConfigs.HasActivityInTime() then
            local tempChapter = {}
            tempChapter.Id = XPokemonManager.GetCurrActivityId()
            tempChapter.Type = XDataCenter.FubenManager.ChapterType.Pokemon
            tempChapter.BannerBg = XPokemonConfigs.GetActivityBg(tempChapter.Id)
            tableInsert(chapters, tempChapter)
        end
        return chapters
    end

    function XPokemonManager.IsOpen()
        local nowTime = XTime.GetServerNowTimestamp()
        local beginTime = XPokemonManager.GetStartTime()
        local endTime = XPokemonManager.GetEndTime()
        return beginTime <= nowTime and nowTime < endTime
    end

    function XPokemonManager.GetStartTime()
        return XPokemonConfigs.GetActivityStartTime(XPokemonManager.GetCurrActivityId()) or 0
    end

    function XPokemonManager.GetEndTime()
        return XPokemonConfigs.GetActivityEndTime(XPokemonManager.GetCurrActivityId()) or 0
    end

    function XPokemonManager.GetCurrActivityTime()
        return XPokemonManager.GetStartTime(), XPokemonManager.GetEndTime()
    end

    local function GetTimeSupplyLastGetTime()
        return _TimeSupplyLastGetTime or 0
    end

    local function UpdateTimeSupplyLastGetTime(time)
        _TimeSupplyLastGetTime = time or 0
    end

    function XPokemonManager.PokemonGetTimeSupplyRewardRequest(callback)
        XNetwork.Call("PokemonGetTimeSupplyRewardRequest", nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            local rewardsList = res.RewardGoods or {}
            UpdateTimeSupplyLastGetTime(res.TimeSupplyLastGetTime)
            XEventManager.DispatchEvent(XEventId.EVENT_POKEMON_RED_POINT_TIME_SUPPLY)
            if callback then callback(rewardsList) end
        end)
    end

    function XPokemonManager.GetTimeSupplyOffsetTime()
        local now = XTime.GetServerNowTimestamp()
        local offset = now - GetTimeSupplyLastGetTime()
        offset = XMath.Clamp(offset, 0, XPokemonConfigs.GetTimeSupplyMaxCount() * XPokemonConfigs.GetTimeSupplyInterval())
        return offset or 0
    end

    function XPokemonManager.CheckCanGetTimeSupply()
        return XPokemonManager.GetTimeSupplyOffsetTime() >= XPokemonConfigs.GetTimeSupplyInterval()
    end
    -----------------其他部分XXX end------------------
    local _IsFirstEnter = false

    local function ResetPokemonData(isReset)
        _Monsters = {}
        _NewMonsterIds = {}
        _MaxEnergy = 0
        XPokemonManager.InitTeam()
        _PassedStageDic = {}
        _RemainingTimes = XPokemonConfigs.GetDefaultStageTimes()
        _TimeSupplyLastGetTime = 0
        _IsFirstEnter = true
        _IsSwitchToInfinity = false
        _NextRecoverTime = 0
        _SkipStageInfo = {}
        _StageSkipTimes = 0
    end

    function XPokemonManager.OnActivityEnd()
        if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") or XLuaUiManager.IsUiLoad("UiSettleLose") or XLuaUiManager.IsUiLoad("UiSettleWin") then
            return
        end
        XUiManager.TipText("PokemonOver")
        XLuaUiManager.RunMain()
    end

    function XPokemonManager.OpenPokemonMainUi()
        if XPokemonManager.IsOpen() then
            local movieId = XPokemonConfigs.GetEnterMovieId()
            if _IsFirstEnter and (not string.IsNilOrEmpty(movieId))then
                XDataCenter.MovieManager.PlayMovie(movieId, function()
                    XLuaUiManager.Open("UiPokemonMainLineBanner")
                end)
                _IsFirstEnter = false
            else
                XLuaUiManager.Open("UiPokemonMainLineBanner")
            end
        else
            XUiManager.TipText("PokemonOver")
        end
    end

    function XPokemonManager.CheckPokemonTaskRedPoint()
        return XDataCenter.TaskManager.CheckLimitTaskList(XPokemonManager.GetCurrTaskTimeLimitId())
    end

    function XPokemonManager.CheckPokemonEnterRedPoint()
        if not XPokemonManager.IsOpen() then return false end

        local timeSupplyOffset = XPokemonManager.GetTimeSupplyOffsetTime()
        local maxTimeSupply = XPokemonConfigs.GetTimeSupplyMaxCount() * XPokemonConfigs.GetTimeSupplyInterval()
        return timeSupplyOffset >= maxTimeSupply
    end

    function XPokemonManager.NotifyPokemonData(data)
        local isReset = data.IsActivityReset
        if isReset then ResetPokemonData() end

        local checkNew = isReset and true --重置时获得的所有怪物均为新获得
        UpdateMonsters(data.MonsterList, checkNew)
        UpdateMaxEnergy(data.MaxEnergy)
        UpdateUnlockedPositionList(data.UnlockedPositionList)
        UpdateTeam(data.FormationData and data.FormationData.MonsterIdList)
        UpdatePassedStage(data.PassedStageIdList)
        UpdateRemainingTimes(data.StageTimes)
        UpdateTimeSupplyLastGetTime(data.TimeSupplyLastGetTime)
        UpdateActivityId(data.ActivityId)
        UpdateRandomMonsterData(data.RandomStageData)
        UpdateNextRecoverTime(data.StageTimesNextRecoverTime)
        UpdateStageSkipTimes(data.StageSkipTimes)
        UpdateSkipStageInfo(data.SkipedStageIdList)
    end

    function XPokemonManager.Init()
        XPokemonManager.InitTeam()
    end

    XPokemonManager.Init()

    return XPokemonManager
end
---------------------(服务器推送) begin------------------
XRpc.NotifyPokemonData = function(data)
    XDataCenter.PokemonManager.NotifyPokemonData(data)
end

XRpc.NotifyPokemonMonster = function(data)
    XDataCenter.PokemonManager.NotifyPokemonMonster(data)
end

XRpc.NotifyPokemonUnlock = function(data)
    XDataCenter.PokemonManager.NotifyPokemonUnlock(data)
end

XRpc.NotifyPokemonStagePassed = function(data)
    XDataCenter.PokemonManager.NotifyPokemonStagePassed(data)
end

XRpc.NotifyPokemonStageTimesInfo = function(data)
    XDataCenter.PokemonManager.NotifyPokemonRemainingTimesChange(data)
end

XRpc.NotifyPokemonStageSkipInfo = function(data)
    XDataCenter.PokemonManager.NotifyPokemonStageSkipInfo(data)
end

XRpc.NotifyPokemonRemoveStageSkiped = function(data)
    XDataCenter.PokemonManager.NotifyPokemonRemoveStageSkiped(data)
end

---------------------(服务器推送)end------------------