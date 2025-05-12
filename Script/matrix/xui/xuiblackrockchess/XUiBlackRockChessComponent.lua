
---@class XUiBlackRockChessComponent : XLuaUi
---@field GridHeads table<number, table<number, XUiGridHeadHud>>
---@field GridHps table<number, XUiGridHpHud>
---@field GridBuffs table<number, XUiGridBuffHud>
---@field GridLvs table<number, XUiGridLvHud>
---@field GridErrors table<number, XUiGridErrorHud>
---@field GridDialog XUiGridDialogHud
---@field _Control XBlackRockChessControl
local XUiBlackRockChessComponent = XLuaUiManager.Register(XLuaUi, "UiBlackRockChessComponent")

local XUiGridHud = require("XUi/XUiBlackRockChess/XUiGrid/XUiGridHud")

local XUiGridHeadHud = require("XUi/XUiBlackRockChess/XUiGrid/XUiGridHeadHud")
--local XUiGridHpHud = require("XUi/XUiBlackRockChess/XUiGrid/XUiGridHpHud")
local XUiGridDialogHud = require("XUi/XUiBlackRockChess/XUiGrid/XUiGridDialogHud")
local XUiGridBuffHud = require("XUi/XUiBlackRockChess/XUiGrid/XUiGridBuffHud")

local StarOffset = CS.UnityEngine.Vector3(-0.5, 0, 0)
local PieceOffset = CS.UnityEngine.Vector3(0, 1.2, 0)
local DialogOffset = CS.UnityEngine.Vector3(0, 1.2, 0)
local SelectOffset = CS.UnityEngine.Vector3(0, 1.5, 0)
local Pivot = CS.UnityEngine.Vector2(0.5, 0.5)

local PartnerHead = 1
local EnemyHead = 2
local BossHead = 3

local ShowingBuff = {}
local ShowingBuffCount = 0

function XUiBlackRockChessComponent:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiBlackRockChessComponent:OnStart()
    self._TxtPreparePosition = CS.XBlackRockChess.XBlackRockChessUtil.Convert2WorldPoint(4, 0)

    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH, self.UpdateHeadView, self)
end

function XUiBlackRockChessComponent:OnGetLuaEvents()
    return {
        XEventId.EVENT_BLACK_ROCK_CHESS_ROUND_CHANGE,
        XEventId.EVENT_BLACK_ROCK_CHESS_GAMER_MOVE_END,
    }
end

function XUiBlackRockChessComponent:OnNotify(evt, ...)
    if evt == XEventId.EVENT_BLACK_ROCK_CHESS_ROUND_CHANGE then
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
    self.GridLvs = {}
    self.GridErrors = {}
    ShowingBuff = {}
    ShowingBuffCount = 0

    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH, self.UpdateHeadView, self)
end

function XUiBlackRockChessComponent:Update()
    for _, grids in pairs(self.GridHeads) do
        for _, grid in pairs(grids) do
            grid:UpdateTransform()
        end
    end

    for _, grid in pairs(self.GridHps) do
        grid:UpdateTransform()
    end

    for _, grid in pairs(self.GridBuffs) do
        grid:UpdateTransform()
    end

    for _, grid in pairs(self.GridLvs) do
        grid:UpdateTransform()
    end

    for _, grid in pairs(self.GridErrors) do
        grid:UpdateTransform()
    end
    
    if self.GridDialog then
        self.GridDialog:UpdateTransform()
    end

    if self.GridSelectActor then
        self.GridSelectActor:UpdateTransform()
    end

    if self.TxtPrepare then
        if self._Control:GetChessPartner():IsPassPreparationStage() then
            self.TxtPrepare.gameObject:SetActiveEx(false)
        else
            self.TxtPrepare.gameObject:SetActiveEx(true)
            self._Control:SetViewPosToLocalPosition(self.TxtPrepare.transform, self._TxtPreparePosition, CS.UnityEngine.Vector3.zero, Pivot)
        end
    end
end

function XUiBlackRockChessComponent:InitUi()
    self.GridDialogBox.gameObject:SetActiveEx(false)
    self.GridHead.gameObject:SetActiveEx(false)
    self.GridBuff.gameObject:SetActiveEx(false)
    self.GridHp.gameObject:SetActiveEx(false)
    self.PanelStar.gameObject:SetActiveEx(false)
    self.GridError.gameObject:SetActiveEx(false)
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
    self.GridHeads[PartnerHead] = {}
    self.GridHeads[EnemyHead] = {}
    self.GridHeads[BossHead] = {}
    
    self.GridHps = {}
    self.GridBuffs = {}
    self.GridLvs = {}
    self.GridErrors = {}

    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_PARTNER_HEAD_HUD, self.ShowPartnerHeadHud, self)
    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_ENEMY_HEAD_HUD, self.ShowEnemyHeadHud, self)
    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_BOSS_HEAD_HUD, self.ShowBossHeadHud, self)
    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_HIDE_PARTNER_HEAD_HUD, self.HidePartnerHeadHud, self)
    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_HIDE_ENEMY_HEAD_HUD, self.HideEnemyHeadHud, self)
    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_HIDE_BOSS_HEAD_HUD, self.HideBossHeadHud, self)
    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_HP_HUD, self.ShowHpHud, self)
    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_HIDE_HP_HUD, self.HideHpHud, self)
    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_CAMERA_DISTANCE_CHANGED, self.OnCameraDistanceChanged, self)
    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_FOCUS_ENEMY, self.OnFocusEnemy, self)
    --self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_CANCEL_FOCUS_ENEMY, self.OnCancelFocus, self)
    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_PREVIEW_DAMAGE, self.OnPreviewDamage, self)
    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_DIALOG_BUBBLE, self.OnShowDialog, self)
    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_BUFF_HUD, self.OnShowBuffHud, self)
    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_HIDE_BUFF_HUD, self.HideBuffHud, self)
    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_FOCUS_SELECT_ACTOR, self.FocusSelectActor, self)
    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_UPDATE_PREPARE_PARTNER, self.UpdatePrepare, self)
end

function XUiBlackRockChessComponent:RemoveCb()
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_PARTNER_HEAD_HUD, self.ShowPartnerHeadHud, self)
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_ENEMY_HEAD_HUD, self.ShowEnemyHeadHud, self)
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_BOSS_HEAD_HUD, self.ShowBossHeadHud, self)
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_HIDE_PARTNER_HEAD_HUD, self.HidePartnerHeadHud, self)
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_HIDE_ENEMY_HEAD_HUD, self.HideEnemyHeadHud, self)
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_HIDE_BOSS_HEAD_HUD, self.HideBossHeadHud, self)
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_HP_HUD, self.ShowHpHud, self)
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_HIDE_HP_HUD, self.HideHpHud, self)
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_CAMERA_DISTANCE_CHANGED, self.OnCameraDistanceChanged, self)
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_FOCUS_ENEMY, self.OnFocusEnemy, self)
    --self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_CANCEL_FOCUS_ENEMY, self.OnCancelFocus, self)
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_PREVIEW_DAMAGE, self.OnPreviewDamage, self)
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_DIALOG_BUBBLE, self.OnShowDialog, self)
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_BUFF_HUD, self.OnShowBuffHud, self)
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_HIDE_BUFF_HUD, self.HideBuffHud, self)
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_FOCUS_SELECT_ACTOR, self.FocusSelectActor, self)
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_UPDATE_PREPARE_PARTNER, self.UpdatePrepare, self)
end

function XUiBlackRockChessComponent:ShowHeadHud(id, target, bossId, pieceType)
    local key = id or bossId
    local grid = self.GridHeads[pieceType][key]
    if not grid then
        local ui = XUiHelper.Instantiate(self.GridHead, self.HeadContainer)
        grid = XUiGridHeadHud.New(ui, self)
        self.GridHeads[pieceType][key] = grid
    end
    grid:Open()
    grid:BindTarget(target, PieceOffset, id, bossId, pieceType)
    grid:RefreshView()
end

function XUiBlackRockChessComponent:ShowPartnerHeadHud(id, target)
    local piece = self._Control:GetChessPartner():GetPieceInfo(id)
    if piece and piece.IsPossessed and piece:IsPossessed() then
        return
    end
    self:ShowHeadHud(id, target, nil, PartnerHead)
end

function XUiBlackRockChessComponent:ShowEnemyHeadHud(id, target)
    self:ShowHeadHud(id, target, nil, EnemyHead)
end

function XUiBlackRockChessComponent:ShowBossHeadHud(bossId, target)
    self:ShowHeadHud(nil, target, bossId, BossHead)
end

---@param partnerPiece XBlackRockChessPreparePiece
--function XUiBlackRockChessComponent:ShowLvHud(partnerPiece)
--    local id = partnerPiece:GetId()
--    local target = partnerPiece:GetIconFollow()
--    local pieceId = partnerPiece:GetConfigId()
--    local grid = self.GridLvs[id]
--    if not grid then
--        local ui = XUiHelper.Instantiate(self.PanelStar, self.HeadContainer)
--        grid = require("XUi/XUiBlackRockChess/XUiGrid/XUiGridLvHud").New(ui, self)
--        self.GridLvs[id] = grid
--    end
--    grid:Open()
--    grid:BindTarget(target, StarOffset, pieceId)
--    grid:RefreshView()
--end

---@param partnerPiece XBlackRockChessPreparePiece
function XUiBlackRockChessComponent:ShowErrorHud(partnerPiece)
    local id = partnerPiece:GetId()
    local target = partnerPiece:GetIconFollow()
    local pieceId = partnerPiece:GetConfigId()
    local grid = self.GridErrors[id]
    if not grid then
        local ui = XUiHelper.Instantiate(self.GridError, self.HeadContainer)
        grid = require("XUi/XUiBlackRockChess/XUiGrid/XUiGridErrorHud").New(ui, self)
        self.GridErrors[id] = grid
    end
    grid:Open()
    grid:BindTarget(target, nil, pieceId)
    partnerPiece:LoadClashEffect()
end

function XUiBlackRockChessComponent:UpdateHeadView()
    for _, grids in pairs(self.GridHeads) do
        for _, grid in pairs(grids) do
            if grid:IsValid() and grid:IsNodeShow() then
                grid:RefreshView()
            end
        end
    end
end

function XUiBlackRockChessComponent:HideHeadHud(id, pieceType)
    local grid = self.GridHeads[pieceType][id]
    if not grid then
        return
    end
    grid:Close()
end

function XUiBlackRockChessComponent:HidePartnerHeadHud(id)
    self:HideHeadHud(id, PartnerHead)
end

function XUiBlackRockChessComponent:HideEnemyHeadHud(id)
    self:HideHeadHud(id, EnemyHead)
end

function XUiBlackRockChessComponent:HideBossHeadHud(id)
    self:HideHeadHud(id, BossHead)
end

function XUiBlackRockChessComponent:HideLvHud(id)
    local grid = self.GridLvs[id]
    if not grid then
        return
    end
    grid:Close()
end

function XUiBlackRockChessComponent:HideErrorHud(id)
    local grid = self.GridErrors[id]
    if not grid then
        return
    end
    grid:Close()

    local partnerPiece = self._Control:GetChessPartner():GetPieceInfo(id)
    if partnerPiece then
        partnerPiece:HideClashEffect()
    end
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
    for _, grids in pairs(self.GridHeads) do
        for _, grid in pairs(grids) do
            grid:SetScale(scale)
        end
    end
    for _, grid in pairs(self.GridLvs) do
        grid:SetScale(scale)
    end
    for _, grid in pairs(self.GridErrors) do
        grid:SetScale(scale)
    end
end

function XUiBlackRockChessComponent:OnFocusEnemy(id)
    local grid = self.GridHeads[EnemyHead][id]
    if not grid or not grid:IsNodeShow() then
        return
    end
    self.LastFocusId = id
    grid:SetTarget(true)
end

--function XUiBlackRockChessComponent:OnCancelFocus()
--    if not XTool.IsNumberValid(self.LastFocusId) then
--        return
--    end
--    local last = self.GridHeads[self.LastFocusId]
--    if not last or not last:IsNodeShow() then
--        return
--    end
--    last:SetTarget(false)
--    self.LastFocusId = nil
--end

function XUiBlackRockChessComponent:OnPreviewDamage(id, damage, isPartner)
    local grid = isPartner and self.GridHeads[PartnerHead][id] or self.GridHeads[EnemyHead][id]
    if not grid or not grid:IsNodeShow() then
        return
    end
    grid:PreviewDamage(damage)
end

function XUiBlackRockChessComponent:OnShowDialog(target, text)
    if not self.GridDialog then
        self.GridDialog = XUiGridDialogHud.New(self.GridDialogBox, self)
    end
    if self.GridDialog:IsNodeShow() then
        self.GridDialog:Close()
    end
    self.GridDialog:BindTarget(target, DialogOffset, text)
    self.GridDialog:Open()
end

function XUiBlackRockChessComponent:OnShowBuffHud(id, target, skillId, count)
    id = id * 1000 + skillId
    local grid = self.GridBuffs[id]
    if not grid then
        local ui = XUiHelper.Instantiate(self.GridBuff, self.BuffContainer)
        grid = XUiGridBuffHud.New(ui, self)
        self.GridBuffs[id] = grid
    end
    if not ShowingBuff[id] then
        ShowingBuffCount = ShowingBuffCount + 1
        ShowingBuff[id] = grid
    end
    grid:BindTarget(target, PieceOffset, skillId, count)
    self:RefreshBuffLayout()
end

function XUiBlackRockChessComponent:HideBuffHud(id, skillId)
    id = id * 1000 + skillId
    local grid = self.GridBuffs[id]
    if not grid then
        return
    end
    if ShowingBuff[id] then
        ShowingBuffCount = ShowingBuffCount - 1
        ShowingBuff[id] = nil
    end
    grid:Close()
    self:RefreshBuffLayout()
end

function XUiBlackRockChessComponent:RefreshBuffLayout()
    local start = -0.15 * (ShowingBuffCount - 1)
    local step, count = 0.3, 0
    for _, grid in pairs(ShowingBuff) do
        local change = start + step * count
        local offset = Vector3(change, PieceOffset.y, PieceOffset.z)
        grid:ChangeOffset(offset)
        grid:Close()
        grid:Open()
        count = count + 1
    end
end

function XUiBlackRockChessComponent:FocusSelectActor(target)
    if not self.GridSelectActor then
        self.GridSelectActor = XUiGridHud.New(self.GridTarget, self)
    end
    self.GridSelectActor:BindTarget(target, SelectOffset)
    self.GridSelectActor:Open()
end

function XUiBlackRockChessComponent:OnGameMoveEnd()
    self:UpdateHeadView()
end

function XUiBlackRockChessComponent:UpdatePrepare()
    local cur = self._Control:GetPartnerLayoutCount()
    local total = self._Control:GetCurNodeCfg().PartnerPieceLimit
    self.TxtPrepare.text = XUiHelper.GetText("BlackRockChessPrepareBar", cur, total)

    local temp = {}
    local partnerPieces = self._Control:GetChessPartner():GetPreparePieceInfoDict()
    for _, piece in pairs(partnerPieces) do
        --self:ShowLvHud(piece)
        temp[piece:GetId()] = true
        if self._Control:GetChessEnemy():IsOverlap(piece) then
            self:ShowErrorHud(piece)
        else
            self:HideErrorHud(piece:GetId())
        end
    end
    for id, _ in pairs(self.GridLvs) do
        if not temp[id] then
            self:HideLvHud(id)
            self:HidePartnerHeadHud(id)
            self:HideErrorHud(id)
        end
    end
end

return XUiBlackRockChessComponent