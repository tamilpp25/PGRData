local XUiColorTableCaptainDrama = XLuaUiManager.Register(XLuaUi,"UiColorTableCaptainDrama")

function XUiColorTableCaptainDrama:OnAwake()
    self:_InitObj()
    self:_AddBtnListener()
end

function XUiColorTableCaptainDrama:OnStart(dramaId, callBack)
    self.DramaId = dramaId
    self.CallBack = callBack
    self:_Refresh()
end

function XUiColorTableCaptainDrama:OnEnable()
    self:_StartTimer()
end

function XUiColorTableCaptainDrama:OnDisable()
    self:_StopTimer()
end


-- private
----------------------------------------------------------------

function XUiColorTableCaptainDrama:_StartTimer()
    self.Timer = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.GameObject) then
            self:_StopTimer()
        end
        self:_UpdateTime()
    end, 1000)
end

function XUiColorTableCaptainDrama:_StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiColorTableCaptainDrama:_UpdateTime()
    self.TxtTime.text = CS.System.DateTime.Now:ToLongTimeString()
end

function XUiColorTableCaptainDrama:_InitObj()
    self.ImgBg = self.BtnPanelMaskGuide.gameObject:GetComponent("Image")
    self.BtnPass.gameObject:SetActiveEx(false)
    self.PanelBtn.gameObject:SetActiveEx(false)
end

function XUiColorTableCaptainDrama:_Refresh()
    self.ImgBg.color = CS.UnityEngine.Color(0, 0, 0, 0)
    self.TxtName.text = XColorTableConfigs.GetDramaName(self.DramaId)
    self.ImgRole:SetSprite(XColorTableConfigs.GetDramaIcon(self.DramaId))
    self.TxtDesc.text = XColorTableConfigs.GetDramaDesc(self.DramaId)
    self:_UpdateTime()
end

function XUiColorTableCaptainDrama:_AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnPanelMaskGuide, self._OnBtnPanelMaskGuideClick)
end

function XUiColorTableCaptainDrama:_OnBtnPanelMaskGuideClick()
    self:Close()
    if self.CallBack then
        self.CallBack()
    end
end

----------------------------------------------------------------