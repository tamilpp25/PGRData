
local XExFubenBaseManager = require("XEntity/XFuben/XExFubenBaseManager")
-- 活动玩法管理器
local XExFubenActivityManager = XClass(XExFubenBaseManager, "XExFubenActivityManager")

function XExFubenActivityManager:ExSetConfig(value)
    if type(value) == "string" then
        value = XFubenConfigs.GetFubenActivityConfigByManagerName(value)
    end
    self.ExConfig = value or {}
end

-- -- 是否展示在主界面
-- function XExFubenActivityManager:ExGetIsShowOnMainUi()
--     if not self.ExConfig.IsShowOnMain then return false end
--     if XFunctionManager.CheckInTimeByTimeId(self.ExConfig.TimeId, true) then return true end
--     return false
-- end

-- -- 获取主界面时间提示
-- function XExFubenActivityManager:ExGetMainTimeTip()
--     local startTime = XFunctionManager.GetStartTimeByTimeId(self.ExConfig.TimeId)
--     local endTime = XFunctionManager.GetEndTimeByTimeId(self.ExConfig.TimeId)
--     return string.format( "%s-%s"
--         , XTime.TimestampToGameDateTimeString(startTime, "MM.dd")
--         , XTime.TimestampToGameDateTimeString(endTime, "MM.dd"))
-- end

-- -- 获取玩法主界面物品id
-- function XExFubenActivityManager:ExGetItemId()
--     return self.ExConfig.ItemId
-- end

-- 获取进度提示
function XExFubenActivityManager:ExGetProgressTip()
    local managerName = self.ExConfig.ManagerName
    if string.IsNilOrEmpty(managerName) then return "" end
    local manager = XDataCenter[managerName]
    if manager == nil then return "" end
    local func = manager["GetProgressTips"]
    if func == nil then return "" end
    return func() or ""
end

return XExFubenActivityManager