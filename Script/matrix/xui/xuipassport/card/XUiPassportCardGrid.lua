---@field _Control XPassportControl
---@class XUiPassportCardGrid:XUiNode
local XUiPassportCardGrid = XClass(XUiNode, "XUiPassportCardGrid")

local CSXTextManagerGetText = CS.XTextManager.GetText

function XUiPassportCardGrid:Ctor(ui)
    self.RewardPanelList = {}
end

function XUiPassportCardGrid:Init(rootUi)
    self.RootUi = rootUi
end

function XUiPassportCardGrid:Refresh(passportBuyRewardShowId)
    local level = self._Control:GetPassportBuyRewardShowLevel(passportBuyRewardShowId)
    if XTool.IsNumberValid(level) then
        self.TextUnLock.text = CSXTextManagerGetText("PassportLevelUnLockDesc", level)
        self.RImgUnLock.gameObject:SetActiveEx(true)
    else
        self.RImgUnLock.gameObject:SetActiveEx(false)
    end

    if not self.GridCommon then
        self.GridCommon = XUiGridCommon.New(self.RootUi, self.Gridicon)
    end

    local rewardData = self._Control:GetPassportBuyRewardShowRewardData(passportBuyRewardShowId, true)
    self.GridCommon:Refresh(rewardData)
    
    local showCount = self._Control:GetPassportBuyRewardShowCount(passportBuyRewardShowId)
    self.TxtCount.text = CSXTextManagerGetText("ShopGridCommonCount", showCount)
    self.TxtCount.gameObject:SetActiveEx(XTool.IsNumberValid(showCount) and true or false)
end

return XUiPassportCardGrid