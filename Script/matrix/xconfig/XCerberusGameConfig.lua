require("XConfig/XConfigCenter")
XCerberusGameConfig = XConfigCenter.CreateTableConfig(XCerberusGameConfig, "XCerberusGameConfig", "Fuben/CerberusGame")
--=============
--配置表枚举
--TableName : 表名，对应需要读取的表的文件名字，不写即为枚举的Key字符串
--TableDefindName : 表定于名，默认同表名
--ReadFuncName : 读取表格的方法，默认为ReadByIntKey
--ReadKeyName : 读取表格的主键名，默认为Id
--DirType : 读取的文件夹类型XConfigCenter.DirectoryType，默认是Share
--LogKey : GetCfgByIdKey方法idKey找不到时所输出的日志信息，默认是唯一Id
--=============
XCerberusGameConfig.TableKey = enum({
    CerberusGameActivity = {},
    CerberusGameChallenge = {},
    CerberusGameChapter = {},
    CerberusGameCommunication = {},
    CerberusGameStoryLine = {},
    CerberusGameStoryPoint = {},
    CerberusGameCharacterInfo = { DirType = XConfigCenter.DirectoryType.Client },
    CerberusGameBoss = { DirType = XConfigCenter.DirectoryType.Client }, -- 挑战模式boss表
    CerberusGameRole = { DirType = XConfigCenter.DirectoryType.Client }, -- 角色池
})

XCerberusGameConfig.ChapterIdIndex = {
    Story = 1,
    Challenge = 2,
}

XCerberusGameConfig.StageDifficulty = {
    Normal = 1,
    Hard = 2,
}

XCerberusGameConfig.StoryPointType = 
{
    Story = 1,
    Communicate = 2,
    Battle = 3,
}

XCerberusGameConfig.StoryPointShowType = 
{
    [1] = "GirdStageFight",
    [2] = "GirdStageFightSpecial",
    [3] = "GridBossPrefab",
    [4] = "GridStory1",
    [5] = "GridStory2",
}

-- 默认队伍
XCerberusGameConfig.ChallengeStageStar = 
{
    [0] = "CerberusGameChallengeStageStar0",
    [1] = "CerberusGameChallengeStageStar1",
    [2] = "CerberusGameChallengeStageStar2",
    [3] = "CerberusGameChallengeStageStar3",
}

local ChallegeIdListByDifficulty = {}

function XCerberusGameConfig.CheckIsChallengeStage(stageId)
    return XCerberusGameConfig.GetAllConfigs(XCerberusGameConfig.TableKey.CerberusGameChallenge)[stageId]
end

function XCerberusGameConfig.GetChallegeIdListByDifficulty(difficulty)
    return ChallegeIdListByDifficulty[difficulty]
end

function XCerberusGameConfig.Init()
    XCerberusGameConfig.CreateChallegeIdListByDifficulty()
end

function XCerberusGameConfig.CreateChallegeIdListByDifficulty()
    local allConfig = XCerberusGameConfig.GetAllConfigs(XCerberusGameConfig.TableKey.CerberusGameBoss)
    for k, bossCfg in pairs(allConfig) do
        for i, stageId in pairs(bossCfg.StageId) do
            if XTool.IsTableEmpty(ChallegeIdListByDifficulty[i]) then
                ChallegeIdListByDifficulty[i] = {}
            end
            table.insert(ChallegeIdListByDifficulty[i], stageId)
        end
    end
end
