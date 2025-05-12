local TABLE_PATH = "Client/Fight/UiFightTutorial.tab"

---@class XUiFightTutorialModel : XModel
local XUiFightTutorialModel = XClass(XModel, "XUiFightTutorialModel")
function XUiFightTutorialModel:OnInit()
    self._ConfigUtil:InitConfig({
        [TABLE_PATH] = { XConfigUtil.ReadType.Int, XTable.XTableUiFightTutorial, "Id", XConfigUtil.CacheType.Normal }
    })
end

function XUiFightTutorialModel:ClearPrivate()
    --这里执行内部数据清理
    
end

function XUiFightTutorialModel:ResetAll()
    --这里执行重登数据清理
    
end

----------public start----------


----------public end----------

----------private start----------


----------private end----------

----------config start----------

function XUiFightTutorialModel:GetTutorial()
    return self._ConfigUtil:Get(TABLE_PATH)
end

function XUiFightTutorialModel:GetConfig(id)
    local cfg = self:GetTutorial()[id]
    if cfg then
        return cfg
    else
        XLog.ErrorTableDataNotFound("XUiFightTutorialModel.GetConfig", "tab", TABLE_PATH, "id", tostring(id))
    end
end

----------config end----------


return XUiFightTutorialModel