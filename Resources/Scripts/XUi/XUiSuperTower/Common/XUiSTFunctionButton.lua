--===========================
--超级爬塔特权绑定按钮(只支持UiButton组件)
--===========================
local XUiSTFunctionButton = XClass(nil, "XUiSTFunctionButton")
--==================
--构造函数
--@param uibutton:对象的UiButton
--@param onClickCallBack:点击按钮时回调
--@param functionKey:绑定按钮的特权键值，不填即不绑定 XSuperTowerManager.FunctionName
--@param reddotEventId:红点事件Id Table
--==================
function XUiSTFunctionButton:Ctor(uibutton, onClickCallBack, functionKey, reddotEventId)
    self.UiButton = uibutton
    self.OnClickCb = onClickCallBack
    self.UiButton.CallBack = function() self:OnClick() end
    self.ReddotEventId = reddotEventId
    self:InitFunction(functionKey)
    self:AddEventListener()
end
--==================
--初始化特权,没有特权绑定时会跳过
--==================
function XUiSTFunctionButton:InitFunction(functionKey)
    if functionKey then
        local funcManager = XDataCenter.SuperTowerManager.GetFunctionManager()
        self.Function = funcManager:GetFunctionByKey(functionKey)
    end
    self:RefreshFunction()
end
--==================
--刷新特权按钮状态
--==================
function XUiSTFunctionButton:RefreshFunction()
    if XTool.UObjIsNil(self.UiButton) then
        self:OnDestroy()
        return
    end
    self.UiButton:SetDisable(self.Function and not self.Function:CheckIsUnlock() or false)
end
--==================
--检查绑定特权有没解锁
--==================
function XUiSTFunctionButton:CheckIsUnlock()
    if self.Function then
        return self.Function:CheckIsUnlock()
    end
    return true
end
--==================
--点击方法
--==================
function XUiSTFunctionButton:OnClick()
    if not self:CheckIsUnlock() then
        local tips = self.Function:GetUnLockDescription()
        XUiManager.TipMsg(tips)
        return
    end
    if self.OnClickCb then
        self.OnClickCb()
    end
end
--==================
--显示红点
--==================
function XUiSTFunctionButton:ShowReddot(count)
    self.UiButton:ShowReddot(count >= 0)
end
--==================
--OnEnable时(需外部调用)
--==================
function XUiSTFunctionButton:OnEnable()
    self:AddEventListener()
end
--==================
--显示时
--==================
function XUiSTFunctionButton:Show()
    self:RefreshFunction()
    self:AddEventListener()
    self.UiButton.gameObject:SetActiveEx(true)
end
--==================
--隐藏时
--==================
function XUiSTFunctionButton:Hide()
    self.UiButton.gameObject:SetActiveEx(false)
    self:RemoveEventListener()
end
--==================
--OnDisable时(需外部调用)
--==================
function XUiSTFunctionButton:OnDisable()
    self:RemoveEventListener()
end
--==================
--OnDestroy时(需外部调用)
--==================
function XUiSTFunctionButton:OnDestroy()
    self:RemoveEventListener()
end
--==================
--加入特权解锁事件监测
--==================
function XUiSTFunctionButton:AddEventListener()
    if self.EventAdded then return end
    self.EventAdded = true
    XEventManager.AddEventListener(XEventId.EVENT_ST_FUNCTION_UNLOCK, function() self:RefreshFunction() end)
    if self.ReddotEventId then
        self.RedId = XRedPointManager.AddRedPointEvent(self.UiButton, self.OnCheckBtnTaskRedPoint, self, self.ReddotEventId)
    end
end
--==================
--移除事件
--==================
function XUiSTFunctionButton:RemoveEventListener()
    if not self.EventAdded then return end
    XEventManager.RemoveEventListener(XEventId.EVENT_ST_FUNCTION_UNLOCK, function() self:RefreshFunction() end)
    self.EventAdded = false
    if self.ReddotEventId then
        XRedPointManager.RemoveRedPointEvent(self.RedId)
    end
end

return XUiSTFunctionButton