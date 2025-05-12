---@class XUiSkyGardenShoppingStreetBuffGrid : XUiNode
---@field TxtNum UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetBuffGrid = XClass(XUiNode, "XUiSkyGardenShoppingStreetBuffGrid")

--region 生命周期

function XUiSkyGardenShoppingStreetBuffGrid:Update(data, i)
    local roundCount = 0
    local config
    if type(data) == "number" then
        config = self._Control:GetBuffConfigById(data)
        roundCount = config.Duration
    else
        if data.BuffId then
            config = self._Control:GetBuffConfigById(data.BuffId)
            roundCount = data.RemainingTurn or config.Duration
        else
            config = self._Control:GetBuffConfigById(data.Id)
            roundCount = config.Duration
        end
    end
    self._buffId = config.Id
    if self.ImgBuff then
        self.ImgBuff:SetSprite(config.Icon)
    end
    if self.PanelNum then
        self.PanelNum.gameObject:SetActive(roundCount > 0)
    end
    self.TxtNum.text = roundCount
    if self.ImgBg and not string.IsNilOrEmpty(config.BgColor) then
        self.ImgBg.color = XUiHelper.Hexcolor2Color(config.BgColor)
    end
end

function XUiSkyGardenShoppingStreetBuffGrid:SetClickCallback(cb)
    self._CallBack = cb
    self.UiSkyGardenShoppingStreetGridBuff.enabled = true
    self.UiSkyGardenShoppingStreetGridBuff.CallBack = function ()
        if self._CallBack then
            self._CallBack()
        else
            XMVCA.XSkyGardenShoppingStreet:ShowBuffTips(self._buffId, self.ImgBuff.transform.position)
        end
    end
end
--endregion

return XUiSkyGardenShoppingStreetBuffGrid
