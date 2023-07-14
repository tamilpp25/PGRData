local XUiPassportCardGrid = XClass(nil, "XUiPassportCardGrid")

local CSXTextManagerGetText = CS.XTextManager.GetText

function XUiPassportCardGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.RewardPanelList = {}
end

function XUiPassportCardGrid:Init(rootUi)
    self.RootUi = rootUi
end

function XUiPassportCardGrid:Refresh(passportBuyRewardShowId)
    local level = XPassportConfigs.GetPassportBuyRewardShowLevel(passportBuyRewardShowId)
    if XTool.IsNumberValid(level) then
        self.TextUnLock.text = CSXTextManagerGetText("PassportLevelUnLockDesc", level)
        self.RImgUnLock.gameObject:SetActiveEx(true)
    else
        self.RImgUnLock.gameObject:SetActiveEx(false)
    end

    if not self.GridCommon then
        self.GridCommon = XUiGridCommon.New(self.RootUi, self.Gridicon)
    end

    local rewardData = XPassportConfigs.GetPassportBuyRewardShowRewardData(passportBuyRewardShowId, true)
    self.GridCommon:Refresh(rewardData)
end

return XUiPassportCardGrid