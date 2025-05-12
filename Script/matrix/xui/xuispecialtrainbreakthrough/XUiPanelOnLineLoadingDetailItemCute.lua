local XUiPanelOnLineLoadingDetail = require("XUi/XUiOnlineLoading/XUiPanelOnLineLoadingDetail")
local XUiPanelOnLineLoadingDetailItem = require("XUi/XUiOnlineLoading/XUiPanelOnLineLoadingDetailItem")

---@class XUiPanelOnLineLoadingDetailItemCute
local XUiPanelOnLineLoadingDetailItemCute = XClass(XUiPanelOnLineLoadingDetailItem, "XUiPanelOnLineLoadingDetailItemCute")

function XUiPanelOnLineLoadingDetailItemCute:GetHalfBodyImage(character)
    return XCharacterCuteConfig.GetCuteModelRoundnessHeadIcon(character.Id)
end

function XUiPanelOnLineLoadingDetailItemCute:Refresh(data, ...)
    XUiPanelOnLineLoadingDetailItemCute.Super.Refresh(self, data, ...)
    --self.ImgLogo.gameObject:SetActiveEx(false)
    if not data then
        return
    end
    local rankScore = data.RankScore
    local icon = XDataCenter.FubenSpecialTrainManager.GetIconByScore(rankScore)
    self.RootUi:SetUiSprite(self.ImgLogo, icon)
end

function XUiPanelOnLineLoadingDetailItemCute:GetProgressEndTextColor()
    return "588AEF"
end

return XUiPanelOnLineLoadingDetailItemCute
