local XUiColorTableStageMainInfo = XLuaUiManager.Register(XLuaUi,"UiColorTableStageMainInfo")

function XUiColorTableStageMainInfo:OnAwake()
    self:_AddBtnListener()
    self:_Init()
end

function XUiColorTableStageMainInfo:OnStart(type, captainId, eventId, cb)
    self:Refresh(type, captainId, eventId, cb)
    XDataCenter.ColorTableManager.GetGameManager():SetCurMainInfoTipType(type)
end

-- public
----------------------------------------------------------------

function XUiColorTableStageMainInfo:Refresh(type, captainId, eventId, cb)
    self.CloseCallBack = cb
    self:_SetPanelActive(type)
    if type == XColorTableConfigs.TipsType.CaptainInfoTip then
        self:_RefreshCaptainInfoTip(captainId)
    elseif type == XColorTableConfigs.TipsType.EventTip then
        self:_RefreshEventTip(eventId)
    end
    self.GameObject:SetActiveEx(true)
end

----------------------------------------------------------------



-- private
----------------------------------------------------------------

function XUiColorTableStageMainInfo:_Init()
    self.TipPanels = {
        [XColorTableConfigs.TipsType.CaptainInfoTip] = self.PanelCaptainInfo,
        [XColorTableConfigs.TipsType.StudyDataTip] = self.PanelStudyData,
        [XColorTableConfigs.TipsType.RoundTip] = self.PanelRound,
        [XColorTableConfigs.TipsType.EsayActionModeTip] = self.PanelAuto,
        [XColorTableConfigs.TipsType.EventTip] = self.PanelEvent,
    }

    self.PanelEventNew = self.Transform:Find("SafeAreaContentPane/PanelCardBg/PanelEvent/PanelTitle/PanelNew")
    self.RImgMovie = self.Transform:Find("SafeAreaContentPane/PanelCardBg/PanelEvent/RImgMovie"):GetComponent("RawImage")
    self.TxtActionPoint.text = XUiHelper.GetText("ColorTableTipActionPoint")
    self.TxtStudyData.text = XUiHelper.ReadTextWithNewLine("ColorTableTipStudyData")
    self.TxtAuto1.text = XUiHelper.GetText("ColorTableTipEsayModeTitle")
    self.TxtAuto2.text = XUiHelper.GetText("ColorTableTipEsayMode")
end

function XUiColorTableStageMainInfo:_SetPanelActive(type)
    for tipType, panel in pairs(self.TipPanels) do
        panel.gameObject:SetActiveEx(tipType == type)
    end
end

-- 刷新队长提示
function XUiColorTableStageMainInfo:_RefreshCaptainInfoTip(captainId)
    self.RImgBuffIcon:SetRawImage(XColorTableConfigs.GetCaptainSkillIcon(captainId))
    self.TxtBuffName.text = XColorTableConfigs.GetCaptainSkillName(captainId)
    self.TxtBuffDetails.text = XColorTableConfigs.GetCaptainSkillDesc(captainId)
end

-- 刷新遭遇事件提示
function XUiColorTableStageMainInfo:_RefreshEventTip(eventId)
    self.RImgEventIcon:SetRawImage(XColorTableConfigs.GetEventSmallIcon(eventId))
    self.RImgMovie:SetRawImage(XColorTableConfigs.GetEventIcon(eventId))
    self.TxtEventTitle.text = XColorTableConfigs.GetEventName(eventId)
    self.TxtEventInfo.text = XColorTableConfigs.GetEventDesc(eventId)

    local handBookId
    local handBookConfigs = XColorTableConfigs.GetColorTableHandbook()
    for id, config in ipairs(handBookConfigs) do
        if config.EventId == eventId then
            handBookId = id
        end
    end

    local isNew = XTool.IsNumberValid(handBookId) and not XDataCenter.ColorTableManager.IsHandbookUnlock(handBookId)
    self.PanelEventNew.gameObject:SetActiveEx(isNew)
end

function XUiColorTableStageMainInfo:_AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self._OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnEnter, self._OnBtnCloseClick)
end

function XUiColorTableStageMainInfo:_OnBtnCloseClick()
    self:Close()
    if self.CloseCallBack then
        self.CloseCallBack()
    end
end

function XUiColorTableStageMainInfo:_OnBtnReRollClick()
    
end

----------------------------------------------------------------