-- 猜拳小游戏游戏进程控制器
---@class XFingerGuessingGameController
---@field StageManager XFingerGuessingStageManager
local XFingerGuessingGameController = XClass(nil, "XFingerGuessingGameController")
local UNNAMED_STR = "UnNamed"
function XFingerGuessingGameController:Ctor()
    self.GameConfig = XFingerGuessingConfig.GetLastestActivityConfig()
    self:InitStageManager()
    self:ResetStatus()
end
--================
--初始化关卡管理器
--================
function XFingerGuessingGameController:InitStageManager()
    local XStageManager = require("XEntity/XMiniGame/FingerGuessing/XFingerGuessingStageManager")
    self.StageManager = XStageManager.New(self)
end
--=======================
--刷新活动数据
--@param data: {
--    int ActivityId //当前活动Id
--    List<FingerGuessingStageInfo> FingerGuessingStageData //已开启的关卡信息
--    
--}
--=======================
--FingerGuessingCurrentStageInfo = {
--    int StageId //关卡Id
--    int PlayerScore // 玩家分数
--    int RobotScore // 机器人分数
--    int CurrentRound // 当前处于回合数
--}
function XFingerGuessingGameController:RefreshActivityData(data)
    self:InitConfigById(data.ActivityId)
    self:SetIsOpenEye(data.IsCheating)
    self:RefreshStageData(data.FingerGuessingStageData)
    self:RefreshCurrentStage(data.CurrentStageData)
end
--=======================
--刷新关卡通常数据
--@param data =
--    List<FingerGuessingStageInfo> FingerGuessingStageData //已开启的关卡信息
--=======================
function XFingerGuessingGameController:RefreshStageData(data)
    self.StageManager:RefreshStageList(data)
end
--=======================
--刷新当前关卡数据
--@param data =
--    FingerGuessingCurrentStageInfo CurrentStageData //当前关卡信息
--=======================
function XFingerGuessingGameController:RefreshCurrentStage(data)
    self.StageManager:RefreshCurrentStage(data)
    self.IsGaming = data.StageId ~= 0
    if data.StageId == 0 then self.PreStageId = self.CurrentStageId end
    self.CurrentStageId = data.StageId
end
--================
--根据Id初始化游戏配置
--================
function XFingerGuessingGameController:InitConfigById(activityId)
    if self:GetId() == activityId then return end
    self.GameConfig = XFingerGuessingConfig.GetActivityConfigById(activityId)
end
--================
--重置成员属性
--================
function XFingerGuessingGameController:ResetStatus()
    
end
--================
--获取活动ID
--================
function XFingerGuessingGameController:GetId()
    return self.GameConfig and self.GameConfig.Id or 0
end
--================
--获取活动时间TimeId
--================
function XFingerGuessingGameController:GetTimeId()
    return self.GameConfig and self.GameConfig.TimeId or 0
end
--================
--获取活动代币道具ID
--================
function XFingerGuessingGameController:GetCoinItemId()
    return self.GameConfig and self.GameConfig.CoinItemId or 0
end
--==================
--获取金币图标
--==================
function XFingerGuessingGameController:GetCoinItemIcon()
    if self.ItemIcon then return self.ItemIcon end
    local itemId = self:GetCoinItemId()
    if not itemId then return nil end
    self.ItemIcon = XDataCenter.ItemManager.GetItemIcon(itemId)
    return self.ItemIcon
end
--================
--获取活动名称
--================
function XFingerGuessingGameController:GetName()
    return self.GameConfig and self.GameConfig.Name or UNNAMED_STR
end
--================
--获取主角名称
--================
function XFingerGuessingGameController:GetHeroName()
    return self.GameConfig and self.GameConfig.HeroName
end
--================
--获取主角全身图
--================
function XFingerGuessingGameController:GetHeroImage()
    return self.GameConfig and self.GameConfig.HeroImage
end
--================
--获取主角头像
--================
function XFingerGuessingGameController:GetPlayerPortraits()
    return self.GameConfig and self.GameConfig.PlayerPortraits
end
-- 获取剧情Id
function XFingerGuessingGameController:GetStartMovieId()
    return self.GameConfig and self.GameConfig.StartMovieId or ""
end
--================
--获取所有关卡对象
--================
function XFingerGuessingGameController:GetAllStages()
    return self.StageManager:GetAllStages()
end
--==================
--获取活动开始时间
--==================
function XFingerGuessingGameController:GetActivityStartTime()
    return XFunctionManager.GetStartTimeByTimeId(self:GetTimeId()) or 0
end
--==================
--获取活动结束时间
--==================
function XFingerGuessingGameController:GetActivityEndTime()
    return XFunctionManager.GetEndTimeByTimeId(self:GetTimeId()) or 0
end
--==================
--获取是否正在游戏
--==================
function XFingerGuessingGameController:GetIsGaming()
    return self.IsGaming
end
--==================
--设置是否正在游戏
--==================
function XFingerGuessingGameController:SetIsGaming(isGaming)
    self.IsGaming = isGaming
end
--==================
--获取当前进行的关卡对象(若没有当前进行的关卡则取最近一次进行的关卡)
--==================
function XFingerGuessingGameController:GetCurrentStage()
    local stageId = 0
    if self.CurrentStageId == 0 then
        stageId = self.PreStageId or 0
    else
        stageId = self.CurrentStageId
    end 
    return self.StageManager:GetStageByStageId(stageId)
end
--==================
--根据关卡Id获取关卡对象
--==================
function XFingerGuessingGameController:GetStageByStageId(stageId)
    return self.StageManager:GetStageByStageId(stageId)
end

function XFingerGuessingGameController:GetLastStageId()
    return self.StageManager:GetLastStageId()
end
--==================
--检查金币是否足够
--==================
function XFingerGuessingGameController:CheckCoinEnough(coin)
    local itemId = self:GetCoinItemId()
    if not itemId then return false end
    local num = XDataCenter.ItemManager.GetCount(itemId)
    return num >= coin
end
--==================
--获取是否开了天眼系统
--==================
function XFingerGuessingGameController:GetIsOpenEye()
    return self.OpenEye
end
--==================
--设置是否开了天眼系统
--==================
function XFingerGuessingGameController:SetIsOpenEye(openEye)
    self.OpenEye = openEye
end
return XFingerGuessingGameController