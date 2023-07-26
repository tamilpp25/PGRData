---@class XActivityBrieButton
local XActivityBrieButton = XClass(nil, "XActivityBrieButton")


local ACTIVITYBRIEBUTTONISFIRSTTIMECLICK = "ActivityBrieButtonIsFirstTimeClick"

function XActivityBrieButton:Ctor(ui, uiRoot, activityGroupId)
    self.BtnCom = ui
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    self.activityGroupId = activityGroupId
    self.IsAlwaysCheck = false
    self.Offset = 0
    self.BtnCom:ShowTag(false)
    self.BtnCom:ShowReddot(false)
    self:InitUnlockAnim()
end

function XActivityBrieButton:Refresh(args)
    local isOpen, str, timeStr = XActivityBrieIsOpen.Get(self.activityGroupId, args)
    self.args = args

    if not string.IsNilOrEmpty(timeStr) then
        self.BtnCom:SetNameByGroup(0, timeStr)
    else
        local config = XActivityBriefConfigs.GetActivityGroupConfig(self.activityGroupId)
        self.BtnCom:SetNameByGroup(0, "")
    end
    local isWaitLockAnim = XTool.IsNumberValid(XActivityBriefConfigs.GetActivityBriefGroupIsRemindWhenOpen(self.activityGroupId))
        and not XDataCenter.ActivityBriefManager.GetIsPlayedUnlockAnim(self.activityGroupId)
    self.BtnCom:SetDisable(not isOpen or isOpen and isWaitLockAnim)
end

---初始化解锁动画状态
function XActivityBrieButton:InitUnlockAnim()
    self.PanelEffectLock = XUiHelper.TryGetComponent(self.Transform, "PanelEffectLock")
    if self.PanelEffectLock then
        self.PanelEffectLock.gameObject:SetActiveEx(false)
    end
end

---播放解锁动画
---@param cb function 动画结束回调
function XActivityBrieButton:PlayUnlockAnim(cb)
    XDataCenter.ActivityBriefManager.SetIsPlayedUnlockAnim(self.activityGroupId)
    if self.PanelEffectLock then
        self.PanelEffectLock.gameObject:SetActiveEx(false)
        self.PanelEffectLock.gameObject:SetActiveEx(true)
        self.BtnCom:SetDisable(false)
        XScheduleManager.ScheduleOnce(function()
            -- 关闭特效防止跳转其他界面返回时出现特效
            self.PanelEffectLock.gameObject:SetActiveEx(false)
            if cb then cb() end
        end, 800)
    else
        if cb then cb() end
    end
end

---可挑战Tag,第一次点击后消失
---@param conditionGroup table<number, string>XRedPointConditions.Conditions
---@param args any XRedPointConditions.Conditions用的参数
---@param isAlwaysCheck boolean 为true时未点击前恒显示tag
---@param offset number|nil 时间戳数据,不填时默认服务器下次刷新时间刷新tag,不为0时服务器下次刷新时间+offset时刷新tag
function XActivityBrieButton:AddNewTagEvent(conditionGroup, args, isAlwaysCheck,offset)
    self.IsAlwaysCheck = isAlwaysCheck
    if self:CheckFirstClicked(offset) or isAlwaysCheck then
        XRedPointManager.AddRedPointEvent(self.BtnCom, self.OnNewTagEvent, self, conditionGroup, args, true)
    else
        self.BtnCom:ShowTag(false)
    end
end

function XActivityBrieButton:OnNewTagEvent(count)
    self:ShowTag(count > -1)
end

---刷新tag
---@param isShow boolean
---@param offset number|nil 时间戳数据,不填时默认服务器下次刷新时间刷新tag,不为0时服务器下次刷新时间 + offset时刷新tag
function XActivityBrieButton:ShowTag(isShow,offset)
    local isOpen = XActivityBrieIsOpen.Get(self.activityGroupId, self.args)
    if (self:CheckFirstClicked(offset) or self.IsAlwaysCheck) and isOpen then
        self.BtnCom:ShowTag(isShow)
    else
        self.BtnCom:ShowTag(false)
    end
end

function XActivityBrieButton:CheckFirstClicked(offset)
    self.Offset = offset or 0
    return not XSaveTool.GetData(self:GetPlayerPrefsKey())
end

---红点刷新事件注册
---@param conditionGroup table<number, string>XRedPointConditions.Conditions
---@param args any XRedPointConditions.Conditions用的参数
function XActivityBrieButton:AddRedPointEvent(conditionGroup, args)
    XRedPointManager.AddRedPointEvent(self.BtnCom, self.OnRedPointEvent, self, conditionGroup, args, true)
end

function XActivityBrieButton:OnRedPointEvent(count)
    self:ShowReddot(count >= 0)
end

---刷新红点
---@param value boolean
function XActivityBrieButton:ShowReddot(value)
    local isOpen = XActivityBrieIsOpen.Get(self.activityGroupId, self.args)
    if not isOpen then
        value = false
    end

    self.BtnCom:ShowReddot(value)
end

function XActivityBrieButton:GetButtonCom()
    return self.BtnCom
end

function XActivityBrieButton:SetOnClick(func)
    self.BtnCom.CallBack = function()
        local isOpen, str = XActivityBrieIsOpen.Get(self.activityGroupId, self.args)
        if isOpen then
            XSaveTool.SaveData(self:GetPlayerPrefsKey(), true)
            func()
        else
            if string.IsNilOrEmpty(str) then
                XLog.Error("没有返回未开放的点击提示，activityGroupId：" .. self.activityGroupId)
            else
                XUiManager.TipMsg(str)
            end
        end
    end
end

---是否第一次点击缓存的key
function XActivityBrieButton:GetPlayerPrefsKey()
    local dayRefreshTime = XTime.GetSeverTodayFreshTime()
    local nowTime = XTime.GetServerNowTimestamp()
    local severNextRefreshTime = XTime.GetSeverNextRefreshTime()
    local timeOffset = self.Offset
    if nowTime > dayRefreshTime + self.Offset then
        timeOffset = severNextRefreshTime + self.Offset
    else
        timeOffset = dayRefreshTime + self.Offset
    end
    return string.format("%s_%s_%s_%s", XPlayer.Id, ACTIVITYBRIEBUTTONISFIRSTTIMECLICK, timeOffset, self.activityGroupId)
end

return XActivityBrieButton