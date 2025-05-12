---@class XBlackRockChessShop : XControl 局内商店信息
---@field _MainControl XBlackRockChessControl 主控制器
---@field _Coin number 金币
---@field _ShopId number 商店Id
---@field _RefreshTimes number 已刷新次数
---@field _Goods table<number,number> 商品列表<商品Id,数量>
---@field _BuffDict XBlackRockChess.XBuff[] 商店里购买的buff
---@field _OverlayDict number[] buff叠加层数
local XBlackRockChessShop = XClass(XControl, "XBlackRockChessShop")

function XBlackRockChessShop:OnInit()
    self._BuffDict = {}
    self._OverlayDict = {}
end

function XBlackRockChessShop:UpdateBaseInfo(info)
    self:UpdateCoin(info.Coin or 0)
    self:UpdateShopData(info.ShopData)
    self._BuyPieceCount = XTool.GetTableCount(info.PartnerPieces)
    self:UpdateShopBuff(info.BuffList)
    self._MainControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_SHOP)
end

function XBlackRockChessShop:UpdateShopData(info)
    if not info then
        self._ShopId = nil
        self._RefreshTimes = 0
        self._Goods = {}
        return
    end
    
    self._ShopId = info.ShopId
    self._RefreshTimes = info.RefreshTimes
    self._Goods = {}
    for i, data in ipairs(info.Goods) do
        self._Goods[i] = {
            GoodsId = data.Id,
            Count = data.Count
        }
    end
end

function XBlackRockChessShop:UpdateShopBuff(buffList)
    self._buffIds = {}
    for _, data in pairs(buffList) do
        local buffId = data.BuffId
        local imp = self._BuffDict[buffId]
        if data.RemainRound == 0 or data.RemainNode == 0 then
            --失效            
            if imp then
                imp:Release()
                self._BuffDict[buffId] = nil
            end
        else
            if not imp then
                local buffType = self._MainControl:GetBuffType(buffId)
                local buff = CS.XBlackRockChess.XBlackRockChessUtil.CreateBuff(buffType)
                if buff then
                    local args = self._MainControl:GetBuffParams(buffId)
                    self._BuffDict[buffId] = buff
                    buff:DoApply(buffId, nil, table.unpack(args))
                    buff:AddTakeEffectCb(handler(self, self.OnBuffTakeEffect))

                    if buff:IsEffectiveByStageInit() then
                        buff:DoTakeEffect()
                    end
                end
            end
            table.insert(self._buffIds, buffId)
        end
        self._OverlayDict[buffId] = data.Overlays
    end
end

function XBlackRockChessShop:OnBuffTakeEffect(args)
    self._MainControl:OnBuffTakeEffect(args)
end

function XBlackRockChessShop:OnRelease()
    self._Goods = {}
    for _, imp in pairs(self._BuffDict) do
        imp:Release()
    end
    self._BuffDict = {}
    self._OverlayDict = {}
end

function XBlackRockChessShop:UpdateCoin(count)
    self._Coin = count
end

function XBlackRockChessShop:GetGoods()
    return self._Goods
end

function XBlackRockChessShop:GetCoin()
    return self._Coin
end

function XBlackRockChessShop:GetShopId()
    return self._ShopId
end

function XBlackRockChessShop:GetRefreshTimes()
    return self._RefreshTimes
end

function XBlackRockChessShop:GetBuyPieceCount()
    return self._BuyPieceCount
end

function XBlackRockChessShop:GetBuffIds()
    return self._buffIds
end

function XBlackRockChessShop:GetBuffOverlay(buffId)
    return self._OverlayDict[buffId] or 0
end

return XBlackRockChessShop