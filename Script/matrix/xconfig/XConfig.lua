local type = type

---@class XConfig@配置基类（存储通用方法）
XConfig = XClass(nil, "XConfig")

local DefaultOfType = {
    ["int"] = 0,
    ["float"] = 0,
    ["string"] = nil,
    ["bool"] = false,
    ["fix"] = fix.zero
}


function XConfig:Ctor(path, xTable, primaryKey)
    primaryKey = primaryKey or "Id"
    self.Path = path
    self.XTable = xTable
    local readTableFunc
    local typeOfPrimaryKey = self.XTable[primaryKey].ValueType
    if typeOfPrimaryKey == "int" then
        readTableFunc = XTableManager.ReadByIntKey
    elseif typeOfPrimaryKey == "string" then
        readTableFunc = XTableManager.ReadByStringKey
    else
        XLog.Error("[XConfig] the type or PrimaryKey is undefined")
    end
    self.Configs = readTableFunc(path, xTable, primaryKey)
end

function XConfig:GetPath()
    return self.Path or ""
end

function XConfig:GetConfigs()
    return self.Configs
end

function XConfig:GetConfig(key)
    local config = self.Configs[key]
    if not config then
        XLog.Error(string.format("配置不存在, Id: %s, 配置路径:%s ", key, self.Path))
        return
    end
    return config
end

function XConfig:GetProperty(key, name)
    local config = self:GetConfig(key)
    if not config then
        return
    end
    local property = config[name]
    if nil == property and self:_GetValueType(name) ~= property then
        XLog.Error(string.format("配置字段未定义, 配置路径: %s, 配置Id:%s, 字段名称: %s", self.Path, key, name))
        return
    end
    return property
end

function XConfig:TryGetConfig(key)
    return self.Configs[key]
end

function XConfig:TryGetProperty(key, name, defaultValue)
    local config = self:GetConfig(key)
    local property = config[name]
    if property == nil then
        return defaultValue or self:_GetValueType(name), false
    end
    return property, true
end

function XConfig:_GetValueType(propertyName)
    return DefaultOfType[self.XTable[propertyName].ValueType]
end 