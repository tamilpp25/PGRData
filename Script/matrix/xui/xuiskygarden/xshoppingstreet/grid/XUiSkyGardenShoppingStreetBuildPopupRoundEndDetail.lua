---@class XUiSkyGardenShoppingStreetBuildPopupRoundEndDetail : XUiNode
local XUiSkyGardenShoppingStreetBuildPopupRoundEndDetail = XClass(XUiNode, "XUiSkyGardenShoppingStreetBuildPopupRoundEndDetail")

function XUiSkyGardenShoppingStreetBuildPopupRoundEndDetail:Update(data)
    local resCfgs = self._Control:GetStageResConfigs()
    local resCfg = resCfgs[data.ResId]
    self.TxtDetail.text = data.Text
    local addNum = data.Num
    self.TxtNum.text = self._Control:GetValueByResConfig(addNum, resCfg)
    self.TxtNum.color = XUiHelper.Hexcolor2Color(resCfg.Color)
end

return XUiSkyGardenShoppingStreetBuildPopupRoundEndDetail
