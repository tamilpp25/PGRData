-- 大秘境【关卡节点】实例
-- 1个关卡节点对应1个关卡库id(关卡库id由服务器随机下发)
-- 1个关卡库对应多个关卡(stage)
-- 所以可用关卡库数据生成关卡节点实例
---@class XRiftStageGroup:XEntity
---@field _OwnControl XRiftControl
---@field _ParentFightLayer XRiftFightLayer
---@field _AllEntityStages XRiftStage[] 所有关卡实例
local XRiftStageGroup = XClass(XEntity, "XRiftStageGroup")

function XRiftStageGroup:OnInit()

end

function XRiftStageGroup:OnRelease()

end

function XRiftStageGroup:SetLayer(layerId)
    self._LayerId = layerId
    self._ParentFightLayer = self._OwnControl:GetEntityFightLayerById(layerId)
end

function XRiftStageGroup:UpdateData()
    self._AllEntityStages = {}

    local stageGroupData = self._OwnControl:GetStageGroupByLayerId(self._LayerId)
    for k, _ in ipairs(stageGroupData.StageDatas) do
        -- 初始化所有拥有的配置关卡（向下单向关系：1个关卡可以重复配置在不同的关卡库）
        local xStage = self._OwnControl:GetStage(self._LayerId, k)
        table.insert(self._AllEntityStages, xStage)
    end
end

---【获取】父层
---@return XRiftFightLayer
function XRiftStageGroup:GetParent()
    return self._ParentFightLayer
end

---【获取】所有关卡实例
---@return XRiftStage[]
function XRiftStageGroup:GetAllEntityStages()
    return self._AllEntityStages
end

return XRiftStageGroup