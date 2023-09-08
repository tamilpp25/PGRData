local XBlackRockChessPiece = require("XModule/XBlackRockChess/XGameObject/XBlackRockChessPiece")
local XBlackRockChessGamer = require("XModule/XBlackRockChess/XGameObject/XBlackRockChessGamer")
local XBlackRockChessEnemy = require("XModule/XBlackRockChess/XGameObject/XBlackRockChessEnemy")
local XBlackRockChessReinforce = require("XModule/XBlackRockChess/XGameObject/XBlackRockChessReinforce")



---@class XBlackRockChessInfo : XControl 游戏对局信息
---@field _StageId number 关卡Id
---@field _Round number 回合数
---@field _EnemyInfo XBlackRockChessEnemy 棋子管理
---@field _GamerInfo XBlackRockChessGamer 玩家管理
---@field _ReinforceInfos table<number, XBlackRockChessReinforce> 玩家管理
---@field _MainControl XBlackRockChessControl 管理器
local XBlackRockChessInfo = XClass(XControl, "XBlackRockChessInfo")

function XBlackRockChessInfo:Ctor(controlId, control)
    self._ReinforceInfos = {}
    self._KillData = {}
    self._Round = 0
    self._IncId = 0
end

function XBlackRockChessInfo:SetEnemyImp(imp)
    self._EnemyInfo:SetImp(imp)
end

function XBlackRockChessInfo:UpdateData(chessInfo)
    if XTool.IsTableEmpty(chessInfo) then
        return
    end
    self._EnemyInfo = self._EnemyInfo or XBlackRockChessEnemy.New(self._Id, self._MainControl)
    self._GamerInfo = self._GamerInfo or XBlackRockChessGamer.New(self._Id, self._MainControl)
    self._StageId = chessInfo.StageId
    self._Round = chessInfo.CurRound
    self._IncId = chessInfo.IncId
    local formations = chessInfo.Formations or {}
    for _, formation in ipairs(formations) do
        local memberType = formation.Type
        if memberType == XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.GAMER then
            self._GamerInfo:UpdateData(formation)
        else
            local id = formation.PieceInfo.Guid
            local info =  self._EnemyInfo:GetPieceInfo(id)
            if not info then
                info = XBlackRockChessPiece.New(id, formation.PieceInfo.PieceId, self._MainControl)
                info:UpdateData(formation.X, formation.Y, formation.Type, formation.PieceInfo)
                self._EnemyInfo:AddPieceInfo(info:GetId(), info)
            else
                info:UpdateData(formation.X, formation.Y, formation.Type, formation.PieceInfo)
            end
            self._EnemyInfo:UpdateTransformPiece(id)
        end
    end
    local reinforces = chessInfo.Reinforces or {}
    for _, reinforce in ipairs(reinforces) do
        local info = self._ReinforceInfos[reinforce.Id]
        if not info then
            info = XBlackRockChessReinforce.New(reinforce.Id, self._MainControl)
            self._ReinforceInfos[reinforce.Id] = info
        end
        info:UpdateData(reinforce.PreviewCd, reinforce.TriggerCd)
    end

    self._KillData = chessInfo.KillData or {}
    
    XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH)
end

function XBlackRockChessInfo:GetKillTotal()
    local total = 0
    for _, count in pairs(self._KillData) do
        total = total + count
    end
    
    return total
end

function XBlackRockChessInfo:GetKillCount(pieceType)
    return self._KillData[pieceType] and self._KillData[pieceType] or 0
end

function XBlackRockChessInfo:AddKillCount(pieceType)
    if not self._KillData[pieceType] then
        self._KillData[pieceType] = 1
        return
    end
    self._KillData[pieceType] = self._KillData[pieceType] + 1
end

function XBlackRockChessInfo:GetPieceDict()
    return self._EnemyInfo:GetPieceInfoDict()
end

---@return XBlackRockChessGamer
function XBlackRockChessInfo:GetGamerInfo()
    return self._GamerInfo
end

---@return XBlackRockChessEnemy
function XBlackRockChessInfo:GetEnemyInfo()
    return self._EnemyInfo
end

function XBlackRockChessInfo:GetPieceFormation(id)
    local info = self._EnemyInfo:GetPieceInfo(id)
    if not info then
        XLog.Error("获取棋子布局信息失败, 不存在Id = " .. id .. "的棋子")
        return
    end
    return info
end

function XBlackRockChessInfo:GetStageId()
    return self._StageId
end

function XBlackRockChessInfo:GetRound()
    return self._Round
end

function XBlackRockChessInfo:ChangeRound(count)
    self._Round = self._Round + count
end

---@return XBlackRockChessPiece[]
function XBlackRockChessInfo:GetCanMovePieceList()
    return self._EnemyInfo:GetCanMovePieceList()
end

function XBlackRockChessInfo:ExitFight()
    if self._GamerInfo then
        self._GamerInfo:Release()
    end
    if self._EnemyInfo then
        self._EnemyInfo:Release()
    end
    for _, info in pairs(self._ReinforceInfos or {}) do
        info:Release()
    end
    self._ReinforceInfos = {}
    self._GamerInfo = nil
    self._EnemyInfo = nil
    self._Round = 0
    self._IncId = 0
end

function XBlackRockChessInfo:UpdateReinforce()
    if XTool.IsTableEmpty(self._ReinforceInfos) then
        return
    end
    for _, info in pairs(self._ReinforceInfos) do
        info:UpdateAction()
    end
end

function XBlackRockChessInfo:GetReinforceActionList()
    if XTool.IsTableEmpty(self._ReinforceInfos) then
        return {}
    end
    local list = {}
    for _, info in pairs(self._ReinforceInfos) do
        list = XTool.MergeArray(list, info:GetActionList())
    end
    return list
end

function XBlackRockChessInfo:GetIncId()
    self._IncId = self._IncId + 1
    return self._IncId
end

function XBlackRockChessInfo:Sync()
    self._GamerInfo:Sync()
    self._EnemyInfo:Sync()

    if not XTool.IsTableEmpty(self._ReinforceInfos) then
        for _, info in pairs(self._ReinforceInfos) do
            info:Sync()
        end
    end
    
end

function XBlackRockChessInfo:Restore()
    self._GamerInfo:Restore()
    self._EnemyInfo:Restore()

    if not XTool.IsTableEmpty(self._ReinforceInfos) then
        for _, info in pairs(self._ReinforceInfos) do
            info:Restore()
        end
    end
end

function XBlackRockChessInfo:OnRelease()
    self:ExitFight()
    self._ReinforceInfos = nil
end

return XBlackRockChessInfo