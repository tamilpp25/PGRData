local XUiGrid3DMapTheme = XClass(nil, "XUiGrid3DMapTheme")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiGrid3DMapTheme:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiGrid3DMapTheme:SetButtonCallBack()
    self.PanelNormal:GetObject("BtnClick").CallBack = function()
        self:OnBtnClick()
    end
    self.PanelSelect:GetObject("BtnClick").CallBack = function()
        self:OnBtnClick()
    end
    self.PanelDisable:GetObject("BtnClick").CallBack = function()
        self:OnBtnClick()
    end
end

function XUiGrid3DMapTheme:OnBtnClick()
    if not self.STTheme:CheckIsOpen() then
        XUiManager.TipMsg(CSTextManagerGetText("STThemeUnlock", self.STTheme:GetStartTimeStr(true)))
        return
    end
    
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_ST_MAP_THEME_SELECT, self.ThemeIndex)
end

function XUiGrid3DMapTheme:UpdateGrid(data, index, isNewTheme)
    self.STTheme = data
    self.ThemeIndex = index
    self.IsNewTheme = isNewTheme
    self:UpdateInfo()
end

function XUiGrid3DMapTheme:UpdateInfo()
    local IsNormal = self.STTheme:CheckIsOpen() and not self.IsNewTheme
    local IsSelect = self.STTheme:CheckIsOpen() and self.IsNewTheme
    local IsDisable = not self.STTheme:CheckIsOpen()
    self.PanelNormal.gameObject:SetActiveEx(IsNormal)
    self.PanelSelect.gameObject:SetActiveEx(IsSelect)
    self.PanelDisable.gameObject:SetActiveEx(IsDisable)

    if IsDisable then
        self.PanelDisable:GetObject("BtnClick"):SetName(self.STTheme:GetName())
        self.PanelDisable:GetObject("TxtOpenTime").text = CSTextManagerGetText("STThemeUnlock", self.STTheme:GetStartTimeStr())
    else
        local panel
        if IsNormal then
            panel = self.PanelNormal
        elseif IsSelect then
            panel = self.PanelSelect
        end
        if panel then
            panel:GetObject("BtnClick"):SetName(self.STTheme:GetName())
            panel:GetObject("TxtHonor").text = self.STTheme:GetStageClearStr()
            panel:GetObject("TxtLayer").text = CSTextManagerGetText("STThemeLayer", self.STTheme:GetHistoryTierStr())
            panel:GetObject("TxtLayerName").text = CSTextManagerGetText("ST3DMainThemeTierLevel")
            panel:GetObject("TxtHonorName").text = CSTextManagerGetText("ST3DMainThemeStageLevel")
        end
    end
end

return XUiGrid3DMapTheme