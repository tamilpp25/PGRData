local XPlanetTeam = require("XEntity/XPlanet/Explore/XPlanetTeam")
local XPlanetCharacter = require("XEntity/XPlanet/Explore/XPlanetCharacter")
local XPlanetBuff = require("XEntity/XPlanet/Explore/XPlanetBuff")
local XPlanetResult = require("XEntity/XPlanet/Explore/XPlanetResult")
local XPlanetRunningExplore = require("XUi/XUiPlanet/Explore/XPlanetRunningExplore")
local ATTR = XPlanetCharacterConfigs.ATTR

XPlanetExploreManagerCreator = function()
    local RequestProto = {
        SetTeam = "PlanetRunningCharacterFormationRequest",
        Move = "PlanetRunningDoMoveRequest",
        PreFight = "PlanetRunningPreFightRequest",
        CheckFight = "PlanetRunningCheckFightRequest",
        SelectBuilding = "PlanetRunningSelectBuildingRequest",
        UseItem = "PlanetRunningUseItemRequest",
        SummonBoss = "PlanetRunningManualSummonBossRequest",
        SetCaptain = "PlanetRunningSetCaptainRequest",
    }

    ---@class XPlanetExploreManager
    local XPlanetExploreManager = {}

    local _StageData = {}
    local _Character = {}
    local _Stage = {}
    ---@type XPlanetResult
    local _Result = false

    ---@type XPlanetTeam
    local _Team = XPlanetTeam.New()

    function XPlanetExploreManager.Init()
    end

    function XPlanetExploreManager.OnNotifyData(data)
        _StageData = data.StageData
        _Team:SetInitData(data.FightCharacters)
    end

    function XPlanetExploreManager.IsCharacterUnlock(characterId)
        local isDefaultUnlock = XPlanetCharacterConfigs.GetCharacterDefaultUnlock(characterId)
        local isUnLock = XDataCenter.PlanetManager.GetViewModel():CheckCharacterIsUnlock(characterId)
        return isDefaultUnlock or isUnLock
    end

    function XPlanetExploreManager.GetTeam()
        return _Team
    end

    ---@return XPlanetCharacter
    function XPlanetExploreManager.GetCharacter(characterId)
        if not _Character[characterId] then
            ---@type XPlanetCharacter
            local character = XPlanetCharacter.New()
            character:SetCharacterId(characterId)
            _Character[characterId] = character
        end
        return _Character[characterId]
    end

    function XPlanetExploreManager.GetAllCharacter()
        local result = {}
        local configs = XPlanetCharacterConfigs.GetAllCharacter()
        for i, config in pairs(configs) do
            local characterId = config.Id
            local character = XPlanetExploreManager.GetCharacter(characterId)
            result[#result + 1] = character
        end
        ---@param a XPlanetCharacter
        ---@param b XPlanetCharacter
        table.sort(result, function(a, b)
            if a:IsUnlock() ~= b:IsUnlock() then
                return a:IsUnlock()
            end

            return a:GetPriority() < b:GetPriority()
        end)
        return result
    end

    function XPlanetExploreManager.GetBuffList(eventIds)
        local result = {}
        for i = 1, #eventIds do
            local eventId = eventIds[i]
            ---@type XPlanetBuff
            local buff = XPlanetBuff.New()
            buff:SetEventId(eventId)
            result[#result + 1] = buff
        end
        return result
    end

    local _FightData
    function XPlanetExploreManager.SetFightData(data)
        _FightData = data
    end

    function XPlanetExploreManager.GetFightData()
        return _FightData
    end

    ---@param character XPlanetCharacter
    function XPlanetExploreManager.RequestUpdateTeam()
        local team = XPlanetExploreManager.GetTeam()
        XNetwork.Call(RequestProto.SetTeam, {
            CharacterIds = team:GetData4Request()
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                team:SetData(res.FightCharacterIds)
                XEventManager.DispatchEvent(XEventId.EVENT_PLANET_UPDATE_TEAM)
                return
            end
        end)
    end

    ---@return XPlanetStage
    function XPlanetExploreManager.GetStage(stageId)
        if not stageId then
            local stageData = XDataCenter.PlanetManager.GetStageData()
            if stageData then
                stageId = stageData:GetStageId()
            else
                XLog.Error("[XPlanetExploreManager] 获取当前stage失败")
                return false
            end
        end
        if _Stage[stageId] then
            return _Stage[stageId]
        end
        ---@type XPlanetStage
        local stage = require("XEntity/XPlanet/Explore/XPlanetStage").New()
        stage:SetStageId(stageId)
        _Stage[stageId] = stage
        return stage
    end

    ---@param character XPlanetCharacter
    function XPlanetExploreManager.RequestExploreMove(gridId, callback)
        XNetwork.Call(RequestProto.Move, {
            Grid = gridId,
        }, function(res)
            if res.Code ~= XCode.Success then
                callback(false)
                XUiManager.TipCode(res.Code)
                return
            end
            callback(true)
            local stageData = XDataCenter.PlanetManager.GetStageData()
            stageData:SetGridId(gridId)
        end)
    end

    local _PreFightLastTime = 0
    local _PreFightDuration = 1 -- 服务端限制间隔是1秒
    local _PreFightTimer = false
    local function RequestFight(gridId, callback)
        _PreFightLastTime = CS.UnityEngine.Time.unscaledTime
        XNetwork.Call(RequestProto.PreFight, {
            PreFightData = {
                Grid = gridId,
                StageId = XDataCenter.PlanetManager.GetStageData():GetStageId()
            }
        }, function(res)
            if res.Code ~= XCode.Success then
                if res.Code == XCode.FightCheckManagerClientVersionError then
                    local code = res.Code
                    local text = CS.XTextManager.GetCodeText(code)
                    XLoginManager.DoDisconnect(text)
                    return
                end
                callback(false, res)
                XUiManager.TipCode(res.Code)
                return
            end
            if callback then
                callback(true, res)
            end
        end)
    end

    function XPlanetExploreManager.RequestPreFight(gridId, callback)
        if _PreFightTimer then
            XLog.Error("[XPlanetExploreManager] 同时请求两次战斗:" .. gridId)
            return
        end
        local time = CS.UnityEngine.Time.unscaledTime
        local duration = time - _PreFightLastTime
        if duration > _PreFightDuration then
            RequestFight(gridId, callback)
            return
        end

        _PreFightTimer = XScheduleManager.ScheduleForever(function()
            local time = CS.UnityEngine.Time.unscaledTime
            local duration = time - _PreFightLastTime
            if duration > _PreFightDuration then
                RequestFight(gridId, callback)
                XScheduleManager.UnSchedule(_PreFightTimer)
                _PreFightTimer = false
            end
        end, 0)
    end

    function XPlanetExploreManager.RequestCheckFight(result2Check, callback)
        local stageId = XDataCenter.PlanetManager.GetStageData():GetStageId()
        result2Check.StageId = stageId,
        XNetwork.Call(RequestProto.CheckFight, {
            StageId = stageId,
            ResultData = result2Check,
        }, function(res)
            if res.Code ~= XCode.Success then
                if callback then
                    callback()
                end
                XUiManager.TipCode(res.Code)
                return
            end
            XPlanetExploreManager.OnNotifyResult(res)
            if callback then
                callback()
            end
        end)
    end

    function XPlanetExploreManager.OnFightComplete(data)
        local gridId = data.Grid
        if gridId then
            XDataCenter.PlanetManager.GetStageData():RemoveMonster(gridId)
        end
    end

    function XPlanetExploreManager.RequestUseItem(data)
        XNetwork.Call(RequestProto.UseItem, data, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
        end)
    end

    function XPlanetExploreManager.RequestSelectBuilding(data)
        XNetwork.Call(RequestProto.SelectBuilding, {
            BuildingIds = data
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
        end)
    end

    function XPlanetExploreManager.OnNotifyResult(res)
        local settleData = res.SettleData
        local data = settleData.StageSettleData
        -- 处理关卡的天赋货币收获值
        XDataCenter.PlanetManager.GetStageData():SetTalentCoin(settleData.TalentCoin)
        if not data then
            return
        end

        -- unlock character
        local characters = data.UnlockCharacters
        for i = 1, #characters do
            local characterId = characters[i]
            XDataCenter.PlanetManager.GetViewModel():SetCharacterUnlock(characterId)
        end

        ---@type XPlanetResult
        local result = XPlanetResult.New()
        result:SetData(settleData)
        _Result = result

        if result:IsStageFinish() then
            local stageId = result:GetStageId()
            if stageId and result:IsWin() then
                if not XDataCenter.PlanetManager.GetViewModel():CheckStageIsPass(stageId) then
                    result:SetFirstPass(true)
                end
                XDataCenter.PlanetManager.GetViewModel():AddPassStage(stageId)
            end
        end
    end

    function XPlanetExploreManager.HandleResult(force)
        local result = _Result
        if not result then
            return
        end
        if result:IsPlayed() and not force then
            return
        end
        result:SetPlayed()
        local settleType = result:GetSettleType()
        if settleType == XPlanetExploreConfigs.SETTLE_TYPE.StageFinish
                or settleType == XPlanetExploreConfigs.SETTLE_TYPE.Lose
                or settleType == XPlanetExploreConfigs.SETTLE_TYPE.Quit
        then
            local explore = XPlanetExploreManager.GetExplore()
            if explore then
                explore:Pause(XPlanetExploreConfigs.PAUSE_REASON.RESULT)
            end
            XDataCenter.PlanetManager.ClearRepeatGuideCache()

            XLuaUiManager.SafeClose("UiPlanetBuildDetail")
            XLuaUiManager.SafeClose("UiPlanetDetail02")
            XLuaUiManager.SafeClose("UiPlanetPropertyWeather")
            XLuaUiManager.SafeClose("UiPlanetPropertyPopover")
            XLuaUiManager.SafeClose("UiPlanetExplore")
            XLuaUiManager.Open("UiPlanetDetail", result)
        end
        XDataCenter.PlanetManager.ClearStageData()
    end

    function XPlanetExploreManager.GetResult()
        return _Result
    end

    function XPlanetExploreManager.NotifyPlanetRunningWeatherChange(data)
        local stageData = XDataCenter.PlanetManager.GetStageData()
        stageData:SetWeatherId(data.Weather)
        stageData:SetWeatherLastCycle(data.WeatherLastCycle)
        -- 事件改变天气
        if XTool.IsNumberValid(data.WeatherLastCycle) then
            stageData:UpdateWeatherGroupIsInEvent()
        end
        XEventManager.DispatchEvent(XEventId.EVENT_PLANET_UPDATE_STAGE_WEATHER)
    end

    ---@type XPlanetRunningExplore
    local _Explore = false
    function XPlanetExploreManager.CreateExplore()
        _Explore = XPlanetRunningExplore.New()
        return _Explore
    end

    function XPlanetExploreManager.DestroyExplore()
        _Explore:Destroy()
        _Explore = false
        XPlanetExploreManager.ClearTimeScale()
    end

    function XPlanetExploreManager.GetExplore()
        return _Explore
    end

    function XPlanetExploreManager.RequestSummonBoss(callback)
        XNetwork.Call(RequestProto.SummonBoss, {}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if callback then
                callback()
            end
        end)
    end

    ---@param entities XPlanetRunningExploreEntity[]
    function XPlanetExploreManager.UpdateCharacterListAttrByClient(entities)
        for i = 1, #entities do
            local entity = entities[i]
            XPlanetExploreManager.UpdateCharacterAttrByClient(entity)
        end
    end

    ---@param entity XPlanetRunningExploreEntity
    function XPlanetExploreManager.UpdateCharacterAttrByClient(entity)
        local characterId = entity.Data.IdFromConfig
        local attr = XPlanetExploreManager.GetCharacterAttr(characterId)
        entity.Attr.MaxLife = attr[ATTR.MaxLife]
        entity.Attr.Attack = attr[ATTR.Attack]
        entity.Attr.Defense = attr[ATTR.Defense]
        entity.Attr.CriticalPercent = attr[ATTR.CriticalChance]
        entity.Attr.CriticalDamageAdded = attr[ATTR.CriticalDamage]
        entity.Attr.Speed = attr[ATTR.AttackSpeed]
    end

    function XPlanetExploreManager.GetCharacterAttr(characterId)
        local attrId = XPlanetCharacterConfigs.GetCharacterAttrId(characterId)
        if not attrId then
            return {}
        end

        local baseAttrConfig = XPlanetStageConfigs.GetAttr(attrId)
        if not baseAttrConfig then
            return {}
        end

        local attr = {
            [ATTR.Life] = baseAttrConfig.Life,
            [ATTR.MaxLife] = baseAttrConfig.Life,
            [ATTR.Attack] = baseAttrConfig.Attack,
            [ATTR.Defense] = baseAttrConfig.Defense,
            [ATTR.CriticalChance] = baseAttrConfig.CriticalChance,
            [ATTR.CriticalDamage] = baseAttrConfig.CriticalDamage,
            [ATTR.AttackSpeed] = baseAttrConfig.AttackSpeed,
        }
        local baseAttr = XTool.Clone(attr)

        local stageData = XDataCenter.PlanetManager.GetStageData()
        local effectList = stageData:GetEffectRecords()
        for i = 1, #effectList do
            ---@type {Id:number, Overlays:number}
            local effect = effectList[i]
            local effectId = effect.Id
            local effectType = XPlanetStageConfigs.GetEffectType(effectId)
            local effectParams = XPlanetStageConfigs.GetEffectParams(effectId)
            if effectType == XPlanetStageConfigs.XPlanetRunningEffectType.AttrChange then
                local attrType = effectParams[3] + 1
                if attr[attrType] then
                    --local existType = effectParams[3]
                    local changeValue = effectParams[5]
                    local value = baseAttr[attrType]

                    if attrType == XPlanetStageConfigs.XPlanetRunningAttrChangeType.TenThousandthRatio then
                        local baseValue = baseAttr[attrType]
                        if (baseValue == 0) then
                            return
                        end

                        changeValue = math.ceil(changeValue / 10000 * value)
                    end

                    if XPlanetStageConfigs.GetEffectOverlying(effectId) then
                        changeValue = changeValue * effect.Overlays
                    end

                    attr[attrType] = attr[attrType] + changeValue
                end
            end
        end

        -- 除了速度, 其他属性不能为负
        for attrType, value in pairs(attr) do
            if value < 0 then
                if attrType ~= ATTR.AttackSpeed then
                    if attrType == ATTR.Life then
                        attr[attrType] = math.min(attr[attrType], 1)
                    elseif attrType == ATTR.Attack then
                        attr[attrType] = math.min(attr[attrType], 1)
                    else
                        attr[attrType] = 0
                    end
                end
            end
        end

        -- 暴击率最大100%
        if attr[ATTR.CriticalChance] > 10000 then
            attr[ATTR.CriticalChance] = 10000
        end

        return attr
    end

    local _TimeScale = XPlanetExploreConfigs.TIME_SCALE_FIGHT.NORMAL
    function XPlanetExploreManager.SetTimeScale(timeScale)
        _TimeScale = timeScale
    end

    function XPlanetExploreManager.GetTimeScale()
        return _TimeScale
    end

    function XPlanetExploreManager.ClearTimeScale()
        _TimeScale = XPlanetExploreConfigs.TIME_SCALE_FIGHT.NORMAL
    end

    function XPlanetExploreManager.SetCaptain(characterId, callback)
        local stageData = XDataCenter.PlanetManager.GetStageData()
        local characterData = stageData:GetCharacterData()
        local captain
        local index
        for i = 1, #characterData do
            local data = characterData[i]
            if data.Id == characterId then
                index = i
                captain = data
            end
        end
        if not index then
            return
        end
        XNetwork.Call(RequestProto.SetCaptain, {
            Index = index - 1
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if index ~= 1 then
                local captainOld = characterData[1]
                characterData[1] = characterData[index]
                characterData[index] = captainOld
            end
            XEventManager.DispatchEvent(XEventId.EVENT_PLANET_UPDATE_CHARACTER)
            if callback then
                callback()
            end
        end)
    end

    ---@param stage XPlanetStage
    function XPlanetExploreManager.EnterStage(stage, callback)
        local stageId = stage:GetStageId()
        local team = XPlanetExploreManager.GetTeam()
        local members = team:GetData4Request()
        local building = stage:GetBuildingSelected()

        XDataCenter.PlanetManager.SetSceneActive(false)
        XDataCenter.PlanetManager.EnterStage("UiPlanetBattleMain", stageId, members, building, callback)
    end

    function XPlanetExploreManager.OpenUiPlanetEncounter(...)
        XLuaUiManager.SafeClose("UiPlanetEncounter")
        XLuaUiManager.Open("UiPlanetEncounter", ...)
    end

    return XPlanetExploreManager
end

XRpc.NotifyPlanetRunningWeatherChange = function(data)
    XDataCenter.PlanetExploreManager.NotifyPlanetRunningWeatherChange(data)
end