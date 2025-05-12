local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiDunhuangRewardGrid : XUiNode
---@field _Control XDunhuangControl
local XUiDunhuangRewardGrid = XClass(XUiNode, "XUiDunhuangRewardGrid")

function XUiDunhuangRewardGrid:OnStart()
    ---@type XDunhuangRewardData
    self._Data = false
    ---@type XUiGridCommon
    self._Grid = XUiGridCommon.New(self.Parent, self.Grid256New)
    XUiHelper.RegisterClickEvent(self, self.BtnClickReward, self.OnClickReward)
end

---@param data XDunhuangRewardData
function XUiDunhuangRewardGrid:Update(data)
    self._Data = data
    if data.IsOn then
        self.PanelDotOn.gameObject:SetActiveEx(true)
        self.PanelDotOff.gameObject:SetActiveEx(false)
        self.TxtNum1.text = data.TextNum
    else
        self.PanelDotOn.gameObject:SetActiveEx(false)
        self.PanelDotOff.gameObject:SetActiveEx(true)
        self.TxtNum2.text = data.TextNum
    end
    if (not data.IsReceived) and data.IsOn then
        if self.EffectAchieved then
            self.EffectAchieved.gameObject:SetActiveEx(true)
        end
        self.BtnClickReward.gameObject:SetActiveEx(true)
    else
        if self.EffectAchieved then
            self.EffectAchieved.gameObject:SetActiveEx(false)
        end
        self.BtnClickReward.gameObject:SetActiveEx(false)
    end
    self.PanelReceived.gameObject:SetActiveEx(data.IsReceived)
    self._Grid:Refresh(data.ItemData)
end

function XUiDunhuangRewardGrid:OnClickReward()
    XMVCA.XDunhuang:RequestReceiveReward(self._Data.Id)
end

return XUiDunhuangRewardGrid