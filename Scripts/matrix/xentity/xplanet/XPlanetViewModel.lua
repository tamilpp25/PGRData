---@class XPlanetViewModel:XDataEntityBase
---@field _ActivityId number
---@field _PassStage table
---@field _UnlockCharacter table
---@field _StageData table
---@field _GlobalEffect table
local XPlanetViewModel = XClass(XDataEntityBase, "XPlanetViewModel")

local default = {
    _ActivityId = 0, --活动Id,
    _PassStage = {},
    _UnlockCharacter = {},

    _SelectBuildings = {},
    _GlobalEffect = {},

    _ReformWeather = 0,
    _ReformIncId = 0,
    _ReformBuildBuyCount = {},
    _ReformBuildCharacterIds = {},
    _ReformBuildingData = {},
    _ReformBuildQuickRecycle = false,
}

function XPlanetViewModel:Ctor(id)
    self:Init(default, id)
end

function XPlanetViewModel:InitData(id)
    self:SetProperty("_ActivityId", id)
end


--region 活动状态
function XPlanetViewModel:IsOpen()
    return XTool.IsNumberValid(self._ActivityId) and XPlanetConfigs.CheckInTime(self._ActivityId)
end

function XPlanetViewModel:GetStartTime()
    return XFunctionManager.GetStartTimeByTimeId(XPlanetConfigs.GetActivityTimeId(self._ActivityId))
end

function XPlanetViewModel:GetEndTime()
    return XFunctionManager.GetEndTimeByTimeId(XPlanetConfigs.GetActivityTimeId(self._ActivityId))
end
--endregion


--region Shop
function XPlanetViewModel:GetActivityShopIdList()
    return XPlanetConfigs.GetActivityShopIdList(self:GetProperty("_ActivityId"))
end
--endregion


--region Task
function XPlanetViewModel:GetActivityTimeLimitTaskId()
    return XPlanetConfigs.GetActivityTimeLimitTaskId(self:GetProperty("_ActivityId"))
end
--endregion


--region Chapter
function XPlanetViewModel:CheckChapterIsUnlock(chapterId, defaultOpen)
    return self:CheckChapterIsInTime(chapterId, defaultOpen) and self:CheckChapterPreStageIsPass(chapterId)
end

function XPlanetViewModel:CheckChapterIsInTime(chapterId, defaultOpen)
    local time = XPlanetStageConfigs.GetChapterOpenTimeId(chapterId)
    return XFunctionManager.CheckInTimeByTimeId(time, defaultOpen)
end

function XPlanetViewModel:CheckChapterPreStageIsPass(chapterId)
    local stageId = XPlanetStageConfigs.GetChapterPreStageId(chapterId)
    if not XTool.IsNumberValid(stageId) then return true end
    return self:CheckStageIsPass(stageId)
end
--endregion


--region Stage
function XPlanetViewModel:GetSelectBuilding()
    return self:GetProperty("_SelectBuildings")
end

---@param data table
function XPlanetViewModel:SetSelectBuilding(data)
    self:SetProperty("_SelectBuildings", data)
end

---@param building XPlanetDataBuilding
function XPlanetViewModel:IsBuildingSelected(building)
    local buildingSelected = self:GetSelectBuilding()
    for _, id in pairs(buildingSelected) do
        if building:GetId() == id then
            return true
        end
    end
    return false
end

function XPlanetViewModel:UpdatePassStage(passStage)
    for _, stageId in pairs(passStage) do
        self._PassStage[stageId] = true
    end
end

function XPlanetViewModel:AddPassStage(stageId)
    self._PassStage[stageId] = true
end

function XPlanetViewModel:CheckStageIsPass(stageId)
    if not XTool.IsNumberValid(stageId) then return true end
    return self._PassStage[stageId]
end

function XPlanetViewModel:CheckStageUnlock(stageId)
    return self:CheckStagePreStagePass(stageId) and self:CheckStageChapterUnlock(stageId)
end

function XPlanetViewModel:CheckStagePreStagePass(stageId)
    local preStageId = XPlanetStageConfigs.GetStagePreStageId(stageId)
    return self:CheckStageIsPass(preStageId)
end

function XPlanetViewModel:CheckStageChapterUnlock(stageId)
    local chapterId = XPlanetStageConfigs.GetStageChapterId(stageId)
    return self:CheckChapterIsInTime(chapterId) and self:CheckChapterPreStageIsPass(chapterId)
end
--endregion


--region Character
function XPlanetViewModel:UpdateUnlockCharacter(UnlockCharacter)
    for _, characterId in pairs(UnlockCharacter) do
        self._UnlockCharacter[characterId] = true
    end
end

function XPlanetViewModel:SetCharacterUnlock(characterId)
    self._UnlockCharacter[characterId] = true
end

function XPlanetViewModel:CheckCharacterIsUnlock(characterId)
    return self._UnlockCharacter[characterId]
end
--endregion


--region GlobalEffect
function XPlanetViewModel:UpdateGlobalEffect(globalEffect)
    self:SetProperty("_GlobalEffect", globalEffect)
end
--endregion


--region ReformCharacter
function XPlanetViewModel:GetReformCharacterIds()
    local result = {}
    local dataList = self:GetProperty("_ReformBuildCharacterIds")
    for _, data in ipairs(dataList) do
        table.insert(result, data.Id)
    end
    return result
end

function XPlanetViewModel:UpdateReformBuildCharacterIds(ReformBuildCharacterIds)
    self:SetProperty("_ReformBuildCharacterIds", ReformBuildCharacterIds)
end

function XPlanetViewModel:CheckReformCharacter()
end
--endregion


--region ReformMode 家园改造
function XPlanetViewModel:UpdateReformMode(data)
    self:UpdateReformWeather(data.ReformMode.Weather)
    self:UpdateReformBuildingData(data.ReformMode.BuildingData)
    self:UpdateReformBuildBuyCount(data.ReformMode.BuildBuyCount)
    self:UpdateReformBuildCharacterIds(data.ReformMode.CharacterIds)
    self:UpdateReformModeIncId(data.ReformMode.IncId)
end

function XPlanetViewModel:CheckReformBuildCardIsUnLock(talentbuildingId)
    local preStageId = XPlanetTalentConfigs.GetTalentBuildingUnlockStageId(talentbuildingId)
    if not XTool.IsNumberValid(preStageId) then return true end
    return self:CheckStageIsPass(preStageId)
end

---天赋建筑的数量
function XPlanetViewModel:GetReformBuildCurCount(talentbuildingId)
    local result = 0
    local buildDataList = self._ReformBuildingData[talentbuildingId]
    if XTool.IsTableEmpty(buildDataList) then
        return result
    end
    for _, _ in pairs(buildDataList.Building) do
        result = result + 1
    end
    return result
end

---天赋建筑购买量
function XPlanetViewModel:GetReformBuildCurBuyCount(talentbuildingId)
    return self._ReformBuildBuyCount[talentbuildingId] or 0
end

---天赋建筑当前剩余卡牌量
function XPlanetViewModel:GetReformCardCurHaveCount(talentbuildingId)
    local result = self:GetReformBuildCurBuyCount(talentbuildingId) - self:GetReformBuildCurCount(talentbuildingId)
    return result > 0 and result or 0
end

function XPlanetViewModel:GetReformBuildMaxBuyCount(talentbuildingId)
    local result = XPlanetTalentConfigs.GetTalentBuildingHoldingCount(talentbuildingId)
    local unlockCountStageIds = XPlanetTalentConfigs.GetTalentBuildingUnlockCountStageIds(talentbuildingId)
    local unlockCounts = XPlanetTalentConfigs.GetTalentBuildingUnlockCounts(talentbuildingId)
    if XTool.IsTableEmpty(unlockCountStageIds) then
        return result
    end
    for index, stageId in ipairs(unlockCountStageIds) do
        if self:CheckStageIsPass(stageId) then
            result = unlockCounts[index]
        end
    end
    return result
end

function XPlanetViewModel:GetReformBuildCanUseFloorId(talentbuildingId)
    local result = {}
    local floorIdList = XPlanetTalentConfigs.GetTalentBuildingCanUseFloorId(talentbuildingId)
    if XTool.IsTableEmpty(floorIdList) then
        return result
    end
    for _, floorId in ipairs(floorIdList) do
        if self:CheckStageIsPass(XPlanetWorldConfigs.GetFloorPreStageId(floorId)) then
            table.insert(result, floorId)
        end
    end
    return result
end

---当前已解锁的天气列表
function XPlanetViewModel:GetReformWeatherList()
    local result = {}
    for _, weatherId in pairs(XPlanetWorldConfigs.GetWeatherIdList()) do
        local stageId = XPlanetWorldConfigs.GetWeatherUnlockStageId(weatherId)
        if self:CheckStageIsPass(stageId)
            and XPlanetWorldConfigs.GetWeatherIsTalentShow(weatherId) then
            table.insert(result, weatherId)
        end
    end
    return result
end

function XPlanetViewModel:GetReformModeIncId()
    return self._ReformIncId
end

function XPlanetViewModel:GetReformWeather()
    return self._ReformWeather
end

function XPlanetViewModel:GetReformBuildingData()
    return self._ReformBuildingData
end

function XPlanetViewModel:GetReformCurHaveBuildList()
    local result = {}
    if XTool.IsTableEmpty(self._ReformBuildingData) then
        return result
    end
    
    for buildId, data in pairs(self._ReformBuildingData) do
        if not XTool.IsTableEmpty(data.Building) then
            table.insert(result, buildId)
        end
    end
    return result
end

function XPlanetViewModel:GetReformBuildBuyCount()
    return self.GetProperty("_ReformBuildBuyCount")
end

function XPlanetViewModel:UpdateReformModeIncId(IncId)
    self:SetProperty("_ReformIncId", IncId)
end

function XPlanetViewModel:UpdateReformWeather(Weather)
    self:SetProperty("_ReformWeather", Weather)
end

function XPlanetViewModel:UpdateReformBuildingData(ReformBuildingData)
    self:SetProperty("_ReformBuildingData", ReformBuildingData)
end

function XPlanetViewModel:UpdateReformBuildBuyCount(ReformBuildBuyCount)
    self:SetProperty("_ReformBuildBuyCount", ReformBuildBuyCount)
end

---添加天赋球建筑数据
---@param data table
function XPlanetViewModel:AddReformBuildData(data)
    if XTool.IsTableEmpty(data) then return end
    local buildDir = self._ReformBuildingData[data.BuildingId]
    if XTool.IsTableEmpty(buildDir) then
        self._ReformBuildingData[data.BuildingId] = {["Building"] = {}}
        buildDir = self._ReformBuildingData[data.BuildingId]
    end
    buildDir.Building[data.Guid] = {
        Occupy = data.TalentBuilding.Occupy,
        Rotate = data.TalentBuilding.Rotate,
        MaterialId = data.TalentBuilding.MaterialId,
    }
    
    -- 激活view层绑定
    self:UpdateBindings("_ReformBuildingData")
end

---更新天赋球建筑数据
---@param building XPlanetBuilding
function XPlanetViewModel:UpdateReformBuildData(building)
    if XTool.IsTableEmpty(building) then return end
    local buildDir = self._ReformBuildingData[building:GetBuildingId()]
    if XTool.IsTableEmpty(buildDir) then return end
    local data = buildDir.Building[building:GetGuid()]
    data.Occupy = building:GetOccupyTileList()
    data.Rotate = building:GetBuildingDirection()
    data.MaterialId = building:GetFloorId()

    -- 激活view层绑定
    self:UpdateBindings("_ReformBuildingData")
end

---移除天赋球建筑数据
function XPlanetViewModel:RemoveReformBuildData(buildingId, guid)
    local buildDir = self._ReformBuildingData[buildingId]
    if XTool.IsTableEmpty(buildDir) then return end
    buildDir.Building[guid] = nil

    -- 激活view层绑定
    self:UpdateBindings("_ReformBuildingData")
end

---清空天赋球建筑数据
function XPlanetViewModel:ClearReformBuildData()
    self:SetProperty("_ReformBuildingData", {})
end
--endregion


--region 数据下发
function XPlanetViewModel:NotifyPlanetRunningDataDb(data)
    self:UpdatePassStage(data.PassStage)
    self:UpdateGlobalEffect(data.GlobalEffect)
    self:UpdateUnlockCharacter(data.UnlockCharacter)
    self:SetSelectBuilding(data.SelectBuildings)

    self:UpdateReformWeather(data.ReformMode.Weather)
    self:UpdateReformModeIncId(data.ReformMode.IncId)
    self:UpdateReformBuildingData(data.ReformMode.BuildingData)
    self:UpdateReformBuildBuyCount(data.ReformMode.BuildBuyCount)
    self:UpdateReformBuildCharacterIds(data.ReformMode.CharacterIds)
end
--endregion

return XPlanetViewModel