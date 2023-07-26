XSceneEntityManager = XSceneEntityManager or {}

local EntityMap = {}
local ChildToKeyGoMap = {}

function XSceneEntityManager.AddEntity(go, entity)
    local list = go:GetComponentsInChildren(typeof(CS.UnityEngine.Collider))
    local keyList = {}
    for i = 0, list.Length - 1 do
        local key = list[i].gameObject
        ChildToKeyGoMap[key] = go
        table.insert(keyList, key)
    end

    if entity and not XTool.UObjIsNil(go) then
        EntityMap[go] = entity
    end
end

function XSceneEntityManager.RemoveEntity(go)
    local key = ChildToKeyGoMap[go]

    if key == nil then
        key = go
    end

    if not XTool.UObjIsNil(key) then
        EntityMap[key] = nil
    end
end

function XSceneEntityManager.ClearEntities()
    EntityMap = {}
    ChildToKeyGoMap = {}
end

function XSceneEntityManager.GetEntity(go)
    local key = ChildToKeyGoMap[go]
    if not key then
        key = go
    end

    if XTool.UObjIsNil(key) then
        return nil
    end
    return EntityMap[key]
end