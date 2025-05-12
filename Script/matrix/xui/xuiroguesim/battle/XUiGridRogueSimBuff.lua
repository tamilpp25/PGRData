---@class XUiGridRogueSimBuff : XUiNode
---@field private _Control XRogueSimControl
local XUiGridRogueSimBuff = XClass(XUiNode, "XUiGridRogueSimBuff")

function XUiGridRogueSimBuff:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnBuff, self.OnBtnBuffClick)
end

---@param id number 自增Id
function XUiGridRogueSimBuff:Refresh(id)
    self.Id = id
    self.BuffId = self._Control.BuffSubControl:GetBuffIdById(id)
    -- 图标
    self.RImgBuff:SetRawImage(self._Control.BuffSubControl:GetBuffIcon(self.BuffId))
    -- 剩余回合数
    local remainingTurn = self._Control.BuffSubControl:GetBuffRemainingTurnById(id)
    self.PanelNum.gameObject:SetActiveEx(remainingTurn >= 0)
    self.TxtNum.text = remainingTurn >= 0 and remainingTurn or ""
end

function XUiGridRogueSimBuff:OnBtnBuffClick()
    XLuaUiManager.Open("UiRogueSimComponent", XEnumConst.RogueSim.BubbleType.Buff, self.Transform.parent)
end

return XUiGridRogueSimBuff
