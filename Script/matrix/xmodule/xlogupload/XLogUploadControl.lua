---@class XLogUploadControl : XControl
---@field private _Model XLogUploadModel
local XLogUploadControl = XClass(XControl, "XUploadLogControl")
function XLogUploadControl:OnInit()
    --初始化内部变量
end

function XLogUploadControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XLogUploadControl:RemoveAgencyEvent()

end

---开始上传
---@return boolean 是否有上传内容
function XLogUploadControl:StartUpload()

end


function XLogUploadControl:OnRelease()
end

return XLogUploadControl