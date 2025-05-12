---@class XUiBigWorldObtain : XBigWorldUi 空花奖励界面
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
local XUiBigWorldObtain = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldObtain")

local XUiSGGridItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")

local OpType = XMVCA.XBigWorldQuest.QuestOpType

function XUiBigWorldObtain:OnAwake()
    self:InitUi()
    self:InitCb()

    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, OpType.PopupBegin)
end

function XUiBigWorldObtain:OnStart(rewardData, title, closeCb)
    self.RewardList = self:GetRewardList(rewardData)
    if title and self.TxtTitle then
        self.TxtTitle.text = title
    end
    self.CloseCb = closeCb
    self:InitView()
end

function XUiBigWorldObtain:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, OpType.PopupEnd)
end

function XUiBigWorldObtain:InitUi()
    self.GridCommon.gameObject:SetActiveEx(false)
    ---@type XUiGridBWItem[]
    self.GridRewards = {}
end

function XUiBigWorldObtain:InitCb()
    self.BtnBack.CallBack = function()
        self:Close()
    end
end

function XUiBigWorldObtain:InitView()
    self:RefreshReward()
end

function XUiBigWorldObtain:GetRewardList(rewardData)
    if not rewardData then
        return {}
    end

    local typeOfData = type(rewardData)

    if typeOfData == "number" then
        if self:IsQuestItem(rewardData) then
            return { rewardData }
        end
        return XRewardManager.GetRewardList(rewardData)
    elseif typeOfData == "table" then
        return rewardData
    end

    XLog.Error("奖励数据有误，请检查数据: ", rewardData)
    return {}
end

function XUiBigWorldObtain:RefreshReward()
    for _, grid in pairs(self.GridRewards) do
        if grid and not XTool.UObjIsNil(grid.GameObject) then
            grid:Close()
        end
    end

    for i, reward in ipairs(self.RewardList) do
        local grid = self.GridRewards[i]
        if not grid then
            local ui = i == 1 and self.GridCommon or XUiHelper.Instantiate(self.GridCommon, self.PanelContent)
            grid = XUiSGGridItem.New(ui, self)
            self.GridRewards[i] = grid
        end
        grid:Open()
        grid:Refresh(reward)
    end
end

function XUiBigWorldObtain:IsQuestItem(templateId)
    return XMVCA.XBigWorldQuest:IsQuestItem(templateId)
end