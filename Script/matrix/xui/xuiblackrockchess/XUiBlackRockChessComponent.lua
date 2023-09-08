
---@class XUiBlackRockChessComponent : XLuaUi
---@field GridHeads table<number, XUiGridHeadHud>
---@field GridHps table<number, XUiGridHpHud>
---@field GridBuffs table<number, XUiGridBuffHud>
---@field GridDialog XUiGridDialogHud
---@field _Control XBlackRockChessControl
local XUiBlackRockChessComponent = XLuaUiManager.Register(XLuaUi, "UiBlackRockChessComponent")

local XUiGridHeadHud = require("XUi/XUiBlackRockChess/XUiGrid/XUiGridHeadHud")
local XUiGridHpHud = require("XUi/XUiBlackRockChess/XUiGrid/XUiGridHpHud")
local XUiGridDialogHud = require("XUi/XUiBlackRockChess/XUiGrid/XUiGridDialogHud")
local XUiGridBuffHud = require("XUi/XUiBlackRockChess/XUiGrid/XUiGridBuffHud")

local PieceOffset = CS.UnityEngine.Vector3(0, 1.2, 0)
local DialogOffset = CS.UnityEngine.Vector3(0, 0.5, 0.5)

function XUiBlackRockChessComponent:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiBlackRockChessComponent:OnStart()
end

function XUiBlackRockChessComponent:OnGetLuaEvents()
    return {
        XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH,
        XEventId.EVENT_BLACK_ROCK_CHESS_ROUND_CHANGE,
        XEventId.EVENT_BLACK_ROCK_CHESS_GAMER_MOVE_END,
    }
end

function XUiBlackRockChessComponent:OnNotify(evt, ...)
    if evt == XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH 
            or evt == XEventId.EVENT_BLACK_ROCK_CHESS_ROUND_CHANGE then
        self:UpdateHeadView()
    elseif evt == XEventId.EVENT_BLACK_ROCK_CHESS_GAMER_MOVE_END then
        self:OnGameMoveEnd()
    end
end

function XUiBlackRockChessComponent:OnEnable() 
    self:StartTimer() 
end

function XUiBlackRockChessComponent:OnDisable()
    self:StopTimer()
end

function XUiBlackRockChessComponent:OnDestroy()
    self:RemoveCb()

    self.GridHeads = {}
    self.GridHps = {}
end

function XUiBlackRockChessComponent:Update()
    for _, grid in pairs(self.GridHeads) do
        grid:UpdateTransform()
    end

    for _, grid in pairs(self.GridHps) do
        grid:UpdateTransform()
    end

    for _, grid in pairs(self.GridBuffs) do
        grid:UpdateTransform()
    end
    
    if self.GridDialog then
        self.GridDialog:UpdateTransform()
    end
end

function XUiBlackRockChessComponent:InitUi()
    self.GridDialogBox.gameObject:SetActiveEx(false)
    self.GridHead.gameObject:SetActiveEx(false)
    self.GridBuff.gameObject:SetActiveEx(false)
    self.GridHp.gameObject:SetActiveEx(false)
end

function XUiBlackRockChessComponent:StartTimer()
    if self.UpdateTimer then
        return
    end
    self.UpdateTimer = XScheduleManager.ScheduleForever(handler(self, self.Update), 1)
end

function XUiBlackRockChessComponent:StopTimer()
    if not self.UpdateTimer then
        return
    end
    XScheduleManager.UnSchedule(self.UpdateTimer)
    self.UpdateTimer = nil
end

function XUiBlackRockChessComponent:InitCb()
    self.GridHeads = {}
    self.GridHps = {}
    self.GridBuffs = {}
    
    self._Control:RegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.SHOW_HEAD_HUD, handler(self, self.ShowHeadHud))
    self._Control:RegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.HIDE_HEAD_HUD, handler(self, self.HideHeadHud))
    
    self._Control:RegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.SHOW_HP_HUD, handler(self, self.ShowHpHud))
    self._Control:RegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.HIDE_HP_HUD, handler(self, self.HideHpHud))
    
    self._Control:RegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.CAMERA_DISTANCE_CHANGED, handler(self, self.OnCameraDistanceChanged))
    
    self._Control:RegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.FOCUS_ENEMY, handler(self, self.OnFocusEnemy))
    self._Control:RegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.CANCEL_FOCUS_ENEMY, handler(self, self.OnCancelFocus))
    self._Control:RegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.PREVIEW_DAMAGE, handler(self, self.OnPreviewDamage))
    self._Control:RegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.SHOW_DIALOG_BUBBLE, handler(self, self.OnShowDialog))
    self._Control:RegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.SHOW_BUFF_HUD, handler(self, self.OnShowBuffHud))
    self._Control:RegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.HIDE_BUFF_HUD, handler(self, self.HideBuffHud))
end

function XUiBlackRockChessComponent:RemoveCb()
    self._Control:UnRegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.SHOW_HEAD_HUD)
    self._Control:UnRegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.HIDE_HEAD_HUD)
    self._Control:UnRegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.SHOW_HP_HUD)
    self._Control:UnRegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.HIDE_HP_HUD)
    self._Control:UnRegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.CAMERA_DISTANCE_CHANGED)
    self._Control:UnRegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.FOCUS_ENEMY)
    self._Control:UnRegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.CANCEL_FOCUS_ENEMY)
    self._Control:UnRegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.PREVIEW_DAMAGE)
    self._Control:UnRegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.SHOW_DIALOG_BUBBLE)
    self._Control:UnRegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.SHOW_BUFF_HUD)
    self._Control:UnRegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.HIDE_BUFF_HUD)
end

function XUiBlackRockChessComponent:ShowHeadHud(id, target)
    local grid = self.GridHeads[id]
    if not grid then
        local ui = XUiHelper.Instantiate(self.GridHead, self.HeadContainer)
        grid = XUiGridHeadHud.New(ui, self)
        self.GridHeads[id] = grid
    end
    grid:BindTarget(target, PieceOffset, id)
    grid:Open()
end

function XUiBlackRockChessComponent:UpdateHeadView()
    for _, grid in pairs(self.GridHeads) do
        if grid:IsValid() and grid:IsNodeShow() then
            grid:RefreshView()
        end
    end
end

function XUiBlackRockChessComponent:HideHeadHud(id)
    local grid = self.GridHeads[id]
    if not grid then
        return
    end
    grid:Close()
end

function XUiBlackRockChessComponent:ShowHpHud(id, target)
    local grid = self.GridHps[id]
    if not grid then
        local ui = XUiHelper.Instantiate(self.GridHp, self.HpContainer)
        grid = XUiGridHpHud.New(ui, self)
        self.GridHps[id] = grid
    end
    grid:BindTarget(target)
    grid:Open()
end

function XUiBlackRockChessComponent:HideHpHud(id)
    local grid = self.GridHps[id]
    if not grid then
        return
    end
    grid:Close()
end

function XUiBlackRockChessComponent:OnCameraDistanceChanged(scale)
    for _, grid in pairs(self.GridHeads) do
        grid:SetScale(scale)
    end
end

function XUiBlackRockChessComponent:OnFocusEnemy(id)
    local grid = self.GridHeads[id]
    if not grid or not grid:IsNodeShow() then
        return
    end
    self.LastFocusId = id
    grid:SetTarget(true)
end

function XUiBlackRockChessComponent:OnCancelFocus()
    if not XTool.IsNumberValid(self.LastFocusId) then
        return
    end
    local last = self.GridHeads[self.LastFocusId]
    if not last or not last:IsNodeShow() then
        return
    end
    last:SetTarget(false)
    self.LastFocusId = nil
end

function XUiBlackRockChessComponent:OnPreviewDamage(id, damage)
    local grid = self.GridHeads[id]
    if not grid or not grid:IsNodeShow() then
        return
    end
    grid:PreviewDamage(damage)
end

function XUiBlackRockChessComponent:OnShowDialog(target, text)
    if not self.GridDialog then
        self.GridDialog = XUiGridDialogHud.New(self.GridDialogBox, self)
    end
    self.GridDialog:BindTarget(target, DialogOffset, text)
    self.GridDialog:Open()
end

function XUiBlackRockChessComponent:OnShowBuffHud(id, target, skillId, count)
    local grid = self.GridBuffs[id]
    if not grid then
        local ui = XUiHelper.Instantiate(self.GridBuff, self.BuffContainer)
        grid = XUiGridBuffHud.New(ui, self)
        self.GridBuffs[id] = grid
    end
    grid:BindTarget(target, PieceOffset, skillId, count)
    grid:Close()
    grid:Open()
end

function XUiBlackRockChessComponent:HideBuffHud(id)
    local grid = self.GridBuffs[id]
    if not grid then
        return
    end
    grid:Close()
end

function XUiBlackRockChessComponent:OnGameMoveEnd()
    self:UpdateHeadView()
end