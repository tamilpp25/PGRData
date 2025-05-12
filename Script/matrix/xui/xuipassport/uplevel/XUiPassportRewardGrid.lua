local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiPassportRewardGrid = XClass(nil, "XUiPassportRewardGrid")

local CSXTextManagerGetText = CS.XTextManager.GetText
local MaxGridCount = 3

function XUiPassportRewardGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.RewardPanelList = {}
end

function XUiPassportRewardGrid:Init(rootUi)
    self.RootUi = rootUi
end

function XUiPassportRewardGrid:Refresh(rewardData)
    local grid = XUiGridCommon.New(self.RootUi, self.GridCommon)
    grid:Refresh(rewardData)

    local count = rewardData and rewardData.Count or 0
    self.TxtCount.text = CSXTextManagerGetText("ShopGridCommonCount", count)
end

return XUiPassportRewardGrid