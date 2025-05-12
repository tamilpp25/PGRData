---@class XUiTheatre3PanelQuantumData
---@field IsChangeA boolean
---@field IsChangeB boolean
---@field IsLevelUp boolean
---@field AValue number
---@field BValue number
---@field QuantumLevelCfg XTableTheatre3QubitLevel
---@field QuantumEffectDescList string[]
---@field QuantumAShowPuzzleList number[]
---@field QuantumBShowPuzzleList number[]

---@class XUiTheatre3PanelQuantum : XUiNode
---@field _Control XTheatre3Control
local XUiTheatre3PanelQuantum = XClass(XUiNode, "XUiTheatre3PanelQuantum")

function XUiTheatre3PanelQuantum:OnStart()
    ---@type UnityEngine.UI.Text[]
    self._TxtList = {
        self.TxtStory1,
        self.TxtStory2,
        self.TxtStory3,
        self.TxtStory4,
        self.TxtStory5,
        self.TxtStory6,
        self.TxtStory7,
        self.TxtStory8,
        self.TxtStory9 or XUiHelper.Instantiate(self.TxtStory1.transform, self.Transform),
        self.TxtStory10 or XUiHelper.Instantiate(self.TxtStory1.transform, self.Transform),
    }
    ---@type UnityEngine.Transform[]
    self._TxtAnimList = {}
    for i, text in ipairs(self._TxtList) do
        self._TxtAnimList[i] = XUiHelper.TryGetComponent(text.transform, "Animation")
    end
    ---@type UnityEngine.Transform
    self.TitleAnim = XUiHelper.TryGetComponent(self.TxtTitle.transform, "Animation")
    self:AddBtnListener()
end

function XUiTheatre3PanelQuantum:OnEnable()
    if not self.Data then
        return
    end
    if self.TxtTitle and self.Data.QuantumLevelCfg then
        self.TxtTitle.text = self.Data.QuantumLevelCfg.FightDesc
    end
    if self.TitleAnim then
        self.TitleAnim.gameObject:SetActiveEx(self.Data.QuantumLevelCfg and XTool.IsNumberValid(self.Data.QuantumLevelCfg.IsShake))
    end
    for i, id in pairs(self.Data.QuantumEffectDescList) do
        self._TxtList[i].text = self._Control:GetCfgQuantumEffectDescById(id)
        self._TxtList[i].gameObject:SetActiveEx(true)
        self._TxtAnimList[i].gameObject:SetActiveEx(self._Control:GetCfgQuantumEffectIsShakeById(id))
    end
    for i = #self.Data.QuantumEffectDescList + 1, #self._TxtList do
        self._TxtList[i].gameObject:SetActiveEx(false)
        self._TxtAnimList[i].gameObject:SetActiveEx(false)
    end
end

function XUiTheatre3PanelQuantum:OnDisable()
end

---@param data XUiTheatre3PanelQuantumData
function XUiTheatre3PanelQuantum:UpdateData(data)
    self.Data = data
end

--region Ui - BtnListener
function XUiTheatre3PanelQuantum:AddBtnListener()
    
end
--endregion

return XUiTheatre3PanelQuantum