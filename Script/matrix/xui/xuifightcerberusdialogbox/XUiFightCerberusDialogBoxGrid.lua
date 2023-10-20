local XUiFightCerberusDialogBoxGrid = XClass(nil, "XUiFightCerberusDialogBoxGrid")
local CSXAudioManager = CS.XAudioManager

function XUiFightCerberusDialogBoxGrid:Ctor()
    self.ShowTime = 0
    self.CurPlayCvIndex = 1
    self.CvQueue = XQueue.New()
end

function XUiFightCerberusDialogBoxGrid:OnEnable()
    if self.ShowTime > 0 then
        self:StartTimer(self.ShowTime)
    end
    if self.CurCvAudioInfo then
        self.CurCvAudioInfo:Resume()
    end
end

function XUiFightCerberusDialogBoxGrid:OnDisable()
    self:StopTimer()
    if self.CurCvAudioInfo then
        self.CurCvAudioInfo:Pause()
    end
end

function XUiFightCerberusDialogBoxGrid:Close()
    self:StopTimer()
    self:StopCurCv()
end

function XUiFightCerberusDialogBoxGrid:Refresh(parentRoot, id)
    local uiPrefabPath = XFightCerberusDialogBoxConfigs.GetUiPrefab(id)
    local uiPrefab = parentRoot:LoadPrefab(uiPrefabPath)
    XTool.InitUiObjectByUi(self, uiPrefab)
    
    self.RImgRole:SetRawImage(XFightCerberusDialogBoxConfigs.GetIcon(id))
    self.TxtRoleName.text = XFightCerberusDialogBoxConfigs.GetName(id)
    self.TxtRoleWord.text = XUiHelper.ConvertLineBreakSymbol(XFightCerberusDialogBoxConfigs.GetDesc(id))

    self.ShowTime = XFightCerberusDialogBoxConfigs.GetShowTime(id)
    self:StopTimer()
    self:StartTimer()

    self:StopCurCv()
    for _, cvId in ipairs(XFightCerberusDialogBoxConfigs.GetCvList(id)) do
        self.CvQueue:Enqueue(cvId)
    end
    self:PlayCv()
    self.GameObject:SetActiveEx(true)
end

function XUiFightCerberusDialogBoxGrid:PlayCv()
    local id = self.CvQueue:Dequeue()
    if not id then
        return
    end
    self.CurCvAudioInfo = CSXAudioManager.PlayCv(id, handler(self, self.PlayCv))
end

function XUiFightCerberusDialogBoxGrid:StopCurCv()
    self.CvQueue:Clear()
    if self.CurCvAudioInfo then
        self.CurCvAudioInfo:Stop()
        self.CurCvAudioInfo = nil
    end
end

function XUiFightCerberusDialogBoxGrid:StartTimer()
    if self.ShowTime <= 0 then
        return
    end
    
    self.Timer = XScheduleManager.ScheduleForever(function()
        self.ShowTime = self.ShowTime - 1
        if self.ShowTime <= 0 then
            self:StopTimer()
            self:StopCurCv()
            if not XTool.UObjIsNil(self.GameObject) then
                self.GameObject:SetActiveEx(false)
            end
        end
    end, XScheduleManager.SECOND)
end

function XUiFightCerberusDialogBoxGrid:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

return XUiFightCerberusDialogBoxGrid