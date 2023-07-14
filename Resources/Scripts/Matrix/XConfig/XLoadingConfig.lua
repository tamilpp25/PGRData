XLoadingConfig = XLoadingConfig or {}

local TypeDic = {}

local TABLE_LOADING_PATH = "Client/Loading/Loading.tab"

function XLoadingConfig.Init()
    local LoadingTemplate = XTableManager.ReadByIntKey(TABLE_LOADING_PATH, XTable.XTableLoading, "Id")

    local typeDic = {}

    --过滤Type
    for _, v in pairs(LoadingTemplate) do
        local type = v.Type
        local list = typeDic[type]
        if list == nil then
            list = {}
            typeDic[type] = list
        end
        table.insert(list, v)
    end

    TypeDic = typeDic
end
function XLoadingConfig.GetCfgByType(type)
    return TypeDic[type]
end