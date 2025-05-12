---@class XBlackRockChessModel : XModel
---@field private _Activity XBlackRockChessActivity
---@field private _ChapterTemplate table<number, table<number, XTableBlackRockChessChapter>>
---@field private _LayoutTemplate table<number, XTableBlackRockChessLayout[]>
local XBlackRockChessModel = XClass(XModel, "XBlackRockChessModel")

local TableKey = {
    -- 活动总控
    BlackRockChessActivity = { CacheType = XConfigUtil.CacheType.Normal },
    -- 活动章节
    BlackRockChessChapter = { CacheType = XConfigUtil.CacheType.Normal },
    -- 活动关卡
    BlackRockChessStage = { CacheType = XConfigUtil.CacheType.Normal },
    -- 关卡布局
    BlackRockChessLayout = { CacheType = XConfigUtil.CacheType.Temp },
    -- 棋子配置
    BlackRockChessPiece = {},
    -- 武器配置
    BlackRockChessWeapon = {},
    -- 武器技能
    BlackRockChessWeaponSkill = {},
    -- 客户端配置
    BlackRockChessConfig = { CacheType = XConfigUtil.CacheType.Normal, DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.String, Identifier = "Key" },
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
    -- 角色
    BlackRockChessCharacter = {},
    -- 角色技能
    BlackRockChessCharacterSkill = {},
    -- 角色/棋子喊话
    ChessGrowls = { DirPath = XConfigUtil.DirectoryType.Client },
    -- 通讯
    ChessCommunication = { DirPath = XConfigUtil.DirectoryType.Client },
    -- 友方棋子
    BlackRockChessPartnerPiece = {},
    -- 节点组
    BlackRockChessNodeGroup = { CacheType = XConfigUtil.CacheType.Normal },
    -- 节点
    BlackRockChessFightNode = { CacheType = XConfigUtil.CacheType.Normal },
    -- 局内商品
    BlackRockChessShopGoods = {},
    -- 局内商店
    BlackRockChessShop = {},
    -- 技能cd（原BlackRockChessWeaponSkill的cd字段废弃）
    BlackRockChessWeaponSkillCd = {},
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

--最大星级
local MAX_STAR = 3

function XBlackRockChessModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    
    self._ConfigUtil:InitConfigByTableKey("BlackRockChess", TableKey)

    self._ArchiveMap = {}
    
    self._CurEnergy = 0
    
    self._CurSelectActorId = 0
    
    self._IsExtraRound = false
    
    self._IsNeedRequestShop = true
    self._ShopRedPointCache = {}
end

function XBlackRockChessModel:ClearPrivate()
    --这里执行内部数据清理
    self._ChapterTemplate = nil
    self._LayoutTemplate = nil
    self._CharacterTypeDict = nil
    self._GrowlsDict = nil
    self._CurEnergy = 0
    self._ShopRedPointCache = {}
    self._IsExtraRound = false
    self._NodeGroup2NodeMap = nil
    self._PartnerLevelUpDict = nil
    self._WeaponSkillCdDict = nil
    self._MyRankData = nil
    self._RankDatas = nil
end

function XBlackRockChessModel:ResetAll()
    --这里执行重登数据清理
    if self._Activity then
        self._Activity:Reset()
    end
    self._IsNeedRequestShop = true
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
    self._Activity:UpdatePassChapters(notifyData.PassChapters)
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

function XBlackRockChessModel:GetCurrencyIds()
    local template = self:_GetActivityConfig()
    return template and template.CurrencyIds or {}
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

---@return XTableChessCommunication
function XBlackRockChessModel:GetCommunicationConfig(communicationId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.ChessCommunication, communicationId)
end

function XBlackRockChessModel:GetGlobalBuffDict()
    return self._Activity and self._Activity:GetGlobalBuffDict() or {}
end

function XBlackRockChessModel:GetActivityProgress()
    local cur, total = 0, 0
    for _, chapterId in pairs(self:_GetActivityConfig().Chapters) do
        local stageIds = self:GetChapterStageIds(chapterId, XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.NORMAL)
        for _, stageId in pairs(stageIds) do
            if self:IsStagePass(stageId) then
                cur = cur + 1
            end
            total = total + 1
        end
    end
    return cur / total
end

function XBlackRockChessModel:GetRetractCount()
    return self._Activity and self._Activity:GetRetractCount() or 0
end

function XBlackRockChessModel:GetShopReminderTimeId()
    local template = self:_GetActivityConfig()
    return template and template.ShopReminderTimeId or 0
end

function XBlackRockChessModel:UpdateNodeInfo(chessInfo)
    if XTool.IsTableEmpty(chessInfo) then
        return
    end
    self._Activity:UpdateNodeInfo(chessInfo.NodeGroupId, chessInfo.NodeIdx)
end

--endregion------------------Activity finish------------------

--region   ------------------Chapter start-------------------

function XBlackRockChessModel:InitChapterDifficultyMap()
    if not self._ChapterTemplate then
        self._ChapterTemplate = {}
        local chapterIds = self:_GetActivityConfig().Chapters
        local chapters = self:GetChapterConfigs()
        for _, chapterId in pairs(chapterIds) do
            for _, chapter in pairs(chapters) do
                if chapter.ChapterId == chapterId then
                    if not self._ChapterTemplate[chapter.ChapterId] then
                        self._ChapterTemplate[chapter.ChapterId] = {}
                    end
                    self._ChapterTemplate[chapter.ChapterId][chapter.Type] = chapter
                end
            end
        end
    end
end

--- 章节配置
---@param chapterId number
---@param difficulty number
---@return XTableBlackRockChessChapter
--------------------------
function XBlackRockChessModel:GetChapterConfig(chapterId, difficulty)
    self:InitChapterDifficultyMap()
    local template = self._ChapterTemplate[chapterId][difficulty]
    if not template then
        XLog.Error("读取章节配置失败(BlackRockChessChapter.tab)，ChapterId = " .. chapterId .. ", Type = " .. difficulty)
        return
    end
    return template
end

function XBlackRockChessModel:GetChapterDifficultyMap()
    self:InitChapterDifficultyMap()
    return self._ChapterTemplate
end

---@return XTableBlackRockChessChapter[]
function XBlackRockChessModel:GetChapterConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.BlackRockChessChapter)
end

---@return XTableBlackRockChessChapter
function XBlackRockChessModel:GetChapterById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BlackRockChessChapter, id)
end

function XBlackRockChessModel:GetChapterStartTime(chapterId, difficulty)
    local template = self:GetChapterConfig(chapterId, difficulty)
    if not template then
        return 0
    end
    return XFunctionManager.GetStartTimeByTimeId(template.TimeId)
end

function XBlackRockChessModel:GetChapterStopTime(chapterId, difficulty)
    local template = self:GetChapterConfig(chapterId, difficulty)
    if not template then
        return 0
    end
    return XFunctionManager.GetEndTimeByTimeId(template.TimeId)
end

function XBlackRockChessModel:IsChapterInTime(chapterId, difficulty, defaultOpen)
    local template = self:GetChapterConfig(chapterId, difficulty)
    if not template then
        return 0
    end
    return XFunctionManager.CheckInTimeByTimeId(template.TimeId, defaultOpen)
end

function XBlackRockChessModel:GetChapterName(chapterId, difficulty)
    local template = self:GetChapterConfig(chapterId, difficulty)
    if not template then
        return ""
    end
    return template.Name
end

function XBlackRockChessModel:GetChapterStageIds(chapterId, difficulty)
    local template = self:GetChapterConfig(chapterId, difficulty)
    if not template then
        return {}
    end
    return template.StageIds
end

function XBlackRockChessModel:CheckChapterCondition(chapterId, difficulty)
    local template = self:GetChapterConfig(chapterId, difficulty)
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

function XBlackRockChessModel:IsChapterPass(chapterId)
    return self._Activity:IsChapterPass(chapterId)
end

function XBlackRockChessModel:GetChapterIdByStage(stageId)
    if not self._ChapterIdStageMap then
        self._ChapterIdStageMap = {}
        for _, cfg in pairs(self:GetChapterConfigs()) do
            for _, stageId in pairs(cfg.StageIds) do
                self._ChapterIdStageMap[stageId] = cfg.ChapterId
            end
        end
    end
    return self._ChapterIdStageMap[stageId]
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

function XBlackRockChessModel:GetStageChessBoardType(stageId)
    local template = self:GetStageConfig(stageId)
    return template and template.ChessBoardType or 1
end

function XBlackRockChessModel:GetStageRetractCount(stageId)
    local template = self:GetStageConfig(stageId)
    return template and template.RetractTimes or 0
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
        local templates = self:GetChapterConfigs()
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
    if not self._Activity then
        return false
    end
    return self._Activity:IsStagePass(stageId)
end

function XBlackRockChessModel:GetStageStar(stageId)
    return self._Activity:GetStageStar(stageId)
end

function XBlackRockChessModel:GetStgaeScore(stageId)
    return self._Activity:GetStgaeScore(stageId)
end

function XBlackRockChessModel:GetStageMaxStar(stageId)
    return self:IsHardStage(stageId) and MAX_STAR or 0
end

function XBlackRockChessModel:GetStageEnterStoryId(stageId)
    local template = self:GetStageConfig(stageId)
    return template and template.EnterStoryId or 0
end

function XBlackRockChessModel:GetStageExitStoryId(stageId)
    local template = self:GetStageConfig(stageId)
    return template and template.ExitStoryId or 0
end

function XBlackRockChessModel:GetStageEnterCommunicationId(stageId)
    local template = self:GetStageConfig(stageId)
    return template and template.EnterCommunicationId or 0
end

function XBlackRockChessModel:GetStageExitCommunicationId(stageId)
    local template = self:GetStageConfig(stageId)
    return template and template.ExitCommunicationId or 0
end

function XBlackRockChessModel:GetStageTargetCondition(stageId)
    local template = self:GetStageConfig(stageId)
    return template and template.TargetCondition
end
--endregion------------------Stage finish------------------

--region 节点

---@return XTableBlackRockChessFightNode[]
function XBlackRockChessModel:GetNodeCfgsByNodeGroupId(nodeGroupId)
    if not self._NodeGroup2NodeMap then
        ---@type table<number,XTableBlackRockChessFightNode[]>
        self._NodeGroup2NodeMap = {}
        ---@type XTableBlackRockChessNodeGroup[]
        local configs = self._ConfigUtil:GetByTableKey(TableKey.BlackRockChessNodeGroup)
        for _, cfg in pairs(configs) do
            local data = self._NodeGroup2NodeMap[cfg.GroupId] or {}
            table.insert(data, self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BlackRockChessFightNode, cfg.NodeId))
            self._NodeGroup2NodeMap[cfg.GroupId] = data
        end
    end
    return self._NodeGroup2NodeMap[nodeGroupId]
end

--endregion

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

function XBlackRockChessModel:GetMemberInitPos(layoutId, memberId)
    local templateList = self:GetLayoutList(layoutId)
    if XTool.IsTableEmpty(templateList) then
        return 0, 0
    end
    for _, template in ipairs(templateList) do
        if template.Member == memberId then
            return template.X, template.Y
        end
    end
    return 0, 0
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

---@return XTableBlackRockChessPartnerPiece
function XBlackRockChessModel:GetPartnerPieceById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BlackRockChessPartnerPiece, id)
end

---@return XTableBlackRockChessPartnerPiece[]
function XBlackRockChessModel:GetPartnerPieceConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.BlackRockChessPartnerPiece)
end

function XBlackRockChessModel:InitPartnerLvUpData()
    if not self._MaxPieceLevel or not self._PartnerLevelUpDict then
        self._MaxPieceLevel = 0
        self._PartnerLevelUpDict = {}
        local configs = self:GetPartnerPieceConfigs()
        for _, cfg in pairs(configs) do
            if self._MaxPieceLevel < cfg.Level then
                self._MaxPieceLevel = cfg.Level
            end
            local group = self._PartnerLevelUpDict[cfg.OriginalPiece] or {}
            group[cfg.Level] = cfg
            self._PartnerLevelUpDict[cfg.OriginalPiece] = group
        end
    end
end

function XBlackRockChessModel:GetPartnerMaxPieceLevel()
    self:InitPartnerLvUpData()
    return self._MaxPieceLevel
end

function XBlackRockChessModel:IsPartnerLevelMax(configId)
    self:InitPartnerLvUpData()
    local template = self:GetPartnerPieceById(configId)
    if template and self._PartnerLevelUpDict[template.OriginalPiece] then
        return self._PartnerLevelUpDict[template.OriginalPiece][template.Level + 1] ~= nil
    end
    return false
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

function XBlackRockChessModel:GetWeaponTypeBySkillId(skillId)
    ---@type XTableBlackRockChessWeapon[]
    local configs = self._ConfigUtil:GetByTableKey(TableKey.BlackRockChessWeapon)
    for _, v in pairs(configs) do
        if table.indexof(v.SkillIds, skillId) then
            return v.Type
        end
    end
    return nil
end

function XBlackRockChessModel:GetWeaponType(weaponId)
    local template = self:_GetWeaponConfig(weaponId)
    return template.Type
end

function XBlackRockChessModel:GetWeaponMoveRange(weaponId)
    local template = self:_GetWeaponConfig(weaponId)
    return template.Step
end

function XBlackRockChessModel:GetWeaponIcon(weaponId)
    local template = self:_GetWeaponConfig(weaponId)
    return template.Icon
end

function XBlackRockChessModel:GetWeaponCircleIcon(weaponId)
    local template = self:_GetWeaponConfig(weaponId)
    return template.CircleIcon
end

function XBlackRockChessModel:GetWeaponCircleIcon(weaponId)
    local template = self:_GetWeaponConfig(weaponId)
    return template.CircleIcon
end

function XBlackRockChessModel:GetWeaponModelUrl(weaponId)
    local template = self:_GetWeaponConfig(weaponId)
    return template.ModelUrl
end

function XBlackRockChessModel:GetWeaponControllerUrl(weaponId)
    local template = self:_GetWeaponConfig(weaponId)
    return template.ControllerUrl
end

function XBlackRockChessModel:GetWeaponName(weaponId)
    local template = self:_GetWeaponConfig(weaponId)
    return template and template.Name or ""
end

function XBlackRockChessModel:GetWeaponDesc(weaponId)
    local template = self:_GetWeaponConfig(weaponId)
    return template and template.Desc or ""
end

function XBlackRockChessModel:GetWeaponDesc2(weaponId)
    local template = self:_GetWeaponConfig(weaponId)
    return template and template.Desc2 or ""
end

function XBlackRockChessModel:GetWeaponUnlockDesc(weaponId)
    local template = self:_GetWeaponConfig(weaponId)
    return template and template.UnlockDesc or ""
end

function XBlackRockChessModel:GetWeaponMapIcon(weaponId)
    local template = self:_GetWeaponConfig(weaponId)
    return template and template.MapIcon or ""
end

function XBlackRockChessModel:GetWeaponMapIcon2(weaponId)
    local template = self:_GetWeaponConfig(weaponId)
    return template and template.MapIcon2 or ""
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
    return template and template.IsDefault
end

function XBlackRockChessModel:GetWeaponSkillCost(skillId)
    local template = self:GetWeaponSkillConfig(skillId)
    return template and template.Cost or 0
end

---@return XTableBlackRockChessWeaponSkillCd[]
function XBlackRockChessModel:GetWeaponSkillCdConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.BlackRockChessWeaponSkillCd)
end

---@return XTableBlackRockChessWeaponSkillCd
function XBlackRockChessModel:GetWeaponSkillById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BlackRockChessWeaponSkillCd, id)
end

---@return XTableBlackRockChessWeaponSkillCd
function XBlackRockChessModel:GetWeaponSkillCd(skillId)
    if not self._WeaponSkillCdDict then
        self._WeaponSkillCdDict = {}
        local configs = self:GetWeaponSkillCdConfigs()
        for _, config in pairs(configs) do
            for _, skillId in pairs(config.SkillIds) do
                self._WeaponSkillCdDict[skillId] = config
            end
        end
    end
    return self._WeaponSkillCdDict[skillId]
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
    local template = self:GetClientConfig("GeniusIds")
    for _, v in pairs(template.Values) do
        table.insert(skills, tonumber(v))
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
                self._HandbookChess[v.Param] = v
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

---@return XTableBlackRockChessCondition[]
function XBlackRockChessModel:GetConditionByType(conditionType)
    if not self._CondTypeDict then
        self._CondTypeDict = {}
        ---@type XTableBlackRockChessCondition[]
        local configs = self._ConfigUtil:GetByTableKey(TableKey.BlackRockChessCondition)
        for _, cfg in pairs(configs) do
            local data = self._CondTypeDict[cfg.Type] or {}
            table.insert(data, cfg)
            self._CondTypeDict[cfg.Type] = data
        end
    end
    return self._CondTypeDict[conditionType]
end

--endregion------------------Condition finish------------------

--region   ------------------StarReward start-------------------

---@return XTableBlackRockChessStarReward[]
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

--region   ------------------角色 start-------------------

---@return XTableBlackRockChessCharacter
function XBlackRockChessModel:GetCharacterConfig(characterId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BlackRockChessCharacter, characterId)
end

function XBlackRockChessModel:GetCharacterTypeDict()
    if not XTool.IsTableEmpty(self._CharacterTypeDict) then
        return self._CharacterTypeDict
    end
    self._CharacterTypeDict = {}
    ---@type table<number, XTableBlackRockChessCharacter>
    local templates = self._ConfigUtil:GetByTableKey(TableKey.BlackRockChessCharacter)
    for id, template in pairs(templates) do
        if not self._CharacterTypeDict[template.Type] then
            self._CharacterTypeDict[template.Type] = {}
        end
        table.insert(self._CharacterTypeDict[template.Type], id)
    end
    
    return self._CharacterTypeDict
end

---@return XTableBlackRockChessCharacterSkill
function XBlackRockChessModel:GetCharacterSkillConfig(skillId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BlackRockChessCharacterSkill, skillId)
end

--endregion------------------角色 finish------------------

--region 局内商店

---@return XTableBlackRockChessShopGoods
function XBlackRockChessModel:GetBattleShopGoodById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BlackRockChessShopGoods, id)
end

---@return XTableBlackRockChessShop
function XBlackRockChessModel:GetBattleShopById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BlackRockChessShop, id)
end

--endregion

--region 排行榜

function XBlackRockChessModel:GetRankData(chapterId)
    return self._RankDatas and self._RankDatas[chapterId]
end

-- 返回空表示未上榜
function XBlackRockChessModel:GetMyRankData(chapterId)
    if not self._MyRankData then
        return nil
    end
    if not self._MyRankData[chapterId] then
        local data = self:GetRankData(chapterId)
        for i, rank in ipairs(data.RankPlayerInfos) do
            if rank.Id == XPlayer.Id then
                self._MyRankData[chapterId] = {}
                self._MyRankData[chapterId].Score = rank.Score
                self._MyRankData[chapterId].Rank = i
                break
            end
        end
    end
    return self._MyRankData[chapterId]
end

function XBlackRockChessModel:SetRankData(chapterId, rankData)
    if not self._RankDatas then
        self._RankDatas = {}
    end
    if not self._MyRankData then
        self._MyRankData = {}
    end
    if XTool.IsNumberValid(rankData.Rank) then
        self._MyRankData[chapterId] = {
            Score = rankData.Score,
            Rank = rankData.Rank,
        }
    else
        self._MyRankData[chapterId] = nil
    end
    self._RankDatas[chapterId] = rankData
end

--endregion

function XBlackRockChessModel:InitGrowlsDict()
    self._GrowlsDict = {}
    ---@type table<number, XTableChessGrowls>
    local templates = self._ConfigUtil:GetByTableKey(TableKey.ChessGrowls)
    for id, template in pairs(templates) do
        local belong = template.Belong
        if not self._GrowlsDict[belong] then
            self._GrowlsDict[belong] = {}
        end
        local trigger = template.TriggerType
        if not self._GrowlsDict[belong][trigger] then
            self._GrowlsDict[belong][trigger] = {}
        end
        for _, arg in ipairs(template.BelongArgs) do
            if not self._GrowlsDict[belong][trigger][arg] then
                self._GrowlsDict[belong][trigger][arg] = {}
            end
            if XTool.IsTableEmpty(template.TriggerArgs) then
                self._GrowlsDict[belong][trigger][arg][0] = id
            else
                for _, tArg in ipairs(template.TriggerArgs) do
                    self._GrowlsDict[belong][trigger][arg][tArg] = id
                end
            end
        end
    end
end

---@return XTableChessGrowls
function XBlackRockChessModel:GetChessGrowlsConfig(belong, triggerType, belongArg, triggerArg)
    if not self._GrowlsDict then
        self:InitGrowlsDict()
    end
    if not self._GrowlsDict[belong] then
        return
    end

    if not self._GrowlsDict[belong][triggerType] then
        return
    end

    if not self._GrowlsDict[belong][triggerType][belongArg] then
        return
    end

    triggerArg = triggerArg or 0
    local growlsId = self._GrowlsDict[belong][triggerType][belongArg][triggerArg]
    if not growlsId then
        return
    end
    
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.ChessGrowls, growlsId)
end

function XBlackRockChessModel:GetChessGrowlsTriggerArgs(belong, triggerType, belongArg)
    if not self._GrowlsDict then
        self:InitGrowlsDict()
    end
    if not self._GrowlsDict[belong] then
        return
    end

    if not self._GrowlsDict[belong][triggerType] then
        return
    end
    
    return self._GrowlsDict[belong][triggerType][belongArg]
end

---@return XTableBlackRockChessEffect
function XBlackRockChessModel:GetEffectConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BlackRockChessEffect, id)
end

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

function XBlackRockChessModel:UpdateSelectActor(value)
    self._CurSelectActorId = value
end

function XBlackRockChessModel:IsSelectActor(value)
    return self._CurSelectActorId == value
end

function XBlackRockChessModel:IsContainReinforce()
    return self._ContainReinforce
end

function XBlackRockChessModel:UpdateContainReinforce(value)
    self._ContainReinforce = value
end

function XBlackRockChessModel:SetChessControl(chessControl)
    self._ChessControl = chessControl
end

function XBlackRockChessModel:GetChessControl()
    return self._ChessControl
end

function XBlackRockChessModel:GetCurNodeCfg()
    if not self._Activity then
        return nil
    end
    local nodeGroupId = self._Activity:GetNodeGroupId()
    local nodeIdx = self._Activity:GetNodeIdx()
    if not nodeGroupId or not nodeIdx then
        return nil
    end
    local nodes = self:GetNodeCfgsByNodeGroupId(nodeGroupId)
    if not nodes or not nodes[nodeIdx] then
        local nodeCount = XTool.IsTableEmpty(nodes) and 0 or #nodes
        XLog.Error(string.format("查找当前节点错误：节点总数:%s 当前组Id:%s 当前节点索引:%s", nodeCount, nodeGroupId, nodeIdx))
    end
    return nodes and nodes[nodeIdx]
end

--endregion------------------Agency finish------------------

--region   ------------------RedPoint start-------------------

function XBlackRockChessModel:CheckRedPointBase()
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

function XBlackRockChessModel:_CheckSingleShopRedPoint(shopId)
    if self._ShopRedPointCache and self._ShopRedPointCache[shopId] ~= nil then
        return self._ShopRedPointCache[shopId]
    end
    local dict = {}
    for _, id in ipairs(self:GetCurrencyIds()) do
        dict[id] = XDataCenter.ItemManager.GetCount(id)
    end
    local goodsList = XShopManager.GetShopGoodsList(shopId, true, true)
    local value = false
    for _, goods in ipairs(goodsList) do
        --售罄
        if goods.BuyTimesLimit == goods.TotalBuyTimes and goods.BuyTimesLimit > 0 then
            goto continue
        end
        --货币不足
        for _, consume in ipairs(goods.ConsumeList) do
            local count = dict[consume.Id] or 0
            if count < consume.Count then
                goto continue
            end
        end
        value = true
        break
        ::continue::
    end
    self._ShopRedPointCache[shopId] = value
    
    return value
end

function XBlackRockChessModel:CheckShopRedPoint(shopId)
    if not self:CheckRedPointBase() then
        return false
    end
    --商店未开放
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.ShopCommon) then
        return false
    end
    local timeId = self:GetShopReminderTimeId()
    if not XTool.IsNumberValid(timeId) then
        return false
    end
    --不在开放时间内
    if not XFunctionManager.CheckInTimeByTimeId(timeId, false) then
        return false
    end
    local ids = self:GetCurrencyIds()
    local isEmpty = true
    for _, id in ipairs(ids) do
        local count = XDataCenter.ItemManager.GetCount(id)
        if count > 0 then
            isEmpty = false
            break
        end
    end
    --货币不足
    if isEmpty then
        return false
    end

    local isSingle = XTool.IsNumberValid(shopId)
    if self._IsNeedRequestShop then
        XShopManager.GetShopInfoList(self:GetShopIds(), function()
            self._IsNeedRequestShop = false
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_ACTIVITY_CHAPTER_REFRESH_RED)
        end, XShopManager.ActivityShopType.BlackRockChessShop)
        return false
    end
    if isSingle then
        return self:_CheckSingleShopRedPoint(shopId)
    end

    for _, id in ipairs(self:GetShopIds()) do
        if self:_CheckSingleShopRedPoint(id) then
            return true
        end
    end
    return false
end

function XBlackRockChessModel:ClearShopRedCache()
    self._ShopRedPointCache = {}
end

function XBlackRockChessModel:CloseStageRedPoint(stageId)
    XSaveTool.SaveData(string.format("BlackRockChessStageEnter_%s", stageId), true)
end

function XBlackRockChessModel:IsEverBeenEnterStage(stageId)
    return XSaveTool.GetData(string.format("BlackRockChessStageEnter_%s", stageId)) ~= nil
end
--endregion------------------RedPoint finish------------------


function XBlackRockChessModel:IsShowCueTip()
    local key = self:GetCookieKey("IsAllActorOperaEnd")
    
    local updateTime = XSaveTool.GetData(key)
    if not updateTime then
        return true
    end
    return XTime.GetServerNowTimestamp() >= updateTime
end

function XBlackRockChessModel:SetCueTipValue(isSelect)
    local key = self:GetCookieKey("IsAllActorOperaEnd")
    if not isSelect then
        XSaveTool.RemoveData(key)
    else
        if not self:IsShowCueTip() then
            return
        end
        local updateTime = XTime.GetSeverTomorrowFreshTime()
        XSaveTool.SaveData(key, updateTime)
    end
end

return XBlackRockChessModel