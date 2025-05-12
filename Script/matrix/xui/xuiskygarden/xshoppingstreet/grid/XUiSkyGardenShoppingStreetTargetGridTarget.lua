---@class XUiSkyGardenShoppingStreetTargetGridTarget : XUiNode
---@field TxtTitle UnityEngine.UI.Text
---@field TxtDetail UnityEngine.UI.Text
---@field ImgComplete UnityEngine.UI.Image
---@field TxtNum UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetTargetGridTarget = XClass(XUiNode, "XUiSkyGardenShoppingStreetTargetGridTarget")

--region 刷新逻辑
function XUiSkyGardenShoppingStreetTargetGridTarget:Update(taskConfigId, index)
    self._index = index
    local config = self._Control:GetStageTaskConfigsById(taskConfigId)
    self._Config = config
    if self.TxtDetailDesc then
        self.TxtDetailDesc.text = config.AccountDesc
    end
    local scheduleDiv = config.ScheduleDiv
    if not scheduleDiv or scheduleDiv == 0 then
        scheduleDiv = 1
    end
    self.TxtTitle.text = config.Name
    self.TxtDetail.text = config.ConditionDesc

    local taskData = self._Control:GetTaskDataByConfigId(taskConfigId)
    if taskData then
        self.TxtNum.text = XTool.MathGetRoundingValueStandard(taskData.Schedule / scheduleDiv, 1) .. "/" .. XTool.MathGetRoundingValueStandard(config.Schedule / scheduleDiv, 1)
        self.ImgComplete.gameObject:SetActive(taskData.Schedule >= config.Schedule)
    else
        self.TxtNum.text = 0 .. "/" .. XTool.MathGetRoundingValueStandard(config.Schedule / scheduleDiv, 1)
        self.ImgComplete.gameObject:SetActive(false)
    end
end

function XUiSkyGardenShoppingStreetTargetGridTarget:SetFinish(cb)
    local scheduleDiv = self._Config.ScheduleDiv
    if not scheduleDiv or scheduleDiv == 0 then
        scheduleDiv = 1
    end
    local num = XTool.MathGetRoundingValueStandard(self._Config.Schedule / scheduleDiv, 1)
    self.TxtNum.text = num .. "/" .. num
    self.ImgComplete.gameObject:SetActive(true)

    if cb then
        self.UiSkyGardenShoppingStreetGridTarget.CallBack = function ()
            cb(self._index)
        end
    end
end
--endregion

return XUiSkyGardenShoppingStreetTargetGridTarget
