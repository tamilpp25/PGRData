local XUiFubenMaintaineractionTipLayer = XLuaUiManager.Register(XLuaUi, "UiFubenMaintaineractionTipLayer")

local TIP_MSG_SHOW_TIME = 5000

function XUiFubenMaintaineractionTipLayer:OnStart(hintText, msgList, type, cb)
    self.Cb = cb
    self.closeState = false
    XUiHelper.StopAnimation()
    self:PlayAnimation("PanelTip")

    self.BtnClose.CallBack = function()
        self:OnBtnCloseClick()
    end

    local pop = function()
        self:Close()
    end

    self.CloseFunc = function()
        if not XTool.UObjIsNil(self.GameObject) then
            self:PlayAnimation("PanelTipEnd", pop)
        end
    end

    self.Timer = XScheduleManager.ScheduleOnce(function()
            if not self.closeState then
                self.closeState = true
                self.CloseFunc()
            end
        end, TIP_MSG_SHOW_TIME)
    
    local msg1 = msgList and msgList[1]
    local msg2 = msgList and msgList[2]
    local msg3 = msgList and msgList[3]
    
    self.TxtDesc1.text = msg1 or ""
    self.TxtDesc2.text = msg2 or ""
    self.TxtDesc3.text = msg3 or ""
    
    self.TxtDesc1.gameObject:SetActiveEx(msg1)
    self.TxtDesc2.gameObject:SetActiveEx(msg2)
    self.TxtDesc3.gameObject:SetActiveEx(msg3)
    
    self.TxtInfoFight.text = hintText or ""
    self.TxtInfoMentor.text = hintText or ""
    self.TxtInfoTask.text = hintText or ""
    
    self.PaneFightinglTip.gameObject:SetActiveEx(type == XMaintainerActionConfigs.TipType.FightComplete)
    self.PaneTaskTip.gameObject:SetActiveEx(type == XMaintainerActionConfigs.TipType.EventComplete)
    self.PaneMentorTip.gameObject:SetActiveEx(type == XMaintainerActionConfigs.TipType.MentorComplete)
end

function XUiFubenMaintaineractionTipLayer:OnBtnCloseClick()

    if self.closeState then
        return
    end

    self.closeState = true
    XScheduleManager.UnSchedule(self.Timer)
    self.BtnClose.interactable = false
    if self.CloseFunc then
        self:CloseFunc()
    else
        --CS.XUiManager.TipsManager:Pop()
        self:Close()
    end
end

function XUiFubenMaintaineractionTipLayer:OnDestroy()
    if self.Cb then
        self.Cb()
    end
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end