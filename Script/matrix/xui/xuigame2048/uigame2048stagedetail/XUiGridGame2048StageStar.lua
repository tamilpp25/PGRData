local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridGame2048StageStar = XClass(XUiNode, 'XUiGridGame2048StageStar')

function XUiGridGame2048StageStar:Refresh(desc, rewardId, isGet)
    self.PanelUnActive.gameObject:SetActiveEx(not isGet)
    self.ImgStar.gameObject:SetActiveEx(not isGet)
    self.TxtUnActive.gameObject:SetActiveEx(not isGet)
    
    self.PanelActive.gameObject:SetActiveEx(isGet)
    self.ImgStarActive.gameObject:SetActiveEx(isGet)
    self.TxtActive.gameObject:SetActiveEx(isGet)

    if isGet then
        self.TxtActive.text = desc
    else
        self.TxtUnActive.text = desc
    end

    if XTool.IsNumberValid(rewardId) then
        self.Grid256New.gameObject:SetActiveEx(true)
        self._RewardGrid = XUiGridCommon.New(self.Parent, self.Grid256New)
        self._RewardGrid:Refresh(XRewardManager.GetRewardList(rewardId)[1])
        self._RewardGrid:SetReceived(isGet)
    else
        self.Grid256New.gameObject:SetActiveEx(false)
    end
end

return XUiGridGame2048StageStar