local XUiPanelArea = require("XUi/XUiMission/XUiPanelArea")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")


---@class XUiPanelAreaWarQuestDetail : XUiNode
---@field
local XUiPanelAreaWarQuestDetail = XClass(XUiNode, "XUiPanelAreaWarQuestDetail")

local CsBtnSelect = CS.UiButtonState.Select
local CsBtnNormal = CS.UiButtonState.Normal

local ColorEnum = {
    Enough = XUiHelper.Hexcolor2Color("323232"),
    NotEnough = XUiHelper.Hexcolor2Color("ff0000")
}

function XUiPanelAreaWarQuestDetail:DoAwake()
    self.Rewards = {}
    
    self.BtnFight.CallBack = function() 
        self:OnBtnFightClick()
    end
    
    self.BtnAuto.CallBack = function() 
        self:OnBtnAutoClick()
    end
    
    self.BtnReward.CallBack = function() 
        self:OnBtnRewardClick()
    end
    
    self.BtnDispatch.CallBack = function() 
        self:OnBtnDispatchClick()
    end
    
    self.BtnLike.CallBack = function() 
        self:OnBtnLikeClick()
    end

    self.GridCommon.gameObject:SetActiveEx(false)
    if not self.TxtTypeTitle then
        self.TxtTypeTitle = self.TxtDispatch.transform.parent:GetComponent("Text")
    end
end

function XUiPanelAreaWarQuestDetail:OnStart(questId, closeCb)
    self.QuestId = questId
    self.CloseCb = closeCb
    self:DoAwake()
    
    self:InitView()
end

function XUiPanelAreaWarQuestDetail:OnDestroy()
    if self.CloseCb then
        self.CloseCb(self.QuestId)
    end
end

function XUiPanelAreaWarQuestDetail:InitView()
    local data = XDataCenter.AreaWarManager.GetAreaWarQuest(self.QuestId)
    self.QuestData = data
    
    local isBeRescued = data:IsBeRescued()
    local isRescue = data:IsRescue()
    local isFight = data:IsFight()
    self.PanelHelp.gameObject:SetActiveEx(not isFight)
    if not isFight then
        self:RefreshHelp()
        XUiPlayerHead.InitPortrait(self.QuestData:GetRescuedHeadPortraitId(), self.QuestData:GetRescuedHeadFrameId(), self.Head)
    end
    
    local title, desc = XAreaWarConfigs.GetRescueDetailText(isRescue)
    self.TxtDispatch.text = desc
    if self.TxtTypeTitle then
        self.TxtTypeTitle.text = title
    end

    self.TxtType.text = data:GetStageDesc()
    self.TxtName.text = data:GetStageName()
    
    self.BtnFight.gameObject:SetActiveEx(isFight)
    self.BtnAuto.gameObject:SetActiveEx(isFight)
    self.BtnReward.gameObject:SetActiveEx(isBeRescued)
    self.BtnLike.gameObject:SetActiveEx(isBeRescued)
    self.BtnDispatch.gameObject:SetActiveEx(isRescue)
    if isFight then
        self:RefreshFight()
    end
    
    self:RefreshReward()
end

function XUiPanelAreaWarQuestDetail:RefreshFight()
    local itemId = XAreaWarConfigs.GetSkipItemId()
    local cost = 1
    self.BtnAuto:SetRawImage(XDataCenter.ItemManager.GetItemIcon(itemId))
    local count = XDataCenter.ItemManager.GetCount(itemId)
    local color = count >= cost and ColorEnum.Enough or ColorEnum.NotEnough
    self.BtnAuto:SetNameAndColorByGroup(1, string.format("%d/%d", cost, count), color)
end

function XUiPanelAreaWarQuestDetail:RefreshReward()
    self.PanelFull.gameObject:SetActiveEx(false)
    local rewardId = self.QuestData:GetRewardId()
    for _, grid in pairs(self.Rewards) do
        grid.GameObject:SetActiveEx(false)
    end
    if not XTool.IsNumberValid(rewardId) then
        return
    end
    if rewardId < 0 then
        self.PanelFull.gameObject:SetActiveEx(true)
        return
    end

    local rewardList = XRewardManager.GetRewardList(rewardId)
    for index, reward in ipairs(rewardList) do
        local grid = self.Rewards[index]
        if not grid then
            local ui = index == 1 and self.GridCommon or XUiHelper.Instantiate(self.GridCommon, self.RewardParent)
            grid = XUiGridCommon.New(self.Parent, ui)
            self.Rewards[index] = grid
        end
        grid:Refresh(reward)
    end
end

function XUiPanelAreaWarQuestDetail:RefreshHelp()
    self.TxtRoleName.text = self.QuestData:GetRescuedName()
    local state
    if self.QuestData:IsLiked() then
        state = CsBtnSelect
        self.BtnLike.enabled = false
    else
        state = CsBtnNormal
        self.BtnLike.enabled = true
    end
    self.BtnLike:SetButtonState(state)
end

function XUiPanelAreaWarQuestDetail:UpdateView()
end

function XUiPanelAreaWarQuestDetail:OnBtnFightClick()
    XDataCenter.AreaWarManager.TryEnterQuestFight(self.QuestId, self.QuestData:GetStageId())
end

function XUiPanelAreaWarQuestDetail:OnBtnAutoClick()
    local itemId = XAreaWarConfigs.GetSkipItemId()
    local count = XDataCenter.ItemManager.GetCount(itemId)
    local cost = 1
    if count < cost then
        XUiManager.TipMsg(XAreaWarConfigs.GetItemNotEnoughText(1))
        return
    end

    XDataCenter.AreaWarManager.RequestAutoQuest(self.QuestId, function(rewardList)
        self.Parent:Close()
        if not XTool.IsTableEmpty(rewardList) then
            XUiManager.OpenUiObtain(rewardList)
        end
    end)
end

function XUiPanelAreaWarQuestDetail:OnBtnLikeClick()
    if not self.QuestData:IsBeRescued() then
        return
    end
    
    local data = self.QuestData
    XDataCenter.AreaWarManager.RequestLikeRescuer(self.QuestId, function()
        data:SetLiked(true)
        self:RefreshHelp()
    end)
end

function XUiPanelAreaWarQuestDetail:OnBtnRewardClick()
    XDataCenter.AreaWarManager.RequestReceiveRescuedQuestReward(self.QuestId, function(rewardList)
        self.Parent:Close()
        if not XTool.IsTableEmpty(rewardList) then
            XUiManager.OpenUiObtain(rewardList)
        end
    end)
end

function XUiPanelAreaWarQuestDetail:OnBtnDispatchClick()
    XDataCenter.AreaWarManager.OpenUiDispatch(self.QuestId, true)
end

return XUiPanelAreaWarQuestDetail