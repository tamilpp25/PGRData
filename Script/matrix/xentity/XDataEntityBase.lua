local pairs = pairs
local setmetatable = setmetatable
local tablePack = table.pack
local tableUnpack = table.unpack
local tableInsert = table.insert
local IsTableEmpty = XTool.IsTableEmpty

---@class XDataEntityBase 数据实体基类（存储通用方法）/ViewModle（当绑定UI对象后转化为VM层）
XDataEntityBase = XClass(nil, "XDataEntityBase")

function XDataEntityBase:Init(default, id)
    self._Default = default --默认值
    self._Properties = {} --属性
    self._BindingsDic = {} --绑定UI对象字典(字段名称 -> UiName -> UI对象 -> 更新函数闭包)

    --hook元方法
    setmetatable(
        self,
        {
            __index = function(t, k)
                local value = self._Properties[k]
                if nil ~= value then
                    return value
                end
                value = self.__class[k]
                if nil ~= value then 
                    return value 
                end
                value = XDataEntityBase[k]
                if nil ~= value then
                    return value
                end
                value = GetClassVituralTable(self.__class)[k]
                if nil ~= value then
                    return value
                end
            end,
            __newindex = function(_, k, v)
                self._Properties[k] = v
            end
        }
    )

    for key, value in pairs(self._Default) do
        self:SetProperty(key, XTool.Clone(value))
    end

    self:InitData(id)
end

function XDataEntityBase:Reset()
    local id = self:GetProperty("_Id")
    for key, value in pairs(self._Default) do
        self:SetProperty(key, XTool.Clone(value))
    end
    self:InitData(id)
end

--- 持久化初始数据
---@param id any 持久化数据Key
---@return void
--------------------------
function XDataEntityBase:InitData(id)
end

--- 设置属性的值
---@param name string 属性名
---@param value any 属性值
---@return void
--------------------------
function XDataEntityBase:SetProperty(name, value)
    if nil == value then
        return
    end

    local oldValue = self._Properties[name]
    self._Properties[name] = value
    
    if type(value) == "table" or oldValue ~= value then --table类型不做比对，默认全量更新
        self:UpdateBindings(name)
    end
end

--- 获取属性的值（如子类字段有修改，重写此方法加上自己的字段名比对特殊处理）
---@param name string 属性名
---@return any 属性值
--------------------------
function XDataEntityBase:GetProperty(name)
    return self[name] or self._Default[name]
end

--[[
    绑定属性到Ui对象（单向绑定）:字段名称 -> UiName -> UI绑定对象 -> 更新函数闭包
    @param name:属性名
    @param uiName:UI名称
    @param func:更新函数闭包
]]
function XDataEntityBase:BindPropertyToObj(uiName, func, name, delayUpdateBindings)
    self._BindingsDic[name] = self._BindingsDic[name] or {}
    self._BindingsDic[name][uiName] = self._BindingsDic[name][uiName] or {}
    tableInsert(self._BindingsDic[name][uiName], func)
    if not delayUpdateBindings then
        func(self:GetProperty(name))
    end
end

--多重绑定
function XDataEntityBase:BindPropertiesToObj(uiName, func, ...)
    local paramNames = tablePack(...)

    local multiParamFunc = function()
        local params = {}
        for _, name in ipairs(paramNames) do
            tableInsert(params, self:GetProperty(name))
        end
        func(tableUnpack(params))
    end

    for _, name in ipairs(paramNames) do
        self:BindPropertyToObj(uiName, multiParamFunc, name, true)
    end

    multiParamFunc()
end

--触发绑定UI对象更新回调
function XDataEntityBase:UpdateBindings(name)
    if IsTableEmpty(self._BindingsDic) then
        return
    end

    local objs = self._BindingsDic[name]
    if IsTableEmpty(objs) then
        return
    end

    for uiName, funcList in pairs(objs) do
        --仅更新展示中的UI数据
        if XLuaUiManager.IsUiShow(uiName) then
            for _, func in pairs(funcList) do
                func(self:GetProperty(name))
            end
        end
    end
end

--解绑属性名称下的指定UI名称已绑定对象
function XDataEntityBase:UnBindPropertyByUiName(name, uiName)
    if not self._BindingsDic[name] then
        return
    end

    self._BindingsDic[name][uiName] = nil

    if IsTableEmpty(self._BindingsDic[name]) then
        self._BindingsDic[name] = nil
    end
end

--解绑UI名称下所有对象已绑定属性
function XDataEntityBase:UnBindUiObjs(uiName)
    if IsTableEmpty(self._BindingsDic) then
        return
    end

    for name in pairs(self._Properties) do
        self:UnBindPropertyByUiName(name, uiName)
    end
end
