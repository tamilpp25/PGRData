local XUiPanelOnLineLoadingDetailItem = require("XUi/XUiOnlineLoading/XUiPanelOnLineLoadingDetailItem")

---@class XUiPanelOnLineLoadingDetailItemCute
local XUiPanelOnLineLoadingDetailItemCute =
    XClass(XUiPanelOnLineLoadingDetailItem, "XUiPanelOnLineLoadingDetailItemCute")

function XUiPanelOnLineLoadingDetailItemCute:GetHalfBodyImage(character)
    return XFubenSpecialTrainConfig.GetCuteModelHalfBodyImage(character.Id)
end

function XUiPanelOnLineLoadingDetailItemCute:Refresh(data, ...)
    XUiPanelOnLineLoadingDetailItemCute.Super.Refresh(self, data, ...)
    if not data then
        return
    end
    local rankScore = data.RankScore
    local icon = XDataCenter.FubenSpecialTrainManager.GetIconByScore(rankScore)
    self.RootUi:SetUiSprite(self.ImgLogo, icon)
end

return XUiPanelOnLineLoadingDetailItemCute
