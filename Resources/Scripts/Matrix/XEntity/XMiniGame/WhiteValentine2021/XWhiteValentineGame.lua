-- 白色情人节约会小游戏活动对象
local XWhiteValentineGame = XClass(nil, "XWhiteValentineGame")
--==========构造函数，初始化，实体操作==========
--==================
--构造函数
--@param GameData:通知活动信息
--==================
function XWhiteValentineGame:Ctor()
    self.GameConfig = XWhiteValentineConfig.GetWhiteValentineConfigByGameId(XWhiteValentineConfig.GetLastConfigId())
    self:InitPlaceManager()
    self:InitCharaManager()
    self:InitStatus()
end
--==================
--初始化地点
--==================
function XWhiteValentineGame:InitPlaceManager()
    local PlaceManager = require("XEntity/XMiniGame/WhiteValentine2021/XWhiteValentinePlaceManager")
    self.PlaceManager = PlaceManager.New(self)
end
--==================
--初始化角色管理器
--==================
function XWhiteValentineGame:InitCharaManager()
    local CharaManager = require("XEntity/XMiniGame/WhiteValentine2021/XWhiteValentineCharaManager")
    self.CharaManager = CharaManager.New(self)
end
--==================
--初始化活动数值
--==================
function XWhiteValentineGame:InitStatus()
    self:ResetStatus()
end
--==================
--重置活动数值
--==================
function XWhiteValentineGame:ResetStatus()
    self:SetEnergy(0)
    self:SetInviteChance(0)
    self.ContributionIcon = nil
    self.ItemIcon = nil
end
--==================
--刷新活动数据
--@param enterActivityData:活动数据
--enterActivityData : { int Energy //体力，int InviteCount //邀请次数,
--                      List<XWhiteValentinesDayRoleDb> RoleDb //角色列表
--                      List<XWhiteValentinesDayPlaceDb> PlaceDb //地点列表
--                      LastRefreshTimestamp //最后一个更新体力时间}
--==================
function XWhiteValentineGame:RefreshData(enterActivityData)
    self:SetEnergy(enterActivityData.Energy)
    self:SetInviteChance(enterActivityData.InviteCount)
    self:SetNextEnergyRecoveryTimeStamp(enterActivityData.LastRefreshTimestamp)
    --先刷新角色状态，再刷新地点状态(地点需要用到新的角色状态)
    self.CharaManager:RefreshData(enterActivityData.RoleDb)
    self.PlaceManager:RefreshData(enterActivityData.PlaceDb)
end
--==================
--检查是否有事件结束
--==================
function XWhiteValentineGame:CheckCanFinishEvent()
    self.CanFinishEvent = self.PlaceManager:CheckCanFinishEvent()
end
--==================
--刷新活动数据
--@param charaData:角色数据
--==================
function XWhiteValentineGame:RefreshChara(charaData)
    self.CharaManager:RefreshChara(charaData)
end
--==================
--刷新地点数据
--@param placeData:地点数据
--==================
function XWhiteValentineGame:RefreshPlace(placeData)
    self.PlaceManager:RefreshPlace(placeData)
end
--==================
--批量刷新地点数据
--@param charaData:角色数据集合
--==================
function XWhiteValentineGame:RefreshPlaceRange(placeDatas)
    self.PlaceManager:RefreshPlaceRange(placeDatas)
    for _, placeData in pairs(placeDatas) do
        local place = self.PlaceManager:GetPlaceByPlaceId(placeData.Id)
        local count = place:GetInviteNum()
        self:SetInviteChance(self:GetInviteChance() + count)
    end
end
--==================
--派遣角色
--@param placeData:被派遣的地点刷新数据
--@param charaData:派遣的角色刷新数据
--@param costEnergy:消耗的体力
--@param nextEnergyRecoveryTimestamp:下一个体力更新的时间戳
--==================
function XWhiteValentineGame:CharaDispatch(placeData, charaData, costEnergy, nextEnergyRecoveryTimestamp)
    self:RefreshChara(charaData)
    self:RefreshPlace(placeData)
    self:CostEnergy(costEnergy)
    self:SetNextEnergyRecoveryTimeStamp(nextEnergyRecoveryTimestamp)
    self:CalculateNextEnergyRecoveryTimeStamp()
end
--==================
--增加新角色
--@param charaId:角色Id
--==================
function XWhiteValentineGame:AddNewChara(charaId)
    self.CharaManager:AddNewChara(charaId)
end
--==================
--计算并设置下一个体力回复的时间戳
--==================
function XWhiteValentineGame:CalculateNextEnergyRecoveryTimeStamp()
    local timeStamp = self:GetNextEnergyRecoveryTimeStamp()
    if timeStamp == 0 then return end
    local nextTimeStamp = timeStamp + self:GetEnergyRecoverySpeed()
    self:SetNextEnergyRecoveryTimeStamp(nextTimeStamp)
end
--==================
--计算时间戳差值，补回体力恢复(处理本地计算体力刷新边际问题)
--==================
function XWhiteValentineGame:CalculateDeltaEnergyRecoveryTimeStamp()
    local now = XTime.GetServerNowTimestamp()
    local delta = now - self:GetNextEnergyRecoveryTimeStamp()
    local deltaEnergy = math.floor(delta / self:GetEnergyRecoverySpeed())
    while(self:GetNextEnergyRecoveryTimeStamp() < now) do
        self:CalculateNextEnergyRecoveryTimeStamp()
    end
    self:SetEnergy(self:GetEnergy() + deltaEnergy)
end
--==================
--体力自增1
--==================
function XWhiteValentineGame:AddOneEnergy()
    self:SetEnergy(self:GetEnergy() + 1)
end
--=================== END =====================

--=================Get,Set,Check================
--==================
--获取活动ID
--==================
function XWhiteValentineGame:GetGameId()
    return self.GameConfig and self.GameConfig.GameId
end
--==================
--获取活动标题
--==================
function XWhiteValentineGame:GetName()
    return self.GameConfig and self.GameConfig.Name
end
--==================
--获取活动TimeID
--==================
function XWhiteValentineGame:GetTimeId()
    return self.GameConfig and self.GameConfig.TimeId
end
--==================
--获取活动条件ID
--==================
function XWhiteValentineGame:GetOpenConditionId()
    return self.GameConfig and self.GameConfig.OpenConditionId
end
--==================
--获取背景图片地址
--==================
function XWhiteValentineGame:GetBgPicturePath()
    return self.GameConfig and self.GameConfig.BgPicturePath
end
--==================
--获取背景特效地址
--==================
function XWhiteValentineGame:GetBgEffectPath()
    return self.GameConfig and self.GameConfig.BgEffectPath
end
--==================
--获取活动体力最大值
--==================
function XWhiteValentineGame:GetMaxEnergy()
    return self.GameConfig and self.GameConfig.MaxEnergy
end
--==================
--获取活动体力恢复速度(单位：秒)
--==================
function XWhiteValentineGame:GetEnergyRecoverySpeed()
    return self.GameConfig and self.GameConfig.EnergyRecoverySpeed
end
--==================
--获取活动体力图标
--==================
function XWhiteValentineGame:GetEnergyIconPath()
    return self.GameConfig and self.GameConfig.EnergyIconPath
end
--==================
--获取贡献值道具ID
--==================
function XWhiteValentineGame:GetContributionItemId()
    return self.GameConfig and self.GameConfig.ContributionItemId
end
--==================
--获取贡献值道具图标
--==================
function XWhiteValentineGame:GetContributionItemIcon()
    if self.ContributionIcon then return self.ContributionIcon end
    local itemId = self:GetContributionItemId()
    if not itemId then return nil end
    self.ContributionIcon = XDataCenter.ItemManager.GetItemIcon(itemId)
    return self.ContributionIcon
end
--==================
--获取金币道具ID
--==================
function XWhiteValentineGame:GetCoinItemId()
    return self.GameConfig and self.GameConfig.CoinItemId
end
--==================
--获取金币图标
--==================
function XWhiteValentineGame:GetCoinItemIcon()
    if self.ItemIcon then return self.ItemIcon end
    local itemId = self:GetCoinItemId()
    if not itemId then return nil end
    self.ItemIcon = XDataCenter.ItemManager.GetItemIcon(itemId)
    return self.ItemIcon
end
--==================
--获取偶遇消耗金币数
--==================
function XWhiteValentineGame:GetRandomMeetCostCoin()
    return self.GameConfig and self.GameConfig.RandomMeetCostCoin or 0
end
--==================
--获取活动开始时间
--==================
function XWhiteValentineGame:GetActivityStartTime()
    return XFunctionManager.GetStartTimeByTimeId(self:GetTimeId()) or 0
end
--==================
--获取活动结束时间
--==================
function XWhiteValentineGame:GetActivityEndTime()
    return XFunctionManager.GetEndTimeByTimeId(self:GetTimeId()) or 0
end
--==================
--获取体力值
--==================
function XWhiteValentineGame:GetEnergy()
    return self.Energy
end
--==================
--设置体力值
--@param energy:体力值
--==================
function XWhiteValentineGame:SetEnergy(energy)
    if not energy then return end
    if energy < 0 then energy = 0 end
    self.Energy = energy > self:GetMaxEnergy() and self:GetMaxEnergy() or energy
    XEventManager.DispatchEvent(XEventId.EVENT_WHITEVALENTINE_ENERGY_REFRESH)
end
--==================
--消耗体力值
--==================
function XWhiteValentineGame:CostEnergy(cost)
    if not cost then return end
    local resultEnergy = self:GetEnergy() - cost
    self:SetEnergy(resultEnergy)
end
--==================
--获取邀请值
--==================
function XWhiteValentineGame:GetInviteChance()
    return self.InviteChance
end
--==================
--设置邀请值
--==================
function XWhiteValentineGame:SetInviteChance(inviteChance)
    if not inviteChance then return end
    if inviteChance < 0 then inviteChance = 0 end
    self.InviteChance = inviteChance
    XEventManager.DispatchEvent(XEventId.EVENT_WHITEVALENTINE_INVITE_CHANCE_REFRESH, self.InviteChance)
end
--==================
--根据角色ID获取角色
--@param charaId:角色Id
--==================
function XWhiteValentineGame:GetChara(charaId)
    return self.CharaManager:GetChara(charaId)
end
--==================
--获取金币数量
--==================
function XWhiteValentineGame:GetCoin()
    local coinId = self:GetCoinItemId()
    if not coinId then return 0 end
    return XDataCenter.ItemManager.GetCount(coinId)
end
--==================
--检查是否能偶遇
--==================
function XWhiteValentineGame:CheckCanEncounter()
    return self:CheckEncounterCoinEnough() and self:CheckOutTeamCharaExist()
end
--==================
--检查偶遇金币是否足够
--==================
function XWhiteValentineGame:CheckEncounterCoinEnough()
    return self:GetCoin() >= self:GetRandomMeetCostCoin()
end
--==================
--检查是否还有未邀约的角色
--==================
function XWhiteValentineGame:CheckOutTeamCharaExist()
    return self.CharaManager:CheckOutTeamCharaExist()
end
--==================
--获取地点管理器
--==================
function XWhiteValentineGame:GetPlaceManager()
    return self.PlaceManager
end
--==================
--获取角色管理器
--==================
function XWhiteValentineGame:GetCharaManager()
    return self.CharaManager
end
--==================
--获取下一次更新体力的时间戳
--==================
function XWhiteValentineGame:GetNextEnergyRecoveryTimeStamp()
    return self.NextEnergyRecoveryTimeStamp or 0
end
--==================
--获取是否有完成事件未领取奖励
--==================
function XWhiteValentineGame:GetCanFinishEvent()
    return self.CanFinishEvent
end
--==================
--检查是否满能量
--==================
function XWhiteValentineGame:CheckIsMaxEnergy()
    return self:GetEnergy() >= self:GetMaxEnergy()
end
--==================
--设置下一次更新体力的时间戳
--==================
function XWhiteValentineGame:SetNextEnergyRecoveryTimeStamp(timeStamp)
    if timeStamp < 0 then timeStamp = 0 end
    self.NextEnergyRecoveryTimeStamp = timeStamp
end
--==================
--检查是否有未邀约的角色
--==================
function XWhiteValentineGame:CheckCanInviteChara()
    return self:GetInviteChance() > 0 and self.CharaManager:CheckOutTeamCharaExist()
end
--==================
--检查是否能派遣
--==================
function XWhiteValentineGame:CheckCanDispatch(place)
    if not place then return false end
    if self:GetEnergy() < place:GetCostEnergy() then
        XUiManager.TipMsg(CS.XTextManager.GetText("WhiteValentineEnergyNotEnough"))
        return false
    end
    return true
end
--=================== END =====================
return XWhiteValentineGame