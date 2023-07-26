local XPlanetWeatherGroup = require("XEntity/XPlanet/Explore/XPlanetWeatherGroup")
local XPlanetDataBuilding = require("XEntity/XPlanet/Explore/XPlanetDataBuilding")

---@class XPlanetStageData:XDataEntityBase
local XPlanetStageData = XClass(XDataEntityBase, "XPlanetStageData")

local default = {
    _StageId = 0,
    _Cycle = 0,
    _WeatherId = 0,
    _WeatherLastCycle = 0,
    _Coin = 0,
    _TalentCoin = 0,
    _GridId = 0,
    _PassGridId = {},
    _RunningItem = {},
    _ItemRecords = {},
    _EffectRecords = {},
    _CharacterData = {},
    _MonsterInc = 0,
    _MonsterData = {},
    _AddEvents = {},
    _IncId = 0,
    _BuildingData = {},
    _KillBossId = {},
}

function XPlanetStageData:Ctor(stageId)
    self:Init(default, stageId)
end

function XPlanetStageData:InitData(stageId)
    self:SetStageId(stageId)
end

function XPlanetStageData:UpdateData(data)
    if XTool.IsTableEmpty(data) then
        self:Reset()
        self:SetStageId(0)
        return
    end

    self:SetStageId(data.StageId)
    self:SetWeatherGroup(data.StageId)
    self:SetBuildIncId(data.IncId)
    self:SetCycle(data.Cycle)
    self:SetWeatherId(data.WeatherId)
    self:SetWeatherLastCycle(data.WeatherLastCycle)
    self:SetCoin(data.Coin)
    self:SetTalentCoin(data.TalentCoin)
    self:SetGridId(data.GridId)
    self:SetMonsterInc(data.MonsterInc)
    self:SetBuildIncId(data.IncId)

    self:SetPassGridId(data.PassGridId)
    self:SetRunningItem(data.RunningItems)
    self:SetItemRecords(data.ItemRecords)
    self:SetEffectRecords(data.CharacterEffectRecords)
    self:SetCharacterData(data.CharacterData)
    self:SetMonsterData(data.MonsterData)
    self:SetAddEvents(data.AddEvents)
    self:SetBuildingData(data.BuildingData)
    self:SetKillBossId(data.KillBossId)
    if XTool.IsNumberValid(data.WeatherLastCycle) then
        self:UpdateWeatherGroupIsInEvent()
    end

    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_UPDATE_STAGE)
end


--region Getter
function XPlanetStageData:GetStageId()
    return self:GetProperty("_StageId")
end

function XPlanetStageData:GetCycle()
    return self:GetProperty("_Cycle")
end

function XPlanetStageData:GetWeatherId()
    return self:GetProperty("_WeatherId")
end

function XPlanetStageData:GetWeatherLastCycle()
    return self:GetProperty("_WeatherLastCycle")
end

function XPlanetStageData:GetCoin()
    return self:GetProperty("_Coin")
end

function XPlanetStageData:GetTalentCoin()
    return self:GetProperty("_TalentCoin")
end

function XPlanetStageData:GetGridId()
    return self:GetProperty("_GridId")
end

function XPlanetStageData:GetMonsterInc()
    return self:GetProperty("_MonsterInc")
end

function XPlanetStageData:GetBuildIncId()
    return self:GetProperty("_IncId")
end

function XPlanetStageData:GetCharacterData()
    return self:GetProperty("_CharacterData")
end

function XPlanetStageData:GetMonsterData()
    return self:GetProperty("_MonsterData")
end

---@return XPlanetWeatherGroup
function XPlanetStageData:GetWeatherGroup()
    return self._WeatherGroup
end
--endregion


--region Setter
---@param stageId number
function XPlanetStageData:SetStageId(stageId)
    self:SetProperty("_StageId", stageId)
end

function XPlanetStageData:SetWeatherGroup(stageId)
    ---@type XPlanetWeatherGroup
    self._WeatherGroup = XPlanetWeatherGroup.New()
    self._WeatherGroup:InitGroup(XPlanetStageConfigs.GetStageWeatherGroupId(stageId))
end

---@param cycle number
function XPlanetStageData:SetCycle(cycle)
    --后端回合计数从0开始的
    self:SetProperty("_Cycle", cycle + 1)
end

---@param weatherId number
function XPlanetStageData:SetWeatherId(weatherId)
    self:SetProperty("_WeatherId", weatherId)
    self._WeatherGroup:SetCurWeather(weatherId)
end

---@param weatherLastCycle number
function XPlanetStageData:SetWeatherLastCycle(weatherLastCycle)
    if XTool.IsNumberValid(weatherLastCycle) then
        self._WeatherGroup:SetCurWeatherEndRound(weatherLastCycle)
        self:SetProperty("_WeatherLastCycle", weatherLastCycle)
    else
        self._WeatherGroup:CleatTempWeatherDir()
        local endRound = self._WeatherGroup:UpdateCurWeatherByRound(self:GetCycle())
        self:SetProperty("_WeatherLastCycle", endRound)
    end
end

function XPlanetStageData:UpdateWeatherGroupIsInEvent()
    self._WeatherGroup:UpdateTempWeather(self:GetWeatherId(), self:GetCycle(), self:GetWeatherLastCycle())
end

---@param coin number
function XPlanetStageData:SetCoin(coin)
    if self:GetCoin() == coin then
        self:UpdateBindings("_Coin")
    end
    self:SetProperty("_Coin", coin)
end

---@param coin number
function XPlanetStageData:SetTalentCoin(coin)
    self:SetProperty("_TalentCoin", coin)
end

---@param gridId number
function XPlanetStageData:SetGridId(gridId)
    self:SetProperty("_GridId", gridId)
end

---@param monsterInc number
function XPlanetStageData:SetMonsterInc(monsterInc)
    self:SetProperty("_MonsterInc", monsterInc)
end

---@param guid number
function XPlanetStageData:SetBuildIncId(guid)
    self:SetProperty("_IncId", guid)
end

---@param data table
function XPlanetStageData:SetPassGridId(data)
    self:SetProperty("_PassGridId", data)
end

---@param data table
function XPlanetStageData:SetRunningItem(data)
    self:SetProperty("_RunningItem", data)
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_UPDATE_ITEM)
end

function XPlanetStageData:GetRunningItem()
    return self:GetProperty("_RunningItem")
end

---@param data table
function XPlanetStageData:SetItemRecords(data)
    self:SetProperty("_ItemRecords", data)
end

---@param data table
function XPlanetStageData:SetEffectRecords(data)
    self:SetProperty("_EffectRecords", data or {})
end

function XPlanetStageData:OnEffectAdd(data)
    local oldData = self:GetEffectRecords()
    self:SetEffectRecords(data)

    local dictNewEffect = {}
    for _, effect in pairs(data) do
        dictNewEffect[effect.Id] = effect.Overlays
    end
    for i = 1, #oldData do
        local effectOld = oldData[i]
        local effectId = effectOld.Id
        if dictNewEffect[effectId] then
            dictNewEffect[effectId] = dictNewEffect[effectId] - effectOld.Overlays
        end
    end

    local effectNew = {}
    for effectId, amount in pairs(dictNewEffect) do
        if amount > 0 then
            effectNew[#effectNew + 1] = effectId
        end
    end
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_NEW_EFFECT, effectNew)
end

function XPlanetStageData:GetEffectRecords()
    return self:GetProperty("_EffectRecords")
end

---@param data table
function XPlanetStageData:SetCharacterData(data)
    self:SetProperty("_CharacterData", data)
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_UPDATE_CHARACTER)
end

---@param data table
function XPlanetStageData:SetMonsterData(data)
    self:SetProperty("_MonsterData", data)
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_UPDATE_MONSTER)
end

---@param list table
function XPlanetStageData:NewMonsterData(list)
    local data = self:GetMonsterData()
    local isSpecialBoss = false
    for i = 1, #list do
        local monster = list[i]
        table.insert(data, monster)
        local bossId = monster.CfgId
        if XPlanetStageConfigs.IsSpecialBoss(bossId) then
            isSpecialBoss = true
        end
    end
    self:SetMonsterData(data)
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_UPDATE_MONSTER)
end

---@param data table
function XPlanetStageData:SetAddEvents(data)
    self:SetProperty("_AddEvents", data)
end

function XPlanetStageData:GetAddEvents(campType, idFromServer)
    local events = self:GetProperty("_AddEvents")
    if not events then
        return {}
    end
    local dictEffect = {}
    local effectRecord = self:GetEffectRecords()
    for _, effect in pairs(effectRecord) do
        dictEffect[effect.Id] = effect.Overlays
    end

    local dict = {}
    for i = 1, #events do
        local event = events[i]
        if campType == event.TargetType then
            local isValid = true
            if idFromServer then
                local isTarget = false
                local targetIds = event.TargetIds
                for j = 1, #targetIds do
                    local targetId = targetIds[j]
                    if targetId == idFromServer then
                        isTarget = true
                        break
                    end
                end
                isValid = isTarget
            end
            if isValid then
                dict[event.Id] = dict[event.Id] or 0
                local effectList = XPlanetStageConfigs.GetEventEffects(event.Id)
                local effect1 = effectList[1]
                local amount = dictEffect[effect1] or 1
                dict[event.Id] = dict[event.Id] + amount
            end
        end
    end
    return dict
end

---@param data table
function XPlanetStageData:SetBuildingData(data)
    self:SetProperty("_BuildingData", data)
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_UPDATE_BUILDING)
end

function XPlanetStageData:GetStageBuildingData()
    return self:GetProperty("_BuildingData")
end

function XPlanetStageData:GetStageBuildingCount(buildingId)
    local result = 0
    local buildDataList = self._BuildingData[buildingId]
    if XTool.IsTableEmpty(buildDataList) then
        return result
    end
    for _, _ in pairs(buildDataList.Building) do
        result = result + 1
    end
    return result
end

function XPlanetStageData:AddStageBuildData(data)
    if XTool.IsTableEmpty(data) then
        return
    end
    local buildDir = self._BuildingData[data.BuildingId]
    if XTool.IsTableEmpty(buildDir) then
        self._BuildingData[data.BuildingId] = { ["Building"] = {} }
        buildDir = self._BuildingData[data.BuildingId]
    end
    buildDir.Building[data.Guid] = {
        Occupy = data.Building.Occupy,
        Rotate = data.Building.Rotate,
        MaterialId = data.Building.MaterialId,
    }
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_UPDATE_BUILDING)
end

function XPlanetStageData:RemoveStageBuildData(buildingId, guid)
    local buildDir = self._BuildingData[buildingId]
    if XTool.IsTableEmpty(buildDir) then
        return
    end
    buildDir.Building[guid] = nil
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_UPDATE_BUILDING)
end
--endregion

function XPlanetStageData:RemoveMonster(gridId2Remove)
    local monsterData = self:GetMonsterData()
    for i = #monsterData, 1, -1 do
        local data = monsterData[i]
        if data.NodeId == gridId2Remove then
            table.remove(monsterData, i)
        end
        local bossId = data.CfgId
        if bossId then
            self:SetKillBoss(bossId)
        end
    end
    self:SetMonsterData(monsterData)
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_REMOVE_BOSS)
end

function XPlanetStageData:IsKillBossId(bossId)
    local dict = self:GetProperty("_KillBossId")
    return dict and dict[bossId]
end

function XPlanetStageData:SetKillBoss(bossId)
    local dict = self:GetProperty("_KillBossId")
    dict = dict or {}
    dict[bossId] = true
end

function XPlanetStageData:SetKillBossId(data)
    local dict = {}
    for i = 1, #data do
        local bossId = data[i]
        dict[bossId] = true
    end
    self:SetProperty("_KillBossId", dict)
end

return XPlanetStageData
