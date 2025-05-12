---@class XLogUploadModel : XModel
local XLogUploadModel = XClass(XModel, "XUploadLogModel")
function XLogUploadModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
end

function XLogUploadModel:ClearPrivate()
    --这里执行内部数据清理
    --XLog.Error("请对内部数据进行清理")
end

function XLogUploadModel:ResetAll()
    --这里执行重登数据清理
    --XLog.Error("重登数据清理")
end

----------public start----------


----------public end----------

----------private start----------


----------private end----------

----------config start----------


----------config end----------


return XLogUploadModel