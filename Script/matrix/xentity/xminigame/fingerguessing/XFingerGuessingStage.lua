-- 猜拳小游戏关卡
---@class XFingerGuessingStage
local XFingerGuessingStage = XClass(nil, "XFingerGuessingStage")
local UNNAMED_STR = "未配置字段"
local FINGER_NUM_NOT_OPEN_TEXT = "?"
local FINGER_TYPE = {
    Rock = 0, -- 石头
    Paper = 1, -- 布
    Scissors = 2, -- 剪刀
}
function XFingerGuessingStage:Ctor(config, controller)
    self.GameController = controller
    self.Config = config
    self:ResetStatus()
end
--==================
--重置状态
--==================
function XFingerGuessingStage:ResetStatus()
    self.IsClear = false
    self.IsOpen = false
    self.IsPlaying = false
    self.CurrentRound = 1
    self.OpenEyeFingerList = {}
    self.FingerDeck = {[FINGER_TYPE.Rock] = 0, [FINGER_TYPE.Paper] = 0, [FINGER_TYPE.Scissors] = 0}
    self.ActionDeck = {}
    self.ChallengeTimes = 0
    self.HighScore = 0
end
--=======================
--FingerGuessingStageInfo
--    int StageId // 关卡Id
--    int ChallengeTimes // 挑战次数
--    bool StageStatus // 关卡状态
--    int HighScore // 最高分
--    List<FingerGuessingRobotTricks> RobotTricksList // 机器人行动列表
--    bool IsCheating // 是否开启天眼
--    List<int> SelectRobotTricks // 天眼预测的行动种类
--=======================
function XFingerGuessingStage:RefreshStageInfo(stageInfo)
    self.IsOpen = true
    self.ChallengeTimes = stageInfo.ChallengeTimes
    self.IsClear = stageInfo.StageStatus
    self.HighScore = stageInfo.HighScore
    self:SetOpenEyeFingerList(stageInfo.SelectRobotTricks)
    self:SetNpcDecks(stageInfo.RobotTricksList)
end
--==================================
--FingerGuessingCurrentStageInfo = {
--    int StageId //关卡Id
--    int PlayerScore // 玩家分数
--    int RobotScore // 机器人分数
--    int CurrentRound // 当前处于回合数
--}
--==================================
function XFingerGuessingStage:RefreshCurrent(currentStageInfo)
    if self:GetStageId() ~= currentStageInfo.StageId then return end
    if currentStageInfo.CurrentRound > 1 then
        local action = self:GetActionByRound(self:GetCurrentRound())
        self.FingerDeck[action] = self.FingerDeck[action] - 1
    end
    self.HeroScore = currentStageInfo.PlayerScore
    self.EnemyScore = currentStageInfo.RobotScore
    self.CurrentRound = currentStageInfo.CurrentRound
end
--==================
--获取关卡配置Id
--==================
function XFingerGuessingStage:GetId()
    return self.Config and self.Config.Id
end
--==================
--获取关卡Id
--==================
function XFingerGuessingStage:GetStageId()
    return self.Config and self.Config.StageId
end
--==================
--根据关卡开放状态获取关卡名称
--==================
function XFingerGuessingStage:GetName()
    if self.IsOpen then
        return self:GetStageName()
    else
        return self:GetLockStageName()
    end
end
--==================
--获取关卡名称(开放关卡时)
--==================
function XFingerGuessingStage:GetStageName()
    return self.Config and self.Config.StageName or UNNAMED_STR
end
--==================
--获取关卡名称(未开放关卡时)
--==================
function XFingerGuessingStage:GetLockStageName()
    local lockName = self.Config and self.Config.LockStageName
    return lockName or self:GetStageName()
end
--==================
--获取关卡描述
--==================
function XFingerGuessingStage:GetDescription()
    return self.Config and string.gsub(self.Config.Description, "\\n", "\n") or UNNAMED_STR
end
--==================
--获取开启天眼二级确认窗口标题
--==================
function XFingerGuessingStage:GetOpenEyeTipsTitle()
    return self.Config and self.Config.OpenEyeTipsTitle
end
--==================
--获取开启天眼二级确认窗口内容
--==================
function XFingerGuessingStage:GetOpenEyeTipsContent()
    return self.Config and self.Config.OpenEyeTipsContent
end
--==================
--根据关卡开放状态获取敌人头像
--==================
function XFingerGuessingStage:GetPortraits()
    if self.IsOpen then
        return self:GetRobotPortraits()
    else
        return self:GetStageLockRobotPortraits()
    end
end
--==================
--获取敌人头像(开放关卡时)地址
--==================
function XFingerGuessingStage:GetRobotPortraits()
    return self.Config and self.Config.RobotPortraits
end
--==================
--获取敌人头像(未解锁关卡时)地址
--==================
function XFingerGuessingStage:GetStageLockRobotPortraits()
    return self.Config and self.Config.StageLockRobotPortraits
end
--==================
--获取机器人全图像
--==================
function XFingerGuessingStage:GetRobotImage()
    return self.Config and self.Config.RobotImage
end
--==================
--获取消耗材料多少
--==================
function XFingerGuessingStage:GetCostItemCount()
    return self.Config and self.Config.CostItemCount or 0
end
--==================
--获取天眼看的种类数
--==================
function XFingerGuessingStage:GetCheatCount()
    return self.Config and self.Config.CheatCount or 0
end
--==================
--获取前一个关卡Id
--==================
function XFingerGuessingStage:GetPreStageId()
    return self.Config and self.Config.PreStageId
end
--==================
--获取胜利分数
--==================
function XFingerGuessingStage:GetWinScore()
    return self.Config and self.Config.WinScore or 0
end
--==================
--获取关卡胜利台词
--==================
function XFingerGuessingStage:GetWinTalk()
    return self.Config and self.Config.WinTalk
end
--==================
--获取关卡失败台词
--==================
function XFingerGuessingStage:GetLoseTalk()
    return self.Config and self.Config.LoseTalk
end
-- 获取开始剧情Id
function XFingerGuessingStage:GetStartMovieId()
    return self.Config and self.Config.StartMovieId or ""
end
-- 获取结束剧情Id
function XFingerGuessingStage:GetEndMovieId()
    return self.Config and self.Config.EndMovieId or ""
end
--==================
--获取游戏总轮数
--==================
function XFingerGuessingStage:GetRoundNum()
    if self.RoundNum then return self.RoundNum end
    self.RoundNum = #XFingerGuessingConfig.GetRoundConfigByStageId(self:GetStageId())
    return self.RoundNum
end
--==================
--获取现在的轮数
--==================
function XFingerGuessingStage:GetCurrentRound()
    return self.CurrentRound or 1
end
--==================
--设置现在的轮数
--==================
function XFingerGuessingStage:SetCurrentRound(roundNum)
    self.CurrentRound = roundNum
    self.RoundConfig = XFingerGuessingConfig.GetRoundConfigById(self.CurrentRound)
end
--==================
--获取关卡是否解锁
--==================
function XFingerGuessingStage:GetIsOpen()
    return self.IsOpen
end
--==================
--获取关卡是否已完成
--==================
function XFingerGuessingStage:GetIsClear()
    return self.IsClear
end
--==================
--设置天眼预测Id列表
--==================
function XFingerGuessingStage:SetOpenEyeFingerList(fingerIdList)
    self.OpenEyeFingerList = {}
    for _, fingerId in pairs(fingerIdList) do
        self.OpenEyeFingerList[fingerId] = true
    end
end
--==================
--获取天眼预测Id列表
--==================
function XFingerGuessingStage:GetOpenEyeFingerList()
    return self.OpenEyeFingerList
end
--==================
--设置NPC卡组与行动序列
--==================
function XFingerGuessingStage:SetNpcDecks(dataList)
    self.FingerDeck = {}
    self.ActionDeck = {}
    for _, data in pairs(dataList) do
        self.ActionDeck[data.Round] = data.Tricks
        self.FingerDeck[data.Tricks] = (self.FingerDeck[data.Tricks] or 0) + 1
    end
end
--==================
--设置NPC卡组与行动序列
--==================
function XFingerGuessingStage:GetFingerNumByFingerId(fingerId)
    return self.FingerDeck[fingerId] or 0
end
--==================
--获取天眼拳型数量的文本
--==================
function XFingerGuessingStage:GetFingerTextByFingerId(fingerId)
    if self:GetIsOpenEye() and self.OpenEyeFingerList[fingerId] then
        return self:GetFingerNumByFingerId(fingerId)
    else
        return FINGER_NUM_NOT_OPEN_TEXT
    end
end
--==================
--获取是否打开天眼
--==================
function XFingerGuessingStage:GetIsOpenEye()
    return self.GameController:GetIsOpenEye()
end
--==================
--获取NPC卡组与行动序列
--==================
function XFingerGuessingStage:GetActionByRound(round)
    return self.ActionDeck[round]
end
--==================
--获取当前回合NPC出拳图标
--==================
function XFingerGuessingStage:GetActionImg()
    local fingerId = self:GetActionByRound(self:GetCurrentRound())
    local fingerConfig = XFingerGuessingConfig.GetFingerConfigById(fingerId)
    return fingerConfig and fingerConfig.Icon
end
--==================
--获取玩家得分
--==================
function XFingerGuessingStage:GetHeroScore()
    return self.HeroScore or 0
end
--==================
--获取敌人得分
--==================
function XFingerGuessingStage:GetEnemyScore()
    return self.EnemyScore or 0
end
--==================
--获取历史最高分
--==================
function XFingerGuessingStage:GetHighScore()
    return self.HighScore or 0
end
--==================
--检查是否第一次进入关卡
--==================
function XFingerGuessingStage:CheckIsFirstEntry()
    return self.ChallengeTimes and self.ChallengeTimes == 0
end
return XFingerGuessingStage