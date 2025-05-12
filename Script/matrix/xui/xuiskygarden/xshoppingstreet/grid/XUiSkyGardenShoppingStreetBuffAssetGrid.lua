---@class XUiSkyGardenShoppingStreetBuffAssetGrid : XUiNode
---@field TxtNum UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetBuffAssetGrid = XClass(XUiNode, "XUiSkyGardenShoppingStreetBuffAssetGrid")

--region 生命周期
function XUiSkyGardenShoppingStreetBuffAssetGrid:Update(data, i)
    local buffId
    if type(data) == "number" then
        buffId = data
    else
        if data.BuffId then
            buffId = data.BuffId
        else
            buffId = data.Id
        end
    end

    local params = self._Control:ParseBuffDescParamsById(buffId)
    local ressCfg = self._Control:GetStageResConfigs()
    local resId, num, resCfg
    for _resId, _num in pairs(params) do
        resId = _resId
        num = _num
        resCfg = ressCfg[resId]
        if resCfg then break end
    end
    if not resCfg then
        self.TxtNum.text = 0
        return
    end

    self.ImgAsset:SetSprite(resCfg.Icon)
    self.ImgAsset.color = XUiHelper.Hexcolor2Color(resCfg.IconColor)
    self.TxtNum.text = self._Control:GetValueByResConfig(num, resCfg)
end
--endregion

return XUiSkyGardenShoppingStreetBuffAssetGrid
