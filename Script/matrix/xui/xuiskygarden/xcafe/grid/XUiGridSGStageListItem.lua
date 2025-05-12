---@class XUiGridSGStageListItem : XUiNode
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field Parent XUiPanelSGStageList
---@field _Control XSkyGardenCafeControl
local XUiGridSGStageListItem = XClass(XUiNode, "XUiGridSGStageListItem")

local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")

local MAX_STAR = 3

local StarKey = {
    On = "On",
    Off = "Off"
}

function XUiGridSGStageListItem:OnStart()
    self:InitCb()
    self:InitView()
end

function XUiGridSGStageListItem:InitCb()
end

function XUiGridSGStageListItem:InitView()
    self._GridStars = {}
    self._Rewards = {}
    self.UiBigWorldItemGrid.gameObject:SetActiveEx(false)
end

function XUiGridSGStageListItem:Refresh(stageId)
    self.TxtTitle.text = self._Control:GetStageName(stageId)
    local info = self._Control:GetStageInfo(stageId)
    local star = info:GetStar()
    for i = 1, MAX_STAR do
        local grid = self._GridStars[i]
        if not grid then
            grid = i == 1 and self.GridStar or XUiHelper.Instantiate(self.GridStar, self.ListStar.transform)
            grid:SetInitialState(StarKey.Off)
            self._GridStars[i] = grid
        end
        grid:ChangeState(i <= star and StarKey.On or StarKey.Off)
    end
    local isClear = star >= MAX_STAR
    self.ImgClear.gameObject:SetActiveEx(isClear)
    if self.RImgLock then
        local unlock = self._Control:IsStageUnlock(stageId)
        self.RImgLock.gameObject:SetActiveEx(not unlock)
        if not unlock then
            local preStageId = self._Control:GetPreStageId(stageId)
            local txt = self._Control:GetStageLockText(preStageId)
            self.TxtLock.text = txt
        end
    end
    self:RefreshReward(stageId, isClear)
end

function XUiGridSGStageListItem:RefreshReward(stageId, isClear)
    local rewardIds = self._Control:GetStageReward(stageId)
    local rewards = {}
    if not isClear and not XTool.IsTableEmpty(rewardIds) then
        for _, rewardId in pairs(rewardIds) do
            local list = XRewardManager.GetRewardList(rewardId)
            if list then
                --只显示第一个
                rewards[#rewards + 1] = list[1]
            end
        end
    end

    XTool.UpdateDynamicItem(self._Rewards, rewards, self.UiBigWorldItemGrid, XUiGridBWItem, self)
end

function XUiGridSGStageListItem:PlayClickAnimation(cb)
    self.GridStageClick:PlayTimelineAnimation(cb, nil, CS.UnityEngine.Playables.DirectorWrapMode.None)
end

return XUiGridSGStageListItem