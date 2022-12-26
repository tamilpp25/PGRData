-- 组合小游戏管理器
XComposeGameManagerCreator = function()
    local XComposeGameManager = {}
    --========================================
    --[[
    *********搜索以下关键字快速到达该类方法模块*********
    =========协议数据结构
    =========成员变量
    =========字典
    =========初始化管理器，基础对象，对象刷新方法
    =========请求协议方法
    =========外部接口方法
    =========XRpc通知协议
    ]]--

    --=============协议数据结构================

    --======活动信息ComposeGameDataDb=============
    -- 活动Id
    -- int ActId
    -- 当前进度
    -- int Schedule
    -- 刷新次数
    -- int RefreshCount
    -- 增加刷新次数时间戳(为 0 表示已达上限)
    -- int RefreshTime
    -- 商品列表
    -- List<int> GoodsList
    -- 商店列表
    -- List<ComposeShopInfo> ShopInfos
    -- 已领取奖励列表
    -- List<int> RecvRewards
    --=============================================

    --==========商品信息ComposeShopInfo=============
    -- 标志Id
    -- int Id
    -- 商品Id
    -- int Goods
    -- 是否已出售
    -- bool IsSell
    --=============================================

    --==========刷新商店数据ComposeRefreshData=====
    -- 活动Id
    -- int ActId
    -- 今日刷新次数
    -- int RefreshCount
    -- 增加刷新次数时间戳(为 0 表示已达上限)
    -- int RefreshTime
    --==============================================

    --==========背包物品列表信息ComposeGoodsInfo=====
    -- 活动Id
    -- int ActId
    -- 背包物品列表
    -- List<int> GoodsList
    --==============================================
    --============= END ================

    --============成员变量==============
    --================
    --是否从服务器接收了活动通知
    --================
    local ReceiveNotify = false
    --================
    --活动对象集合
    --================
    local Games = {}
    --============= END ================

    --==============字典================
    --================
    --请求协议名称
    --================
    local REQUEST_NAMES = { --请求名称
        BuyShopGoods = "ComposeBuyShopGoodsRequest", -- 购买商店物品
        RefreshShopList = "ComposeFlushShopRequest", -- 刷新商店商品
        GetReward = "ComposeScheduleRewardRequest", -- 领取合成进度奖励
    }
    --============= END ================

    --==============玩法常量================
    --================
    --是否DEBUG模式(调试模式输出打印，取本地时间等)
    --================
    XComposeGameManager.DEBUG_MODE = false
    --================
    --背包格子数量
    --================
    XComposeGameManager.BAG_GRIDS_NUM = 8
    --============= END ================

    --=====================================
    --==============初始化管理器，活动对象处理方法================

    --================
    --管理器初始化方法
    --================
    function XComposeGameManager.Init()
        local config = XComposeGameConfig.GetDefaultConfig()
        if config then
            XComposeGameManager.DEBUG_MODE = config.DebugMode and config.DebugMode == 1
        end
    end
    --================
    --接收活动通知
    --================
    function XComposeGameManager.OnNotifyComposeActivityInfo(ComposeGameDataDb)
        local game = Games[ComposeGameDataDb.ActId]
        if not game then
            XComposeGameManager.DebugLog(
                "组合小游戏接收协议:NotifyComposeActivityInfo, 接收到新活动通知, 准备新增活动对象:",
                ComposeGameDataDb
            )
            XComposeGameManager.AddGame(ComposeGameDataDb)
        else
            XComposeGameManager.DebugLog(
                "组合小游戏接收协议:NotifyComposeActivityInfo, 接收到活动刷新通知, 准备刷新活动对象:",
                ComposeGameDataDb
            )
            game:RefreshComposeGameData(ComposeGameDataDb)
        end
    end
    --================
    --接收商店刷新数据ComposeRefreshData
    --================
    function XComposeGameManager.OnNotifyComposeRefreshData(ComposeRefreshData)
        local game = Games[ComposeRefreshData.ActId]
        if not game then
            XComposeGameManager.DebugLog("OnNotifyComposeFlushShopInfo错误，原因：找不到对应活动ID的活动对象。 ActId:" .. tostring(ComposeRefreshData.ActId))
            return
        end
        game:SetRefreshStatus(ComposeRefreshData)
    end
    --================
    --接收背包刷新数据ComposeGoodsInfo
    --================
    function XComposeGameManager.OnNotifyComposeGoodsInfo(ComposeGoodsInfo)
        local game = Games[ComposeGoodsInfo.ActId]
        if not game then
            XComposeGameManager.DebugLog("OnNotifyComposeGoodsInfo错误，原因：找不到对应活动ID的活动对象。 ActId:" .. tostring(ComposeGoodsInfo.ActId))
            return
        end
        game:SetRefreshStatus(ComposeGoodsInfo)
    end
    --================
    --添加一个新活动
    --================
    function XComposeGameManager.AddGame(ComposeGameDataDb)
        local XComposeGame = require("XEntity/XMiniGame/ComposeFactory/XComposeGame")
        if XComposeGame then
            Games[ComposeGameDataDb.ActId] = XComposeGame.New(ComposeGameDataDb)
        end
    end
    --================
    --Debug方法
    --================
    function XComposeGameManager.DebugLog(...)
        if not XComposeGameManager.DEBUG_MODE then return end
        XLog.Debug(...)
    end
    --============= END ================
    --==============外部接口方法================

    --===============
    --根据活动ID获取活动对象
    --@param gameId:活动ID
    --===============
    function XComposeGameManager.GetGameById(gameId)
        local game = Games[gameId]
        if not game then
            XComposeGameManager.DebugLog("XComposeGameManager.GetGameById获取组合小游戏活动对象失败，GameId:", gameId)
            return nil
        end
        XComposeGameManager.DebugLog("获取组合小游戏活动对象成功，GameId:", gameId)
        return game
    end  
    --================
    --判断是否第一次进入玩法(本地存储纪录)
    --@param gameId:活动ID
    --================
    function XComposeGameManager.GetIsFirstIn(gameId)
        if not gameId then return false end
        local localData = XSaveTool.GetData("ComposeGameFirstIn" .. XPlayer.Id .. tostring(gameId))
        if localData == nil then
            XSaveTool.SaveData("ComposeGameFirstIn".. XPlayer.Id .. tostring(gameId), true)
            return true
        end
        return false
    end
    --================
    --判断是否新获得道具
    --@param gameId:活动ID
    --================
    function XComposeGameManager.GetItemIsNew(gameId, itemId)
        local game = Games[gameId]
        if not game then
            XComposeGameManager.DebugLog("XComposeGameManager.GetGameById获取组合小游戏活动对象失败，GameId:", gameId)
            return nil
        end
        XComposeGameManager.DebugLog("获取组合小游戏活动对象成功，GameId:", gameId)
        return game:GetItemIsNew(itemId)
    end
    --===============
    --跳转到组合小游戏
    --@param gameId:活动ID
    --===============
    function XComposeGameManager.JumpTo(gameId)
        local game = XComposeGameManager.GetGameById(gameId)
        if not game then return end
        local canGoTo, notStart = game:CheckIsOpenTime()
        if canGoTo then
            XLuaUiManager.Open("UiComposeGame", gameId)
        elseif notStart then
            XUiManager.TipMsg(CS.XTextManager.GetText("ComposeGameNotStart"))
        else
            XUiManager.TipMsg(CS.XTextManager.GetText("ComposeGameNotInTime"))
        end
    end
    
    function XComposeGameManager.BuyItem(shopGrid)
        local item = shopGrid:GetItem()
        local game = Games[item:GetGameId()]
        if not game then
            XComposeGameManager.DebugLog("XComposeGameManager.BuyItem获取组合小游戏活动对象失败，GameId:", gameId)
            return nil
        end
        local canBuy, desc = game:CheckCanBuyItem(item)
        if canBuy then
            XNetwork.Call(REQUEST_NAMES.BuyShopGoods, { ShopId = shopGrid:GetBuyId() }, function(reply)
                    if reply.Code ~= XCode.Success then
                        XUiManager.TipCode(reply.Code)
                        return
                    end
                    game:BuyItem(item:GetId())
                    shopGrid:Buy()
                    CsXGameEventManager.Instance:Notify(XEventId.EVENT_COMPOSEGAME_BAGITEM_REFRESH)
                end)
        else
            XUiManager.TipMsg(desc)
        end
    end
    
    function XComposeGameManager.RefreshShop(gameId)
        local game = XComposeGameManager.GetGameById(gameId)
        if not game then return end
        local canRefresh = game:CheckCanRefresh()
        if canRefresh then
            XNetwork.Call(REQUEST_NAMES.RefreshShopList, {}, function(reply)
                    if reply.Code ~= XCode.Success then
                        XUiManager.TipCode(reply.Code)
                        return
                    end
                    game:RefreshShopInfoList(reply.ShopInfo)
                    CsXGameEventManager.Instance:Notify(XEventId.EVENT_COMPOSEGAME_SHOP_ITEM_REFRESH)
                end)
        end
    end
    
    function XComposeGameManager.GetReward(gameId, box)
        XNetwork.Call(REQUEST_NAMES.GetReward, { Schedule = box:GetSchedule() }, function(reply)
                if reply.Code ~= XCode.Success then
                    XUiManager.TipCode(reply.Code)
                    return
                end
                box:SetIsReceive(true)
                XUiManager.OpenUiObtain(reply.RewardGoodsList)
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_COMPOSEGAME_TREASURE_GET)
            end)
    end
    --============= END ================
    XComposeGameManager.Init()
    return XComposeGameManager
end
--========================================
--=============XRpc通知协议================
--====数据结构参照本文件的"协议数据结构"=====
--==============
--通知合成活动数据
--@param ComposeGameDataDb:活动信息
--==============
XRpc.NotifyComposeActivityData = function(ComposeGameDataDb)
    XDataCenter.ComposeGameManager.DebugLog("接受到NotifyComposeActivityInfo数据，数据：", ComposeGameDataDb)
    XDataCenter.ComposeGameManager.OnNotifyComposeActivityInfo(ComposeGameDataDb)
end
--==============
--通知刷新商店数据
--@param ComposeFlushShopInfo:刷新商店数据
--==============
XRpc.NotifyComposeRefreshData = function(ComposeRefreshData)
    XDataCenter.ComposeGameManager.DebugLog("接受到NotifyComposeRefreshData数据，数据：", ComposeRefreshData)
    XDataCenter.ComposeGameManager.OnNotifyComposeRefreshData(ComposeRefreshData)
end
--==============
--通知背包物品列表
--@param composeGoodsInfo:背包物品列表
--==============
XRpc.NotifyComposeGoodsData = function(ComposeGoodsInfo)
    XDataCenter.ComposeGameManager.DebugLog("接受到NotifyComposeGoodsInfo数据，数据：", ComposeGoodsInfo)
    --XDataCenter.ComposeGameManager.OnNotifyComposeGoodsInfo(ComposeGoodsInfo)
end
--============= END ================