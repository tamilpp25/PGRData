local XUiPanelTrialGet = XClass(nil, "XUiPanelTrialGet")

function XUiPanelTrialGet:Ctor(ui,uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    XTool.InitUiObject(self)
    self:InitScript()
end

function XUiPanelTrialGet:SetBtnCB(cb)
    self.BtnCb = cb
end

-- 处理特效和动画
function XUiPanelTrialGet:SetAnimationFx()
    self.FxUiPanelTrialGet01.gameObject:SetActive(true)
    self.timer = XScheduleManager.ScheduleOnce(function()
        self.FxUiPanelTrialGet02.gameObject:SetActive(true)
        XScheduleManager.UnSchedule(self.timer)
    end,200)
end

function XUiPanelTrialGet:InitScript()
    self:AddListener()
end


function XUiPanelTrialGet:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelTrialGet:RegisterClickEvent函数出错, 原因：点击回调函数不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelTrialGet:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelTrialGet:AddListener()
    self:RegisterClickEvent(self.BtnClick, self.OnBtnClickClick)
end
-- auto

-- 设置背景
function XUiPanelTrialGet:SetBg(iconpath)
    if not iconpath then
        return
    end

    self.UiRoot:SetUiSprite(self.ImgWafer,iconpath)
end

function XUiPanelTrialGet:SetName(name)
    self.TxtName.text = name or ""
end

function XUiPanelTrialGet:OnBtnClickClick()
    if not self.BtnCb then
        return
    end
    self.BtnCb()
end

return XUiPanelTrialGet