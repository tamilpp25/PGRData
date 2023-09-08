---@class XBlackRockChessModel : XModel
---@field private _Activity XBlackRockChessActivity
---@field private _ChapterTemplate table<number, table<number, XTableBlackRockChessChapter>>
---@field private _LayoutTemplate table<number, XTableBlackRockChessLayout[]>
local XBlackRockChessModel = XClass(XModel, "XBlackRockChessModel")

local TableKey = {
    -- 活动总控
    BlackRockChessActivity = { CacheType = XConfigUtil.CacheType.Normal },
    -- 活动章节
    BlackRockChessChapter = { CacheType = XConfigUtil.CacheType.Temp },
    -- 活动关卡
    BlackRockChessStage = {},
    -- 关卡布局
    BlackRockChessLayout = { CacheType = XConfigUtil.CacheType.Temp },
    -- 棋子配置
    BlackRockChessPiece = {},
    -- 武器配置
    BlackRockChessWeapon = {},
    -- 武器技能
    BlackRockChessWeaponSkill = {},
    -- 客户端配置
    BlackRockChessConfig = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.String, Identifier = "Key" },
    -- 剧情配置
    BlackRockChessArchive = { DirPath = XConfigUtil.DirectoryType.Client },
    -- 剧情类型配置
    BlackRockChessArchiveType = { DirPath = XConfigUtil.DirectoryType.Client },
    -- 增援配置
    BlackRockChessReinforce = {},
    -- 图鉴配置
    BlackRockChessHandbook = {},
    -- buff配置
    BlackRockChessBuff = {},
    -- 星级奖励
    BlackRockChessStarReward = {},
    -- 条件
    BlackRockChessCondition = {},
    -- 特效
    BlackRockChessEffect = { DirPath = XConfigUtil.DirectoryType.Client },
}

--入口类型
local EntryType = {
    -- 常规对局
    Easy = 1,
    -- 深入对局
    Hard = 2,
}

--章节难度
local DifficultyType = {
    -- 简单
    Easy = 1,
    -- 困难
    Hard = 2,
}

local WeaponType = {
    -- 霰弹枪
    Shotgun = 1,
    -- 小刀
    Knife = 2
}

--玩家在Layout的MemberId
local PlayerMemberId = -1

--最大星级
local MAX_STAR = 3

function XBlackRockChessModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    
    self._ConfigUtil:InitConfigByTableKey("BlackRockChess", TableKey)

    self._ArchiveMap = {}
    
    self._CurEnergy = 0
    
    self._IsExtraRound = false
end

function XBlackRockChessModel:ClearPrivate()
    --这里执行内部数据清理
    self._ChapterTemplate = nil
    
    self._LayoutTemplate = nil

    self._CurEnergy = 0

    self._IsExtraRound = false
end

function XBlackRockChessModel:ResetAll()
    --这里执行重登数据清理
    if self._Activity then
        self._Activity:Reset()
    end
    self._Activity = nil
end

function XBlackRockChessModel:IsOpen()
    if not self._Activity or not XTool.IsNumberValid(self._Activity:GetActivityId()) then
        return false
    end
    return self:IsActivityInTime()
end

--region   ------------------Protocol start-------------------

-- 登录下发
function XBlackRockChessModel:UpdateBlackRockChessData(notifyData)
    if XTool.IsTableEmpty(notifyData) then
        return
    end
    
    local activityId = notifyData.ActivityId
    if not activityId then
        self:ResetAll()
        return
    end
    if not self._Activity then
        self._Activity = require("XModule/XBlackRockChess/XEntity/XBlackRockChessActivity").New(activityId)
    elseif activityId ~= self._Activity:GetActivityId() then
        self._Activity:Reset()
        self._Activity = require("XModule/XBlackRockChess/XEntity/XBlackRockChessActivity").New(activityId)
    end
    self._Activity:UpdateUnlockId(notifyData.WeaponList, notifyData.SkillList)
    self._Activity:UpdatePassStage(notifyData.PassStages)
    self._Activity:UpdateBuffData(notifyData.BuffData)
end

--endregion------------------Protocol finish------------------


--region   ------------------Table Config start-------------------

--region   ------------------Activity start-------------------

--- 活动配置
---@return XTableBlackRockChessActivity
--------------------------
function XBlackRockChessModel:_GetActivityConfig()
    if not self._Activity then
        return {}
    end
    local activityId = self._Activity:GetActivityId()
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BlackRockChessActivity, activityId)
end

function XBlackRockChessModel:GetActivityStartTime()
    local template = self:_GetActivityConfig()
    if not XTool.IsNumberValid(template.TimeId) then
        return 0
    end
    return XFunctionManager.GetStartTimeByTimeId(template.TimeId)
end

function XBlackRockChessModel:GetActivityStopTime()
    local template = self:_GetActivityConfig()
    if not XTool.IsNumberValid(template.TimeId) then
        return 0
    end
    return XFunctionManager.GetEndTimeByTimeId(template.TimeId)
end

function XBlackRockChessModel:IsActivityInTime(defaultOpen)
    local template = self:_GetActivityConfig()
    if not XTool.IsNumberValid(template.TimeId) then
        return false
    end
    return XFunctionManager.CheckInTimeByTimeId(template.TimeId, defaultOpen)
end

function XBlackRockChessModel:GetActivityName()
    local template = self:_GetActivityConfig()
    if string.IsNilOrEmpty(template.Name) then
        return ""
    end
    return template.Name
end

function XBlackRockChessModel:GetEasyChapterId()
    local template = self:_GetActivityConfig()
    local chapterList = template.Chapters
    return chapterList and chapterList[EntryType.Easy] or 0
end

function XBlackRockChessModel:GetHardChapterId()
    local template = self:_GetActivityConfig()
    local chapterList = template.Chapters
    return chapterList and chapterList[EntryType.Hard] or 0
end

function XBlackRockChessModel:GetMaxEnergy()
    local template = self:_GetActivityConfig()
    if not XTool.IsNumberValid(template.MaxEnergy) then
        return 0
    end
    return template.MaxEnergy
end

function XBlackRockChessModel:GetDefaultWeapon()
    local template = self:_GetActivityConfig()
    if not XTool.IsNumberValid(template.DefaultWeapon) then
        return WeaponType.Shotgun
    end
    return template.DefaultWeapon
end

function XBlackRockChessModel:GetShopIds()
    local template = self:_GetActivityConfig()
    if not XTool.IsNumberValid(template.ShopIds) then
        return {}
    end
    return template.ShopIds
end

function XBlackRockChessModel:IsWeaponUnlock(weaponId)
    local defaultWeaponId = self:GetDefaultWeapon()
    if defaultWeaponId == weaponId then
        return true
    end
    return self._Activity and self._Activity:IsWeaponUnlock(weaponId) or false
end

function XBlackRockChessModel:IsSkillUnlock(skillId)
    if self:WeaponSkillIsDefault(skillId) then
        return true
    end
    return self._Activity:IsSkillUnlock(skillId)
end

function XBlackRockChessModel:GetArchiveData()
    if XTool.IsTableEmpty(self._ArchiveMap) then
        local archives = self._ConfigUtil:GetByTableKey(TableKey.BlackRockChessArchive)
        for _, v in pairs(archives) do
            local data = self._ArchiveMap[v.Type]
            if not data then
                local archiveType = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BlackRockChessArchiveType, v.Type)
                data = {}
                data.Name = archiveType and archiveType.Name or ""
                data.archives = {}
                self._ArchiveMap[v.Type] = data
            end
            table.insert(data.archives, v)
        end
    end
    return self._ArchiveMap
end

function XBlackRockChessModel:GetGlobalBuffDict()
    return self._Activity and self._Activity:GetGlobalBuffDict() or {}
end

function XBlackRockChessModel:GetActivityProgress()
    local normal1 = self:GetChapterStageIds(XEnumConst.BLACK_ROCK_CHESS.CHAPTER_ID.CHAPTER_ONE, XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.NORMAL)
    local normal2 = self:GetChapterStageIds(XEnumConst.BLACK_ROCK_CHESS.CHAPTER_ID.CHAPTER_TWO, XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.NORMAL)
    
    local sum, total = 0, 0
    for _, stageId in ipairs(normal1) do
        total = total + 1
        local value = self._Activity:IsStagePass(stageId) and 1 or 0
        sum = sum + value
    end

    for _, stageId in ipairs(normal2) do
        total = total + 1
        local value = self._Activity:IsStagePass(stageId) and 1 or 0
        sum = sum + value
    end
    
    local hard1 = self:GetChapterStageIds(XEnumConst.BLACK_ROCK_CHESS.CHAPTER_ID.CHAPTER_ONE, XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.HARD)
    local hard2 = self:GetChapterStageIds(XEnumConst.BLACK_ROCK_CHESS.CHAPTER_ID.CHAPTER_TWO, XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.HARD)

    for _, stageId in ipairs(hard1) do
        total = total + self:GetStageMaxStar(stageId)
        sum = sum + self._Activity:GetStageStar(stageId)
    end

    for _, stageId in ipairs(hard2) do
        total = total + self:GetStageMaxStar(stageId)
        sum = sum + self:GetStageStar(stageId)
    end
    return sum / total
end

--endregion------------------Activity finish------------------

--region   ------------------Chapter start-------------------

--- 章节配置
---@param chapterId number
---@param difficulty number
---@return XTableBlackRockChessChapter
--------------------------
function XBlackRockChessModel:_GetChapterConfig(chapterId, difficulty)
    if not self._ChapterTemplate then
        self._ChapterTemplate = {}
        ---@type table<number, XTableBlackRockChessChapter>
        local templates = self._ConfigUtil:GetByTableKey(TableKey.BlackRockChessChapter)
        for _, template in pairs(templates) do
            if not self._ChapterTemplate[template.ChapterId] then
                self._ChapterTemplate[template.ChapterId] = {}
            end
            self._ChapterTemplate[template.ChapterId][template.Type] = template
        end
    end
    local template = self._ChapterTemplate[chapterId][difficulty]
    if not template then
        XLog.Error("读取章节配置失败(BlackRockChessChapter.tab)，ChapterId = " .. chapterId .. ", Type = " .. difficulty)
        return
    end
    return template
end

function XBlackRockChessModel:GetChapterStartTime(chapterId, difficulty)
    local template = self:_GetChapterConfig(chapterId, difficulty)
    if not template then
        return 0
    end
    return XFunctionManager.GetStartTimeByTimeId(template.TimeId)
end

function XBlackRockChessModel:GetChapterStopTime(chapterId, difficulty)
    local template = self:_GetChapterConfig(chapterId, difficulty)
    if not template then
        return 0
    end
    return XFunctionManager.GetEndTimeByTimeId(template.TimeId)
end

function XBlackRockChessModel:IsChapterInTime(chapterId, difficulty, defaultOpen)
    local template = self:_GetChapterConfig(chapterId, difficulty)
    if not template then
        return 0
    end
    return XFunctionManager.CheckInTimeByTimeId(template.TimeId, defaultOpen)
end

function XBlackRockChessModel:GetChapterName(chapterId, difficulty)
    local template = self:_GetChapterConfig(chapterId, difficulty)
    if not template then
        return ""
    end
    return template.Name
end

function XBlackRockChessModel:GetChapterStageIds(chapterId, difficulty)
    local template = self:_GetChapterConfig(chapterId, difficulty)
    if not template then
        return {}
    end
    return template.StageIds
end

function XBlackRockChessModel:CheckChapterCondition(chapterId, difficulty)
    local template = self:_GetChapterConfig(chapterId, difficulty)
    if not template then
        return false, ""
    end
    local timeId = template.TimeId
    if XTool.IsNumberValid(timeId) then
        local timeOfNow = XTime.GetServerNowTimestamp()
        local timeOfBgn = XFunctionManager.GetStartTimeByTimeId(timeId)
        local timeOnEnd = XFunctionManager.GetEndTimeByTimeId(timeId)
        -- 未到开放时间
        if timeOfBgn > timeOfNow then
            return false, XUiHelper.GetText("ScheOpenCountdown", XTime.TimestampToGameDateTimeString(timeOfBgn, "yyyy-MM-dd"))

        elseif timeOnEnd < timeOfNow then --活动结束
            return false, XUiHelper.GetText("ActivityAlreadyOver")
        end
    end
    
    local conditionId = template.Condition
    if not XTool.IsNumberValid(conditionId) then
        return true, ""
    end
    return XConditionManager.CheckCondition(conditionId)
end

--endregion------------------Chapter finish------------------

--region   ------------------Stage start-------------------

--- 关卡配置
---@param stageId number
---@return XTableBlackRockChessStage
--------------------------
function XBlackRockChessModel:GetStageConfig(stageId)
    local template = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BlackRockChessStage, stageId)
    if not template then
        XLog.Error("获取关卡配置失败(BlackRockChessStage.tab) StageId = " .. stageId)
        return
    end
    return template
end

function XBlackRockChessModel:GetStageLayoutId(stageId)
    local template = self:GetStageConfig(stageId)
    if not template then
        return 0
    end
    return template.LayoutId
end

function XBlackRockChessModel:GetStageDifficulty(stageId)
    local _, difficulty = self:GetStageChapterAndDifficulty(stageId)
    return difficulty
end

function XBlackRockChessModel:IsHardStage(stageId)
    return self:GetStageDifficulty(stageId) == XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.HARD
end

---@return number,number
function XBlackRockChessModel:GetStageChapterAndDifficulty(stageId)
    if not self._StageChapterDifficlityMap then
        self._StageChapterDifficlityMap = {}
        local templates = self._ConfigUtil:GetByTableKey(TableKey.BlackRockChessChapter)
        for _, v in pairs(templates) do
            for _, stage in pairs(v.StageIds) do
                self._StageChapterDifficlityMap[stage] = { v.ChapterId, v.Type }
            end
        end
    end
    local data = self._StageChapterDifficlityMap[stageId]
    if not data then
        XLog.Error("BlackRockChessChapter表中没有配置关卡：" .. stageId)
        return 1, 1
    end
    return data[1], data[2]
end

function XBlackRockChessModel:IsStagePass(stageId)
    return self._Activity:IsStagePass(stageId)
end

function XBlackRockChessModel:GetStageStar(stageId)
    return self._Activity:GetStageStar(stageId)
end

function XBlackRockChessModel:GetStageMaxStar(stageId)
    return self:IsHardStage(stageId) and MAX_STAR or 0
end
--endregion------------------Stage finish------------------

--region   ------------------Layout start-------------------

--- 布局配置
---@param layoutId number
---@return XTableBlackRockChessLayout[]
--------------------------
function XBlackRockChessModel:GetLayoutList(layoutId)
    if not self._LayoutTemplate then
        self._LayoutTemplate = {}
        ---@type table<number, XTableBlackRockChessLayout>
        local templates = self._ConfigUtil:GetByTableKey(TableKey.BlackRockChessLayout)
        for _, template in pairs(templates) do
            local lId = template.LayoutId
            if not self._LayoutTemplate[lId] then
                self._LayoutTemplate[lId] = {}
            end
            table.insert(self._LayoutTemplate[lId], template)
        end
    end
    
    local templateList = self._LayoutTemplate[layoutId]
    if not templateList then
        XLog.Error("获取布局配置失败(BlackRockChessLayout.tab) LayoutId = " .. layoutId)
        return
    end
    return templateList
end

--endregion------------------Layout finish------------------

--region   ------------------Piece start-------------------

--- 棋子配置
---@param pieceId number
---@return XTableBlackRockChessPiece
--------------------------
function XBlackRockChessModel:GetPieceConfig(pieceId)
    local template = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BlackRockChessPiece, pieceId)
    if not template then
        XLog.Error("获取棋子配置失败(BlackRockChessPiece.tab) Id = " .. pieceId)
        return
    end
    return template
end

function XBlackRockChessModel:GetPiecePrefab(pieceId)
    if pieceId == PlayerMemberId then
        return self:GetClientConfigWithIndex("CharacterPrefab", 1)
    end
    local template = self:GetPieceConfig(pieceId)
    if not template then
        return ""
    end
    
    return template.Prefab
end

function XBlackRockChessModel:GetPieceType(pieceId)
    local template = self:GetPieceConfig(pieceId)
    if not template then
        return 0
    end
    return template.Type
end
--endregion------------------Piece finish------------------

--region   ------------------Weapon start-------------------
---@return XTableBlackRockChessWeapon
function XBlackRockChessModel:_GetWeaponConfig(weaponId)
    local template = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BlackRockChessWeapon, weaponId)
    return template
end

---@return XTableBlackRockChessWeaponSkill
function XBlackRockChessModel:GetWeaponSkillConfig(skillId)
    local template = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BlackRockChessWeaponSkill, skillId)
    return template
end

function XBlackRockChessModel:GetWeaponType(weaponId)
    local template = self:_GetWeaponConfig(weaponId)
    return template.Type
end

function XBlackRockChessModel:GetWeaponIcon(weaponId)
    local template = self:_GetWeaponConfig(weaponId)
    return template.Icon
end

function XBlackRockChessModel:GetWeaponIds()
    local templates = self._ConfigUtil:GetByTableKey(TableKey.BlackRockChessWeapon)
    local list = {}
    for id, _ in pairs(templates) do
        table.insert(list, id)
    end
    
    return list
end

function XBlackRockChessModel:GetWeaponIdByType(weaponType)
    local templates = self._ConfigUtil:GetByTableKey(TableKey.BlackRockChessWeapon)
    local weaponId
    for id, template in pairs(templates) do
        if template.Type == weaponType then
            weaponId = id
            break
        end
    end

    return weaponId
end

function XBlackRockChessModel:GetWeaponName(weaponId)
    local template = self:_GetWeaponConfig(weaponId)
    return template and template.Name or ""
end

function XBlackRockChessModel:GetWeaponDesc(weaponId)
    local template = self:_GetWeaponConfig(weaponId)
    return template and template.Desc or ""
end

function XBlackRockChessModel:GetWeaponUnlockDesc(weaponId)
    local template = self:_GetWeaponConfig(weaponId)
    return template and template.UnlockDesc or ""
end

function XBlackRockChessModel:GetWeaponMapIcon(weaponId)
    local template = self:_GetWeaponConfig(weaponId)
    return template and template.MapIcon or ""
end

function XBlackRockChessModel:GetWeaponSkillIds(weaponId)
    local template = self:_GetWeaponConfig(weaponId)
    return template and template.SkillIds or {}
end

function XBlackRockChessModel:GetWeaponSkillIcon(skillId)
    local template = self:GetWeaponSkillConfig(skillId)
    return template and template.Icon or ""
end

function XBlackRockChessModel:WeaponSkillIsDefault(skillId)
    local template = self:GetWeaponSkillConfig(skillId)
    return template and template.IsDefault == 1 or false
end

function XBlackRockChessModel:GetWeaponSkillCost(skillId)
    local template = self:GetWeaponSkillConfig(skillId)
    return template and template.Cost or 0
end

--endregion------------------Weapon finish------------------

--region   ------------------Buff start-------------------

---@return XTableBlackRockChessBuff
function XBlackRockChessModel:GetBuffConfig(buffId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BlackRockChessBuff, buffId)
end

---@return XTableBlackRockChessBuff[]
function XBlackRockChessModel:GetPassiveSkill()
    local skills = {}
    local templates = self._ConfigUtil:GetByTableKey(TableKey.BlackRockChessBuff)
    for _, v in pairs(templates) do
        if v.TargetType[1] == -1 then
            table.insert(skills, v)
        end
    end
    return skills
end

--endregion------------------Buff finish------------------

--region   ------------------Handbook start-------------------

function XBlackRockChessModel:GetHandbookConfigs()
    local configs = self._ConfigUtil:GetByTableKey(TableKey.BlackRockChessHandbook)
    return configs or {}
end

---@return XTableBlackRockChessHandbook[]
function XBlackRockChessModel:GetHandBookChessConfigs()
    if not self._HandbookChess then
        self._HandbookChess = {}
        local configs = self:GetHandbookConfigs()
        for _, v in pairs(configs) do
            if v.HandbookType == 2 then
                self._HandbookChess[v.Type] = v
            end
        end
    end
    return self._HandbookChess
end

--endregion------------------Handbook finish------------------

--region   ------------------ClientConfig start-------------------

---@return XTableBlackRockChessConfig
function XBlackRockChessModel:GetClientConfig(key)
    local template = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BlackRockChessConfig, key)
    return template
end

---@return string
function XBlackRockChessModel:GetClientConfigWithIndex(key, index)
    local template = self:GetClientConfig(key)
    return template and template.Values[index] or ""
end

function XBlackRockChessModel:GetPieceMoveConfig()
    local template = self:GetClientConfig("MoveConfig")
    if not template then
        return 1, 2
    end
    return tonumber(template.Values[1]), tonumber(template.Values[2])
end

--endregion------------------ClientConfig finish------------------

--region   ------------------Reinforce start-------------------

---@return XTableBlackRockChessReinforce
function XBlackRockChessModel:GetReinforceConfig(reinforceId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BlackRockChessReinforce, reinforceId)
end

--endregion------------------Reinforce finish------------------

--region   ------------------Condition start-------------------

---@return XTableBlackRockChessCondition
function XBlackRockChessModel:GetConditionConfig(conditionId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BlackRockChessCondition, conditionId)
end

--endregion------------------Condition finish------------------

--region   ------------------StarReward start-------------------

function XBlackRockChessModel:GetStarRewardByTemplateId(templateId)
    if not self._StarRewardTemplates then
        self._StarRewardTemplates = {}
        local templates = self._ConfigUtil:GetByTableKey(TableKey.BlackRockChessStarReward)
        for _, v in pairs(templates) do
            if not self._StarRewardTemplates[v.TemplateId] then
                self._StarRewardTemplates[v.TemplateId] = {}
            end
            self._StarRewardTemplates[v.TemplateId][v.Star] = v
        end
    end
    return self._StarRewardTemplates[templateId]
end

--endregion------------------StarReward finish------------------

--region   ------------------特效 start-------------------

---@return XTableBlackRockChessEffect
function XBlackRockChessModel:GetEffectConfig(effectId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BlackRockChessEffect, effectId)
end


--endregion------------------特效 finish------------------

--endregion------------------Table Config finish------------------


--region   ------------------Agency start-------------------

function XBlackRockChessModel:GetCurEnergy()
    return self._CurEnergy
end

function XBlackRockChessModel:UpdateEnergy(value)
    self._CurEnergy = value
end

function XBlackRockChessModel:IsExtraRound()
    return self._IsExtraRound
end

function XBlackRockChessModel:UpdateExtraRound(value)
    self._IsExtraRound = value
end

--endregion------------------Agency finish------------------

--region   ------------------RedPoint start-------------------

local function CheckRedPointBase()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.BlackRockChess) then
        return false
    end
    ---@type XBlackRockChessAgency
    local ag = XMVCA:GetAgency(ModuleId.XBlackRockChess)
    if not ag or not ag:IsOpen() then
        return false
    end

    return true
end

function XBlackRockChessModel:GetCookieKey(key)
    local activityId = self._Activity and self._Activity:GetActivityId() or 0
    return string.format("BLACK_ROCK_CHESS_LOCAL_DATA_ID_%s_%s_KEY_%s", XPlayer.Id, activityId, key)
end

--- 活动入口蓝点
---@return boolean
--------------------------
function XBlackRockChessModel:CheckEntrancePoint()
    if self:CheckChapterTwoRedPoint() then
        return true
    end

    if self:CheckHardRedPoint() then
        return true
    end
    
    return false
end

--- 深入对局蓝点
---@return boolean
--------------------------
function XBlackRockChessModel:CheckChapterTwoRedPoint()
    if not CheckRedPointBase() then
        return false
    end

    local open, _ = self:CheckChapterCondition(XEnumConst.BLACK_ROCK_CHESS.CHAPTER_ID.CHAPTER_TWO, 
            XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.NORMAL)
    if not open then
        return false
    end

    local key = self:GetCookieKey("CHAPTER_TWO_UNLOCK")
    if not XSaveTool.GetData(key) then
        return true
    end
    return false
end

--标记已读
function XBlackRockChessModel:MarkChapterTwoRedPoint()
    if not CheckRedPointBase() then
        return
    end

    local open, _ = self:CheckChapterCondition(XEnumConst.BLACK_ROCK_CHESS.CHAPTER_ID.CHAPTER_TWO, 
            XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.NORMAL)
    if not open then
        return
    end
    local key = self:GetCookieKey("CHAPTER_TWO_UNLOCK")
    if XSaveTool.GetData(key) then
        return
    end

    XSaveTool.SaveData(key, true)
end

function XBlackRockChessModel:_CheckSingleHardChapterRedPoint(hardChapterId)
    local open, _ = self:CheckChapterCondition(hardChapterId, XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.HARD)
    if not open then
        return false
    end
    local key = self:GetCookieKey("CHAPTER_HARD_UNLOCK_" .. hardChapterId)
    if not XSaveTool.GetData(key) then
        return true
    end

    return false
end

function XBlackRockChessModel:CheckHardRedPoint(hardChapterId)
    if not CheckRedPointBase() then
        return false
    end
    if not XTool.IsNumberValid(hardChapterId) then
        local chapterIds = { 
            XEnumConst.BLACK_ROCK_CHESS.CHAPTER_ID.CHAPTER_ONE, 
            XEnumConst.BLACK_ROCK_CHESS.CHAPTER_ID.CHAPTER_TWO
        }
        for _, chapterId in pairs(chapterIds) do
            if self:_CheckSingleHardChapterRedPoint(chapterId) then
                return true
            end
        end
    else
        return self:_CheckSingleHardChapterRedPoint(hardChapterId)
    end
    return false
end

function XBlackRockChessModel:MarkHardChapterRedPoint(hardChapterId)
    if not XTool.IsNumberValid(hardChapterId) then
        return
    end
    local open, _ = self:CheckChapterCondition(hardChapterId, XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.HARD)
    if not open then
        return
    end
    local key = self:GetCookieKey("CHAPTER_HARD_UNLOCK_" .. hardChapterId)
    if XSaveTool.GetData(key) then
        return
    end
    XSaveTool.SaveData(key, true)
end
--endregion------------------RedPoint finish------------------


return XBlackRockChessModel