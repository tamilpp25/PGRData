---@class XConfigUtil
XConfigUtil = XClass(nil, "XConfigUtil")

XConfigUtil.ReadType = {
    Int = 1,
    String = 2,
    IntAll = 3,
    StringAll = 4
}
---配置表缓存方式
XConfigUtil.CacheType = {
    Normal = 0, --常驻
    Private = 1, --ClearPrivate的时候释放
    Temp = 2, --临时返回, 不做缓存
    Preload = 3, --预加载, 一初始化就load(内存常驻)
}

XConfigUtil.DirectoryType = {
    Share = 1,
    Client = 2,
}

local IsWindowsEditor = XMain.IsWindowsEditor

function XConfigUtil.GetReadHandler(readType)
    if readType == XConfigUtil.ReadType.Int then
        return XTableManager.ReadByIntKey
    elseif readType == XConfigUtil.ReadType.String then
        return XTableManager.ReadByStringKey
    elseif readType == XConfigUtil.ReadType.IntAll then
        return XTableManager.ReadAllByIntKey
    elseif readType == XConfigUtil.ReadType.StringAll then
        return XTableManager.ReadAllByStringKey
    end
    XLog.Error("Can not find read handler: ".. readType)
end

function XConfigUtil:Ctor(id)
    self._Id = id
    self._ConfigArgs = nil
    self._Configs = {}
    if IsWindowsEditor then
        self._CheckerFunc = {}
    end
end

---注册配置表的读取方式
--- tableKey{ tableName = {ReadFunc , DirPath, Identifier, TableDefindName, CacheType} }
--- forceAllCacheType 将整个tablekey的读表方式改为 forceAllCacheType
function XConfigUtil:InitConfigByTableKey(parentPath, tableKey, forceAllCacheType)
    -- 枚举出反向的k-v
    if not self._TableKey then
        self._TableKey = {}
    end
    for k, v in pairs(tableKey) do
        self._TableKey[v] = k
    end

    -- 将表的格式转化成可供InitConfig使用的格式
    if not self._ConfigArgs then --这里直接初始化, 走单个添加, 减少遍历量
        self._ConfigArgs = {}
    end
    for k, v in pairs(tableKey) do
        local dirPath = "Share"
        if v.DirPath and v.DirPath == XConfigUtil.DirectoryType.Client then
            dirPath = "Client"
        end
        local path = dirPath.."/".. parentPath .."/" .. k ..".tab"
        local arg = {}
        arg[1] = v.ReadFunc or XConfigUtil.ReadType.Int
        arg[2] = v.TableDefindName and XTable[v.TableDefindName] or XTable["XTable"..k]
        arg[3] = v.Identifier or "Id"
        local chacheType = v.CacheType or XConfigUtil.CacheType.Private
        if forceAllCacheType and not v.CacheType then
            chacheType = forceAllCacheType
        end
        arg[4] = chacheType

        if not self._TablePath then
            self._TablePath = {}
        end
        self._TablePath[k] = path

        self:AddSingleConfig(path, { arg[1], arg[2], arg[3], arg[4] })
    end
end

---给定配置表Key，获取一个配置表
---@param tableKey table 配置表的Key
---@return any 配置表
function XConfigUtil:GetByTableKey(tableKey)
    local path = self:GetPathByTableKey(tableKey)
    return self:Get(path)
end

---给定配置表Key，获取该配置表路径
---@param tableKey table 配置表的Key
function XConfigUtil:GetPathByTableKey(tableKey)
    local key = self._TableKey[tableKey]
    if not key then
        XLog.Error("The tableKey given is not exist. ModuleId: " .. self._Id)
        return nil
    end

    local path = self._TablePath[key]
    if not path then
        XLog.Error("The path given is not exist. ModuleId: " .. self._Id)
        return nil
    end
    return path
end

---给定配置表Key和Id，获取该配置表指定Id的配置
---@param tableKey table 配置表的Key
---@param idKey any 该配置表的主键Id或Key
---@param noTips boolean 若没有查找到对应项，是否要打印错误日志
function XConfigUtil:GetCfgByTableKeyAndIdKey(tableKey, idKey, noTips)
    local path = self:GetPathByTableKey(tableKey)
    return self:GetCfgByPathAndIdKey(path, idKey, noTips)
end

---给定配置表路径和Id，获取该配置表指定Id的配置 
---@param path string 配置表路径
---@param idKey any 该配置表的主键Id或Key
---@param noTips boolean 若没有查找到对应项，是否要打印错误日志
function XConfigUtil:GetCfgByPathAndIdKey(path, idKey, noTips)
    if not path then
        XLog.Error("The path given is not exist. ModuleId: " .. self._Id)
        return nil
    end
    local allConfigs = self:Get(path)
    if not allConfigs then
        return nil
    end
    local config = allConfigs[idKey]
    if not config then
        if not noTips then
            XLog.Error(string.format("ModuleId:%s出错:找不到%s数据。搜索路径: %s 索引%s = %s", self._Id, "唯一Id", path, "唯一Id", tostring(idKey)))
        end
        return nil
    end
    return config
end

---{path = {readFunc, xtable, identifier, CacheType}}
---@param arg any
function XConfigUtil:InitConfig(arg)
    if not self._ConfigArgs then
        self._ConfigArgs = arg
        for i, v in pairs(arg) do---检测是否需要预加载 (预加载的常驻在内存中)
            if v[4] == XConfigUtil.CacheType.Preload then
                self:Get(i)
            end
        end
    else
        for i, v in pairs(arg) do
            self:AddSingleConfig(i, v)
        end
    end
end

function XConfigUtil:AddCheckerByTableKey(tableKey, func, thisObj)
    if IsWindowsEditor then
        local path = self:GetPathByTableKey(tableKey)
        if path then
            self:AddChecker(path, func, thisObj)
        else
            XLog.Error("XConfigUtil:AddCheckerByTableKey: 找不到对应path")
        end
    end
end

function XConfigUtil:AddChecker(path, func, thisObj)
    if IsWindowsEditor then
        if not self._CheckerFunc[path] then
            self._CheckerFunc[path] = { func, thisObj}
        else
            XLog.Error("请勿重复添加表格检测函数: " .. path)
        end
    end
end

function XConfigUtil:AddSingleConfig(path, args)
    if self._ConfigArgs[path] then
        XLog.Error("请勿重复注册配置表: " .. path)
        return
    end
    self._ConfigArgs[path] = args
    if args[4] == XConfigUtil.CacheType.Preload then
        self:Get(path)
    end
end

---通过path获取一个配置表
---@param path string 配置表路径
---@return any 配置表
function XConfigUtil:Get(path)
    local config = self._Configs[path]
    if config then
        return config
    end
    if self._ConfigArgs[path] then
        local args = self._ConfigArgs[path]
        local func = XConfigUtil.GetReadHandler(args[1])
        if func then
            local config = func(path, args[2], args[3])
            if args[4] ~= XConfigUtil.CacheType.Temp then --临时的表格不缓存
                self._Configs[path] = config
            end
            if IsWindowsEditor then --在编辑器状态下检查如果是私有的表格, 然后界面没有引用的话可能是有问题的
                if self._CheckerFunc[path] then --有检测函数
                    local funcData = self._CheckerFunc[path]
                    funcData[1](funcData[2], config)
                end
                if args[4] == XConfigUtil.CacheType.Temp then --临时配置表
                    WeakRefCollector.AddRef(WeakRefCollector.Type.Config, config, path)
                elseif args[4] == XConfigUtil.CacheType.Private then --私有配置表都需要检测弱引用
                    if not XMVCA:_CheckControlRef(self._Id) then
                        XLog.Error(string.format("配置表为私有 %s, 但目前暂无control使用.", path))
                    end
                elseif args[4] == XConfigUtil.CacheType.Preload then
                    XMVCA:AddPreloadConfig(path)
                end
            end
            return config
        end
    else
        XLog.Error("can not find config args: " .. path)
    end
end

---清理一个配置表
---@param path string 配置表路径
function XConfigUtil:Clear(path)
    local config = self._Configs[path]
    if config then
        XTableManager.ReleaseTable(path)
        self._Configs[path] = nil
    end
end

---清理所有内部配置表, 在XModel.ClearPrivate时执行
function XConfigUtil:ClearPrivate()
    if not self._ConfigArgs then
        return
    end
    for path, arg in pairs(self._ConfigArgs) do
        local cacheType = arg[4]
        if cacheType == XConfigUtil.CacheType.Private then
            local config = self._Configs[path]
            if config then
                XTableManager.ReleaseTable(path)
                self._Configs[path] = nil
                if IsWindowsEditor then
                    WeakRefCollector.AddRef(WeakRefCollector.Type.Config, config, path)
                end
            end
        end
    end
end

---清理所有配置表
function XConfigUtil:Release()
    for path, _ in pairs(self._Configs) do
        XTableManager.ReleaseTable(path)
    end
    self._Configs = nil
    self._ConfigArgs = nil
    self._TablePath = nil
    self._TableKey = nil
    self._CheckerFunc = nil
end
