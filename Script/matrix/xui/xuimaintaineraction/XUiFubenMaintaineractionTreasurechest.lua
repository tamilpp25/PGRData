local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiFubenMaintaineractionTreasurechest = XLuaUiManager.Register(XLuaUi, "UiFubenMaintaineractionTreasurechest")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiFubenMaintaineractionTreasurechest:OnStart(rewardId, rewardList, title, subTitle, curCount, maxCount, closeCb)
    self:SetButtonCallBack()
    self.Grid256.gameObject:SetActiveEx(false)
    self.CloseCb = closeCb
    self:ShowInfo(rewardId, rewardList, title, subTitle, curCount, maxCount)
end

function XUiFubenMaintaineractionTreasurechest:SetButtonCallBack()
    self.BtnClose.CallBack = function()
        self:OnBtnCloseClick()
    end
end

function XUiFubenMaintaineractionTreasurechest:OnBtnCloseClick()
    self.CloseCb()
    self:Close()
end

function XUiFubenMaintaineractionTreasurechest:ShowInfo(rewardId, rewardList, title, subTitle, curCount, maxCount)
    local rewards = rewardId and XRewardManager.GetRewardList(rewardId) or rewardList
    
    if rewards then
        for i, item in pairs(rewards) do
            local obj = CS.UnityEngine.Object.Instantiate(self.Grid256,self.PanelDetails)
            local grid = XUiGridCommon.New(self, obj)
            grid:Refresh(item)
            grid.GameObject:SetActiveEx(true)
        end
    end
    self.TxtTitle.text = title
    self.TxtSubTitle.text = subTitle
    self.BoxCount.text = string.format("%d/%d", curCount, maxCount)
end