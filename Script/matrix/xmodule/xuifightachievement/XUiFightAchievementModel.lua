local TABLE_PATH = "Client/Fight/UiFightAchievement.tab"

---@class XUiFightAchievementModel : XModel
local XUiFightAchievementModel = XClass(XModel, "XUiFightAchievementModel")
function XUiFightAchievementModel:OnInit()
    self._ConfigUtil:InitConfig({
        [TABLE_PATH] = { XConfigUtil.ReadType.Int, XTable.XTableUiFightAchievement, "Id", XConfigUtil.CacheType.Normal }
    })
end

function XUiFightAchievementModel:ClearPrivate()
    --这里执行内部数据清理
end

function XUiFightAchievementModel:ResetAll()
    --这里执行重登数据清理
end

----------public start----------


----------public end----------

----------private start----------


----------private end----------

----------config start----------

function XUiFightAchievementModel:GetConfig(id)
    local cfg = self._ConfigUtil:Get(TABLE_PATH)[id]
    if cfg then
        return cfg
    else
        XLog.ErrorTableDataNotFound("XUiFightAchievementModel.GetConfig", "tab", TABLE_PATH, "id", tostring(id))
    end
end

----------config end----------


return XUiFightAchievementModel