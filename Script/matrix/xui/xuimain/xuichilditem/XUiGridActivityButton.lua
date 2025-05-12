---@class XUiGridActivityButton: XUiNode
local XUiGridActivityButton = XClass(XUiNode, "XUiGridActivityButton")

function XUiGridActivityButton:Ctor(ui, parent, config)
    self.Config = config
    self.GameObject.name = string.format("GridBtnActivity%d", config.Id)
    -- 名字/icon
    self.Btn:SetNameByGroup(0, self.Config.Name)
    self.Btn:SetNameByGroup(1, self.Config.NameEN)
    self.Btn:SetRawImage(self.Config.BtnIcon)
    -- 红点注册
    self._IsDailyRedPoint = false
    self._DailyRedPointKey = nil
    local reds = self.Config.RedPointConditions
    if not XTool.IsTableEmpty(reds) then
        local realReds = {}
        for k, v in pairs(reds) do
            local redPointKey = XRedPointConditions.Types[v]
            table.insert(realReds, redPointKey)
            if XMVCA.XDailyReset:IsDailyResetRedPoint(redPointKey) then
                self._IsDailyRedPoint = true
                self._DailyRedPointKey = string.format("%s_ActivityBtn_%s", XPlayer.Id, self.Config.Id)
            end
        end
        self.RedId = self:AddRedPointEvent(self.Btn.ReddotObj, self.CheckRed, self, realReds, self._DailyRedPointKey)
    end

    -- 特效
    if self.Config.Effect1 then
        self.EffectGo1 = self.Effect1:LoadPrefab(self.Config.Effect1)
    end
    if self.Config.Effect2 then
        self.EffectGo2 = self.Effect2:LoadPrefab(self.Config.Effect2)
    end

    XUiHelper.RegisterClickEvent(self, self.Btn, self.OnBtnClick)
end

function XUiGridActivityButton:OnBtnClick()
    local skipId = self.Config.SkipId
    if not skipId or skipId == 0 then
        return
    end
    local activityId = self.Config.Id or 0
    if activityId > 0 and not XMVCA.XSubPackage:CheckSubpackage(XEnumConst.SUBPACKAGE.ENTRY_TYPE.MAIN_LEFT_TOP_ACTIVITY, activityId) then
        return
    end

    XUiHelper.RecordBuriedSpotTypeLevelOne(1000 + self.Config.Id)
    XFunctionManager.SkipInterface(skipId)
    if self._IsDailyRedPoint then
        XMVCA.XDailyReset:SaveDailyRedPoint(self._DailyRedPointKey)
        if self.RedId then
            XRedPointManager.Check(self.RedId)
        end
    end
end

function XUiGridActivityButton:OnEnable()
    if self.RedId then
        XRedPointManager.Check(self.RedId)
    end
end

function XUiGridActivityButton:CheckRed(count)
    self.Btn:ShowReddot(count >= 0)
end

function XUiGridActivityButton:InitEvent(fun)
    -- 红点事件
    if not string.IsNilOrEmpty(self.Config.RedPointRefreshEventId) then
        XEventManager.AddEventListener(self.Config.RedPointRefreshEventId, self.RefreshReddotShow, self)
    end
    
    if not fun then
        return
    end
    self.EventFun = function()
        fun()
    end

    local eventId = self.Config.EventId
    if not eventId then
        return
    end

    XEventManager.AddEventListener(eventId, self.EventFun, self)
end

-- 两种方式激活：
-- 1.Ui初始化时检查check
-- 2.监听事件检查check
function XUiGridActivityButton:CheckShow()
    local isShow = XMVCA.XUiMain:CheckActivityBtnShow(self.Config)
    if isShow then
        self:Open()
    else
        self:Close()
    end

    return isShow
end

function XUiGridActivityButton:RefreshReddotShow()
    if self:IsNodeShow() then
        if XTool.IsNumberValid(self.RedId) then
            XRedPointManager.Check(self.RedId)
        end
    end
end

function XUiGridActivityButton:RefreshByTimeUpdate()
    if not self.Config then
        return
    end

    -- 刷新倒计时
    -- 如果有leftTime字段 优先用leftTime，否则不显示
    local text = ""
    if self.Config.LeftTimeFun then
        text = XMVCA.XLeftTime:GetLeftTimeByFunName(self.Config.LeftTimeFun, self.Config.TimeId)
    end

    self.Btn:SetNameByGroup(2, text)
end

function XUiGridActivityButton:OnRelease()
    if not string.IsNilOrEmpty(self.Config.RedPointRefreshEventId) then
        XEventManager.RemoveEventListener(self.Config.RedPointRefreshEventId, self.RefreshReddotShow, self)
    end
    
    local eventId = self.Config.EventId
    if not eventId or not self.EventFun then
        return
    end
    XEventManager.RemoveEventListener(eventId, self.EventFun, self)
end

return XUiGridActivityButton