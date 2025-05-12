local XBigWorldBackpackConfigModel = require("XModule/XBigWorldBackpack/XBigWorldBackpackConfigModel")

---@class XBigWorldBackpackModel : XBigWorldBackpackConfigModel
local XBigWorldBackpackModel = XClass(XBigWorldBackpackConfigModel, "XBigWorldBackpackModel")

function XBigWorldBackpackModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self:_InitTableKey()
end

function XBigWorldBackpackModel:ClearPrivate()
    --这里执行内部数据清理
    -- XLog.Error("请对内部数据进行清理")
end

function XBigWorldBackpackModel:ResetAll()
    --这里执行重登数据清理
    -- XLog.Error("重登数据清理")
end

return XBigWorldBackpackModel