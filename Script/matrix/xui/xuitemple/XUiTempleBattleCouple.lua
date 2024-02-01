local XUiTempleBattle = require("XUi/XUiTemple/XUiTempleBattle")

---@class XUiTempleBattleCouple:XUiTempleBattle
local XUiTempleBattleCouple = XLuaUiManager.Register(XUiTempleBattle, "UiTempleBattleCouple")

function XUiTempleBattleCouple:OnAwake()
    XUiTempleBattle.OnAwake(self)
    self.PanelOptionRound.gameObject:SetActiveEx(false)
    self.PanelQingrenjieCharacter.gameObject:SetActiveEx(true)

    local panelBar = self.ImgBar.transform.parent
    panelBar.gameObject:SetActiveEx(false)
end

function XUiTempleBattleCouple:InitGameControl()
    ---@type XTempleCoupleGameControl
    self._GameControl = self._Control:GetCoupleGameControl()
end

-- 情人节关卡没有选项按钮
function XUiTempleBattleCouple:UpdateBlockOptions()
end

function XUiTempleBattleCouple:OnStart(stageId)
    XUiTempleBattle.OnStart(self, stageId)

    if self._GameControl:IsCanQuickPass() then
        self.BtnSettlement.gameObject:SetActiveEx(true)
        self:RegisterClickEvent(self.BtnSettlement, self.OnClickSettle)
    end
end

--function XUiTempleBattleCouple:Update()
--    if not XUiTempleBattle.Update(self) then
--        return
--    end
--end

function XUiTempleBattleCouple:OnClickSettle()
    self._GameControl:QuickPass()
end

return XUiTempleBattleCouple