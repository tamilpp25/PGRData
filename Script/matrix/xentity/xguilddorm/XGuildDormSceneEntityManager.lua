local XGuildDormSceneEntityManager = XClass(nil, "XGuildDormSceneEntityManager")

function XGuildDormSceneEntityManager:Ctor()
    self.ChildToKeyGoMap = {}
    self.EntityMap = {}
    self.FurnitureEntities = {}
end

function XGuildDormSceneEntityManager:AddEntity(go, entity)
    local list = go:GetComponentsInChildren(typeof(CS.UnityEngine.Collider))
    local keyList = {}
    for i = 0, list.Length - 1 do
        local key = list[i].gameObject
        self.ChildToKeyGoMap[key] = go
        table.insert(keyList, key)
    end
    if entity and not XTool.UObjIsNil(go) then
        self.EntityMap[go] = entity
        if self:CheckEntityIsFurniture(entity) then
            table.insert(self.FurnitureEntities, entity)
        end
    end
end

function XGuildDormSceneEntityManager:RemoveEntity(go)
    local key = self.ChildToKeyGoMap[go]
    if key == nil then
        key = go
    end
    if not XTool.UObjIsNil(key) then
        if self:CheckEntityIsFurniture(self.EntityMap[key]) then
            for i = #self.FurnitureEntities, 1 do
                if self.FurnitureEntities[i] == self.EntityMap[key] then
                    table.remove(self.FurnitureEntities, i)
                    break
                end
            end
        end
        self.EntityMap[key] = nil
    end
end

function XGuildDormSceneEntityManager:ClearEntities()
    self.EntityMap = {}
    self.ChildToKeyGoMap = {}
end

function XGuildDormSceneEntityManager:GetEntity(go)
    local key = self.ChildToKeyGoMap[go]
    if not key then
        key = go
    end
    if XTool.UObjIsNil(key) then
        return nil
    end
    return self.EntityMap[key]
end

function XGuildDormSceneEntityManager:CheckEntityIsFurniture(entity)
    return entity and entity.__cname == "XGuildDormFurniture"
end

return XGuildDormSceneEntityManager