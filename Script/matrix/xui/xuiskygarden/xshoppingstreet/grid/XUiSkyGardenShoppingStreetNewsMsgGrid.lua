---@class XUiSkyGardenShoppingStreetNewListGrid : XUiNode
local XUiSkyGardenShoppingStreetNewListGrid = XClass(XUiNode, "XUiSkyGardenShoppingStreetNewListGrid")

--region 生命周期
function XUiSkyGardenShoppingStreetNewListGrid:OnStart(...)
    self._LogList = {}
end

function XUiSkyGardenShoppingStreetNewListGrid:Update(data)
    self.TagNews.gameObject:SetActiveEx(not data.IsExpired and data.IsNews)
    self.TagMessage.gameObject:SetActiveEx(not data.IsExpired and not data.IsNews)
    self.TagLose.gameObject:SetActiveEx(data.IsExpired)
    if data.IsNews then
        local config = self._Control:GetNewsConfigById(data.Id)
        self.TxtDetail.text = config.Desc
        self.TxtTitle.text = config.Name
    else
        local config = self._Control:GetGrapevineConfigById(data.Id)
        self.TxtDetail.text = self._Control:ParseGrapevine(data.Data)
        self.TxtTitle.text = config.Name
    end
end
--endregion

return XUiSkyGardenShoppingStreetNewListGrid
