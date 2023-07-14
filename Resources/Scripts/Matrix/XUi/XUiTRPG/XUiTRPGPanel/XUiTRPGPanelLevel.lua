local XUiTRPGPanelLevel = XClass(nil, "XUiTRPGPanelLevel")

local CSXTextManagerGetText = CS.XTextManager.GetText
local stringGsub = string.gsub

function XUiTRPGPanelLevel:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self:InitUi()
    self:AutoAddListener()
    self:Refresh()

    XEventManager.AddEventListener(XEventId.EVENT_TRPG_BASE_INFO_CHANGE, self.Refresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_TRPG_OPEN_LEVEL_DIALOG, self.CheckRedPoint, self)
end

function XUiTRPGPanelLevel:Delete()
    XEventManager.RemoveEventListener(XEventId.EVENT_TRPG_BASE_INFO_CHANGE, self.Refresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TRPG_OPEN_LEVEL_DIALOG, self.CheckRedPoint, self)
end

function XUiTRPGPanelLevel:InitUi()
    self.TxtLevel = XUiHelper.TryGetComponent(self.Transform, "TxtLevel", "Text")
    self.Btn = XUiHelper.TryGetComponent(self.Transform, "Btn", "XUiButton")
    self.ImgLevel = XUiHelper.TryGetComponent(self.Transform, "PanelJindu/ImgLevel", "Image")
    self.TxtEXP = XUiHelper.TryGetComponent(self.Transform, "TxtEXP", "Text")
    self.TxtEndurance = XUiHelper.TryGetComponent(self.Transform, "TxtEndurance", "Text")
    self.BtnXq = XUiHelper.TryGetComponent(self.Transform, "BtnXq", "XUiButton")
    self.Red = XUiHelper.TryGetComponent(self.Transform, "Red")
end

function XUiTRPGPanelLevel:AutoAddListener()
    if self.Btn then
        XUiHelper.RegisterClickEvent(self, self.Btn, self.OnBtnClick)
    end
    if self.BtnXq then
        XUiHelper.RegisterClickEvent(self, self.BtnXq, self.OnClickBtnDesc)
    end
end

function XUiTRPGPanelLevel:Refresh()
    self:UpdateExploreLevel()
    self:UpdateEndurance()
    self:CheckRedPoint()
end

function XUiTRPGPanelLevel:UpdateExploreLevel()
    local level = XDataCenter.TRPGManager.GetExploreLevel()
    local curExp = XDataCenter.TRPGManager.GetExploreCurExp()
    local maxExp = XDataCenter.TRPGManager.GetExploreMaxExp()
    if self.ImgLevel and maxExp > 0 then
        self.ImgLevel.fillAmount = curExp / maxExp
    end
    if self.TxtLevel then
        self.TxtLevel.text = level
    end

    if self.TxtEXP then
        local isMaxLevel = XTRPGConfigs.IsMaxLevel(level)
        if isMaxLevel then
            self.TxtEXP.text = CSXTextManagerGetText("TRPGExploreExp", "-", "-")
        else
            self.TxtEXP.text = CSXTextManagerGetText("TRPGExploreExp", curExp, maxExp)
        end
    end
end

function XUiTRPGPanelLevel:UpdateEndurance()
    if not self.TxtEndurance then return end
    local curEndurance = XDataCenter.TRPGManager.GetExploreCurEndurance()
    local maxEndurance = XDataCenter.TRPGManager.GetExploreMaxEndurance()
    self.TxtEndurance.text = CSXTextManagerGetText("TRPGExploreEndurance", curEndurance, maxEndurance)
end

function XUiTRPGPanelLevel:OnBtnClick()
    XLuaUiManager.Open("UiTRPGDialog")
end

function XUiTRPGPanelLevel:OnClickBtnDesc()
    local title = CSXTextManagerGetText("TRPGEnduranceTitle") 
    local desc = CSXTextManagerGetText("TRPGEnduranceDesc")
    desc = stringGsub(desc, "\\n", "\n")
    XUiManager.UiFubenDialogTip(title, desc)
end

function XUiTRPGPanelLevel:CheckRedPoint()
    if self.Red then
        local isShow = XDataCenter.TRPGManager.IsShowExploreRedPointLevel()
        self.Red.gameObject:SetActiveEx(isShow)
    end
end

return XUiTRPGPanelLevel