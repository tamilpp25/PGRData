local XUiFightCerberusDialogBoxGrid = XClass(nil, "XUiFightCerberusDialogBoxGrid")
local CSXAudioManager = CS.XAudioManager

function XUiFightCerberusDialogBoxGrid:Ctor()
    self.ShowTime = 0
    self.CurPlayCvIndex = 1
    self.CvQueue = XQueue.New()
    self.CurLoadUiPrefabPath = ""
end

function XUiFightCerberusDialogBoxGrid:OnEnable()
    if self.ShowTime > 0 then
        self.GameObject:SetActiveEx(true)
        if self.AnimEnable then
            self.AnimEnable:Play()
        end
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
    self.GameObject:SetActiveEx(false)
end

function XUiFightCerberusDialogBoxGrid:Close()
    self:StopCurCv()
end

function XUiFightCerberusDialogBoxGrid:Refresh(parentRoot, id)
    self:StopTimer()
    self:StopCurCv()
    
    local uiPrefabPath = XFightCerberusDialogBoxConfigs.GetUiPrefab(id)
    local isNewUiPrefab = self.CurLoadUiPrefabPath ~= uiPrefabPath or XTool.UObjIsNil(self.GameObject)
    if isNewUiPrefab then
        XTool.InitUiObjectByUi(self, parentRoot:LoadPrefab(uiPrefabPath))
        self.CurLoadUiPrefabPath = uiPrefabPath
    end
    
    self.GameObject:SetActiveEx(true)
    if self.ShowTime <= 0 or isNewUiPrefab then
        if self.AnimDisable and self.AnimDisable.gameObject.activeInHierarchy then
            self.AnimDisable:Stop()
        end
        if self.AnimEnable and self.AnimEnable.gameObject.activeInHierarchy then
            self.AnimEnable.transform:PlayTimelineAnimation()
        end
    elseif self.QieHuan and self.QieHuan.gameObject.activeInHierarchy then
        self.GameObject:SetActiveEx(true)
        self.QieHuan.transform:PlayTimelineAnimation()
    end
    
    self.RImgRole:SetRawImage(XFightCerberusDialogBoxConfigs.GetIcon(id))
    self.TxtRoleName.text = XFightCerberusDialogBoxConfigs.GetName(id)
    self.TxtRoleWord.text = XUiHelper.ConvertLineBreakSymbol(XFightCerberusDialogBoxConfigs.GetDesc(id))

    self.ShowTime = XFightCerberusDialogBoxConfigs.GetShowTime(id)
    self:StartTimer()
    for _, cvId in ipairs(XFightCerberusDialogBoxConfigs.GetCvList(id)) do
        self.CvQueue:Enqueue(cvId)
    end
    self:PlayCv()
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
                if self.AnimEnable and self.AnimEnable.gameObject.activeInHierarchy then
                    self.AnimEnable:Stop()
                end
                if self.AnimDisable and self.AnimDisable.gameObject.activeInHierarchy then
                    self.AnimDisable.transform:PlayTimelineAnimation(function(isFinished)
                        if isFinished then
                            self.GameObject:SetActiveEx(false)
                        end
                    end)
                else
                    self.GameObject:SetActiveEx(false)
                end
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