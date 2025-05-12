---@class XCerberusGameModel : XModel
local XCerberusGameModel = XClass(XModel, "XCerberusGameModel")
local TableKey =
{
    CerberusGameActivity = {},
    CerberusGameChallenge = {},
    CerberusGameChapter = {},
    CerberusGameCommunication = {},
    CerberusGameStoryLine = {},
    CerberusGameStoryPoint = {},
    CerberusGameCharacterInfo = { DirPath = XConfigUtil.DirectoryType.Client },
    CerberusGameCharacterInfoV2P9 = { DirPath = XConfigUtil.DirectoryType.Client, TableDefindName = "XTableCerberusGameCharacterInfo" },
    CerberusGameBoss = { DirPath = XConfigUtil.DirectoryType.Client }, -- 挑战模式boss表
    CerberusGameRole = { DirPath = XConfigUtil.DirectoryType.Client }, -- 角色池
    CerberusGameClientConfig = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Key", ReadFunc =  XConfigUtil.ReadType.String }, -- 客户端杂项
}

function XCerberusGameModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._ConfigUtil:InitConfigByTableKey("Fuben/CerberusGame", TableKey, XConfigUtil.CacheType.Normal)

    self:InitData()
end

-- 初始化数据
function XCerberusGameModel:InitData()
    self.ActivityId = 1 -- 默认给1，改成常驻
    --------- 数据字典
    -- 剧情模式节点字典
    ---@type table<number, XCerberusGameStoryPoint>
    self.StoryPointDic = {}
    ---@type table<number, XCerberusGameStage>
    self.StageIdDataDic = {}
    self.StageTeamInfoByServer = {}
    self.StageIdChapterIdDic = {} -- 根据StageId查找ChapterId
    self.StageIdPointDic = {} -- 根据StageId查找StoryPointId
    --------- 临时变量
    ---@type XCerberusGameStoryPoint
    self.LastSelectXStoryPoint = nil
    self.LastSelectStoryLineDifficulty = nil
    ---@type table<number, XCerberusGameTeam>
    self.ChapterTeamDic = {}
    self.ChallegeIdListByDifficulty = {}
end

function XCerberusGameModel:CreateStageIdPointDic()
    for id, v in pairs(self:GetCerberusGameStoryPoint()) do
        if v.StoryPointType == XEnumConst.CerberusGame.StoryPointType.Story or v.StoryPointType ==  XEnumConst.CerberusGame.StoryPointType.Battle then
            self.StageIdPointDic[tonumber(v.StoryPointTypeParams[1])] = id
        end
    end
end

function XCerberusGameModel:GetStoryPointByStageIdPointDic(stageId)
    if XTool.IsTableEmpty(self.StageIdPointDic) then
        self:CreateStageIdPointDic()
    end
    return self.StageIdPointDic[stageId]
end

function XCerberusGameModel:CreateChallegeIdListByDifficulty()
    local allConfig = self:GetCerberusGameBoss()
    for k, bossCfg in pairs(allConfig) do
        for i, stageId in pairs(bossCfg.StageId) do
            if XTool.IsTableEmpty(self.ChallegeIdListByDifficulty[i]) then
                self.ChallegeIdListByDifficulty[i] = {}
            end
            table.insert(self.ChallegeIdListByDifficulty[i], stageId)
        end
    end
end

function XCerberusGameModel:CteateStageIdChapterIdDic()
    -- 路线图
    local allLineConfigs = self:GetCerberusGameStoryLine()
    for k, v in pairs(allLineConfigs) do
        for k2, storyPointId in pairs(v.StoryPointIds) do
            local storyPointConfig = self:GetCerberusGameStoryPoint()[storyPointId]
            if storyPointConfig.StoryPointType == XEnumConst.CerberusGame.StoryPointType.Battle or storyPointConfig.StoryPointType == XEnumConst.CerberusGame.StoryPointType.Story then
                local stageId = tonumber(storyPointConfig.StoryPointTypeParams[1])
                self.StageIdChapterIdDic[stageId] = v.ChapterId
            end
        end
    end

    -- 挑战模式
    local allConfigsChallenge = self:GetCerberusGameChallenge()
    for stageId, v in pairs(allConfigsChallenge) do
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        stageInfo.Type = XDataCenter.FubenManager.StageType.CerberusGame
        self.StageIdChapterIdDic[stageId] = v.ChapterId
    end
end

function XCerberusGameModel:ClearPrivate()
    --这里执行内部数据清理
end

function XCerberusGameModel:ResetAll()
    --这里执行重登数据清理
    self:InitData()
end

----------public start----------
function XCerberusGameModel:GetTableKey()
    return TableKey or {}
end

function XCerberusGameModel:GetConfigByTableKey(tableKey)
    return self._ConfigUtil:GetByTableKey(tableKey)
end

----------public end----------

----------private start----------


----------private end----------

----------config start----------
function XCerberusGameModel:GetCerberusGameClientConfig()
    return self._ConfigUtil:GetByTableKey(TableKey.CerberusGameClientConfig)
end

function XCerberusGameModel:GetCerberusGameActivity()
    return self._ConfigUtil:GetByTableKey(TableKey.CerberusGameActivity)
end

function XCerberusGameModel:GetCerberusGameChallenge()
    return self._ConfigUtil:GetByTableKey(TableKey.CerberusGameChallenge)
end

function XCerberusGameModel:GetCerberusGameChapter()
    return self._ConfigUtil:GetByTableKey(TableKey.CerberusGameChapter)
end

function XCerberusGameModel:GetCerberusGameCommunication()
    return self._ConfigUtil:GetByTableKey(TableKey.CerberusGameCommunication)
end

function XCerberusGameModel:GetCerberusGameStoryLine()
    return self._ConfigUtil:GetByTableKey(TableKey.CerberusGameStoryLine)
end

function XCerberusGameModel:GetCerberusGameStoryPoint() 
    return self._ConfigUtil:GetByTableKey(TableKey.CerberusGameStoryPoint) 
end

function XCerberusGameModel:GetCerberusGameCharacterInfo() 
    return self._ConfigUtil:GetByTableKey(TableKey.CerberusGameCharacterInfo) 
end

function XCerberusGameModel:GetCerberusGameBoss() 
    return self._ConfigUtil:GetByTableKey(TableKey.CerberusGameBoss) 
end

function XCerberusGameModel:GetCerberusGameRole() 
    return self._ConfigUtil:GetByTableKey(TableKey.CerberusGameRole) 
end

----------config end----------


return XCerberusGameModel