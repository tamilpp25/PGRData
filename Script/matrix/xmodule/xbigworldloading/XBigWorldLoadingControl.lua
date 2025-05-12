---@class XBigWorldLoadingControl : XControl
---@field private _Model XBigWorldLoadingModel
local XBigWorldLoadingControl = XClass(XControl, "XBigWorldLoadingControl")

function XBigWorldLoadingControl:OnInit()
    -- 初始化内部变量
end

function XBigWorldLoadingControl:AddAgencyEvent()
    -- control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XBigWorldLoadingControl:RemoveAgencyEvent()

end

function XBigWorldLoadingControl:OnRelease()
    -- XLog.Error("这里执行Control的释放")
end

---@return XTableBigWorldLoading[]
function XBigWorldLoadingControl:GetLoadingConfigsByLevelId(levelId, worldId)
    local loadingConfigs = self._Model:GetLoadingConfigsByLevelId(levelId)
    local result = {}

    if XTool.IsTableEmpty(loadingConfigs) then
        local levelIds = CS.StatusSyncFight.XFightClient.GetWorldLevelIds(worldId)

        for _, levelId in pairs(levelIds) do
            local configs = self._Model:GetLoadingConfigsByLevelId(levelId)

            if not XTool.IsTableEmpty(configs) then
                for _, config in pairs(configs) do
                    if self:_CheckLoadingConditions(config.ConditionIds) then
                        table.insert(result, config)
                    end
                end
            end
        end
    else
        for _, config in pairs(loadingConfigs) do
            if self:_CheckLoadingConditions(config.ConditionIds) then
                table.insert(result, config)
            end
        end
    end

    return result
end

---@return XTableBigWorldLoading[]
function XBigWorldLoadingControl:GetRandomLoadingByLevelId(levelId, worldId)
    local loadingConfigs = self:GetLoadingConfigsByLevelId(levelId, worldId)

    if XTool.IsTableEmpty(loadingConfigs) then
        return nil
    end

    return XTool.WeightRandomSelect(loadingConfigs)
end

function XBigWorldLoadingControl:_CheckLoadingConditions(conditionIds)
    local isShow = true

    if not XTool.IsTableEmpty(conditionIds) then
        for _, conditionId in pairs(conditionIds) do
            if not XMVCA.XBigWorldService:CheckCondition(conditionId) then
                isShow = false
                break
            end
        end
    end

    return isShow
end

return XBigWorldLoadingControl
