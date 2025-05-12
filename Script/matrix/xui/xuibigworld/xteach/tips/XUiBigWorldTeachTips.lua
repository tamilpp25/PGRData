---@class XUiBigWorldTeachTips : XBigWorldUi
---@field BtnTeach XUiComponent.XUiButton
---@field BtnClose XUiComponent.XUiButton
---@field ImgNomalFillBar UnityEngine.RectTransform
---@field ImgPressFillBar UnityEngine.RectTransform
---@field _Control XBigWorldTeachControl
local XUiBigWorldTeachTips = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldTeachTips")

function XUiBigWorldTeachTips:OnAwake()
    self._TeachId = 0
    self._Timer = false
    self._ShowTime = 0
    self._BeginTime = 0

    self:_RegisterButtonClicks()
end

function XUiBigWorldTeachTips:OnStart(teachId)
    self._TeachId = teachId
end

function XUiBigWorldTeachTips:OnEnable()
    self:_Refresh()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldTeachTips:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiBigWorldTeachTips:OnDestroy()
end

function XUiBigWorldTeachTips:OnGetEvents()
    return {
        CS.XEventId.EVENT_UI_AWAKE,
        CS.XEventId.EVENT_UI_DESTROY,
    }
end

function XUiBigWorldTeachTips:OnNotify(event, ui)
    if event == CS.XEventId.EVENT_UI_AWAKE then
        local uiName = self:_GetUiNameByUiData(ui)
        
        if uiName then
            if XMVCA.XBigWorldUI:IsPauseFight(uiName) then
                self:_RemoveSchedules()
            end
        end
    elseif event == CS.XEventId.EVENT_UI_DESTROY then
        local uiName = self:_GetUiNameByUiData(ui)
        
        if uiName then
            if XMVCA.XBigWorldUI:IsPauseFight(uiName) then
                self:_Refresh()
            end
        end
    end
end

-- region 按钮事件

function XUiBigWorldTeachTips:OnBtnTeachClick()
    self._Control:ReadTeach(self._TeachId, function()
        XMVCA.XBigWorldUI:Close(self.Name, function()
            XMVCA.XBigWorldUI:Open("UiBigWorldPopupTeach", self._TeachId)
        end)
    end)
end

function XUiBigWorldTeachTips:OnBtnCloseClick()
    self:Close()
end

-- endregion

-- region 私有方法

function XUiBigWorldTeachTips:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.BtnTeach.CallBack = Handler(self, self.OnBtnTeachClick)
    self.BtnClose.CallBack = Handler(self, self.OnBtnCloseClick)
end

function XUiBigWorldTeachTips:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldTeachTips:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldTeachTips:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldTeachTips:_RemoveSchedules()
    -- 在此处移除定时器
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XUiBigWorldTeachTips:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldTeachTips:_Refresh()
    self._ShowTime = self._Control:GetTeachTipShowTime()
    self._BeginTime = CS.UnityEngine.Time.time
    self.BtnTeach:SetNameByGroup(0, self._Control:GetTeachTitleByTeachId(self._TeachId))
    self.ImgNomalFillBar.fillAmount = 1
    self.ImgPressFillBar.fillAmount = 1

    self._Timer = XScheduleManager.ScheduleForever(Handler(self, self._Update), 1)
end

function XUiBigWorldTeachTips:_Update()
    local offsetTime = (CS.UnityEngine.Time.time - self._BeginTime)
    
    self.ImgNomalFillBar.fillAmount = 1 - offsetTime / self._ShowTime
    self.ImgPressFillBar.fillAmount = 1 - offsetTime / self._ShowTime

    if offsetTime > self._ShowTime then
        self:_RemoveSchedules()
        self:Close()
    end
end

function XUiBigWorldTeachTips:_GetUiNameByUiData(ui)
    if ui then
        local uiData = ui.UiData

        if uiData then
            return uiData.UiName
        end
    end

    return nil
end

-- endregion

return XUiBigWorldTeachTips
