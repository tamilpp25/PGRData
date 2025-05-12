---@class XUiSkyGardenShoppingStreetGameTargetDot : XUiNode
---@field TxtTitle UnityEngine.UI.Text
---@field TxtDetail UnityEngine.UI.Text
---@field ImgComplete UnityEngine.UI.Image
---@field TxtNum UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetGameTargetDot = XClass(XUiNode, "XUiSkyGardenShoppingStreetGameTargetDot")

--region 刷新逻辑
function XUiSkyGardenShoppingStreetGameTargetDot:Update(taskConfigId)
    local taskData = self._Control:GetTaskDataByConfigId(taskConfigId)
    if taskData then
        local config = self._Control:GetStageTaskConfigsById(taskConfigId)
        self.ImgOn.gameObject:SetActive(taskData.Schedule >= config.Schedule)
    else
        self.ImgOn.gameObject:SetActive(false)
    end
end
--endregion

return XUiSkyGardenShoppingStreetGameTargetDot
