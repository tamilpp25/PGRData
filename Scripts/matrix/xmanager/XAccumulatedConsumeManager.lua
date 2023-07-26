XAccumulatedConsumeManagerCreator = function()
    local XAccumulatedConsumeManager = {}
    -------------------活动入口Start---------------------
    local XConsumeDrawActivityEntity = require("XEntity/XAccumulatedConsume/XConsumeDrawActivityEntity")
    local _ActivityId = XAccumulatedConsumeConfig.GetDefaultActivityId() --当前开发活动Id
    local _ConsumeDrawActivity = {}
    
    local function UpdateActivityId(activityId)
        if not XTool.IsNumberValid(activityId) then
            _ActivityId = XAccumulatedConsumeConfig.GetDefaultActivityId()
            return
        end
        
        _ActivityId = activityId
    end

    local function GetConsumeDraw(activityId)
        if not XTool.IsNumberValid(activityId) then
            XLog.Error("XAccumulatedConsumeManager GetConsumeDraw error: 活动Id错误, activityId: " .. activityId)
            return
        end

        local consumeDraw = _ConsumeDrawActivity[activityId]
        if not consumeDraw then
            consumeDraw = XConsumeDrawActivityEntity.New(activityId)
            _ConsumeDrawActivity[activityId] = consumeDraw
        end
        return consumeDraw
    end
    
    function XAccumulatedConsumeManager.GetConsumeDrawActivity()
        return GetConsumeDraw(_ActivityId)
    end
    
    function XAccumulatedConsumeManager.HandleActivityEndTime()
        XUiManager.TipText("ConsumeActivityOver")
        XLuaUiManager.RunMain()
    end
    
    -------------------活动入口End-----------------------
    -------------------抽奖入口Start--------------------- 
    local AccumulatedConsumeDrawDoDrawRequest = "AccumulatedConsumeDrawDoDrawRequest"  --抽奖请求
    local _DrawNum = 0 --当前抽奖次数（服务端通知）
    local _DrawCumulativeNum = 0 --当前累计次数（客户端累计 包含服务端下发的次数）
    
    local function UpdateDrawNum(count)
        _DrawNum = count or _DrawNum
        _DrawCumulativeNum = _DrawNum
    end
    
    --抽奖
    function XAccumulatedConsumeManager.ConsumeDrawDoDrawRequest(count, cb)
        local requestBody = { Count = count }
        XNetwork.CallWithAutoHandleErrorCode(
                AccumulatedConsumeDrawDoDrawRequest,
                requestBody,
                function(res)
                    if res.Code ~= XCode.Success then
                        XUiManager.TipCode(res.Code)
                        if cb then
                            cb(nil, nil)
                        end
                        return
                    end
                    _DrawCumulativeNum = _DrawCumulativeNum + count
                    if cb then
                        cb(res.DropRewardList, res.ProgressRewardList)
                    end
                end
        )
    end
    -------------------抽奖入口End-----------------------
    -------------------进度奖励Start---------------------
    function XAccumulatedConsumeManager.GetDrawCumulativeNum()
        return _DrawCumulativeNum
    end
    -------------------进度奖励End-----------------------
    -------------------规则说明Start---------------------
    local XConsumeDrawRuleEntity = require("XEntity/XAccumulatedConsume/XConsumeDrawRuleEntity")
    local _ConsumeDrawRule = {}

    local function GetConsumeDrawRule(drawId)
        if not XTool.IsNumberValid(drawId) then
            XLog.Error("XAccumulatedConsumeManager GetConsumeDrawRule error, drawId: " .. drawId)
            return
        end

        local consumeDrawRule = _ConsumeDrawRule[drawId]
        if not consumeDrawRule then
            consumeDrawRule = XConsumeDrawRuleEntity.New(drawId)
            _ConsumeDrawRule[drawId] = consumeDrawRule
        end
        return consumeDrawRule
    end
    
    function XAccumulatedConsumeManager.GetConsumeDrawRule()
        ---@type ConsumeDrawActivityEntity
        local consumeDraw = XAccumulatedConsumeManager.GetConsumeDrawActivity()
        local drawId = consumeDraw:GetDrawId()
        return GetConsumeDrawRule(drawId)
    end
    -------------------规则说明End-----------------------

    local function ResetData()
        _ActivityId = 0 --当前开放活动Id
        _ConsumeDrawRule = {}
        _DrawCumulativeNum = 0
        _DrawNum = 0
    end
    
    ---@desc 服务端下发信息
    --[[  public sealed class NotifyAccumulatedConsumeDrawData
    --    {
    --        // 活动Id
    --        public int ActId;
    --        // 当前抽奖次数
    --        public int DrawNum;
    --        // 已领取进度奖励
    --        public List<XAccumulatedConsumeDrawRecv> RecvInfo = new List<XAccumulatedConsumeDrawRecv>();
    --    }
    ]]
    function XAccumulatedConsumeManager.NotifyAccumulatedConsumeDrawData(data)
        local activityId = data.ActId

        if XTool.IsNumberValid(_ActivityId) and activityId ~= _ActivityId then
            ResetData()
        end
        
        UpdateActivityId(activityId)
        UpdateDrawNum(data.DrawNum)

        XAccumulatedConsumeManager.GetShopInfo()
    end
    
    -- 玩家尚未搬空代币商店，且有可够买商品
    function XAccumulatedConsumeManager.CheckCanBuyGoods()
        -----@type ConsumeDrawActivityEntity
        local consumeDraw = XAccumulatedConsumeManager.GetConsumeDrawActivity()
        local itemId = consumeDraw:GetShopCoinItemId()
        local itemCount = XDataCenter.ItemManager.GetCount(itemId)
        -- 代币已搬空
        if not XTool.IsNumberValid(itemCount) then
            return false
        end

        local infoList = XShopManager.GetShopBaseInfoByTypeAndTag(XShopManager.ShopType.AccumulateConsume)
        if XTool.IsTableEmpty(infoList) then
            XAccumulatedConsumeManager.GetShopInfo()
            return false
        end
        local shopId = consumeDraw:GetShopId()
        if not XTool.IsNumberValid(shopId) then
            return false
        end
        local shopGoods = XShopManager.GetShopGoodsList(shopId)
        for _, good in pairs(shopGoods or {}) do
            -- 售罄
            if good.TotalBuyTimes >= good.BuyTimesLimit then
                goto CONTINUE
            end
            -- 价格
            for _, count in pairs(good.ConsumeList) do
                if count.Id == itemId and count.Count <= itemCount then
                    return true
                end
            end
            :: CONTINUE ::
        end
        
        return false
    end
    
    local isOnce = false
    function XAccumulatedConsumeManager.GetShopInfo()
        if isOnce then
            return
        end
        -- 红点检测需要使用到商品信息
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon, false, true)
                or XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopActive, false, true) then
            isOnce = true
            ---@type ConsumeDrawActivityEntity
            local consumeDraw = XAccumulatedConsumeManager.GetConsumeDrawActivity()
            local shopId = consumeDraw:GetShopId()
            XShopManager.ClearBaseInfoData()
            XShopManager.GetBaseInfo(function()
                XShopManager.GetShopInfo(shopId, nil, true)
            end)
        end
    end

    -- Skip累消活动
    function XAccumulatedConsumeManager.OnOpenActivityMain()
        ---@type ConsumeDrawActivityEntity
        local consumeDraw = XAccumulatedConsumeManager.GetConsumeDrawActivity()
        if not consumeDraw:CheckActivityTimeout(true) then
            XLuaUiManager.Open("UiConsumeActivityMain")
        end
    end

    -- Skip福袋抽卡
    function XAccumulatedConsumeManager.OnOpenLuckyBag()
        ---@type ConsumeDrawActivityEntity
        local consumeDraw = XAccumulatedConsumeManager.GetConsumeDrawActivity()
        if not consumeDraw:CheckLuckyTimeout(true) then
            XLuaUiManager.Open("UiConsumeActivityLuckyBag")
        end
    end
    -- Skip福行商商店
    function XAccumulatedConsumeManager.OpenActivityShop()
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon)
                or XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopActive) then
            ---@type ConsumeDrawActivityEntity
            local consumeDraw = XAccumulatedConsumeManager.GetConsumeDrawActivity()
            local shopId = consumeDraw:GetShopId()
            XShopManager.GetShopInfo(shopId, function()
                XLuaUiManager.Open("UiConsumeActivityShop")
            end)
        end
    end
    
    function XAccumulatedConsumeManager.Init()
       
    end
    
    XAccumulatedConsumeManager.Init()
    return XAccumulatedConsumeManager
end

XRpc.NotifyAccumulatedConsumeDrawData = function(data)
    XDataCenter.AccumulatedConsumeManager.NotifyAccumulatedConsumeDrawData(data)
end