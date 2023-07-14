local XUiGridInfoSupportCondition = require("XUi/XUiFubenBabelTower/XUiGridInfoSupportCondition")

local XUiPanelBabelTowerRoom = XClass(nil, "XUiPanelBabelTowerRoom")

function XUiPanelBabelTowerRoom:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.GridCondition.gameObject:SetActiveEx(false)
    self.DynamicTableSupportConditon = XDynamicTableNormal.New(self.PanelCondition.gameObject)
    self.DynamicTableSupportConditon:SetProxy(XUiGridInfoSupportCondition)
    self.DynamicTableSupportConditon:SetDelegate(self)
end

-- team : XTeam
function XUiPanelBabelTowerRoom:SetData(stageId, team)
    self.StageTemplate = XFubenBabelTowerConfigs.GetBabelTowerStageTemplate(stageId)
    local characterIds = team:GetEntityIds()
    self:Refresh(characterIds)
end

function XUiPanelBabelTowerRoom:Refresh(characterIds)
    self.CharacterIds = characterIds

    self.TxtTotalPoint.text = self:GetTotalSupportPoint()

    self.SupportConditionList = self:GetStageSupportConditionListSort()
    self.DynamicTableSupportConditon:SetDataSource(self.SupportConditionList)
    self.DynamicTableSupportConditon:ReloadDataASync()
end

function XUiPanelBabelTowerRoom:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.SupportConditionList[index] then
            grid:SetItemInfo(self.SupportConditionList[index])
        end
    end
end

function XUiPanelBabelTowerRoom:GetStageSupportConditionListSort()
    if not self.StageTemplate then return {} end
    local conditionList = {}
    for i = 1, #self.StageTemplate.SupportConditionId do
        local conditionId = self.StageTemplate.SupportConditionId[i]
        local conditionTemplate = XFubenBabelTowerConfigs.GetBabelTowerSupportConditonTemplate(conditionId)
        local isSupport = self:CheckBabelTeamCondition(conditionTemplate.Condition)
        table.insert(conditionList, {
            SupportConditionId = conditionId,
            IsSupport = isSupport
        })
    end
    table.sort(conditionList, function(elementA, elemenbB)
        local priorityA = elementA.IsSupport and 1 or 0
        local priorityB = elemenbB.IsSupport and 1 or 0
        if priorityA == priorityB then
            return elementA.SupportConditionId < elemenbB.SupportConditionId
        end
        return priorityA > priorityB
    end)
    return conditionList
end

function XUiPanelBabelTowerRoom:CheckBabelTeamCondition(conditionId)
    if conditionId == nil or conditionId == 0 then return true end
    local characterIds = {}
    for i = 1, XFubenBabelTowerConfigs.MAX_TEAM_MEMBER do
        local characterId = self.CharacterIds[i]
        if characterId ~= nil and characterId ~= 0 then
            table.insert(characterIds, characterId)
        end
    end
    local isConditionAvailable = XConditionManager.CheckCondition(conditionId, characterIds)
    return isConditionAvailable
end

function XUiPanelBabelTowerRoom:GetTotalSupportPoint()
    local totalSupportPoint = self.StageTemplate.BaseSupportPoint or 0

    local characterIds = {}
    for i = 1, XFubenBabelTowerConfigs.MAX_TEAM_MEMBER do
        local characterId = self.CharacterIds[i]
        if characterId ~= nil and characterId ~= 0 then
            table.insert(characterIds, characterId)
        end
    end

    for i = 1, #self.StageTemplate.SupportConditionId do
        local supportConditionId = self.StageTemplate.SupportConditionId[i]
        local supportConditionTemplate = XFubenBabelTowerConfigs.GetBabelTowerSupportConditonTemplate(supportConditionId)
        if supportConditionTemplate.Condition == nil or supportConditionTemplate.Condition == 0 then
            totalSupportPoint = totalSupportPoint + supportConditionTemplate.PointAdd
        else
            local isConditionAvailable = XConditionManager.CheckCondition(supportConditionTemplate.Condition, characterIds)
            if isConditionAvailable then
                totalSupportPoint = totalSupportPoint + supportConditionTemplate.PointAdd
            end
        end

    end

    return totalSupportPoint
end

return XUiPanelBabelTowerRoom