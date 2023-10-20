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

function XAnniversaryControl:IsActivityInTime(activityid)
    local cfg=self._Model:GetAnniversaryActivity()[activityid]
    if cfg then
        return XFunctionManager.CheckSkipInDuration(cfg.SkipID)
    end
end

function XAnniversaryControl:IsActivityOutTime(activityid)
    local cfg=self._Model:GetAnniversaryActivity()[activityid]
    if cfg then
        local curTime=XTime.GetServerNowTimestamp()
        local skipCfg=XFunctionConfig.GetSkipFuncCfg(cfg.SkipID)
        --没有配置默认不开放
        if not skipCfg then return true end
        
        local endTime=0
        if skipCfg.TimeId then
            endTime=XFunctionManager.GetEndTimeByTimeId(skipCfg.TimeId)
        else
            endTime=skipCfg.CloseTime
        end
        return curTime<=endTime
    end
end

function XAnniversaryControl:IsActivityConditionSatisfy(activityId)
    local cfg=self._Model:GetAnniversaryActivity()[activityId]
    local isOpen=true
    local desc=nil
    if cfg then
        isOpen,desc = XFunctionManager.IsCanSkip(cfg.SkipID)
    end
    
    return isOpen,desc
end

function XAnniversaryControl:JudgeCanOpen(activityid)
    
    if self:IsActivityOutTime(activityid) then
        --活动已结束
        return false,XUiHelper.GetText('ActivityAlreadyOver')
    elseif self:IsActivityInTime(activityid) then
        return self:IsActivityConditionSatisfy(activityid)
    else
        local cfg=self._Model:GetAnniversaryActivity()[activityid]
        if cfg then
            --活动于xx月xx日开启
            local skipCfg=XFunctionConfig.GetSkipFuncCfg(cfg.SkipID)
            if skipCfg then
                if skipCfg.TimeId then
                    local startTime=XFunctionManager.GetStartTimeByTimeId(skipCfg.TimeId)
                    local month,week,day=XUiHelper.GetTimeNumber(startTime)
                    return false,XUiHelper.GetText('ActivityOpenMonthDayTime',month,day)
                else
                    return false,XUiHelper.GetText('ActivityAlreadyOver')
                end
            end
            
        end

    end
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