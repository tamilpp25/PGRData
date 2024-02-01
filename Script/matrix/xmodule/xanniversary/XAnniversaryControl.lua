---@class XAnniversaryControl : XControl
---@field private _Model XAnniversaryModel
local XAnniversaryControl = XClass(XControl, "XAnniversaryControl")
function XAnniversaryControl:OnInit()
    --初始化内部变量
end

function XAnniversaryControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XAnniversaryControl:RemoveAgencyEvent()

end

function XAnniversaryControl:OnRelease()
end

function XAnniversaryControl:SkipToActivity(activityId)
    local cfg=self._Model:GetAnniversaryActivity()[activityId]
    if cfg then
        XFunctionManager.SkipInterface(cfg.SkipID)
    end
end

--region 获取Model数据
function XAnniversaryControl:GetReviewPicturesCount()
    return XTool.GetTableCount(self._Model:GetAnniversaryReviewPictures())
end

function XAnniversaryControl:GetReviewPictures()
    return self._Model:GetAnniversaryReviewPictures()
end

function XAnniversaryControl:GetAnniversaryReviewDataUIById(id)
    return self._Model:GetAnniversaryReviewDataUI()[id]
end

function XAnniversaryControl:GetAnniversaryReivewSharePlatforms()
    return self._Model:GetAnniversaryReivewSharePlatforms()
end
--endregion

return XAnniversaryControl