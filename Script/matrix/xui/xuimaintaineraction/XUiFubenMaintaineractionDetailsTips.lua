local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiFubenMaintaineractionDetailsTips = XLuaUiManager.Register(XLuaUi, "UiFubenMaintaineractionDetailsTips")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiFubenMaintaineractionDetailsTips:OnStart(node,IsReward)
    self:SetButtonCallBack()
    self.GridCommon.gameObject:SetActiveEx(false)
    self:ShowInfo(node, IsReward)
end

function XUiFubenMaintaineractionDetailsTips:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
end

function XUiFubenMaintaineractionDetailsTips:OnBtnBackClick()
    self:Close()
end

function XUiFubenMaintaineractionDetailsTips:ShowInfo(node, IsReward)
    self.PanelTreasureChest.gameObject:SetActiveEx(IsReward)
    self.PanelRandom.gameObject:SetActiveEx(not IsReward)
    if IsReward then
        local rewards
        
        if node.GetRewardId then
            rewards = XRewardManager.GetRewardList(node:GetRewardId())
        elseif node.GetRewardList then
            rewards = node:GetRewardList()
        end
        
        if rewards then
            for i, item in pairs(rewards) do
                local obj = CS.UnityEngine.Object.Instantiate(self.GridCommon,self.PanelContent)
                local grid = XUiGridCommon.New(self, obj)
                grid:Refresh(item)
                grid.GameObject:SetActiveEx(true)
            end
        end
        
        self.TxtRewardTitle.text = node:GetRewardTitle()
        
        self.TxtMentorTitle.gameObject:SetActiveEx(node:GetIsMentor())
        self.TxtMentorTitle.text = node:GetDesc()
    else
        self.TxtDescTitle.text = node:GetName()
        self.TxtDescription.text = node:GetDesc()
    end
end