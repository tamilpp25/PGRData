---@class XPanelTheatre3Energy : XUiNode
---@field _Control XTheatre3Control
local XPanelTheatre3Energy = XClass(XUiNode, "XPanelTheatre3Energy")

function XPanelTheatre3Energy:OnStart()
    if not self.Red then
        self.Red = XUiHelper.TryGetComponent(self.Transform, "Red")
    end
    self._CacheEnergy = self._Control:GetCurEnergy()
    self:InitEnergyList()
    self.Energy1.gameObject:SetActiveEx(false)
end

function XPanelTheatre3Energy:OnEnable()
end

function XPanelTheatre3Energy:OnDisable()
    self._Control:SetAddEnergyLimitRedPoint(false)
    self._CacheEnergy = self._Control:GetCurEnergy()
end

function XPanelTheatre3Energy:InitEnergyList()
    ---@type XGridTheatre3Energy[]
    self._EnergyList = self._EnergyList or {}
    local _, maxEnergy = self._Control:GetCurEnergy()
    local XGridTheatre3Energy = require("XUi/XUiTheatre3/Adventure/Main/XGridTheatre3Energy")
    for i = 1, maxEnergy do
        if not self._EnergyList[i] then
            ---@type XGridTheatre3Energy
            local grid = XGridTheatre3Energy.New(XUiHelper.Instantiate(self.Energy1.gameObject, self.Energy1.transform.parent), self, i, maxEnergy)
            self._EnergyList[i] = grid
        end
    end
end

function XPanelTheatre3Energy:Refresh(isALine)
    local curEnergy, maxEnergy = self._Control:GetCurEnergy()
    local residue = maxEnergy - curEnergy
    local name
    for i = 1, maxEnergy do
        name = "Energy"..i
        if self._EnergyList[i] then
            self._EnergyList[i]:Open()
            self._EnergyList[i]:RefreshShow(residue, self._CacheEnergy)
        end
    end
    for i = maxEnergy + 1, XEnumConst.THEATRE3.MaxEnergyCount do
        name = "Energy"..i
        if self._EnergyList[i] then
            self._EnergyList[i]:Close()
        end
    end
    if isALine then
        self.TxtEnergyNum.text = XUiHelper.GetText("Theatre3EnergyNum", residue, maxEnergy)
    else
        self.TxtEnergyNum.text = XUiHelper.GetText("Theatre3EnergyQuantumNum", residue, maxEnergy)
    end
    if self.TxtTips then
        if XTool.IsNumberValid(residue) then
            self.TxtTips.text = XUiHelper.GetText("Theatre3EnergyUnused", self._Control:GetEnergyUnusedDesc(residue))
        else
            self.TxtTips.text = ""
        end
    end
    if self.Red then
        self.Red.gameObject:SetActiveEx(self._Control:GetAddEnergyLimitRedPoint())
    end
end

---显示可恢复的能量点
function XPanelTheatre3Energy:ShowCanAddEnergy(value)
    local curEnergy, maxEnergy = self._Control:GetCurEnergy()
    local residue = maxEnergy - curEnergy
    local willBeEnergy = residue + value > maxEnergy and maxEnergy or residue + value
    local name
    for i = 1, maxEnergy do
        name = "Energy"..i
        if self._EnergyList[i] then
            self._EnergyList[i]:Open()
            self._EnergyList[i]:RefreshShow(residue, self._CacheEnergy)
            self._EnergyList[i]:PlayEnergyShiny(i > residue and i <= willBeEnergy)
        end
    end
end

return XPanelTheatre3Energy