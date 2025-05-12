---@class XUiTheatre3GridLuckyCharacter : XUiNode
---@field _Control XTheatre3Control
local XUiTheatre3GridLuckyCharacter = XClass(XUiNode, "XUiTheatre3GridLuckyCharacter")

function XUiTheatre3GridLuckyCharacter:OnStart()
    ---@type UnityEngine.Transform[]
    self._EnergyList = {}
    --self:AddBtnListener()
end

function XUiTheatre3GridLuckyCharacter:Refresh(characterId)
    self._CharacterId = characterId
    local characterIcon = XMVCA.XCharacter:GetCharHalfBodyImage(self._CharacterId)
    self.ImgDraw:SetRawImage(characterIcon)
    
    local cost = self._Control:GetCharacterCost(self._CharacterId)
    for i = 1, cost do
        local go = self._EnergyList[i]
        if not go then
            go = i == 1 and self.ImgEnergy or XUiHelper.Instantiate(self.ImgEnergy, self.PanelEnergy)
            self._EnergyList[i] = go
        end
        go.gameObject:SetActiveEx(true)
    end
    for i = cost + 1, #self._EnergyList do
        self._EnergyList[i].gameObject:SetActiveEx(false)
    end
end

--region Ui - BtnListener
function XUiTheatre3GridLuckyCharacter:AddBtnListener()
    self._Control:RegisterClickEvent(self, self.BtnYes1, self.OnBtnSelectClick)
end

function XUiTheatre3GridLuckyCharacter:OnBtnSelectClick()
    self._Control:RequestSelectLuckCharacter(self._CharacterId)
end
--endregion

return XUiTheatre3GridLuckyCharacter