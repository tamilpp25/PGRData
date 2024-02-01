local XUiAccumulateDrawLogGrid = require("XUi/XUiAccumulateDraw/XUiAccumulateDrawLogGrid")
---@class XUiAccumulateDrawLog : XLuaUi
---@field BtnTanchuangClose XUiComponent.XUiButton
---@field BtnClose XUiComponent.XUiButton
---@field PanelContent UnityEngine.RectTransform
---@field PanelTxt UnityEngine.RectTransform
---@field _Control XAccumulateExpendControl
local XUiAccumulateDrawLog = XLuaUiManager.Register(XLuaUi, "UiAccumulateDrawLog")

-- region 生命周期
function XUiAccumulateDrawLog:OnAwake()
    ---@type XUiAccumulateDrawLogGrid[]
    self._RulerUiList = {}
    self.PanelTxt.gameObject:SetActiveEx(false)
    self:_RegisterButtonClicks()
end

function XUiAccumulateDrawLog:OnStart()
    local rulers = self._Control:GetRulerList()

    for i, ruler in pairs(rulers) do
        local rulerUi = self._RulerUiList[i]

        if not rulerUi then
            local panel = XUiHelper.Instantiate(self.PanelTxt, self.PanelContent)

            rulerUi = XUiAccumulateDrawLogGrid.New(panel, self, ruler)
            rulerUi:Open()
            self._RulerUiList[i] = rulerUi
        else
            rulerUi:Refresh(ruler)
        end
    end
end

function XUiAccumulateDrawLog:OnDestroy()
    self._PanelTxtUiList = nil
end
-- endregion

-- region 私有方法
function XUiAccumulateDrawLog:_RegisterButtonClicks()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close, true)
    self:RegisterClickEvent(self.BtnClose, self.Close, true)
end
-- endregion

return XUiAccumulateDrawLog
