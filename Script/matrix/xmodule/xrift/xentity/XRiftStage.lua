-- 1个关卡库对应多个关卡(stage)
-- 不同的【Rift关卡cfg】可以配置同一个stageId
-- 且不同的关卡库可以配置相同的【Rift关卡cfg】Id
---@class XRiftStage:XEntity
---@field _OwnControl XRiftControl
local XRiftStage = XClass(XEntity, "XRiftStage")

function XRiftStage:OnInit()

end

function XRiftStage:OnRelease()

end

---@param config XTableRiftStage
function XRiftStage:SetConfig(layerId, config, index)
    self._LayerId = layerId
    self._StageId = config.StageId
    self._Index = index
    self._Config = config
end

---【获取】Config
function XRiftStage:GetConfig()
    return self._Config
end

---【获取】父层
---@return XRiftStageGroup
function XRiftStage:GetParent()
    return self._OwnControl:GetStageGroup(self._LayerId)
end

function XRiftStage:GetStageData()
    return self._OwnControl:GetStageData(self._LayerId, self._Index)
end

---【检查】通过该关卡
function XRiftStage:CheckHasPassed()
    local stageData = self:GetStageData()
    return stageData and stageData.IsPassed or false
end

function XRiftStage:GetPassTime()
    local stageData = self:GetStageData()
    return stageData and stageData.PassTime or 0
end

return XRiftStage