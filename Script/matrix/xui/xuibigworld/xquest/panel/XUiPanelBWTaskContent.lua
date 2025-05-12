---@class XUiGridBWObjective : XUiNode
---@field _Control XBigWorldQuestControl
local XUiGridBWObjective = XClass(XUiNode, "XUiGridBWObjective")

---@param objective XBigWorldQuestObjective
function XUiGridBWObjective:Refresh(objective)
    self:Open()
    local id = objective:GetId()
    self.TxtTitle.text = self._Control:GetObjectiveTitle(id)

    --local isBool = self._Control:IsBoolObjectiveType(id)
    --self.TxtProgress.gameObject:SetActiveEx(not isBool)
    local progress = objective:GetProgress()
    --if isBool then
    --    local isFinish = progress > 0
    --    --self.ImgComplete.gameObject:SetActiveEx(isFinish)
    --    --self.ImgInComplete.gameObject:SetActiveEx(not isFinish)
    --else
    --    --self.ImgComplete.gameObject:SetActiveEx(false)
    --    --self.ImgInComplete.gameObject:SetActiveEx(false)
    --    self.TxtProgress.text = self._Control:GetObjectiveProgressDesc(id, progress)
    --end

    self.TxtProgress.text = self._Control:GetObjectiveProgressDesc(id, progress)
end


---@class XUiPanelBWTaskContent : XUiNode
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field Parent XUiBigWorldTaskMain
---@field _Control XBigWorldQuestControl
local XUiPanelBWTaskContent = XClass(XUiNode, "XUiPanelBWTaskContent")

local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")

function XUiPanelBWTaskContent:OnStart()
    self:InitCb()
    self:InitView()
end

function XUiPanelBWTaskContent:InitCb()
    self.BtnGo.CallBack = function()
        self:OnBtnGoClick()
    end

    self.BtnTrack.CallBack = function()
        self:OnBtnTrackClick()
    end

    self.BtnUntrack.CallBack = function()
        self:OnBtnUntrackClick()
    end
end

function XUiPanelBWTaskContent:InitView()
    if not self.PanelRewardRoot then
        self.PanelRewardRoot = self.PanelReward.transform.parent.gameObject
    end
    self.GridCommonTask.gameObject:SetActiveEx(false)
    self._RewardGrids = {}
    self._ObjectiveGrids = {}
end

function XUiPanelBWTaskContent:RefreshView(questId)
    self._QuestId = questId
    self.TxtTitle.text = self._Control:GetQuestName(questId)
    local stepDataList = self._Control:GetActiveStepData(questId)
    self:RefreshReward(stepDataList)
    self:RefreshDetail(stepDataList)
    self:RefreshBtn()
end

function XUiPanelBWTaskContent:RefreshBtn()
    local questId = self._QuestId
    local isTrack = self._Control:IsTrackQuest(questId)
    self.BtnGo.gameObject:SetActiveEx(isTrack)
    self.BtnTrack.gameObject:SetActiveEx(not isTrack)
    self.BtnUntrack.gameObject:SetActiveEx(isTrack)
    self.BtnSubmit.gameObject:SetActiveEx(false)
end

---@param stepDataList XBigWorldQuestStep[]
function XUiPanelBWTaskContent:RefreshReward(stepDataList)
    local count = 0
    if not XTool.IsTableEmpty(stepDataList) then
        for _, stepData in pairs(stepDataList) do
            local stepId = stepData:GetId()
            local rewardId = self._Control:GetStepReward(stepId)
            if rewardId and rewardId > 0 then

                local rewardList = XRewardManager.GetRewardList(rewardId)
                for _, reward in pairs(rewardList) do
                    local grid = self._RewardGrids[count]
                    if not grid then
                        local ui = count == 0 and self.GridCommonTask or XUiHelper.Instantiate(self.GridCommonTask, self.PanelReward.transform)
                        grid = XUiGridBWItem.New(ui, self.Parent)
                        self._RewardGrids[count] = grid
                    end
                    count = count + 1
                    grid:Refresh(reward)
                end
            end
        end
    end
    local hasReward = count > 0
    self.PanelRewardRoot:SetActiveEx(hasReward)
    for index, grid in pairs(self._RewardGrids) do
        if index > count then
            grid.GameObject:SetActiveEx(false)
        end
    end
end

---@param stepDataList XBigWorldQuestStep[]
function XUiPanelBWTaskContent:RefreshDetail(stepDataList)
    local desc, location = "", ""
    if stepDataList then
        --如果有多个，只取第一个
        local step = stepDataList[1]
        local stepId = step:GetId()
        local objectiveList = step:GetObjectiveList()
        desc = self._Control:GetStepText(stepId)
        location = self._Control:GetStepLocation(stepId)
        self:RefreshObjective(objectiveList)
    end
    self.TxtStep.text = desc
    --self.TxtContentLocation.text = location
end

function XUiPanelBWTaskContent:RefreshObjective(objectiveList)
    local count = 1

    if not XTool.IsTableEmpty(objectiveList) then
        for _, objective in pairs(objectiveList) do
            local grid = self._ObjectiveGrids[count]
            if not grid then
                local ui = count == 1 and self.GridObjective or XUiHelper.Instantiate(self.GridObjective, self.ObjectiveRoot.transform)
                grid = XUiGridBWObjective.New(ui, self.Parent)
                self._ObjectiveGrids[count] = grid
            end
            grid:Refresh(objective)
        end
    end

    for index, grid in pairs(self._ObjectiveGrids) do
        if index > count then
            grid:Close()
        end
    end
end

function XUiPanelBWTaskContent:OnBtnGoClick()
    XMVCA.XBigWorldMap:OpenBigWorldMapUiAnchorQuest(self._QuestId)
end

function XUiPanelBWTaskContent:OnBtnTrackClick()
    XMVCA.XBigWorldQuest:TrackQuest(self._QuestId, function()
        self:RefreshBtn()
    end)
end

function XUiPanelBWTaskContent:OnBtnUntrackClick()
    XMVCA.XBigWorldQuest:UnTrackQuest(self._QuestId, function()
        self:RefreshBtn()
    end)
end

return XUiPanelBWTaskContent