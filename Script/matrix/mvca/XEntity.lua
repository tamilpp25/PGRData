---@class XEntity : XUidObject
---@field protected _OwnControl XEntityControl
---@field protected _ParentEntity XEntity
XEntity = XClass(XUidObject, "XEntity")
local IsWindowsEditor = XMain.IsWindowsEditor
function XEntity:Ctor(ownControl, parentEntity)
    self._OwnControl = ownControl
    self._ParentEntity = parentEntity
    self._ChildEntities = {}
    self._ChildEntitiesTypes = {}
    ---@type table<any, number> 用来存储最小uid值的entity
    self._TypesMinUid = {}
end

function XEntity:__Init(...)
    self:OnInit(...)
end

function XEntity:OnInit()

end

function XEntity:__Release()
    self:RemoveAllChildEntities()
    self:OnRelease()
    self._OwnControl = nil
    self._ParentEntity = nil
    if IsWindowsEditor then
        WeakRefCollector.AddRef(WeakRefCollector.Type.Entity, self)
    end
end

function XEntity:OnRelease()

end

---@param cls any 实体的Class
---@return XEntity
function XEntity:AddChildEntity(cls, ...)
    ---@type XEntity
    local entity = cls.New(self._OwnControl, self)
    local uid = entity:GetUid()

    local minUid = self._TypesMinUid[cls]
    if not minUid or minUid > uid then --记录一个最小id
        self._TypesMinUid[cls] = uid
    end

    self._ChildEntities[uid] = entity

    local typesDict = self._ChildEntitiesTypes[cls]
    if not typesDict then
        typesDict = {}
        self._ChildEntitiesTypes[cls] = typesDict
    end
    typesDict[uid] = entity
    entity:__Init(...)
    return entity
end

---@param entity XEntity 实体对象
function XEntity:RemoveChildEntity(entity)
    local uid = entity:GetUid()
    if self._ChildEntities[uid] then
        local cls = entity.__class
        entity:__Release()

        self._ChildEntities[uid] = nil
        local typesDict = self._ChildEntitiesTypes[cls]
        typesDict[uid] = nil
        local hasOtherEntity = true
        if not next(typesDict) then
            self._ChildEntitiesTypes[cls] = nil
            hasOtherEntity = false
        end

        local minUid = self._TypesMinUid[cls]
        if minUid == uid then --如果相等要重新找一个
            if hasOtherEntity then
                local tempUid = -1
                for uid, _ in pairs(typesDict) do
                    if tempUid == -1 or uid < tempUid then
                        tempUid = uid
                    end
                end
                self._TypesMinUid[cls] = tempUid
            else
                self._TypesMinUid[cls] = nil --没有后续的实体了, 直接清空
            end
        end
    end
end

---获取该类型第一个添加的实体
---@param cls any 实体的class
function XEntity:GetFirstChildEntityWithType(cls)
    local minUid = self._TypesMinUid[cls]
    return self:GetChildEntityWithUid(minUid)
end

---根据传入的类型获取所有的子实体
---@param cls any 实体的Class
---@return table<number, XEntity>
function XEntity:GetChildEntitiesWithType(cls)
    return self._ChildEntitiesTypes[cls]
end

---根据uid获取对应的子实体
---@param uid number 实体的uid
---@return XEntity
function XEntity:GetChildEntityWithUid(uid)
    return self._ChildEntities[uid]
end

---获取所有子实体对象
---@return table<number, XEntity>
function XEntity:GetAllChildEntities()
    return self._ChildEntities
end

---移除所有的子实体对象
function XEntity:RemoveAllChildEntities()
    for _, entity in pairs(self._ChildEntities) do
        entity:__Release()
    end
    self._ChildEntities = {}
    self._ChildEntitiesTypes = {}
end
