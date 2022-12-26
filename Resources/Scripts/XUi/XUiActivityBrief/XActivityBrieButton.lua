local XActivityBrieButton = XClass(nil, "XActivityBrieButton")


local ACTIVITYBRIEBUTTONISFIRSTTIMECLICK = "ActivityBrieButtonIsFirstTimeClick"

function XActivityBrieButton:Ctor(ui, uiRoot, activityGroupId)
    self.BtnCom = ui
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    self.activityGroupId = activityGroupId
    self.IsAlwaysCheck = false
    self.BtnCom:ShowTag(false)
    self.BtnCom:ShowReddot(false)
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

    self.BtnCom:SetDisable(not isOpen)
end

--可挑战Tag,第一次点击后消失
--添加特殊处理,需要一直显示Tag的则第三个参数为true
function XActivityBrieButton:AddNewTagEvent(conditionGroup, args, isAlwaysCheck)
    self.IsAlwaysCheck = isAlwaysCheck
    if self:CheckFirstClicked() or isAlwaysCheck then
        XRedPointManager.AddRedPointEvent(self.BtnCom, self.OnNewTagEvent, self, conditionGroup, args, true)
    else
        self.BtnCom:ShowTag(false)
    end
end

function XActivityBrieButton:OnNewTagEvent(count)
    self:ShowTag(count > -1)
end

function XActivityBrieButton:ShowTag(isShow)
    local isOpen = XActivityBrieIsOpen.Get(self.activityGroupId, self.args)

    if (self:CheckFirstClicked() or self.IsAlwaysCheck) and isOpen then
        self.BtnCom:ShowTag(isShow)
    else
        self.BtnCom:ShowTag(false)
    end
end

function XActivityBrieButton:CheckFirstClicked()
    return not XSaveTool.GetData(self:GetPlayerPrefsKey())
end

--红点
function XActivityBrieButton:AddRedPointEvent(conditionGroup, args)
    XRedPointManager.AddRedPointEvent(self.BtnCom, self.OnRedPointEvent, self, conditionGroup, args, true)
end

function XActivityBrieButton:OnRedPointEvent(count)
    self:ShowReddot(count >= 0)
end

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

-- 记录是否第一次点击
function XActivityBrieButton:GetPlayerPrefsKey()
    local severNextRefreshTime = XTime.GetSeverNextRefreshTime()
    return string.format("%s_%s_%s_%s", XPlayer.Id, ACTIVITYBRIEBUTTONISFIRSTTIMECLICK, severNextRefreshTime, self.activityGroupId)
end

return XActivityBrieButton