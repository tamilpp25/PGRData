local XBlackRockChessPartnerPiece = require("XModule/XBlackRockChess/XGameObject/XBlackRockChessPartnerPiece")
local XBlackRockChessPreparePiece = require("XModule/XBlackRockChess/XGameObject/XBlackRockChessPreparePiece")

local SITE = XEnumConst.BLACK_ROCK_CHESS.PARTNER_PIECE_STATE.SITE
local GOINTO_BATTLE = XEnumConst.BLACK_ROCK_CHESS.PARTNER_PIECE_STATE.GOINTO_BATTLE

local OperateToSite = 0
local OperateToLayout = 1
local Distance = CS.UnityEngine.Vector2Int.Distance

--战斗力排序
local SortPieceTypeByPower = {
    [XEnumConst.BLACK_ROCK_CHESS.CHESS_TYPE.QUEEN] = 1,
    [XEnumConst.BLACK_ROCK_CHESS.CHESS_TYPE.ROOK] = 2,
    [XEnumConst.BLACK_ROCK_CHESS.CHESS_TYPE.BISHOP] = 3,
    [XEnumConst.BLACK_ROCK_CHESS.CHESS_TYPE.KNIGHT] = 4,
    [XEnumConst.BLACK_ROCK_CHESS.CHESS_TYPE.PAWN] = 5,
    [XEnumConst.BLACK_ROCK_CHESS.CHESS_TYPE.KING] = 6,
}

--Action排行
local SortPieceTypeByActionType = {
    [XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.MOVE] = 1,
    [XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.PROMOTION] = 2,
    [XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.REINFORCE_PREVIEW] = 3,
    [XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.REINFORCE_TRIGGER] = 4,
    [XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.TRANSFORM] = 5,
    [XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.SUMMON] = 6,
}

local AsyncMove = asynTask(function(pieceInfo, point, onlyMove, cb)
    if not pieceInfo then
        if cb then cb() end
        return
    end
    pieceInfo:MoveTo(point, onlyMove, cb)
end)

---@class XBlackRockChessPartner : XEntityControl 友方
---@field _MainControl XBlackRockChessControl
---@field _PieceInfoDict table<number, XBlackRockChessPartnerPiece>
---@field _PreparePieceInfoDict table<number, XBlackRockChessPreparePiece>
---@field _LayoutDict table<number, PartnerLayout> 布阵 key:guid
---@field _PrepareSites table<number, PartnerSite> 备战位
---@field _FailReinforceList table<number, XBlackRockChessPiece[]>
---@field _TransmigrationDict XBlackRockChessPartnerPiece[] 转生
---@field _TransformDict XBlackRockChessPartnerPiece[] 转化
local XBlackRockChessPartner = XClass(XEntityControl, "XBlackRockChessPartner")
local XBlackRockChessPiece = require("XModule/XBlackRockChess/XGameObject/XBlackRockChessPiece")

---@type XBlackRockChess.XBlackRockChessManager
local XBlackRockChessManager = CS.XBlackRockChess.XBlackRockChessManager.Instance

function XBlackRockChessPartner:OnInit()
    ---@type UnityEngine.Vector2Int
    self._TempVec2 = CS.UnityEngine.Vector2Int(0, 0)
    self._PieceInfoDict = {}
    self._SummonDict = {}
    self._PreparePieceInfoDict = {}
    self._ReinforceDict = {}
    self._TransmigrationDict = {}
    self._TransformDict = {}
    self._FailReinforceList = {}
    self._ActionList = {}
    self._AsyncOnRoundBeginCb = handler(self, self.AsyncOnRoundBegin)
    self._OnSortMoveAndAttack = handler(self, self.OnSortMoveAndAttack)
    local interval, _ = self._MainControl:GetPieceMoveConfig()
    self._MoveInterval = interval
end

function XBlackRockChessPartner:Sync()
    for _, info in pairs(self._PieceInfoDict) do
        info:Sync()
    end
    self._ActionList = {}
end

function XBlackRockChessPartner:SetImp(imp)
    --避免重复设置
    if self._Imp then
        return
    end
    self._Imp = imp
end

function XBlackRockChessPartner:AddHpOverflowByType(pieceType, value)
    local dict = self:GetPieceInfoDict()
    for _, piece in pairs(dict) do
        if piece:GetPieceType() == pieceType then
            piece:AddHpOverflow(value)
        end
    end
end

--region 友军棋子上阵和布局

function XBlackRockChessPartner:SetPieceToSite(index, guid, pieceId)
    self:RemoveLayout(guid)
    self:AddPrepareBattleSite(index, guid, pieceId)
    self._MainControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_UPDATE_PREPARE_PARTNER)
end

function XBlackRockChessPartner:SetPieceToLayout(guid, pieceId, x, y)
    self:AddLayout(guid, x, y, pieceId)
    self:RemovePrepareBattleSite(guid)
    self._MainControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_UPDATE_PREPARE_PARTNER)
end

function XBlackRockChessPartner:AddLayout(guid, x, y, pieceId)
    if not self._LayoutDict then
        self._LayoutDict = {}
    end
    self._LayoutDict[guid] = {
        X = x,
        Y = y,
        Guid = guid,
        PieceId = pieceId,
    }
    self._Imp:AddLayout(guid, x, y, pieceId)
    self:UpdatePreparePieceInfo(x, y, guid, pieceId, GOINTO_BATTLE)
end

function XBlackRockChessPartner:RemoveLayout(guid)
    self._LayoutDict[guid] = nil
    self._Imp:RemoveLayout(guid)
end

function XBlackRockChessPartner:AddPrepareBattleSite(index, guid, pieceId)
    if not self._PrepareSites then
        self._PrepareSites = {}
    end
    self._PrepareSites[index] = {
        Guid = guid,
        PieceId = pieceId,
    }
    self._Imp:AddSites(index, guid, pieceId)
    self:UpdatePreparePieceInfo(index, 0, guid, pieceId, SITE)
end

---@return PartnerSite
function XBlackRockChessPartner:RemovePrepareBattleSite(guid)
    if XTool.IsTableEmpty(self._PrepareSites) then
        return
    end
    for idx, data in pairs(self._PrepareSites) do
        if data.Guid == guid then
            local site = self._PrepareSites[idx]
            self._PrepareSites[idx] = nil
            self._Imp:RemoveSites(guid)
            return
        end
    end
end

--- 找一个空位
function XBlackRockChessPartner:GetEmptyPrepareBattleSite()
    for i = 1, self._SiteLimit do
        if not self._PrepareSites[i] then
            return i
        end
    end
end

-- 局内商店用
function XBlackRockChessPartner:GetAllPreparePieces()
    local datas = {}
    if not XTool.IsTableEmpty(self._PrepareSites) then
        for _, data in pairs(self._PrepareSites) do
            table.insert(datas, {
                Guid = data.Guid,
                PieceId = data.PieceId,
                IsLayout = false,
            })
        end
    end
    if not XTool.IsTableEmpty(self._LayoutDict) then
        for _, data in pairs(self._LayoutDict) do
            table.insert(datas, {
                Guid = data.Guid,
                PieceId = data.PieceId,
                IsLayout = true,
            })
        end
    end
    return datas
end

function XBlackRockChessPartner:IsPreparePieceEmpty()
    return XTool.IsTableEmpty(self._PrepareSites) and XTool.IsTableEmpty(self._LayoutDict)
end

function XBlackRockChessPartner:RecyclePiece(guid)
    self:RemovePieceInfo(guid)
    self:RemovePrepareBattleSite(guid)
    self:RemovePreparePieceInfo(guid)
    self:RemoveLayout(guid)
    self._MainControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_HIDE_PARTNER_HEAD_HUD, guid)
end

function XBlackRockChessPartner:GetPrepareSiteIndex(guid)
    if XTool.IsTableEmpty(self._PrepareSites) then
        return nil
    end
    for index, data in pairs(self._PrepareSites) do
        if data.Guid == guid then
            return index
        end
    end
    return nil
end

--endregion

--- 友方棋子布阵和备战席（关卡更新）
function XBlackRockChessPartner:SetPrepareData(layouts, pieceBag)
    -- PS:开始战斗调用这个接口的时候 C#还没初始化 但是修改C#初始化会涉及很多 就先这样
    if self:IsPassPreparationStage() then
        self:ClearPreparation()
    else
        self._LayoutsData = layouts
        self._PieceBagData = pieceBag
    end
end

function XBlackRockChessPartner:UpdatePrepareData(sellPrepareSiteIdx)
    self:ModifyPrepareData()
    -- 刷新备战席
    if XTool.IsNumberValid(sellPrepareSiteIdx) then
        local emptySite = 0
        for i = sellPrepareSiteIdx, 8 do
            local pieceData = self._PrepareSites[i]
            if pieceData and emptySite > 0 then
                local piece = self:GetPieceInfo(pieceData.Guid)
                CS.XBlackRockChess.XBlackRockChessManager.Instance:PlayMoveTo(piece._Imp, emptySite, 0)
                self._PrepareSites[i] = nil
                self._PrepareSites[emptySite] = pieceData
                emptySite = i
            elseif not pieceData then
                emptySite = i
            end
        end
    end
end

-- 增量/减量修改备战席（购买棋子）
function XBlackRockChessPartner:ModifyPrepareData()
    if not self._PieceBagData then
        return
    end
    if self:IsPassPreparationStage() then
        return
    end
    local add = {}
    local remove = {}
    if XTool.IsTableEmpty(self._OldPieceBagData) then
        add = self._PieceBagData
    else
        remove = XTool.Clone(self._OldPieceBagData)
        for _, data in ipairs(self._PieceBagData) do
            local isNew = true
            for i, oldData in ipairs(remove) do
                if data.Guid == oldData.Guid then
                    table.remove(remove, i)
                    isNew = false
                    break
                end
            end
            if isNew then
                table.insert(add, data)
            end
        end
    end
    for _, data in pairs(remove) do
        self:RecyclePiece(data.Guid)
    end
    for _, data in pairs(add) do
        local idx = self:GetEmptyPrepareBattleSite()
        self:SetPieceToSite(idx, data.Guid, data.PieceId)
    end
    self._OldPieceBagData = self._PieceBagData
    self._PieceBagData = nil
    self._MainControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_UPDATE_PREPARE_PARTNER)
end

function XBlackRockChessPartner:DoEnterFight()
    -- 棋盘上的棋子
    local pieceDict = self:GetPieceInfoDict()
    local impDict = {}
    for _, piece in pairs(pieceDict) do
        local x, y = piece:GetPos()
        local guid = piece:GetId()
        local templateId = piece:GetConfigId()
        local imp = piece._Imp
        if XTool.UObjIsNil(imp) then
            imp = XBlackRockChessManager:AddPartnerPiece(templateId, x, y)
            imp.Id = guid
        end
        impDict[piece] = imp
    end

    if not self:IsPassPreparationStage() then
        -- 备战栏和布阵的棋子
        self._Imp:ClearLayout()
        self._Imp:ClearSites()

        self._SiteLimit = self._MainControl:GetPrapareBattleSiteCount()
        self._LayoutLimit = self._MainControl:GetCurNodeCfg().PartnerPieceLimit

        self._LayoutDict = {}
        self._PrepareSites = {}
        for _, data in pairs(self._LayoutsData) do
            self:SetPieceToLayout(data.Guid, data.PieceId, data.X, data.Y)
        end
        for i, data in ipairs(self._PieceBagData) do
            if not self._LayoutDict[data.Guid] then
                self:SetPieceToSite(i, data.Guid, data.PieceId)
            end
        end
        
        self._OldPieceBagData = self._PieceBagData
        self._PieceBagData = nil
        self._LayoutsData = nil
    else
        CS.XBlackRockChess.XBlackRockChessManager.Instance.Partner:SetIsLayout(false)
    end

    self._MainControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_UPDATE_PREPARE_PARTNER)

    for piece, imp in pairs(impDict) do
        piece:SetImp(imp, true)
        piece:UpdatePreview()
    end
end

--- 更新棋盘中的棋子（请求同步上阵数据后 上阵棋子会变成棋盘棋子）
function XBlackRockChessPartner:UpdatePieceData(formation, exists)
    local id = formation.Guid
    exists[id] = true
    self:UpdatePieceInfo(formation, XEnumConst.BLACK_ROCK_CHESS.PARTNER_PIECE_STATE.BATTLE)

    local curRound = self._MainControl:GetChessRound()
    for round, list in pairs(self._FailReinforceList) do
        if curRound - round >= 2 then
            for _, info in pairs(list) do
                local id = info:GetId()
                self:RemovePieceInfo(id)
            end
        end
    end
end

function XBlackRockChessPartner:UpdatePieceInfo(formation)
    local guid = formation.Guid
    local pieceId = formation.PieceInfo.PieceId
    local info = self:GetPieceInfo(guid)
    if not info then
        info = self:AddEntity(XBlackRockChessPartnerPiece, guid, pieceId)
        self:AddPieceInfo(guid, info)
    end
    info:UpdateData(formation)
    self:UpdateTransformPiece(guid)
end

function XBlackRockChessPartner:UpdatePreparePieceInfo(x, y, guid, pieceId, state)
    local info = self:GetPieceInfo(guid)
    if info then
        if state == SITE then
            info:SwitchToSite(x, y)
        else
            info:SwitchToBattle(x, y)
        end
    else
        info = self:AddEntity(XBlackRockChessPreparePiece, guid, pieceId)
        info:InitData(x, y, state)
        self._PreparePieceInfoDict[guid] = info
        self._MainControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_PARTNER_HEAD_HUD, guid, info:GetIconFollow())
    end
    info:UpdateHUD()
end

function XBlackRockChessPartner:RemovePreparePieceInfo(guid)
    self._PreparePieceInfoDict[guid] = nil
end

function XBlackRockChessPartner:UpdateFormation(exists)
    local removeId = {}
    for _, info in pairs(self._PieceInfoDict) do
        if not exists[info:GetId()] then
            table.insert(removeId, info:GetId())
        end
    end

    if not XTool.IsTableEmpty(removeId) then
        for _, id in ipairs(removeId) do
            self:RemovePieceInfo(id)
        end
    end
end

function XBlackRockChessPartner:UpdatePieceByCSharp(guid, pieceId, x, y, operate)
    if operate == OperateToSite then
        self:SetPieceToSite(x, guid, pieceId)
    elseif operate == OperateToLayout then
        self:SetPieceToLayout(guid, pieceId, x, y)
    end
end

function XBlackRockChessPartner:TryAutoGoIntoBattle()
    CS.XBlackRockChess.XBlackRockChessManager.Instance.Partner:SetIsLayout(false)
    self:AutoGoIntoBattle()
    for _, pieceInfo in pairs(self._PreparePieceInfoDict) do
        pieceInfo:SetPieceState(XEnumConst.BLACK_ROCK_CHESS.PARTNER_PIECE_STATE.BATTLE)
    end
end

--- 自动上阵
function XBlackRockChessPartner:AutoGoIntoBattle()
    if self:IsLayoutLimit() then
        return
    end

    local boardWidth = CS.XBlackRockChess.XChessBoard.BoardWidth
    -- 先上阵士兵 士兵只能在最下面一行
    for k, site in pairs(self._PrepareSites) do
        local pieceType = self._MainControl:GetPartnerPieceById(site.PieceId).Type
        if pieceType == 1 then
            for posX = 1, boardWidth do
                if not self:IsPieceAtCoord(posX, 1) then
                    self:SetPieceToLayout(site.Guid, site.PieceId, posX, 1)
                    if self:IsLayoutLimit() then
                        return
                    end
                    break
                end
            end
        end
    end

    local waitBattlePiece = self:GetFirstPrepareBattleSitePiece(true)
    if not waitBattlePiece then
        -- 全部上阵完毕
        return
    end

    local player = XBlackRockChessManager:GetPlayer()
    local center = player.CurrentPoint
    local round = 1
    -- 以角色为中心 一圈圈往外扩
    while (round <= boardWidth and waitBattlePiece) do
        local top = center.y + round;
        local bottom = center.y - round;
        local left = center.x - round;
        local right = center.x + round;

        local curX = center.x;
        local curY = top;
        local count = 8 * round;

        -- 顺时针查找
        for i = 1, count do
            if curY == top and curX < right then
                -- 往右
                curX = curX + 1
            elseif curX == right and curY > bottom then
                -- 往下
                curY = curY - 1
            elseif curY == bottom and curX > left then
                -- 往左
                curX = curX - 1
            elseif curX == left and curY < top then
                -- 往上
                curY = curY + 1
            end
            
            if not self:IsPieceAtCoord(curX, curY) then
                self:SetPieceToLayout(waitBattlePiece.Guid, waitBattlePiece.PieceId, curX, curY)
                if self:IsLayoutLimit() then
                    return
                end
                waitBattlePiece = self:GetFirstPrepareBattleSitePiece(true)
            end

            if not waitBattlePiece then
                break
            end
        end
        round = round + 1
    end
end

function XBlackRockChessPartner:GetFirstPrepareBattleSitePiece(isNoPawn)
    for i = 1, self._SiteLimit do
        local site = self._PrepareSites[i]
        if site then
            local pieceType = self._MainControl:GetPartnerPieceById(site.PieceId).Type
            if not isNoPawn or pieceType ~= 1 then
                return site
            end
        end
    end
    return nil
end

function XBlackRockChessPartner:GetPieceInPrepareBattleSite(guid)
    for _, site in pairs(self._PrepareSites) do
        if site.Guid == guid then
            return site.PieceId
        end
    end
    return 0
end

function XBlackRockChessPartner:RemoveReinforce(pieceId)
    self._ReinforceDict[pieceId] = nil
end

---@param pieceInfo XBlackRockChessPiece
function XBlackRockChessPartner:AddPieceInfo(id, pieceInfo)
    self._PieceInfoDict[id] = pieceInfo
    if self._SummonDict[id] then
        local imp, virtual = self._SummonDict[id].Imp, self._SummonDict[id].IsVirtual
        pieceInfo:Summon(imp, true, virtual)
        self._SummonDict[id] = nil
        return
    end
end

function XBlackRockChessPartner:RemovePieceInfo(id)
    local info = self._PieceInfoDict[id] or self._PreparePieceInfoDict[id]
    if info then
        self:RemoveEntity(info)
    end
    self._PieceInfoDict[id] = nil
    self._TransmigrationDict[id] = nil
    self._MainControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_HIDE_PARTNER_HEAD_HUD, id)
end

function XBlackRockChessPartner:GetPieceInfo(id)
    return self._PieceInfoDict[id] or self._PreparePieceInfoDict[id]
end

function XBlackRockChessPartner:GetPieceAtCoord(v2Int)
    for _, pieceInfo in pairs(self._PieceInfoDict) do
        local point = pieceInfo:GetMovedPoint()
        if point.x == v2Int.x and point.y == v2Int.y then
            return pieceInfo
        end
    end
    return nil
end

function XBlackRockChessPartner:GetPieceInfoDict()
    return self._PieceInfoDict
end

function XBlackRockChessPartner:GetPreparePieceInfoDict()
    return self._PreparePieceInfoDict
end

--- 布阵
function XBlackRockChessPartner:GetLayoutDict()
    return self._LayoutDict
end

--- 备战席
function XBlackRockChessPartner:GetPrepareBattleSite()
    return self._PrepareSites
end

--- 将棋子的索引发给服务端保存起来
function XBlackRockChessPartner:GetPieceBagData()
    local datas = {}
    local layouts = {}
    if not XTool.IsTableEmpty(self._LayoutDict) then
        for _, v in pairs(self._LayoutDict) do
            local data = {}
            data.Guid = v.Guid
            data.PieceId = v.PieceId
            table.insert(layouts, data)
        end
    end
    for i = 1, 8 do
        local data = {}
        local site = self._PrepareSites[i]
        if site then
            data.Guid = site.Guid
            data.PieceId = site.PieceId
        elseif #layouts > 0 then
            -- 按照现在的显示逻辑 上阵棋子的索引并不重要 因为棋子下阵时会重新找位置 UI上也不会显示出来
            -- 所以这里直接随便找个位置放上去
            data = table.remove(layouts, 1)
        else
            break
        end
        table.insert(datas, data)
    end
    return datas
end

function XBlackRockChessPartner:GetLayoutDictCount()
    local count = 0
    for _, _ in pairs(self._LayoutDict) do
        count = count + 1
    end
    return count
end

--- 该位置是否已经有布局棋子在了
function XBlackRockChessPartner:IsLayoutPieceThere(x, y)
    if not XTool.IsTableEmpty(self._LayoutDict) then
        for _, data in pairs(self._LayoutDict) do
            if data.X == x and data.Y == y then
                return data
            end
        end
    end
    return false
end

--- 棋子是否能升阶
function XBlackRockChessPartner:IsLevelUp(configId)
    local config = self._MainControl:GetPartnerPieceById(configId)
    return self._MainControl:IsPartnerLevelMax(configId) and not XTool.IsTableEmpty(self:GetPieceByType(config.Type))
end

function XBlackRockChessPartner:GetPieceByType(pieceType)
    local result = {}
    for _, piece in pairs(self._PreparePieceInfoDict) do
        local config = self._MainControl:GetPartnerPieceById(piece:GetConfigId())
        if config.Type == pieceType then
            table.insert(result, piece)
        end
    end
    return result
end

function XBlackRockChessPartner:IsLayoutLimit()
    return self:GetLayoutDictCount() >= self._LayoutLimit
end

function XBlackRockChessPartner:IsPieceAtCoord(x, y)
    self._TempVec2:Set(x, y)
    if self:IsLayoutPieceThere(x, y) then
        return true
    end
    return self._MainControl:PieceAtCoord(self._TempVec2) ~= nil
end

--- 是否已经过了备战阶段（备战和上阵棋子只在备战阶段显示）
function XBlackRockChessPartner:IsPassPreparationStage()
    return not XTool.IsNumberValid(self._MainControl:GetShopInfo():GetShopId())
end

function XBlackRockChessPartner:ClearPreparation()
    self._LayoutsData = nil
    self._PieceBagData = nil
    self._OldPieceBagData = nil
    for _, pieceInfo in pairs(self._PreparePieceInfoDict) do
        self:RecyclePiece(pieceInfo:GetId())
    end
    self._PreparePieceInfoDict = {}
    self._LayoutDict = {}
    self._PrepareSites = {}
end

----------------------------------------------------->开始战斗<-----------------------------------------------------

function XBlackRockChessPartner:OnRoundBegin()
    if not self._Imp then
        return
    end
    self._Imp:OnRoundBegin()
    self:AsyncOnRoundBegin()
end

function XBlackRockChessPartner:OnRoundBeginAsyn()
    if not self._Imp then
        return
    end
    self._Imp:OnRoundBegin()
    self._MainControl:RunAsynWithPCall(self._AsyncOnRoundBeginCb)
end

function XBlackRockChessPartner:AsyncOnRoundBegin()
    -- 屏蔽角色移动
    self._MainControl:OnCancelSkill(false)
    
    local isMoving = false
    local attackList = self:UpdateAttackPieceList()
    local enemys = self._MainControl:GetChessEnemy():GetPieceInfoDict()
    local ignorePieceIds = {}
    for _, info in pairs(attackList) do
        local infoMovedPoint = info:GetMovedPoint()
        local debugLog = string.format("开始思考棋子[%s]的行为\n血量[%s] 临时血量[%s]\n", info:GetId(), info:GetHp(), info:GetAtkLift())
        ---@type XBlackRockChessPiece
        local finallyDim -- 攻击行为
        local finallyPoint -- 移动行为
        local dimMinHpPiece
        local dontWillingPieces = {}
        ---@type XBlackRockChessPiece[]
        local moveToPieces = {}
        for _, enemy in pairs(enemys) do
            if enemy:IsPreview() then
                goto CONTINUE
            end
            local isWilling = info:IsWillingAttack(enemy)
            if info:CheckAttack(enemy) and isWilling and not ignorePieceIds[enemy:GetId()] then
                if not dimMinHpPiece then
                    debugLog = debugLog .. string.format("可攻击对象:敌方[%s] 血量[%s]\n", enemy:GetId(), enemy:GetHp())
                    dimMinHpPiece = enemy
                else
                    local hp = dimMinHpPiece:GetHp() - enemy:GetHp()
                    local isNear = Distance(infoMovedPoint, dimMinHpPiece:GetMovedPoint()) > Distance(infoMovedPoint, enemy:GetMovedPoint())
                    if hp > 0 or (hp == 0 and isNear) then
                        debugLog = debugLog .. string.format("可攻击对象:敌方[%s] 血量[%s]\n", enemy:GetId(), enemy:GetHp())
                        dimMinHpPiece = enemy
                    end
                end
            end
            if enemy:CheckAttack(info) and not isWilling then
                table.insert(dontWillingPieces, enemy) 
            end
            if isWilling then
                table.insert(moveToPieces, enemy)
            end
            :: CONTINUE ::
        end
        if dimMinHpPiece then
            -- 攻击范围内有合适的攻击对象：攻击血量最低的敌方棋子
            finallyDim = dimMinHpPiece
            debugLog = debugLog .. string.format("主动攻击敌方[%s]\n", dimMinHpPiece:GetId())
        elseif info:GetPieceType() == XEnumConst.BLACK_ROCK_CHESS.CHESS_TYPE.PAWN then
            -- 士兵特殊处理
            finallyPoint = info._Imp:SearchByPoint()
            debugLog = debugLog .. string.format("士兵移动到[%s,%s]\n", finallyPoint.x, finallyPoint.y)
        elseif #dontWillingPieces > 0 then
            -- 处于更强大敌人的攻击范围内
            local saftPoint = info:SearchPartnerSaftPoint()
            if saftPoint then
                -- 移动到不会被攻击的格子里进行回避
                finallyPoint = saftPoint
                debugLog = debugLog .. string.format("移动到[%s,%s]进行躲避\n", finallyPoint.x, finallyPoint.y)
            else
                -- 无路可退
                table.sort(dontWillingPieces, function(a, b)
                    return self._MainControl:PieceCommonSort(infoMovedPoint, a, b)
                end)
                local piece = dontWillingPieces[1]
                -- 可能敌棋能攻击到友棋 但是友棋攻击不到敌棋
                if info:CheckAttack(piece) and not ignorePieceIds[piece:GetId()] then
                    -- 攻击敌棋
                    finallyDim = piece
                    debugLog = debugLog .. string.format("无路可退 攻击敌方[%s]\n", finallyDim:GetId())
                else
                    -- 朝敌棋移动
                    finallyPoint = info:SearchPartnerByPoint(piece:GetMovedPoint())
                    debugLog = debugLog .. string.format("无路可退 朝敌方[%s,%s]移动\n", finallyPoint.x, finallyPoint.y)
                end
            end
        else
            -- 攻击范围内有没有合适的攻击对象 且 没有被更强大敌人攻击的危险
            local kingPiece = self._MainControl:GetChessEnemy():GetKingPiece()
            if kingPiece then
                -- 朝敌方国王移动
                finallyPoint = info:SearchPartnerByPoint(kingPiece:GetMovedPoint())
                debugLog = debugLog .. string.format("攻击不到别人且附近没有危险 往国王方向移动\n")
            elseif #moveToPieces > 0 then
                -- 朝离自己近血量比自己低的棋子移动
                table.sort(moveToPieces, function(a, b)
                    return self._MainControl:PieceDistanceSort(infoMovedPoint, a, b)
                end)
                finallyPoint = info:SearchPartnerByPoint(moveToPieces[1]:GetMovedPoint())
                debugLog = debugLog .. string.format("攻击不到别人且附近没有危险且没有国王 朝近距离的低血敌方[%s]移动 血量[%s]\n", moveToPieces[1]:GetId(), moveToPieces[1]:GetHp())
            end
            -- 还有其他情况则待机
        end
        if info:IsPromotion() then
            -- 士兵升变
            info:Promotion()
        elseif finallyDim then
            -- 攻击
            if finallyDim:IsCanBeAttacked() then
                info:MoveTo(finallyDim:GetMovedPoint(), true, function()
                    self:DoAttack(info, finallyDim)
                end)
            else
                info:PlayMoveTo(finallyDim:GetMovedPoint(), function()
                    -- 攻击失败 回到原位
                    info:PlayMoveTo(infoMovedPoint)
                end)
            end
            isMoving = true
            ignorePieceIds[finallyDim:GetId()] = true
        elseif finallyPoint then
            -- 移动
            if info:IsCanMove() then
                info:MoveTo(finallyPoint, true)
                isMoving = true
            else
                debugLog = string.format("棋子[%s]本回合不移动", info:GetId())
            end
        end
        CS.XLog.Warning(debugLog)
    end
    if isMoving then
        asynWaitSecond(self._MoveInterval)
    end
    -- 表演结束
    self._MainControl:SyncWait()
    -- 回合结束
    self:OnRoundEnd()
end

---@param a XBlackRockChessPiece
---@param b XBlackRockChessPiece
function XBlackRockChessPartner:SortByDistance(a, b)
    local aDistance
end

---攻击敌方棋子
---@param partner XBlackRockChessPartnerPiece
---@param enemy XBlackRockChessPiece
function XBlackRockChessPartner:PlayAttackEnemy(partner, enemy)
    AsyncMove(partner, self:GetMovedPoint(), true)
    self._MainControl:SyncWait()
end

---@param partner XBlackRockChessPartnerPiece
function XBlackRockChessPartner:PartnerMoveTo(partner, position)
    AsyncMove(partner, position, true)
    self._MainControl:SyncWait()
end

---@param partner XBlackRockChessPartnerPiece
---@param enemy XBlackRockChessPiece
function XBlackRockChessPartner:DoAttack(partner, enemy)
    local enemyAtk = math.max(0, enemy:GetHp() - partner:GetAtkLift())
    local partnerAtk = partner:GetHp() + partner:GetAtkLift()
    local enemyPoint = enemy:GetMovedPoint()
    local partnerPoint = partner:GetMovedPoint()
    if enemy:AttackEdByPiece(partnerAtk) then
        partner:AttackEdByPiece(enemyAtk)
        CS.XBlackRockChess.XBlackRockChessManager.Instance:ShowDpsOnGrid(enemyPoint.x, enemyPoint.y, partnerAtk)
        CS.XBlackRockChess.XBlackRockChessManager.Instance:ShowDpsOnGrid(partnerPoint.x, partnerPoint.y, enemyAtk)
        self._MainControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_PARTNER_HEAD_HUD, partner:GetId(), partner:GetIconFollow())
        self._MainControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_ENEMY_HEAD_HUD, enemy:GetId(), enemy:GetIconFollow())
        enemy:OnSkillHit()
        partner:OnSkillHit()
        if not enemy:IsAlive() then
            -- 友方棋子击杀敌方棋子 角色回复能量（怒气）
            self._MainControl:PartnerFightRecoverEnergy()
        end
        return
    end
    CS.XBlackRockChess.XBlackRockChessManager.Instance:ShowDpsOnGrid(enemyPoint.x, enemyPoint.y, 0)
end

---@return XBlackRockChessPartnerPiece[]
function XBlackRockChessPartner:UpdateAttackPieceList()
    local list = {}
    for _, info in pairs(self._PieceInfoDict) do
        info:UpdatePreview()
        if info:IsAttackAble() then
            table.insert(list, info)
        end
    end
    table.sort(list, self._OnSortMoveAndAttack)
    return list
end

function XBlackRockChessPartner:OnSortMoveAndAttack(pieceA, pieceB)
    local typeA = self._MainControl:GetPartnerPieceType(pieceA:GetConfigId())
    local typeB = self._MainControl:GetPartnerPieceType(pieceB:GetConfigId())

    if typeA ~= typeB then
        return SortPieceTypeByPower[typeA] < SortPieceTypeByPower[typeB]
    end

    local xA, yA = pieceA:GetPos()
    local xB, yB = pieceB:GetPos()

    --Y轴坐标从大到小，优先选择大的（最靠近“上”），目前左下角为原点
    if yA ~= yB then
        return yA > yB
    end

    --X轴坐标从小到大，优先选择小的（最靠近“左”）
    if xA ~= xB then
        return xA < xB
    end

    return pieceA:GetId() > pieceB:GetId()
end

function XBlackRockChessPartner:OnRoundEnd()
    if not self._Imp then
        return
    end
    self._Imp:OnRoundEnd()
    if self._MainControl:IsFightingStageEnd() then
        self._MainControl:RequestSyncRound()
    else
        self._MainControl:OnCancelSkill(true)
        self._MainControl:GetChessGamer():OnRoundBegin()
    end
end

---敌方棋子转生为友方棋子
function XBlackRockChessPartner:Transmigration(configId, guid, point, liveCd, hp)
    local tranId = self._MainControl:GetPieceTransPartnerPiece(configId)
    if not XTool.IsNumberValid(tranId) then
        return
    end
    local imp = XBlackRockChessManager:AddPartnerPiece(tranId, point.x, point.y)
    imp.Id = guid
    ---@type XBlackRockChessPartnerPiece
    local pieceInfo = self:AddEntity(XBlackRockChessPartnerPiece, guid, tranId)
    self._TransmigrationDict[guid] = pieceInfo
    self:AddPieceInfo(guid, pieceInfo)
    pieceInfo:TransformPiece(imp, liveCd, hp)
    --不需要通过ActionList发给服务端
end

---提前销毁存活回合为0的临时棋子
function XBlackRockChessPartner:UpdateTransmigration()
    for _, pieceInfo in pairs(self._TransmigrationDict) do
        -- 上回合是1 这回合为0 需要销毁
        if pieceInfo:GetLiveCd() <= 1 then
            self:RemovePieceInfo(pieceInfo:GetId())
        end
    end
end

---棋子转换
---@param pieceId number 挂载buff的棋子id
---@param imp XBlackRockChess.XPiece
function XBlackRockChessPartner:TransformPiece(pieceId, imp, originObjId, hitActorId, hitRoundCount)
    if XTool.UObjIsNil(imp) then
        return
    end
    local pieceInfo = self:GetPieceInfo(originObjId)
    if not pieceInfo or pieceInfo:IsPreview() or not pieceInfo:IsAlive() then
        imp:Disable()
        imp:Destroy()
        return
    end
    self._TransformDict[originObjId] = pieceInfo:GetLocalInfo()
    pieceInfo:TransformPiece(imp, imp.ConfigId)

    table.insert(self._ActionList, self:CreateAction(pieceId, XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.TRANSFORM, originObjId, imp.ConfigId, hitActorId, hitRoundCount))
end

function XBlackRockChessPartner:UpdateTransformPiece(id)
    if not self._TransformDict[id] then
        return
    end
    local info = self._TransformDict[id]
    local currentInfo = self:GetPieceInfo(id)
    if info.IsVirtual and currentInfo then
        local imp = currentInfo:GetLocalInfo().Imp
        local tmp = CS.XBlackRockChess.XBlackRockChessManager.Instance:Virtual2Piece(imp)
        if not tmp then
            self._MainControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_HIDE_PARTNER_HEAD_HUD, id)
            info.Imp:Destroy()
            self:RemovePieceInfo(id)
        else
            self._MainControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_PARTNER_HEAD_HUD, id, currentInfo:GetIconFollow())
        end
    end
    self._TransformDict[id] = nil
end

function XBlackRockChessPartner:GetActionList()
    local list = {}
    local isRevive = self._MainControl:GetChessGamer():IsRevive()
    local isTriggerProtect = self._MainControl:GetChessGamer():IsTriggerProtect()
    local isRestore = isRevive or isTriggerProtect

    for _, info in pairs(self._PieceInfoDict) do
        local iList = info:GetActionList(isRestore)
        list = XTool.MergeArray(list, iList)
    end

    --玩家死亡后，直接移除召唤 + 转换的虚影
    if isRestore then
        self:RestoreBuff()
    else
        list = XTool.MergeArray(list, self:GetValidActionList())
    end

    table.sort(list, function(a, b)
        local typeA = a.ActionType
        local typeB = b.ActionType
        if typeA ~= typeB then
            return SortPieceTypeByActionType[typeA] < SortPieceTypeByActionType[typeB]
        end
        local pieceA = self:GetPieceInfo(a.ObjId)
        local pieceB = self:GetPieceInfo(b.ObjId)
        if not pieceA and pieceB then
            return false
        end
        if not pieceB and pieceA then
            return true
        end
        if not pieceA and not pieceB then
            return false
        end
        return self:OnSortMoveAndAttack(pieceA, pieceB)
    end)

    return list
end

function XBlackRockChessPartner:GetValidActionList()
    local list = {}
    for _, action in pairs(self._ActionList) do
        if action.ActionType == XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.SUMMON then
            local insId = action.Params[2]
            local impData = self._SummonDict[insId]
            --虚影时判断该位置是否有棋子
            if impData and impData.IsVirtual then
                local point = impData.Imp.CurrentPoint
                --存在棋子，移除虚影召唤
                if CS.XBlackRockChess.XBlackRockChessManager.Instance:PieceAtCoord(point) then
                    CS.XBlackRockChess.XBlackRockChessManager.Instance:RestoreVirtualShadow(impData.Imp)
                    --因为这里还未生成实体，如果从棋盘上移除，会移除棋子的位置
                    impData.Imp:Destroy()
                    self._SummonDict[insId] = nil
                else
                    table.insert(list, action)
                end
            elseif impData then
                table.insert(list, action)
            end
        elseif action == XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.TRANSFORM then
            local insId = action.Params[1]
            local localInfo = self._TransformDict[insId]
            local info = self:GetPieceInfo(insId)
            if localInfo and info then
                --虚影时判断该位置是否有棋子
                if localInfo.IsVirtual then
                    local point = localInfo.Imp.CurrentPoint
                    --存在棋子，移除虚影召唤
                    if CS.XBlackRockChess.XBlackRockChessManager.Instance:PieceAtCoord(point) then
                        info:RestoreTransform(localInfo.Imp, localInfo.ConfigId, localInfo.IsVirtual)
                        self._TransformDict[insId] = nil
                    else
                        table.insert(list, action)
                    end
                else
                    table.insert(list, action)
                end
            end
        else
            table.insert(list, action)
        end

    end

    return list
end

---回合结束同步失败时重置数据
function XBlackRockChessPartner:Restore()
    self:RestoreBuff()
    for _, info in pairs(self._PieceInfoDict) do
        info:Restore()
    end
    self._ActionList = {}
end

function XBlackRockChessPartner:RestoreBuff()
    for _, action in pairs(self._ActionList) do
        if action.ActionType == XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.SUMMON then
            local insId = action.Params[2] or 0
            local impData = self._SummonDict[insId]
            if impData then
                CS.XBlackRockChess.XBlackRockChessManager.Instance:RestoreSummon(impData.Imp)
                if impData.IsVirtual then
                    CS.XBlackRockChess.XBlackRockChessManager.Instance:RestoreVirtualShadow(impData.Imp)
                end
            end
            self._SummonDict[insId] = nil
        elseif action.ActionType == XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.TRANSFORM then
            local insId = action.Params[1]
            local localInfo = self._TransformDict[insId]
            local info = self:GetPieceInfo(insId)
            if info then
                info:RestoreTransform(localInfo.Imp, localInfo.ConfigId, localInfo.IsVirtual)
            end
            self._TransformDict[insId] = nil
        end
    end
end

function XBlackRockChessPartner:ClearRetractData()
    self._DisableDict = {}
    self._RemoveDict = {}
    self._AllPieceDict = {}
end

function XBlackRockChessPartner:RetractData(formation)
    local id = formation.Guid
    local info = self:GetPieceInfo(id)
    --上个回合击杀了
    if info then
        --已经死亡但未同步
        local isDead = (not info:IsAlive())
        if isDead then
            self._DisableDict[id] = true
        end
        info:UpdateData(formation)
        self:UpdateTransformPiece(id)
        if not isDead then
            info:Sync()
        end
    else
        self._RemoveDict[id] = formation
    end
    self._AllPieceDict[id] = true
end

function XBlackRockChessPartner:Retract()
    if not XTool.IsTableEmpty(self._AllPieceDict) then
        local remove = {}
        for id, info in pairs(self._PieceInfoDict) do
            if not self._AllPieceDict[id] then
                remove[id] = id
                info:ForceDestroy()
            end
            --不是棋子，则变回虚影
            if not info:IsPiece() and not remove[id] then
                info:DoReinforcePreviewRetract()
            end
        end
        for id, info in pairs(remove) do
            self:RemovePieceInfo(id)
        end
    end
    --将隐藏的棋子重新显示
    for id, _ in pairs(self._DisableDict) do
        local info = self:GetPieceInfo(id)
        info:Restore()
    end
    --将移除的棋子重新加载
    for id, formation in pairs(self._RemoveDict) do
        local pieceInfo = formation.PieceInfo or {}
        local imp = CS.XBlackRockChess.XBlackRockChessManager.Instance:AddPartnerPiece(pieceInfo.PieceId,
                formation.X, formation.Y, formation.Type ~= XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.PARTNERPIECE)
        if imp then
            local info = self:AddEntity(XBlackRockChessPiece, id, pieceInfo.PieceId)
            self:AddPieceInfo(id, info)

            info:UpdateData(formation)
            info:SetImp(imp)
        end
    end
    self:RestoreBuff()
    local curRound = self._MainControl:GetChessRound() + 1
    local failList = self._FailReinforceList[curRound]
    if not XTool.IsTableEmpty(failList) then
        for _, info in pairs(failList) do
            info:DoReinforcePreviewRetract(true)
        end
        self._FailReinforceList[curRound] = nil
    end
end

---棋子召唤
---@param pieceId number 挂载buff的棋子id
---@param impList XBlackRockChess.XPiece[]
function XBlackRockChessPartner:Summon(pieceId, buffId, impList, isVirtual, effectCount, hitActorId, hitRoundCount)
    for i = 0, impList.Count - 1 do
        local imp = impList[i]
        if imp then
            self:SummonOne(pieceId, buffId, imp, isVirtual, effectCount, hitActorId, hitRoundCount)
        end
    end
end

function XBlackRockChessPartner:SummonOne(pieceId, buffId, imp, isVirtual, effectCount, hitActorId, hitRoundCount)
    self._MainControl:LoadVirtualEffect(imp, imp.ConfigId)
    local insId = self._MainControl:GetIncId()
    self._SummonDict[insId] = {
        Imp = imp,
        IsVirtual = isVirtual,
    }

    table.insert(self._ActionList, self:CreateAction(pieceId, XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.SUMMON,
            imp.ConfigId, insId, imp.CurrentPoint.x, imp.CurrentPoint.y, buffId, effectCount, hitActorId, hitRoundCount))
end

function XBlackRockChessPartner:CreateAction(objId, actionType, ...)
    return self._MainControl:CreateAction(objId, actionType, XEnumConst.BLACK_ROCK_CHESS.CHESS_OBJ_TYPE.PARTNER, ...)
end

function XBlackRockChessPartner:ProcessPieceEffect()
    for _, piece in pairs(self._PieceInfoDict) do
        piece:DoProcessBuffEffect()
    end
end

---@param cls any 实体的Class
---@return XBlackRockChessPiece
function XBlackRockChessPartner:AddEntity(cls, ...)
    ---@type XEntity
    local entity = cls.New(self._MainControl)
    local uid = entity:GetUid()

    local minUid = self._TypesMinUid[cls]
    if not minUid or minUid > uid then
        --记录一个最小id
        self._TypesMinUid[cls] = uid
    end

    self._EntitiesDict[uid] = entity

    local typesDict = self._EntitiesTypesDict[cls]
    if not typesDict then
        typesDict = {}
        self._EntitiesTypesDict[cls] = typesDict
    end

    typesDict[uid] = entity
    entity:__Init(...)
    return entity
end

function XBlackRockChessPartner:OnRelease()
    self._Imp = nil
    self._PieceInfoDict = {}
    self._PreparePieceInfoDict = {}
    self._ReinforceDict = {}
    self._TransmigrationDict = {}
    self._FailReinforceList = {}
    self._ActionList = {}
    self._SummonDict = {}
    self._TransformDict = {}
end

return XBlackRockChessPartner

---@class PartnerLayout
---@field X number
---@field Y number
---@field PieceId number
---@field Guid number

---@class PartnerSite
---@field Guid number
---@field PieceId number