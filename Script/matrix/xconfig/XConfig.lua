local type = type

--配置基类（存储通用方法）
XConfig = XClass(nil, "XConfig")

function XConfig:Ctor(path, xTable, primaryKey)
    primaryKey = primaryKey or "Id"
    self.Path = path
    self.XTable = xTable
    self.Configs = XTableManager.ReadByIntKey(path, xTable, primaryKey)
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
    local property = config[name]
    if nil == property and XTableManager.GetTypeDefaultValue(self.XTable[name].ValueType) ~= property then
        XLog.Error(string.format("配置字段未定义, 配置路径: %s, 配置Id:%s, 字段名称: %s", self.Path, key, name))
        return
    end
    return property
end
