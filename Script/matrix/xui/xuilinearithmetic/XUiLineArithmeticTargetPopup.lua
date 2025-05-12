local XUiLineArithmeticGameStarGrid = require("XUi/XUiLineArithmetic/XUiLineArithmeticGameStarGrid")

---@class XUiLineArithmeticTargetPopup : XLuaUi
---@field _Control XLineArithmeticControl
local XUiLineArithmeticTargetPopup = XLuaUiManager.Register(XLuaUi, "UiLineArithmeticTargetPopup")

function XUiLineArithmeticTargetPopup:Ctor()
    ---@type XUiLineArithmeticGameStarGrid[]
    self._StarGrids = {}
end

function XUiLineArithmeticTargetPopup:OnAwake()
    self.GridTarget.gameObject:SetActiveEx(false)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangCloseBig, self.OnClickClose)
    XUiHelper.RegisterClickEvent(self, self.BtnNext, self.OnClickNext)
    XUiHelper.RegisterClickEvent(self, self.BtnAgain, self.OnClickAgain)
end

function XUiLineArithmeticTargetPopup:OnStart()
    self:UpdateStarTarget()
end

function XUiLineArithmeticTargetPopup:UpdateStarTarget()
    self._Control:UpdateStarTarget()

    local uiData = self._Control:GetUiData()
    local stars = uiData.StarDescData

    for i = 1, #stars do
        local starDesc = stars[i]
        local uiGrid = self._StarGrids[i]
        if not uiGrid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridTarget, self.GridTarget.parent)
            uiGrid = XUiLineArithmeticGameStarGrid.New(ui, self)
            self._StarGrids[i] = uiGrid
        end
        uiGrid:Open()
        uiGrid:Update(starDesc)
    end
    for i = #stars + 1, #self._StarGrids do
        local uiGrid = self._StarGrids[i]
        uiGrid:Close()
    end
end

function XUiLineArithmeticTargetPopup:OnClickAgain()
    self._Control:StartGame()
    XEventManager.DispatchEvent(XEventId.EVENT_LINE_ARITHMETIC_UPDATE_GAME)
    self:Close()
end

function XUiLineArithmeticTargetPopup:OnClickNext()
    self._Control:ChallengeNextStage()
end

function XUiLineArithmeticTargetPopup:OnClickClose()
    self:Close()
    XLuaUiManager.Close("UiLineArithmeticGame")
end

return XUiLineArithmeticTargetPopup