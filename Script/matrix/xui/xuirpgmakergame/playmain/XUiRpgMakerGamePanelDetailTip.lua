local XUiRpgMakerGamePanelDetailTip = XClass(nil, "XUiRpgMakerGamePanelDetailTip")

local CSXTextManagerGetText = CS.XTextManager.GetText
local CloseTotalTime = CS.XGame.ClientConfig:GetInt("RpgMakerGamePlayMainShowObjectTipsStayTime")
local Second = XScheduleManager.SECOND

function XUiRpgMakerGamePanelDetailTip:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.IsPlayingAnima = false
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Hide)
end

function XUiRpgMakerGamePanelDetailTip:Show(modelKey, modelName)
    self:RefreshTxt(modelKey, modelName)
    if self.Timer and not self.IsPlayingAnima then
        self.IsPlayingAnima = true
        self:SetActive(true)
        self.RootUi:PlayAnimation("PanelDetailTipEnable")
    end
end

function XUiRpgMakerGamePanelDetailTip:RefreshTxt(modelKey, modelName)
    local name
    local desc
    local icon
    if not string.IsNilOrEmpty(modelKey) then
        name = XRpgMakerGameConfigs.GetRpgMakerGameModelName(modelKey)
        desc = XRpgMakerGameConfigs.GetRpgMakerGameModelDesc(modelKey)
        icon = XRpgMakerGameConfigs.GetRpgMakerGameModelIcon(modelKey)
    elseif not string.IsNilOrEmpty(modelName) then
        name = XRpgMakerGameConfigs.GetRpgMakerGameName(modelName)
        desc = XRpgMakerGameConfigs.GetRpgMakerGameDesc(modelName)
        icon = XRpgMakerGameConfigs.GetRpgMakerGameIcon(modelName)
    end

    if string.IsNilOrEmpty(name) or string.IsNilOrEmpty(desc) then
        return
    end
    
    self:StopTimer()

    local secondTime = CloseTotalTime
    
    self.TxtJd.text = CSXTextManagerGetText("RpgMakerGameTipClose", XUiHelper.GetTimeDesc(secondTime))
    self.ImgJd.fillAmount = 1
    self.TxtName.text = name or ""
    self.TxtDetail.text = desc or ""

    if icon then
        self.RootUi:SetUiSprite(self.ImgIcon, icon)
        self.ImgIcon.gameObject:SetActiveEx(true)
    else
        self.ImgIcon.gameObject:SetActiveEx(false)
    end

    local timeLeft
    self.Timer = XUiHelper.Tween(CloseTotalTime, function(f)
        if XTool.UObjIsNil(self.GameObject) then
            return
        end

        timeLeft = 1 - f
        self.TxtJd.text = timeLeft > 0 and CSXTextManagerGetText("RpgMakerGameTipClose", XUiHelper.GetTimeDesc(math.ceil(timeLeft * CloseTotalTime))) or ""
        self.ImgJd.fillAmount = CloseTotalTime * timeLeft / CloseTotalTime
    end, function ()
        self:Hide()
    end)
end

function XUiRpgMakerGamePanelDetailTip:Hide()
    self:StopTimer()
    self.RootUi:PlayAnimation("PanelDetailTipDisable", function()
        self:SetActive(false)
    end)
    self.IsPlayingAnima = false
end

function XUiRpgMakerGamePanelDetailTip:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiRpgMakerGamePanelDetailTip:SetActive(isActive)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    self.GameObject.gameObject:SetActiveEx(isActive)
end

return XUiRpgMakerGamePanelDetailTip