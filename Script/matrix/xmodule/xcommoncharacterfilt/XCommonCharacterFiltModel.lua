---@class XCommonCharacterFiltModel : XModel
local XCommonCharacterFiltModel = XClass(XModel, "XCommonCharacterFiltModel")
function XCommonCharacterFiltModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析

    self.SelectTagData = {} -- 记录缓存用
    self.SelectListData = {}
    self.SortTagData = {}
end

function XCommonCharacterFiltModel:ClearPrivate()
    --这里执行内部数据清理
end

function XCommonCharacterFiltModel:ResetAll()
    --这里执行重登数据清理
    self.SelectTagData = {} -- 记录缓存用
    self.SelectListData = {}
    self.SortTagData = {}
end

----------public start----------


----------public end----------

----------private start----------


----------private end----------

----------config start----------


----------config end----------


return XCommonCharacterFiltModel