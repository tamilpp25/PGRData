local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridStageStar = XClass(XUiNode, 'XUiGridStageStar')

function XUiGridStageStar:Refresh(desc, rewardId, isGet)
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
    else
        self.Grid256New.gameObject:SetActiveEx(false)
    end
end

return XUiGridStageStar