---这是一个基于XControl拓展的Control, 可支持添加Entity, 其中Entity可访问Model及其注册的Control
---@class XEntityControl : XControl
XEntityControl = XClass(XControl, "XEntityControl")

function XEntityControl:Ctor(id, mainControl)
    ---@type table<number, XEntity>
    self._EntitiesDict = {}
    ---@type table<any, table<number, XEntity>>
    self._EntitiesTypesDict = {}
    ---@type table<any, number> 用来存储最小uid值的entity
    self._TypesMinUid = {}
    self._TickTimer = false
    self._UpdateHandler = false
end

---添加一个定时器
---@param interval number 间隔时间
---@param delay number 延迟开始时间
function XEntityControl:StartTick(interval, delay)
    if not self._TickTimer then
        if not self._UpdateHandler then
            self._UpdateHandler = handler(self, self.OnUpdate)
        end
        self._TickTimer = XScheduleManager.ScheduleForever(self._UpdateHandler, interval, delay)
    end
end

---停止当前定时器
function XEntityControl:StopTick()
    if self._TickTimer then
        XScheduleManager.UnSchedule(self._TickTimer)
        self._TickTimer = false
    end
end

---@param cls any 实体的Class
---@return XEntity
function XEntityControl:AddEntity(cls, ...)
    ---@type XEntity
    local entity = cls.New(self)
    local uid = entity:GetUid()

    local minUid = self._TypesMinUid[cls]
    if not minUid or minUid > uid then --记录一个最小id
        self._TypesMinUid[cls] = uid
    end

    self._EntitiesDict[uid] = entity

    local typesDict = self._EntitiesTypesDict[cls]
    if not typesDict then
        typesDict = {}
        self._EntitiesTypesDict[cls] = typesDict
    end

    typesDict[uid] = entity
    entity:__Init(...)
    return entity
end

---@param entity XEntity 实体对象
function XEntityControl:RemoveEntity(entity)
    local uid = entity:GetUid()
    if self._EntitiesDict[uid] then
        local cls = entity.__class
        entity:__Release()

        self._EntitiesDict[uid] = nil
        local typesDict = self._EntitiesTypesDict[cls]
        typesDict[uid] = nil
        local hasOtherEntity = true
        if not next(typesDict) then
            self._EntitiesTypesDict[cls] = nil
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
function XEntityControl:GetFirstEntityWithType(cls)
    local minUid = self._TypesMinUid[cls]
    return self:GetEntityWithUid(minUid)
end

---根据传入的类型获取所有的实体
---@param cls any 实体的Class
---@return table<number, XEntity>
function XEntityControl:GetEntitiesWithType(cls)
    return self._EntitiesTypesDict[cls]
end

---根据uid获取对应的实体
---@param uid number 实体的uid
---@return XEntity
function XEntityControl:GetEntityWithUid(uid)
    return self._EntitiesDict[uid]
end

---获取所有实体对象
---@return table<number, XEntity>
function XEntityControl:GetAllEntities()
    return self._EntitiesDict
end

---移除所有的实体对象
function XEntityControl:RemoveAllEntities()
    for _, entity in pairs(self._EntitiesDict) do
        entity:__Release()
    end
    self._EntitiesDict = {}
    self._EntitiesTypesDict = {}
end

function XEntityControl:OnUpdate()

end


function XEntityControl:Release()
    self:RemoveAllEntities()
    self:StopTick()
    self._UpdateHandler = nil
    XEntityControl.Super.Release(self)
end

