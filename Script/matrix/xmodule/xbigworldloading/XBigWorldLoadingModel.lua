---@class XBigWorldLoadingModel : XModel
local XBigWorldLoadingModel = XClass(XModel, "XBigWorldLoadingModel")

local TableKey = {
    BigWorldLoading = {},
}

function XBigWorldLoadingModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._LevelLoadingMap = false
    
    self._ConfigUtil:InitConfigByTableKey("BigWorld/Common/Loading", TableKey)
end

function XBigWorldLoadingModel:ClearPrivate()
    --这里执行内部数据清理
end

function XBigWorldLoadingModel:ResetAll()
    --这里执行重登数据清理
    self._LevelLoadingMap = false
end

---@return XTableBigWorldLoading[]
function XBigWorldLoadingModel:GetBigWorldLoadingConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.BigWorldLoading) or {}
end

---@return XTableBigWorldLoading
function XBigWorldLoadingModel:GetBigWorldLoadingConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BigWorldLoading, id, false) or {}
end

function XBigWorldLoadingModel:GetBigWorldLoadingLevelIdById(id)
    local config = self:GetBigWorldLoadingConfigById(id)

    return config.LevelId
end

function XBigWorldLoadingModel:GetBigWorldLoadingNameById(id)
    local config = self:GetBigWorldLoadingConfigById(id)

    return config.Name
end

function XBigWorldLoadingModel:GetBigWorldLoadingDescById(id)
    local config = self:GetBigWorldLoadingConfigById(id)

    return config.Desc
end

function XBigWorldLoadingModel:GetBigWorldLoadingImageUrlById(id)
    local config = self:GetBigWorldLoadingConfigById(id)

    return config.ImageUrl
end

function XBigWorldLoadingModel:GetBigWorldLoadingWeightById(id)
    local config = self:GetBigWorldLoadingConfigById(id)

    return config.Weight
end

function XBigWorldLoadingModel:GetBigWorldLoadingConditionIdsById(id)
    local config = self:GetBigWorldLoadingConfigById(id)

    return config.ConditionIds
end

---@return table<number, XTableBigWorldLoading[]>
function XBigWorldLoadingModel:GetLevelLoadingMap()
    if not self._LevelLoadingMap then
        local configs = self:GetBigWorldLoadingConfigs()
        
        self._LevelLoadingMap = {}
        for id, config in pairs(configs) do
            local levelId = config.LevelId
            
            if not self._LevelLoadingMap[levelId] then
                self._LevelLoadingMap[levelId] = {}
            end

            table.insert(self._LevelLoadingMap[levelId], config)
        end
    end

    return self._LevelLoadingMap
end

---@return XTableBigWorldLoading[]
function XBigWorldLoadingModel:GetLoadingConfigsByLevelId(levelId)
    local levelLoadingMap = self:GetLevelLoadingMap()

    return levelLoadingMap[levelId]
end

return XBigWorldLoadingModel