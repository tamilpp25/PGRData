---@class XUiMainModel : XModel
local XUiMainModel = XClass(XModel, "XUiMainModel")

-- tableKey{ tableName = {ReadFunc , DirPath, Identifier, TableDefindName, CacheType} }
local TableKey = 
{
    UiPanelTip = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
}

function XUiMainModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析

    --定义TableKey
    self._ConfigUtil:InitConfigByTableKey("UiMain", TableKey)
end

function XUiMainModel:ClearPrivate()
    --这里执行内部数据清理
    XLog.Error("请对内部数据进行清理")
end

function XUiMainModel:ResetAll()
    --这里执行重登数据清理
end

----------public start----------

---@return table<number, XTableUiPanelTip>
function XUiMainModel:GetUiPanelTip()
    return self._ConfigUtil:GetByTableKey(TableKey.UiPanelTip)
end

----------public end----------

----------private start----------


----------private end----------

----------config start----------


----------config end----------


return XUiMainModel