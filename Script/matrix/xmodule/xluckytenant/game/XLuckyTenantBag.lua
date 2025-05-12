--local XLuckyTenantPiece = require("XModule/XLuckyTenant/Game/XLuckyTenantPiece")
local XLuckyTenantEnum = require("XModule/XLuckyTenant/Game/XLuckyTenantEnum")

---@class XLuckyTenantBag
local XLuckyTenantBag = XClass(nil, "XLuckyTenantBag")

function XLuckyTenantBag:Ctor()
    ---@type XLuckyTenantPiece[]
    self._Pieces = {}

    ---@type XLuckyTenantPiece[]
    self._Props = {}

    self._Uid = 0
    local createFunc = function()
        local XLuckyTenantPiece = require("XModule/XLuckyTenant/Game/XLuckyTenantPiece")
        return XLuckyTenantPiece.New()
    end
    ---@param piece XLuckyTenantPiece
    local releaseFunc = function(piece)
        piece:Clear()
    end
    ---@type XPool
    self._Pool = XPool.New(createFunc, releaseFunc)

    self._PiecesAmount = 0
    self._MaxPiecesAmount = 99

    -- 被删掉的，需要纪录下来
    self._PieceDeleted = {}
    self._PieceDeletedDictionary = {}

    self._IsTagDirty = true
    self._Tag = {}
end

---@param config XTableLuckyTenantStage
---@param game XLuckyTenantGame
function XLuckyTenantBag:Init(model, config, isResumeGame, game)
    if not config then
        XLog.Error("[XLuckyTenantBag] config不存在")
        return
    end
    self._MaxPiecesAmount = config.BagCapacity
    if isResumeGame then
        return
    end
    local initialPiece = config.InitialPiece
    local initialPieceAmount = config.InitialPieceNum
    for i = 1, #initialPiece do
        local pieceId = initialPiece[i]
        local pieceAmount = initialPieceAmount[i] or 1
        game:AddNewPieceToBag(model, pieceId)
        for i = 2, pieceAmount do
            game:AddNewPieceToBag(model, pieceId)
        end
    end

    if config.InitialPieceGroup > 0 then
        local elements = {}
        game:GetRandomBucketByGroupId(elements, model, config.InitialPieceGroup)
        local selected = game:RandomSelect(model, elements, config.InitialPieceGroupAmount)
        for i = 1, #selected do
            ---@type XTableLuckyTenantChessRandomGroup
            local groupConfig = selected[i]
            local pieceId = groupConfig.PieceId
            game:AddNewPieceToBag(model, pieceId)
        end
    end
    self:InitProps(game, model)
    self._IsTagDirty = true
end

---@param game XLuckyTenantGame
---@param model XLuckyTenantModel
function XLuckyTenantBag:InitProps(game, model)
    for name, id in pairs(XLuckyTenantEnum.PropId) do
        local itemType = model:GetLuckyTenantChessTypeById(id)
        local prop = self:GetProp(itemType)
        if not prop then
            ---@type XLuckyTenantPiece
            local isSuccess, piece = game:AddNewPieceToBag(model, id)
            if isSuccess then
                piece:SetAmount(0)
                self._PiecesAmount = self._PiecesAmount + 1
            else
                XLog.Error("[XLuckyTenantBag] 道具初始化失败，背包上限过小")
            end
        end
    end
end

function XLuckyTenantBag:GetNewUid()
    self._Uid = self._Uid + 1
    return self._Uid
end

---@return XLuckyTenantPiece
function XLuckyTenantBag:NewPiece(model, pieceId, uid)
    if uid then
        if self._Uid < uid then
            self._Uid = uid
        end
    else
        uid = self:GetNewUid()
    end
    local pieceConfig = model:GetLuckyTenantChessConfigById(pieceId)
    if not pieceConfig then
        XLog.Error("[XLuckyTenantGame] 不存在的棋子:" .. tostring(pieceId))
    end
    ---@type XLuckyTenantPiece
    local piece = self._Pool:GetItemFromPool()
    piece:Set(uid, pieceConfig)
    return piece
end

function XLuckyTenantBag:EnterPool(piece)
    self._Pool:ReturnItemToPool(piece)
end

---@param item XLuckyTenantPiece
function XLuckyTenantBag:AddPiece(item)
    self._IsTagDirty = true
    local uid = item:GetUid()
    if self._Pieces[uid] then
        local newUid = self:GetNewUid()
        item:Set(newUid)
        XLog.Error("[XLuckyTenantBag] 有问题, 重复的Uid:" .. tostring(uid), "替换为" .. newUid)
    end

    if item:IsProp() then
        local type = item:GetPieceType()
        local prop = self._Props[type]
        if not prop then
            self._Props[type] = item
        else
            local amount = item:GetAmount()
            if amount == 0 then
                XLog.Error("[XLuckyTenantBag] 获得道具，但是道具数量为0？有问题")
                return false
            end
            prop:SetAmount(prop:GetAmount() + amount)
        end
        return true
    end
    if item:IsPiece() then
        if self._Pieces[uid] then
            XLog.Error("[XLuckyTenantBag] 背包重复插入棋子:" .. uid)
            return false
        end
        if self._PiecesAmount >= self._MaxPiecesAmount then
            XLog.Error("[XLuckyTenantBag] 背包数量过多，添加失败，超过" .. self._MaxPiecesAmount)
            return false
        end
        self._Pieces[uid] = item
        self._PiecesAmount = self._PiecesAmount + 1
        return true
    end
    XLog.Error("[XLuckyTenantBag] 未定义的物品类型" .. tostring(item:GetPieceType()))
end

function XLuckyTenantBag:DeletePieceByUid(uid)
    self._IsTagDirty = true
    local piece = self:GetPiece(uid)
    if piece then
        local id = piece:GetId()
        self._PieceDeleted[#self._PieceDeleted + 1] = id
        self._Pieces[uid] = nil
        self._PieceDeletedDictionary[id] = (self._PieceDeletedDictionary[id] or 0) + 1
        self:EnterPool(piece)
        self._PiecesAmount = self._PiecesAmount - 1
        if self._PiecesAmount < 0 then
            XLog.Error("[XLuckyTenantBag] 背包数量计算错误，小于0")
            self._PiecesAmount = 0
        end
    end
end

---@return XLuckyTenantPiece
function XLuckyTenantBag:GetPiece(uid)
    return self._Pieces[uid]
end

---@return XLuckyTenantPiece
function XLuckyTenantBag:GetProp(type)
    return self._Props[type]
end

function XLuckyTenantBag:GetPropAmount(type)
    local prop = self._Props[type]
    if prop then
        return prop:GetAmount()
    end
    return 0
end

---@return XLuckyTenantPiece[]
function XLuckyTenantBag:GetPieces()
    return self._Pieces
end

function XLuckyTenantBag:FindPiece(pieceId, excludedList)
    for i, piece in pairs(self._Pieces) do
        if (not excludedList) or (not excludedList[piece:GetUid()]) then
            if piece:GetId() == pieceId then
                return piece
            end
        end
    end
end

function XLuckyTenantBag:GetPiecesAmount()
    local amount = 0
    for i, v in pairs(self._Pieces) do
        amount = amount + 1
    end
    return amount
end

function XLuckyTenantBag:GetDeletedPieceAmount()
    return #self._PieceDeleted
end

function XLuckyTenantBag:GetDeletedPieceAmountById(pieceId)
    return self._PieceDeletedDictionary[pieceId] or 0
end

function XLuckyTenantBag:ReducePropAmount(type)
    local prop = self:GetProp(type)
    if prop then
        local amount = math.max(prop:GetAmount() - 1, 0)
        prop:SetAmount(amount)
    end
end

--function XLuckyTenantBag:GetTagAmount(tag)
--    local tagAmount = 0
--    for uid, piece in pairs(self._Pieces) do
--        if piece:HasTag(tag) then
--            tagAmount = tagAmount + 1
--        end
--    end
--    return tagAmount
--end

function XLuckyTenantBag:GetPieceAmountById(pieceId)
    local pieceAmount = 0
    for uid, piece in pairs(self._Pieces) do
        if piece:GetId() == pieceId then
            pieceAmount = pieceAmount + 1
        end
    end
    return pieceAmount
end

function XLuckyTenantBag:GetEncodeMessage(log)
    local grids = {}
    local pieces = self:GetPieces()
    for uid, piece in pairs(pieces) do
        local pieceParams = piece:GetParamsEncodeMessage()
        local message = XMessagePack.Encode(pieceParams)
        if uid ~= piece:GetUid() then
            XLog.Error("[XLuckyTenantBag] encode有错误, pieceUId与背包key不相等")
        else
            grids[#grids + 1] = {
                ChessId = piece:GetId(),
                Uid = piece:GetUid(),
                ChessParams = message,
            }
            if log then
                log[#log + 1] = {
                    ChessId = piece:GetId(),
                    Uid = piece:GetUid(),
                    ChessParams = pieceParams,
                }
            end
        end
    end
    for type, piece in pairs(self._Props) do
        local pieceParams = piece:GetParamsEncodeMessage()
        local message = XMessagePack.Encode(pieceParams)
        grids[#grids + 1] = {
            ChessId = piece:GetId(),
            Uid = piece:GetUid(),
            ChessParams = message,
        }
        if log then
            log[#log + 1] = {
                ChessId = piece:GetId(),
                Uid = piece:GetUid(),
                ChessParams = pieceParams,
            }
        end
    end

    return grids
end

function XLuckyTenantBag:UpdateTag()
    for tag, amount in pairs(self._Tag) do
        self._Tag[tag] = nil
    end
    for uid, piece in pairs(self._Pieces) do
        local tags = piece:GetTag()
        for i = 1, #tags do
            local tag = tags[i]
            self._Tag[tag] = self._Tag[tag] or 0
            self._Tag[tag] = self._Tag[tag] + 1
        end
    end
end

function XLuckyTenantBag:GetTag()
    local isDirty = self._IsTagDirty
    if self._IsTagDirty then
        self:UpdateTag()
        self._IsTagDirty = false
    end
    return self._Tag, isDirty
end

function XLuckyTenantBag:GetTagAmount(tag)
    return self._Tag[tag] or 0
end

return XLuckyTenantBag
