---抽卡校准数据
---@class XDrawActivityTargetInfo
local XDrawActivityTargetInfo = XClass(nil, "XDrawActivityTargetInfo")

function XDrawActivityTargetInfo:Ctor()
    self._ActivityId = 0
    self._TargetTimes = 0
    self._TargetId = 0
    self._StartTime = 0
    self._EndTime = 0
    self._AdjustTimes = 0
    self._DrawGroupId = 0
    self._TargetTemplateIds = {}
end

function XDrawActivityTargetInfo:UpdateData(data)
    if XTool.IsTableEmpty(data) then
        return
    end
    self._ActivityId = data.ActivityId
    self._TargetTimes = data.TargetTimes
    self._StartTime = data.StartTime
    self._EndTime = data.EndTime
    self._AdjustTimes = data.AdjustTimes
    self._DrawGroupId = data.DrawGroupId
    if not XTool.IsTableEmpty(data.TargetTemplateIds) then
        self._TargetTemplateIds = data.TargetTemplateIds
    end
    if not XTool.IsTableEmpty(data.EffectTargetTemplateIds) then
        self._TargetTemplateIds = data.EffectTargetTemplateIds
    end
    self:SetTargetId(data.TargetId)
end

--region Setter
function XDrawActivityTargetInfo:SetTargetId(targetId)
    if not table.indexof(self._TargetTemplateIds, targetId) then
        self._TargetId = 0
        return
    end
    self._TargetId = targetId
end

function XDrawActivityTargetInfo:SetTargetTimes(times)
    self._TargetTimes = times
end
--endregion

--region Getter
function XDrawActivityTargetInfo:GetActivityId()
    return self._ActivityId
end

function XDrawActivityTargetInfo:GetTargetId()
    return self._TargetId
end

function XDrawActivityTargetInfo:GetDrawGroupId()
    return self._DrawGroupId
end

-- 排序逻辑按照【暂不选择】→【当前选择】→【剩余按当前配置的可选数组倒序排列】
function XDrawActivityTargetInfo:GetTargetTemplateIds()
    local result = {}
    if XTool.IsNumberValid(self._TargetId) then
        table.insert(result, self._TargetId)
    end
    for i = #self._TargetTemplateIds, 1, -1 do
        if self._TargetId ~= self._TargetTemplateIds[i] then
            table.insert(result, self._TargetTemplateIds[i])
        end
    end
    return result
end

function XDrawActivityTargetInfo:GetTargetCount()
    return self._AdjustTimes - self._TargetTimes
end
--endregion

return XDrawActivityTargetInfo