XLoadingConfig = XLoadingConfig or {}

local CustomLoadingCfg = {}
local LoadingAllowType = {}
local CGBlockGroup = {}
local TypeDic = {}

local TABLE_LOADING_PATH = "Client/Loading/Loading.tab"
local TABLE_CUSTOM_LOADING_PATH = "Client/Loading/CustomLoading.tab"

XLoadingConfig.DEFAULT_TYPE = "0"

function XLoadingConfig.Init()
    local LoadingTemplate = XTableManager.ReadAllByIntKey(TABLE_LOADING_PATH, XTable.XTableLoading, "Id")
    CustomLoadingCfg = XTableManager.ReadByIntKey(TABLE_CUSTOM_LOADING_PATH, XTable.XTableCustomLoading, "Id")[1]
    TypeDic = {}
    --过滤Type
    for _, v in pairs(LoadingTemplate) do
        local type = v.Type
        local list = TypeDic[type]
        if not list then
            list = {}
            TypeDic[type] = list
        end
        table.insert(list, v)
    end

    LoadingAllowType = {}
    for _, v in pairs(CustomLoadingCfg.AllowType) do
        LoadingAllowType[v] = true
    end

    CGBlockGroup = {}
    for _, v in pairs(CustomLoadingCfg.BlockGroup) do
        CGBlockGroup[v] = true
    end
end

function XLoadingConfig.GetCfgByType(type)
    return TypeDic[type]
end

-- 范围：0-10000
function XLoadingConfig.GetCustomRate()
    return CustomLoadingCfg.Rate
end

function XLoadingConfig.GetCustomMaxSize()
    return CS.XGame.Config:GetInt("CustomLoadingMaxSize")
end

function XLoadingConfig.GetCustomUseSpine()
    return CustomLoadingCfg.UseSpine
end

function XLoadingConfig.CheckCustomAllowType(stageLoadingType)
    return LoadingAllowType[stageLoadingType]
end

function XLoadingConfig.CheckCustomBlockGroup(groupId)
    return CGBlockGroup[groupId]
end