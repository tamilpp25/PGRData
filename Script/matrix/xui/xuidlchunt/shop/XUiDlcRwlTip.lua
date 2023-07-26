local XUiDlcRwlTipItemGrid = require("XUi/XUiDlcHunt/Shop/XUiDlcRwlTipItemGrid")

local XUiObtain = require("XUi/XUiObtain/XUiObtain")
local XUiDlcRwlTip = XLuaUiManager.Register(XUiObtain, "UiDlcRwlTip")

function XUiDlcRwlTip:AutoInitUi()
    self.ScrView = self.Transform:Find("SafeAreaContentPane/ScrView"):GetComponent("ScrollRect")
    self.PanelContent = self.Transform:Find("SafeAreaContentPane/ScrView/Viewport/PanelContent")
    self.GridCommon = self.Transform:Find("SafeAreaContentPane/ScrView/Viewport/PanelContent/GridCommon")
    self.BtnBack = self.Transform:Find("SafeAreaContentPane/BtnBack"):GetComponent("Button")
    --self.TxtTitle = self.Transform:Find("SafeAreaContentPane/GameObject/TxtTitle1"):GetComponent("Text")
    --self.BtnCancel = self.Transform:Find("SafeAreaContentPane/BtnCancel"):GetComponent("Button")
    --self.BtnSure = self.Transform:Find("SafeAreaContentPane/BtnSure"):GetComponent("Button")
end

function XUiDlcRwlTip:PlayAnimationAniObtain()
    --self:PlayAnimation("AniObtain")
end

function XUiDlcRwlTip:Refresh(rewardGoodsList, horizontalNormalizedPosition)
    rewardGoodsList = XRewardManager.MergeAndSortRewardGoodsList(rewardGoodsList)
    XUiHelper.CreateTemplates(self, self.Items, rewardGoodsList, XUiDlcRwlTipItemGrid.New, self.GridCommon, self.PanelContent, function(grid, data)
        grid:Refresh(data, nil, nil, false)
    end)

    if horizontalNormalizedPosition then
        self.ScrView.horizontalNormalizedPosition = horizontalNormalizedPosition
    end
end

return XUiDlcRwlTip