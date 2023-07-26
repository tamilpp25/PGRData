local XPlanetBoss = require("XEntity/XPlanet/Explore/XPlanetBoss")
local XPlanetDataBuilding = require("XEntity/XPlanet/Explore/XPlanetDataBuilding")

---@class XPlanetStage
local XPlanetStage = XClass(nil, "XPlanetStage")

function XPlanetStage:Ctor()
    self._StageId = false
end

---@param a XPlanetDataBuilding
---@param b XPlanetDataBuilding
function XPlanetStage:SortBuilding(a, b)
    local recommendA, recommendB = 0, 0
    if self:IsRecommend(a) then
        recommendA = 1
    end
    if self:IsRecommend(b) then
        recommendB = 1
    end
    if recommendA ~= recommendB then
        return recommendA > recommendB
    end

    local bandedA, bandedB = 0, 0
    if self:IsBanned(a) then
        bandedA = 1
    end
    if self:IsBanned(b) then
        bandedB = 1
    end
    if bandedA ~= bandedB then
        return bandedA < bandedB
    end
    return a:GetId() < b:GetId()
end

function XPlanetStage:GetStageId()
    return self._StageId
end

function XPlanetStage:SetStageId(stageId)
    self._StageId = stageId
end

function XPlanetStage:GetName()
    return XPlanetStageConfigs.GetStageFullName(self._StageId)
end

function XPlanetStage:GetIcon()
    return XPlanetStageConfigs.GetStageIcon(self._StageId)
end

function XPlanetStage:GetProgressPerRound()
    return XPlanetStageConfigs.GetProgressPerRound(self._StageId)
end

---@param a XPlanetBoss
---@param b XPlanetBoss
local function SortBoss(a, b)
    return a:GetProgress2Born() < b:GetProgress2Born()
end

---@return XPlanetBoss[]
function XPlanetStage:GetBoss()
    local bossGroupId = XPlanetStageConfigs.GetStageBossGroupId(self._StageId)
    local bossArray = XPlanetStageConfigs.GetBossByGroup(bossGroupId)
    local result = {}
    for i = 1, #bossArray do
        local config = bossArray[i]
        ---@type XPlanetBoss
        local boss = XPlanetBoss.New()
        boss:SetBossId(config.BossId)
        boss:SetGroupIdFromStage(config.GroupId)
        result[#result + 1] = boss
    end
    table.sort(result, SortBoss)
    return result
end

function XPlanetStage:GetTeam()
    return XDataCenter.PlanetExploreManager.GetTeam()
end

function XPlanetStage:GetDesc()
    local events = XPlanetStageConfigs.GetStageEnvironmentEvents(self._StageId)
    local desc = ""
    for i, eventId in pairs(events) do
        if XPlanetStageConfigs.GetEventIsShow(eventId) then
            local descEvent = XPlanetStageConfigs.GetEventDesc(eventId)
            desc = string.format("%s%s\n", desc, descEvent)
        end
    end
    return desc
end

function XPlanetStage:GetBuildingCanBring()
    local buildingList = XPlanetWorldConfigs.GetBuildingCanBring()

    local result = {}
    for i = 1, #buildingList do
        local id = buildingList[i]
        if XDataCenter.PlanetManager.CheckBuildingIsUnLock(id) then
            result[#result + 1] = XPlanetDataBuilding.New(id)
        end
    end

    table.sort(result, Handler(self, self.SortBuilding))
    return result
end

---@param building XPlanetDataBuilding
function XPlanetStage:IsRecommend(building)
    local configs = XPlanetStageConfigs.GetBuildingRecommend(self:GetStageId())
    for i = 1, #configs do
        local config = configs[i]
        if config.Building == building:GetId() then
            return true
        end
    end
    return false
end

---@param building XPlanetDataBuilding
function XPlanetStage:IsBanned(building)
    local configs = XPlanetStageConfigs.GetStageDisableBuilding(self:GetStageId())
    for i = 1, #configs do
        local id = configs[i]
        if id == building:GetId() then
            return true
        end
    end
    return false
end

---@param building XPlanetDataBuilding
function XPlanetStage:IsSureBring(building)
    local configs = XPlanetStageConfigs.GetStageCompelUsedBuilding(self:GetStageId())
    for i = 1, #configs do
        local id = configs[i]
        if id == building:GetId() then
            return true
        end
    end
    return false
end

function XPlanetStage:GetBuildingRecommendDefault()
    local idList = XPlanetStageConfigs.GetBuildingRecommendDefault(self:GetStageId())
    return idList
end

function XPlanetStage:GetBuildingCapacity()
    return XPlanetStageConfigs.GetStageCarryBuildingCount(self:GetStageId())
end

function XPlanetStage:GetBuildingBringAmount()
    local data = XDataCenter.PlanetManager.GetViewModel():GetSelectBuilding()
    local result = {}
    data = self:GetBuildingAssurance(data)
    for i = 1, #data do
        local id = data[i]
        ---@type XPlanetDataBuilding
        local building = XPlanetDataBuilding.New(id)
        if building:IsCanSelect() then
            result[#result + 1] = building
        end
    end
    return #result
end

function XPlanetStage:GetBuildingBanned()
    local buildingBanned = XPlanetStageConfigs.GetStageDisableBuilding(self:GetStageId())
    return buildingBanned
end

function XPlanetStage:GetBuildingSureBring()
    local buildingSureBring = XPlanetStageConfigs.GetStageCompelUsedBuilding(self:GetStageId())
    return buildingSureBring
end

local function SortBuilding(a, b)
    return a < b
end

local BringStatus = {
    Bring = 0,
    Oversize = 1,
    MustBring = 2,
    Banned = 3,
    CanNotSelect = 4,
    Lock = 5,
}

function XPlanetStage:GetBuildingAssurance(buildingList)
    local result = {}
    local isChanged = false

    -- 去重
    local dict = {}
    for i = 1, #buildingList do
        local id = buildingList[i]
        dict[id] = BringStatus.Bring
    end

    -- 去除 canSelect == 0
    for i = 1, #buildingList do
        local id = buildingList[i]
        if not XPlanetWorldConfigs.GetBuildingIsCanSelect(id) then
            dict[id] = BringStatus.CanNotSelect
        end
    end

    -- 增加必带的
    local buildingSureBring = self:GetBuildingSureBring()
    for _, id in pairs(buildingSureBring) do
        dict[id] = BringStatus.MustBring
    end

    -- 去除禁止的
    local buildingBanned = self:GetBuildingBanned()
    for _, id in pairs(buildingBanned) do
        dict[id] = BringStatus.Banned
    end

    -- 去除未解锁的
    for id, value in pairs(dict) do
        if not XDataCenter.PlanetManager.CheckBuildingIsUnLock(id) then
            dict[id] = BringStatus.Lock
        end
    end

    -- 卸载超过上限的
    local amountMax = XPlanetStageConfigs.GetStageCarryBuildingCount(self:GetStageId())
    local count = 0
    for id, value in pairs(dict) do
        if value == BringStatus.Bring then
            count = count + 1
        elseif value == BringStatus.MustBring and XPlanetWorldConfigs.GetBuildingIsCanSelect(id) then
            count = count + 1
        end
    end
    if count > amountMax then
        local list = {}
        for id, value in pairs(dict) do
            list[#list + 1] = id
        end
        -- 从id大的开始卸载
        table.sort(list, SortBuilding)
        for i = 1, #list do
            local id = list[i]
            local value = dict[id]
            if value == BringStatus.Bring then
                dict[id] = BringStatus.Oversize
                count = count - 1
                if count <= amountMax then
                    break
                end
            end
        end
    end

    for id, value in pairs(dict) do
        if value == BringStatus.Bring or value == BringStatus.MustBring then
            result[#result + 1] = id
        end
    end
    table.sort(result, SortBuilding)

    if #result ~= #buildingList then
        isChanged = true
    else
        for i = 1, #result do
            if result[i] ~= buildingList[i] then
                isChanged = true
                break
            end
        end
    end

    return result, isChanged
end

---@param building XPlanetDataBuilding
function XPlanetStage:SetBuildingSelected(building, isSelected)
    local data = XDataCenter.PlanetManager.GetViewModel():GetSelectBuilding()
    if isSelected then
        data[#data + 1] = building:GetId()
    else
        for i = 1, #data do
            local id = data[i]
            if id == building:GetId() then
                table.remove(data, i)
                break
            end
        end
    end
    data = self:GetBuildingAssurance(data)
    XDataCenter.PlanetManager.GetViewModel():SetSelectBuilding(data)
    XDataCenter.PlanetExploreManager.RequestSelectBuilding(data)
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_UPDATE_BUILDING_SELECT)
end

function XPlanetStage:GetBuildingSelected()
    local viewModel = XDataCenter.PlanetManager.GetViewModel()
    local data = viewModel:GetSelectBuilding()
    local isChanged
    data, isChanged = self:GetBuildingAssurance(data)
    if isChanged then
        XDataCenter.PlanetExploreManager.RequestSelectBuilding(data)
    end
    viewModel:SetSelectBuilding(data)
    return data
end

return XPlanetStage