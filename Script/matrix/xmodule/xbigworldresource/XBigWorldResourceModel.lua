local XBigWorldResourceConfigModel = require("XModule/XBigWorldResource/XBigWorldResourceConfigModel")

---@class XBigWorldResourceModel : XBigWorldResourceConfigModel
local XBigWorldResourceModel = XClass(XBigWorldResourceConfigModel, "XBigWorldResourceModel")
function XBigWorldResourceModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self:_InitTableKey()
end

function XBigWorldResourceModel:ClearPrivate()
    --这里执行内部数据清理
end

function XBigWorldResourceModel:ResetAll()
    --这里执行重登数据清理
end

return XBigWorldResourceModel