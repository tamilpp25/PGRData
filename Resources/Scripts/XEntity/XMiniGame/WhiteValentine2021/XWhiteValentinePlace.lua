-- 约会活动地点对象
local XWhiteValentinePlace = XClass(nil, "XWhiteValentinePlace")
--==========构造函数，初始化，实体操作==========
--==================
--构造函数
--@param Game:约会Game对象
--@param PlaceId:地点ID
--@param PlaceData:地点数据(可缺省)
--==================
function XWhiteValentinePlace:Ctor(GameController, PlaceId)
    self.GameController = GameController
    self:InitConfig(PlaceId)
end

function XWhiteValentinePlace:InitConfig(PlaceId)
    self:ResetStatus()
    self.Config = XWhiteValentineConfig.GetWhiteValentinePlaceByPlaceId(PlaceId)
end
--==================
--重置地点配置以外数据
--==================
function XWhiteValentinePlace:ResetStatus()
    self.EventCfg = nil
    self.EventRankCfg = nil
    self.EventAttrCfg = nil
    self.EventFinishCount = 0
    self.DispatchingChara = nil
    self.EventEndTime = 0
end
--==================
--刷新数据
--@param PlaceData:{int Id //地点ID，int RoleId //在该地点派遣的角色Id, int EventCfgId //事件Id，
--                  long EventEndTime //结束时间戳,0 表示未派遣角色
--                  int EventFinishCount //此地点的完成事件计数}
--==================
function XWhiteValentinePlace:RefreshData(PlaceData)
    if not PlaceData then return end
    self.EventCfg = XWhiteValentineConfig.GetWhiteValentineEventByEventId(PlaceData.EventCfgId)
    self.EventRankCfg = XWhiteValentineConfig.GetWhiteValentineRankConfigById(PlaceData.EventRankType)
    self.EventAttrCfg = XWhiteValentineConfig.GetWhiteValentineAttrById(self.EventCfg.AttrType)
    self.EventFinishCount = PlaceData.EventFinishCount
    self.EventEndTime = PlaceData.EventEndTime
    self:SetDispatchingChara(self.GameController:GetChara(PlaceData.RoleId))
end
--=================== END =====================
--=================对外接口(Get,Set,Check等接口)================
--==================
--获取游戏ID
--==================
function XWhiteValentinePlace:GetGameId()
    return self.GameController and self.GameController:GetGameId()
end
--==================
--获取地点ID
--==================
function XWhiteValentinePlace:GetPlaceId()
    return self.Config and self.Config.Id
end
--==================
--获取地点序号
--==================
function XWhiteValentinePlace:GetOrderId()
    return self.Config and self.Config.OrderId
end
--==================
--获取地点开放前置
--==================
function XWhiteValentinePlace:GetPrePlaceId()
    return self.Config and self.Config.PrePlaceId
end
--==================
--获取地点附赠邀请次数
--==================
function XWhiteValentinePlace:GetInviteNum()
    return self.Config and self.Config.InviteNum
end
--==================
--获取默认事件
--==================
function XWhiteValentinePlace:GetDefaultEventId()
    return self.Config and self.Config.DefaultEventId
end
--==================
--获取随机事件池
--==================
function XWhiteValentinePlace:GetRandomEventId()
    return self.Config and self.Config.RandomEventId
end
--==================
--获取地点是否开放
--==================
function XWhiteValentinePlace:GetIsOpen()
    return self.EventCfg ~= nil
end
--==================
--获取事件名称
--==================
function XWhiteValentinePlace:GetEventName()
    return self.EventCfg and self.EventCfg.Name
end
--==================
--获取事件描述
--==================
function XWhiteValentinePlace:GetEventDescription()
    return self.EventCfg and self.EventCfg.Description
end
--==================
--获取阶级名称
--==================
function XWhiteValentinePlace:GetEventRankName()
    return self.EventRankCfg and self.EventRankCfg.Name
end
--==================
--获取事件阶级图标
--==================
function XWhiteValentinePlace:GetRankIcon()
    return self.EventRankCfg and self.EventRankCfg.IconPath
end
--==================
--获取事件阶级贡献值奖励
--==================
function XWhiteValentinePlace:GetRankContributionReward()
    return self.EventRankCfg and self.EventRankCfg.RewardContribution
end
--==================
--获取事件阶级消耗时间
--==================
function XWhiteValentinePlace:GetCostTime()
    return self.EventRankCfg and self.EventRankCfg.CostTime
end
--==================
--获取事件阶级金币奖励
--==================
function XWhiteValentinePlace:GetRankCoinReward()
    return self.EventRankCfg and self.EventRankCfg.RewardCoin
end
--==================
--获取地点背景图
--==================
function XWhiteValentinePlace:GetBgPath()
    return self.Config and self.Config.BgPath
end
--==================
--获取地点事件消耗体力
--==================
function XWhiteValentinePlace:GetCostEnergy()
    return self.EventRankCfg and self.EventRankCfg.CostEnergy or 0
end
--==================
--获取地点事件属性图标
--==================
function XWhiteValentinePlace:GetEventAttrIcon()
    return self.EventAttrCfg and self.EventAttrCfg.IconPath
end
--==================
--获取地点事件属性种类
--==================
function XWhiteValentinePlace:GetEventAttrType()
    return self.EventAttrCfg and self.EventAttrCfg.Id
end
--==================
--获取派遣至此地点的角色
--==================
function XWhiteValentinePlace:GetDispatchingChara()
    return self.DispatchingChara
end
--==================
--设置派遣至此地点的角色
--==================
function XWhiteValentinePlace:SetDispatchingChara(chara)
    self.DispatchingChara = chara
end
--==================
--获取派遣结束时间，为0表示没有派遣
--==================
function XWhiteValentinePlace:GetEventEndTime()
    return self.EventEndTime or 0
end
--==================
--获取离派遣结束的时间
--==================
function XWhiteValentinePlace:GetEventEndTimeString()
    local timeEnd = self:GetEventEndTime()
    local timeNow = XTime.GetServerNowTimestamp()
    local leftTime = timeEnd - timeNow
    if leftTime < 0 then leftTime = 0 end
    local string = CS.XTextManager.GetText("WhiteValentinePlaceCountDownStr", XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.TO_A_MINUTE))
    return string
end
--==================
--获取是否正在派遣倒计时中，未派遣或已完成都会返回false
--==================
function XWhiteValentinePlace:GetIsDispatching()
    local timeNow = XTime.GetServerNowTimestamp()
    return (self.EventEndTime > 0) and (timeNow < self:GetEventEndTime())
end
--==================
--检查本地点事件是否已完成
--==================
function XWhiteValentinePlace:CheckCanFinishEvent()
    if self:GetEventEndTime() == 0 then return false end
    local timeNow = XTime.GetServerNowTimestamp()
    return timeNow >= self.EventEndTime
end
--==================
--获取贡献值道具图标
--==================
function XWhiteValentinePlace:GetContributionItemIcon()
    return self.GameController:GetContributionItemIcon()
end
--==================
--获取金币图标
--==================
function XWhiteValentinePlace:GetCoinItemIcon()
    return self.GameController:GetCoinItemIcon()
end
--=================== END =====================
return XWhiteValentinePlace