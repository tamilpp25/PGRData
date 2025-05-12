---@class XTheatre4Grid
local XTheatre4Grid = XClass(nil, "XTheatre4Grid")

function XTheatre4Grid:Ctor()
    -- 格子配置Id(不一定有)
    self.GridId = 0
    -- 颜色
    self.Color = 0
    -- 颜色资源值
    self.ColorResource = 0
    -- 内容类型
    self.Type = 0
    -- x坐标
    self.PosX = 0
    -- y坐标
    self.PosY = 0
    -- 探索状态
    self.State = 0
    -- 通用参数(根据格子类型可表示宝箱GroupId、战斗节点GroupId,商店GroupId,事件GroupId)
    self.ContentGroup = 0
    -- 内容id（战斗Id、掉落id）
    self.ContentId = 0
    -- 战斗数据
    ---@type XTheatre4Fight
    self.Fight = nil
    -- 商店数据（类型为商店翻格后生成）
    ---@type XTheatre4Shop
    self.Shop = nil
    -- 事件数据（类型为事件翻格后生成）
    ---@type XTheatre4Event
    self.Event = nil
    -- 建筑数据
    ---@type XTheatre4Building
    self.Building = nil

    -- 长
    self.Length = 1
    -- 宽
    self.Width = 1
    
    -- 将被禁用/摧毁的天数
    self.DisabledDay = 0
end

-- 服务端通知
function XTheatre4Grid:NotifyGridData(data)
    self.GridId = data.GridId or 0
    self.Color = data.Color or 0
    self.ColorResource = data.ColorResource or 0
    self.Type = data.Type or 0
    self.PosX = data.PosX or 0
    self.PosY = data.PosY or 0
    self.State = data.State or 0
    self.ContentGroup = data.ContentGroup or 0
    self.ContentId = data.ContentId or 0
    self.DisabledDay = data.DisabledDay or 0
    self:UpdateFight(data.Fight)
    self:UpdateShop(data.Shop)
    self:UpdateEvent(data.Event)
    self:UpdateBuilding(data.Building)
end

function XTheatre4Grid:UpdateFight(data)
    if not data then
        self.Fight = nil
        return
    end
    if not self.Fight then
        self.Fight = require("XModule/XTheatre4/XEntity/XTheatre4Fight").New()
    end
    self.Fight:NotifyFightData(data)
end

function XTheatre4Grid:UpdateShop(data)
    if not data then
        self.Shop = nil
        return
    end
    if not self.Shop then
        self.Shop = require("XModule/XTheatre4/XEntity/XTheatre4Shop").New()
    end
    self.Shop:NotifyShopData(data)
end

function XTheatre4Grid:UpdateEvent(data)
    if not data then
        self.Event = nil
        return
    end
    if not self.Event then
        self.Event = require("XModule/XTheatre4/XEntity/XTheatre4Event").New()
    end
    self.Event:NotifyEventData(data)
end

function XTheatre4Grid:UpdateBuilding(data)
    if not data then
        self.Building = nil
        return
    end
    if not self.Building then
        self.Building = require("XModule/XTheatre4/XEntity/XTheatre4Building").New()
    end
    self.Building:NotifyBuildingData(data)
end

-- 获取格子Id
function XTheatre4Grid:GetGridId()
    return 100 * 100 + self.PosX * 100 + self.PosY
end

-- 获取格子坐标
function XTheatre4Grid:GetGridPos()
    return self.PosX, self.PosY
end

-- 获取格子颜色
function XTheatre4Grid:GetGridColor()
    return self.Color
end

-- 获取格子颜色资源
function XTheatre4Grid:GetGridColorResource()
    return self.ColorResource
end

-- 获取格子类型
function XTheatre4Grid:GetGridType()
    return self.Type
end

-- 获取格子状态
function XTheatre4Grid:GetGridState()
    return self.State
end

-- 获取格子内容组
function XTheatre4Grid:GetGridContentGroup()
    return self.ContentGroup
end

-- 获取格子内容Id
function XTheatre4Grid:GetGridContentId()
    return self.ContentId
end

-- 获取格子战斗组Id
function XTheatre4Grid:GetGridFightGroupId()
    if not self.Fight then
        return 0
    end
    return self.Fight:GetFightGroupId()
end

-- 获取格子战斗Id
function XTheatre4Grid:GetGridFightStageId()
    if not self.Fight then
        return 0
    end
    return self.Fight:GetStageId()
end

-- 获取格子血量百分比
function XTheatre4Grid:GetGridHpPercent()
    if not self.Fight then
        return 0
    end
    local hpPercent = self.Fight:GetHpPercent()
    hpPercent = math.floor(hpPercent / 100)
    -- 血量最低为1%
    if hpPercent <= 0 then
        hpPercent = 1
    end
    return hpPercent
end

-- 获取格子惩罚倒计时
function XTheatre4Grid:GetGridPunishCountdown()
    if not self.Fight then
        return -1
    end
    return self.Fight:GetPunishCountdown()
end

-- 获取格子战斗事件
---@return number[]
function XTheatre4Grid:GetGridFightEvents()
    if not self.Fight then
        return nil
    end
    return self.Fight:GetFightEvents()
end

-- 获取格子战斗奖励
---@return XTheatre4Asset[]
function XTheatre4Grid:GetGridFightRewards()
    if not self.Fight then
        return nil
    end
    return self.Fight:GetRewards()
end

-- 检查格子战斗数据是否为空
function XTheatre4Grid:IsGridFightEmpty()
    return not self.Fight
end

-- 获取格子商店数据
---@return XTheatre4Shop
function XTheatre4Grid:GetGridShop()
    return self.Shop
end

-- 获取格子商店Id
function XTheatre4Grid:GetGridShopId()
    if not self.Shop then
        return 0
    end
    return self.Shop:GetShopId()
end

-- 获取格子商店已刷新次数
function XTheatre4Grid:GetGridShopRefreshTimes()
    if not self.Shop then
        return 0
    end
    return self.Shop:GetRefreshTimes()
end

-- 获取格子商店商品列表
---@return XTheatre4ShopGoods[]
function XTheatre4Grid:GetGridShopGoods()
    if not self.Shop then
        return nil
    end
    return self.Shop:GetGoods()
end

-- 获取格子商店免费购买次数
function XTheatre4Grid:GetGridShopFreeBuyTimes()
    if not self.Shop then
        return 0
    end
    return self.Shop:GetFreeBuyTimes()
end

-- 获取格子商店折扣
function XTheatre4Grid:GetGridShopDiscount()
    if not self.Shop then
        return 1
    end
    return self.Shop:GetDiscount()
end

-- 获取格子事件数据
---@return XTheatre4Event
function XTheatre4Grid:GetGridEvent()
    return self.Event
end

-- 获取格子事件Id
function XTheatre4Grid:GetGridEventId()
    if not self.Event then
        return 0
    end
    return self.Event:GetEventId()
end

-- 获取格子事件关卡Id
function XTheatre4Grid:GetGridEventStageId()
    if not self.Event then
        return 0
    end
    return self.Event:GetStageId()
end

-- 获取格子事件关卡得分
function XTheatre4Grid:GetGridEventStageScore()
    if not self.Event then
        return 0
    end
    return self.Event:GetStageScore()
end

-- 获取格子建筑数据
---@return XTheatre4Building
function XTheatre4Grid:GetGridBuilding()
    return self.Building
end

-- 获取格子建筑Id
function XTheatre4Grid:GetGridBuildingId()
    if not self.Building then
        return 0
    end
    return self.Building:GetBuildingId()
end

-- 获取格子建筑类型
function XTheatre4Grid:GetGridBuildingType()
    if not self.Building then
        return 0
    end
    return self.Building:GetBuildingType()
end

-- 获取格子长宽
function XTheatre4Grid:GetGridSize()
    return self.Length, self.Width
end

-- 获取格子显示的Id
function XTheatre4Grid:GetGridDisplayId()
    if self:IsGridTypeBox() or self:IsGridTypeMonster() or self:IsGridTypeBoss() or self:IsGridTypeShop() then
        return self:GetGridContentId()
    elseif self:IsGridTypeEvent() then
        return self:GetGridEventId()
    elseif self:IsGridTypeBuilding() then
        return self:GetGridBuildingId()
    end
    return 0
end

-- 检测是否是无格子
function XTheatre4Grid:IsGridTypeNothing()
    return self.Type == XEnumConst.Theatre4.GridType.Nothing
end

-- 检测是否是空格子
function XTheatre4Grid:IsGridTypeEmpty()
    return self.Type == XEnumConst.Theatre4.GridType.Empty
end

-- 检测是否是障碍格子
function XTheatre4Grid:IsGridTypeHurdle()
    return self.Type == XEnumConst.Theatre4.GridType.Hurdle
end

-- 检测是否是商店格子
function XTheatre4Grid:IsGridTypeShop()
    return self.Type == XEnumConst.Theatre4.GridType.Shop
end

-- 检测是否是宝箱格子
function XTheatre4Grid:IsGridTypeBox()
    return self.Type == XEnumConst.Theatre4.GridType.Box
end

-- 检测是否是怪物格子
function XTheatre4Grid:IsGridTypeMonster()
    return self.Type == XEnumConst.Theatre4.GridType.Monster
end

-- 检测是否是Boss格子
function XTheatre4Grid:IsGridTypeBoss()
    return self.Type == XEnumConst.Theatre4.GridType.Boss
end

-- 检测是否是事件格子
function XTheatre4Grid:IsGridTypeEvent()
    return self.Type == XEnumConst.Theatre4.GridType.Event
end

-- 检测是否是起始格子
function XTheatre4Grid:IsGridTypeStart()
    return self.Type == XEnumConst.Theatre4.GridType.Start
end

-- 检测是否是白格子
function XTheatre4Grid:IsGridTypeBlank()
    return self.Type == XEnumConst.Theatre4.GridType.Blank
end

-- 检测是否是建筑格子
function XTheatre4Grid:IsGridTypeBuilding()
    return self.Type == XEnumConst.Theatre4.GridType.Building
end

-- 检测是否是未知状态
function XTheatre4Grid:IsGridStateUnknown()
    return self.State == XEnumConst.Theatre4.GridExploreState.Unknown
end

-- 检测是否是可见状态
function XTheatre4Grid:IsGridStateVisible()
    return self.State == XEnumConst.Theatre4.GridExploreState.Visible
end

-- 检测是否是可探索状态
function XTheatre4Grid:IsGridStateDiscover()
    if self:IsHasBeenCrush() then
        return false
    end
    return self.State == XEnumConst.Theatre4.GridExploreState.Discover
end

-- 检测是否是已探索状态
function XTheatre4Grid:IsGridStateExplored()
    return self.State == XEnumConst.Theatre4.GridExploreState.Explored
end

-- 检测是否是已处理状态
function XTheatre4Grid:IsGridStateProcessed()
    return self.State == XEnumConst.Theatre4.GridExploreState.Processed
end

-- 检测是否是红色
function XTheatre4Grid:IsGridColorRed()
    return self.Color == XEnumConst.Theatre4.ColorType.Red
end

-- 检测是否是黄色
function XTheatre4Grid:IsGridColorYellow()
    return self.Color == XEnumConst.Theatre4.ColorType.Yellow
end

-- 检测是否是蓝色
function XTheatre4Grid:IsGridColorBlue()
    return self.Color == XEnumConst.Theatre4.ColorType.Blue
end

function XTheatre4Grid:GetDisabledDay()
    return self.DisabledDay
end

function XTheatre4Grid:IsHasBeenCrush()
    local disabledDay = self:GetDisabledDay()
    if disabledDay and disabledDay > 0 then
        local currentDay = XMVCA.XTheatre4:GetDays()
        if currentDay > disabledDay then
            return true
        end
    end
    return false
end

return XTheatre4Grid
