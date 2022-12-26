local XReformBaseSourceGroup = XClass(nil, "XReformBaseSourceGroup")

function XReformBaseSourceGroup:Ctor(config)
    self.Config = config
    -- XReformMemberSource | XReformEnemySource
    self.Sources = {}
    -- key : id , vlaue : XReformMemberSource | XReformEnemySource
    self.SourceDic = {}
end

function XReformBaseSourceGroup:GetSourceById(id)
    return self.SourceDic[id]
end

function XReformBaseSourceGroup:GetSourcesWithEntity(checkAdd)
    if checkAdd == nil then checkAdd = true end
    local result = {} -- 携带有实体的源
    local nextAddSource = nil -- 下一个待添加的源
    local emptyPosCount = 0 -- 剩余空位置数量
    for _, source in ipairs(self.Sources) do
        -- 查找实体
        if source:GetEntityType() == XReformConfigs.EntityType.Entity 
            or source:GetTargetId() ~= nil then
            table.insert(result, source)
        elseif checkAdd and source:GetEntityType() == XReformConfigs.EntityType.Add
            and source:GetTargetId() == nil then
            emptyPosCount = emptyPosCount + 1
            if nextAddSource == nil then nextAddSource = source end
        end
    end
    return result, nextAddSource, emptyPosCount
end

-- 剩余空位置的数量
function XReformBaseSourceGroup:GetEmptyPosCount()
    local result = 0
    for _, source in ipairs(self.Sources) do
        if source:GetEntityType() == XReformConfigs.EntityType.Add
            and source:GetTargetId() == nil then
            result = result + 1
        end
    end
    return result
end

function XReformBaseSourceGroup:GetSourceIndexById(id)
    for index, sourceId in ipairs(self.Config.SubId) do
        if sourceId == id then
            return index
        end
    end
    return -1
end

return XReformBaseSourceGroup