---@class XCommonCharacterFiltModel : XModel
local XCommonCharacterFiltModel = XClass(XModel, "XCommonCharacterFiltModel")
function XCommonCharacterFiltModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析

    self.SelectTagData = {} -- 记录缓存用
    self.SelectListData = {}
    self.SortTagData = {}
    self.LastSortResList = nil
    self.NotSortTrigger = nil
    self.FilterGoProxyDic = {} -- 缓存筛选器GameObject和代理的字典
end

function XCommonCharacterFiltModel:ClearPrivate()
    --这里执行内部数据清理
end

function XCommonCharacterFiltModel:ResetAll()
    --这里执行重登数据清理
    self.SelectTagData = {} -- 记录缓存用
    self.SelectListData = {}
    self.SortTagData = {}
    self.LastSortResList = nil
    self.NotSortTrigger = nil
    self.FilterGoProxyDic = {} 
end

----------public start----------


----------public end----------

----------private start----------


----------private end----------

----------config start----------


----------config end----------


return XCommonCharacterFiltModel