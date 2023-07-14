-- 组合小游戏进度宝箱对象
local XComposeGameProgressTreasure = XClass(nil, "XComposeGameProgressTreasure")
local SortBySchedule = function(a, b)
    return a:GetSchedule() < b:GetSchedule()
end
--=============数据结构================
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
-- List<int> RecvSchedule
--=============================================

--==========商品信息ComposeShopInfo=============
-- 标志Id
-- int Id
-- 商品Id
-- int Goods
-- 是否已出售
-- bool IsSell
--=============================================
--=================== END =====================


--==========构造函数，初始化，实体操作==========
--==================
--构造函数
--@param Game:所属的活动对象
--@param ComposeGameDataDb:NotifyComposeActivityInfo通知活动信息
--==================
function XComposeGameProgressTreasure:Ctor(Game, ComposeGameDataDb)
    self.Game = Game
    self:Init()
    self:RefreshData(ComposeGameDataDb)
end
--==================
--初始化
--==================
function XComposeGameProgressTreasure:Init()
    self.Schedule = 0
    self.Treasures = {}
end
--==================
--刷新数据
--@param ComposeGameDataDb:NotifyComposeActivityInfo通知活动信息
--==================
function XComposeGameProgressTreasure:RefreshData(ComposeGameDataDb)
    if self.Schedule ~= ComposeGameDataDb.Schedule then
        self.Schedule = ComposeGameDataDb.Schedule
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_COMPOSEGAME_SCHEDULE_REFRESH)
    end
    local XTreasure = require("XEntity/XMiniGame/ComposeFactory/XComposeGameTreasureBox")
    local schedules = self.Game:GetSchedule()
    local rewardIds = self.Game:GetRewardId()
    local recvDic = {}
    for _, sche in pairs(ComposeGameDataDb.RecvSchedule) do
        recvDic[sche] = true
    end
    for i = 1, #schedules do
        local schedule = schedules[i]
        local rewardId = rewardIds[i]
        self.Treasures[schedule] = XTreasure.New(self, schedule, rewardId, recvDic[schedule])
    end
end

function XComposeGameProgressTreasure:SetSchedule(schedule)
    local targetSchedule = self.Schedule + schedule
    if self.Schedule ~= targetSchedule then
        self.Schedule = targetSchedule
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_COMPOSEGAME_SCHEDULE_REFRESH)
    end
end
--=================== END =====================

--=================对外接口(Get,Set,Check等接口)================
--==================
--获取背包格子列表
--==================
function XComposeGameProgressTreasure:SetIsReceiveBySchedule(schedule)
    if not self.Treasures[schedule] then
       return 
    end
    self.Treasures[schedule]:SetIsReceive(true)
end
--==================
--获取当前进度
--==================
function XComposeGameProgressTreasure:GetCurrentSchedule()
    return self.Schedule
end
--==================
--获取经过排序的宝箱对象列表
--==================
function XComposeGameProgressTreasure:GetTreasureBoxes()
    local list = {}
    for _, box in pairs(self.Treasures) do
        table.insert(list, box)
    end
    table.sort(list, SortBySchedule)
    return list
end
--=================== END =====================
return XComposeGameProgressTreasure