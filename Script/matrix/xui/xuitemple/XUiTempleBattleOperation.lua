local XUiTempleBattleGrid = require("XUi/XUiTemple/XUiTempleBattleGrid")

---@field _Control XTempleControl
---@class XUiTempleBattleOperation:XUiNode
local XUiTempleBattleOperation = XClass(XUiNode, "XUiTempleBattleOperation")

function XUiTempleBattleOperation:Ctor()
    self._Grids = {}
end

function XUiTempleBattleOperation:OnStart(gameControl)
    ---@type XTempleGameControl
    self._GameControl = gameControl
    XUiHelper.RegisterClickEvent(self, self.BtnDelete, self.OnBtnDeleteClick)
    XUiHelper.RegisterClickEvent(self, self.BtnChange, self.OnBtnChangeClick)
    XUiHelper.RegisterClickEvent(self, self.BtnYes, self.OnBtnYesClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMove, self.OnBtnMoveClick)
    --if self._GameControl:IsCoupleChapter() then
    --    self.BtnDelete.gameObject:SetActiveEx(false)
    --end
end

---@param data XTempleUiDataOperation
function XUiTempleBattleOperation:Update(data)
    --self.PanelGrid
    --self.Grid
    ---@type UnityEngine.UI.GridLayoutGroup
    local groupLayout = self.PanelGrid
    groupLayout.constraintCount = data.ConstraintCount
    ---@type UnityEngine.RectTransform
    local rectTransform = self.Transform
    rectTransform.localPosition = data.Position
    self:_UpdateDynamicItem(self._Grids, data.Grids, self.Grid, XUiTempleBattleGrid)
    self:UpdateControlPos(data.Position)

    if data.IsRed then
        self.BtnYes:SetDisable(true)
    else
        self.BtnYes:SetDisable(false)
    end
end

function XUiTempleBattleOperation:OnBtnDeleteClick()
    self._GameControl:OnClickCancel()
end

function XUiTempleBattleOperation:OnBtnChangeClick()
    self._GameControl:OnClickRotate()
end

function XUiTempleBattleOperation:OnBtnYesClick()
    self._GameControl:OnClickConfirm()
end

function XUiTempleBattleOperation:OnBtnMoveClick()
end

function XUiTempleBattleOperation:_UpdateDynamicItem(gridArray, dataArray, uiObject, class)
    if #gridArray == 0 then
        uiObject.gameObject:SetActiveEx(false)
    end
    for i = 1, #dataArray do
        local grid = gridArray[i]
        if not grid then
            local uiObject = CS.UnityEngine.Object.Instantiate(uiObject, uiObject.transform.parent)
            grid = class.New(uiObject, self)
            gridArray[i] = grid
        end
        grid:Open()
        grid:Update(dataArray[i], i)
    end
    for i = #dataArray + 1, #gridArray do
        local grid = gridArray[i]
        grid:Close()
    end
end

function XUiTempleBattleOperation:UpdateControlPos(pos)
    if self.PanelControl then
        local isRight = pos.x >= -300
        local isUp = pos.y >= 180
        if isRight then
            self.BtnMove.transform:SetParent(self.ControlPosLeft, false)
        else
            self.BtnMove.transform:SetParent(self.ControlPosRight, false)
        end
        if isUp then
            self.PanelControl.transform:SetParent(self.ControlPosDown, false)
        else
            self.PanelControl.transform:SetParent(self.ControlPosUp, false)
        end

        -- 4个角落各对应一个位置
        if isUp then
            self.PanelScore.transform:SetParent(self.ControlPosScoreDownLeft, false)
            --if isRight then
            --else
            --    self.PanelScore.transform:SetParent(self.ControlPosScoreDownRight, false)
            --end
        else
            self.PanelScore.transform:SetParent(self.ControlPosScoreUpLeft, false)
            --if isRight then
            --else
            --    self.PanelScore.transform:SetParent(self.ControlPosScoreUpRight, false)
            --end
        end
    end
end

return XUiTempleBattleOperation
