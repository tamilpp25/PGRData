local XUIGridStaff = require("XUi/XUiMovie/XUIGridStaff")

local ipairs = ipairs
local mathAbs = math.abs
local CSXScheduleManagerScheduleOnce = XScheduleManager.ScheduleOnce
local CSXScheduleManagerUnSchedule = XScheduleManager.UnSchedule
local Lerp = CS.UnityEngine.Vector3.Lerp
local Vector3 = CS.UnityEngine.Vector3

local DEFAULT_ANIM_DURATION_PRE_LINE = 0.5--每行字幕滚动时间/s

local XMovieActionStaff = XClass(XMovieActionBase, "XMovieActionStaff")

function XMovieActionStaff:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    self.StaffPath = params[1]--职员表配置路径
    self.BgPath = params[2]--背景路径（默认黑色背景）
    self.IsCanSkip = paramToNumber(params[3]) ~= 0--是否跳过（非0可跳过，否则隐藏skip按钮）
    local speed = paramToNumber(params[4])
    self.AnimDurationPreLine = speed == 0 and DEFAULT_ANIM_DURATION_PRE_LINE or speed--每行字幕滚动时间(s)
    self.DelayAtBegin = paramToNumber(params[5]) * XScheduleManager.SECOND--开头字幕停留时间(s)
    self.DelayAtEnd = paramToNumber(params[6]) * XScheduleManager.SECOND--结尾字幕停留时间(s)
end

function XMovieActionStaff:OnInit()
    local bgPath = self.BgPath
    if not string.IsNilOrEmpty(bgPath) then
        self.UiRoot.RImgBgStaff:SetRawImage(bgPath)
    end

    if not self:IsBlock() then
        self.UiRoot.PanelDialog.gameObject:SetActiveEx(false)--对话节点无法通过正常exit逻辑退出，需手动隐藏
    end
    self.UiRoot.BtnSkip.gameObject:SetActiveEx(self.IsCanSkip)
    self.UiRoot.TxtStaffName.gameObject:SetActiveEx(false)
    self.UiRoot.BtnSkipStaff.CallBack = function() self:OnClickBtnSkipStaff() end

    local staffPath = self.StaffPath
    local staffIds = XMovieConfigs.GetStaffIdList(staffPath)
    self.GridList = {}
    self.StaffIds = staffIds
    for index, staffId in ipairs(staffIds) do
        local grid = self.GridList[index]
        if not grid then
            local obj = CS.UnityEngine.Object.Instantiate(self.UiRoot.TxtStaffName.gameObject, self.UiRoot.PanelStaffContent)
            grid = XUIGridStaff.New(obj)
            self.GridList[index] = grid
        end
        grid:Refresh(staffPath, staffId)
        grid.GameObject:SetActiveEx(true)
    end

    self.UiRoot.PanelStaff.gameObject:SetActiveEx(true)
    self.UiRoot.PanelStaff.transform.localPosition = Vector3(0, -10000, 0)

    self.NeedDelay = self.DelayAtEnd ~= 0
    CSXScheduleManagerScheduleOnce(function()
        self.UiRoot.PanelStaff.transform.localPosition = Vector3(0, 0, 0)

        local contentGo = self.UiRoot.PanelStaffContent
        local viewHeight = self.UiRoot.StaffViewport.transform.rect.height
        local initPos = contentGo.transform.localPosition
        local startPos = Vector3(initPos.x, initPos.y - viewHeight * 0.5, initPos.z)
        local targetPos = Vector3(startPos.x, contentGo.transform.rect.height - viewHeight, startPos.z)
        local duration = self.AnimDurationPreLine * #self.StaffIds

        contentGo.transform.localPosition = startPos

        CSXScheduleManagerScheduleOnce(function()
            self:LetsRoll(startPos, targetPos, duration)
        end, self.DelayAtBegin)
    end, 0)
end

function XMovieActionStaff:OnAnimEnd()
    self:DestroyTimer()
    self:DestroyDelayTimer()
    self.UiRoot.PanelStaff.gameObject:SetActiveEx(false)
    self.UiRoot.BtnSkip.gameObject:SetActiveEx(true)
end

function XMovieActionStaff:OnClickBtnSkipStaff()
    if self.IsRoll then return end
end

function XMovieActionStaff:LetsRoll(startPos, targetPos, duration)
    local contentGo = self.UiRoot.PanelStaffContent
    local onRefreshFunc = function(time)

        if XTool.UObjIsNil(contentGo) then
            self:DestroyTimer()
            return true
        end

        local tf = contentGo.transform
        if tf.localPosition == targetPos then
            return true
        end

        tf.localPosition = Lerp(startPos, targetPos, time)

    end

    local finishCb = function()
        if XTool.UObjIsNil(contentGo) then return end

        if self.NeedDelay then

            self:DestroyDelayTimer()
            local delayTime = self.DelayAtEnd
            self.DelayTimer = CSXScheduleManagerScheduleOnce(function()
                if XTool.UObjIsNil(contentGo) then return end

                self.NeedDelay = nil
                local startPos = contentGo.transform.localPosition
                local targetPos = Vector3(startPos.x, contentGo.transform.rect.height, startPos.z)
                local duration = self.AnimDurationPreLine * 10--默认空白10行
                self:LetsRoll(startPos, targetPos, duration)

            end, delayTime)

            return
        end

        self.IsRoll = nil
        self:OnAnimEnd()

        if self:IsBlock() then
            XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK)
        end

    end

    self:DestroyTimer()
    self.IsRoll = true
    self.Timer = XUiHelper.Tween(duration, onRefreshFunc, finishCb)
end

function XMovieActionStaff:DestroyTimer()
    if self.Timer then
        CSXScheduleManagerUnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XMovieActionStaff:DestroyDelayTimer()
    if self.DelayTimer then
        CSXScheduleManagerUnSchedule(self.DelayTimer)
        self.DelayTimer = nil
    end
end

return XMovieActionStaff