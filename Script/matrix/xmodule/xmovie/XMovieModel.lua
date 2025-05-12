-- tableKey{ tableName = {ReadFunc , DirPath, Identifier, TableDefindName, CacheType} }
local TableKey = 
{
    MovieKeyword = { DirPath = XConfigUtil.DirectoryType.Client },
    MovieRecordOptions = { CacheType = XConfigUtil.CacheType.Normal, ReadFunc = XConfigUtil.ReadType.String },
    MovieClientConfig = { CacheType = XConfigUtil.CacheType.Normal, DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Key", ReadFunc = XConfigUtil.ReadType.String },
}

---@class XMovieModel : XModel
local XMovieModel = XClass(XModel, "XMovieModel")
function XMovieModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析

    -- config相关
    self._ConfigUtil:InitConfigByTableKey("Movie", TableKey)

    -- 剧情已选项相关记录
    self.MovieOptionsDic = {}
end

function XMovieModel:ClearPrivate()
    --这里执行内部数据清理
    --XLog.Error("请对内部数据进行清理")
end

function XMovieModel:ResetAll()
    --这里执行重登数据清理
    --XLog.Error("重登数据清理")
end

-- 打包成OptionId
---@param actionId number 对应配置表的ActionId
---@param optionIndex number 选项下标
function XMovieModel:PackOptionId(actionId, optionIndex)
    optionIndex = optionIndex or 0
    return actionId * 1000 + optionIndex
end

-- 解包OptionId
---@return number 对应配置表的ActionId
---@return number 选项下标
function XMovieModel:UnPackOptionId(optionId)
    local actionId = math.floor(optionId / 1000)
    local optionIndex = optionId % 1000
    return actionId, optionIndex
end

--============================================================== #region 配置表 ==============================================================
--- 获取名词注释配置
function XMovieModel:GetKeywordConfig(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.MovieKeyword)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Client/Movie/MovieKeyword.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

--- 选项记录配置
function XMovieModel:GetRecordOptionsConfig(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.MovieRecordOptions)
    return cfgs[id]
end

-- 剧情记录选项配置是否存在
function XMovieModel:IsRecordOptionsConfigExit(id)
    local config = self:GetRecordOptionsConfig(id)
    return config ~= nil
end

-- 获取ClientConfig表配置
function XMovieModel:GetClientConfig(key, index)
    if index == nil then index = 1 end
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.MovieClientConfig, key)
    return config and config.Params[index] or ""
end

-- 获取ClientConfig表配置所有参数
function XMovieModel:GetClientConfigParams(key)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.MovieClientConfig, key)
    return config and config.Params or {}
end
--============================================================== #endregion 配置表 ==============================================================


--============================================================== #region 协议数据 ==============================================================
-- 更新剧情选项
function XMovieModel:UpdateMovieOptions(movieId, options)
    local optionDic = {}
    -- 初始化配置选项
    local cfg = self:GetRecordOptionsConfig(movieId)
    for i, optionId in ipairs(cfg.Options) do
        optionDic[optionId] = false
    end
    -- 更新服务器记录
    if options then
        for _, optionId in pairs(options) do
            optionDic[optionId] = true
        end
    end
    self.MovieOptionsDic[movieId] = optionDic
end

-- 新增剧情选项记录
function XMovieModel:AddMovieOption(movieId, optionId)
    local optionDic = self.MovieOptionsDic[movieId]
    optionDic[optionId] = true
end

-- 是否选择过选项
function XMovieModel:IsOptionPassed(movieId, actionId, optionIndex)
    local optionDic = self.MovieOptionsDic[movieId]
    if not optionDic then 
        return false 
    end
    
    optionIndex = optionIndex or 0
    local optionId = self:PackOptionId(actionId, optionIndex)
    return optionDic[optionId] == true
end

-- 选项Id是否需要记录
function XMovieModel:IsOptionNeedRecord(movieId, actionId, optionIndex)
    local optionDic = self.MovieOptionsDic[movieId]
    if not optionDic then 
        return false 
    end

    local optionId = self:PackOptionId(actionId, optionIndex)
    return optionDic[optionId] == false -- 已记录为true，无效为nil
end

--============================================================== #endregion 协议数据 ==============================================================

return XMovieModel
