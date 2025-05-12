---@class XUiTheatre3QuantumLevelUp : XLuaUi
---@field _Control XTheatre3Control
---@field BtnQuantumLv XUiComponent.XUiButton
local XUiTheatre3QuantumLevelUp = XLuaUiManager.Register(XLuaUi, "UiTheatre3QuantumLevelUp")

function XUiTheatre3QuantumLevelUp:OnAwake()
    self:AddBtnListener()
    self:InitBtnQuantum()
end

function XUiTheatre3QuantumLevelUp:InitBtnQuantum()
    if self._Control:IsAdventureALine() then
        self.BtnQuantumLv1.gameObject:SetActiveEx(true)
        self.BtnQuantumLv2.gameObject:SetActiveEx(false)
        self.BtnQuantumLv = self.BtnQuantumLv1
    else
        self.BtnQuantumLv1.gameObject:SetActiveEx(false)
        self.BtnQuantumLv2.gameObject:SetActiveEx(true)
        self.BtnQuantumLv = self.BtnQuantumLv2
    end
    if self.Text2 == self.Text1 then
        self.Text2 = XUiHelper.TryGetComponent(self.PanelQuantumDetail2, "ImgBgRed/Text", "Text")
    end
end

---@param data XUiTheatre3PanelQuantumData
function XUiTheatre3QuantumLevelUp:OnStart(data, lvUpText, aText, bText, cb)
    self._CloseCb = cb
    if data.IsLevelUp then
        if self._Control:IsAdventureALine() then
            self.PanelQuantumDetail1.gameObject:SetActiveEx(true)
            self.PanelQuantumDetail2.gameObject:SetActiveEx(false)
            self.Text1.text = lvUpText
        else
            self.PanelQuantumDetail1.gameObject:SetActiveEx(false)
            self.PanelQuantumDetail2.gameObject:SetActiveEx(true)
            self.Text2.text = lvUpText
        end
    else
        self.PanelQuantumDetail1.gameObject:SetActiveEx(data.IsChangeA)
        self.PanelQuantumDetail2.gameObject:SetActiveEx(data.IsChangeB)
        self.Text1.text = aText
        self.Text2.text = bText
    end
    
    self.BtnQuantumLv:SetNameByGroup(0, data.AValue)
    self.BtnQuantumLv:SetNameByGroup(1, data.BValue)
    if data.QuantumLevelCfg then
        self.BtnQuantumLv:SetNameByGroup(2, data.QuantumLevelCfg.Title)
        --全屏特效
        if self.Effect and not string.IsNilOrEmpty(data.QuantumLevelCfg.ScreenEffectUrl) then
            local screenEffectUrl = self._Control:GetClientConfig(data.QuantumLevelCfg.ScreenEffectUrl, self._Control:IsAdventureALine() and 1 or 2)
            self.Effect:LoadUiEffect(screenEffectUrl)
        end
    end
    local aValue = data.AValue
    local aLvValue = 0
    for _, levelId in ipairs(data.QuantumAShowPuzzleList) do
        if levelId <= self.BtnQuantumLv.ImageList.Count then
            local value = self._Control:GetCfgQuantumLevelValue(levelId)
            self.BtnQuantumLv.ImageList[levelId-1].fillAmount = math.min(aValue / (value - aLvValue) , 1)
            aValue = math.max(data.BValue - value, 0)
            aLvValue = value
        end
    end
    local bValue = data.BValue
    local bLvValue = 0
    for _, levelId in ipairs(data.QuantumBShowPuzzleList) do
        if levelId <= self.BtnQuantumLv.ImageList.Count then
            local value = self._Control:GetCfgQuantumLevelValue(levelId)
            self.BtnQuantumLv.ImageList[levelId-1].fillAmount = math.min(bValue / (value - bLvValue) , 1)
            bValue = math.max(data.BValue - value, 0)
            bLvValue = value
        end
    end
end

--region Ui - BtnListener
function XUiTheatre3QuantumLevelUp:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
end

function XUiTheatre3QuantumLevelUp:OnBtnBackClick()
    self:Close()
    if self._CloseCb then
        self._CloseCb()
    end
end
--endregion

return XUiTheatre3QuantumLevelUp