XDormConfig = XDormConfig or {}

-- 加载宿舍类型
XDormConfig.DormDataType = {
    Self = 0,
    Target = 1,
    Template = 2, -- 模板宿舍
    Collect = 3, -- 收藏宿舍
    Provisional = 4, --导入宿舍
    CollectNone = 5,
}

-- 构造体喜欢类型
XDormConfig.CharacterLikeType = {
    LoveType = "LoveType",
    LikeType = "LikeType",
}

-- 仓库Toggle
XDormConfig.DORM_BAG_PANEL_INDEX = {
    FURNITURE = 1, -- 家具
    CHARACTER = 2, -- 构造体
    DRAFT = 3, -- 图纸
}

-- 仓库住户Toggle
XDormConfig.DORM_CHAR_INDEX = {
    CHARACTER = 1, -- 构造体
    EMNEY = 2, -- 侵蚀体
    -- HUMAN = 3, -- 人类
    INFESTOR = 3, -- 授格者
    NIER = 4, -- 联动
}

-- 跳转类型
XDormConfig.VisitDisplaySetType = {
    MySelf = 1,
    MyFriend = 2,
    Stranger = 3
}

-- 访问类型
XDormConfig.VisitTabTypeCfg = {
    MyFriend = 1,
    Visitor = 2
}

-- 宿舍激活状态
XDormConfig.DormActiveState = {
    Active = 0,
    UnActive = 1
}

-- 宿舍构造体抚摸状态
XDormConfig.TouchState = {
    Hide = 0, -- 关闭
    Touch = 1, -- 抚摸
    WaterGun = 2, -- 水枪
    Play = 3, -- 玩耍
    TouchSuccess = 4, -- 抚摸成功
    WaterGunSuccess = 5, -- 水枪成功
    PlaySuccess = 6, --玩耍成功
    Hate = 7, -- 讨厌
    TouchHate = 8, --讨厌抚摸
}

-- 打工状态
XDormConfig.WorkPosState = {
    Working = 1, --打工中
    Worked = 0, --打工完成
    Empty = -1, --空的
    RewardEd = 2, --奖励领取完
    Lock = 3,
}

-- 客户端展示事件Id
XDormConfig.ShowEventId = {
    VitalityAdd = 101, -- 体力增加
    VitalityCut = 102, -- 体力减少
    MoodAdd = 103, -- 心情增加
    MoodCut = 104, -- 心情减少
    VitalitySpeedAdd = 105, -- 体力速度增加
    VitalitySpeedCut = 106, -- 体力速度减少
    MoodSpeedAdd = 107, -- 心情速度增加
    MoodSpeedCut = 108, -- 心情速度减少
}

-- 客户端展示事件Id
XDormConfig.ShowEffectType = {
    Simple = 1, -- 单行模式
    Complex = 2, -- 多行模式
}

-- 客户端展示事件Id
XDormConfig.CompareType = {
    Less = 0, -- 小于等于
    Greater = 1, -- 大于等于
    Equal = 2, -- 等于
}

-- 回复类型
XDormConfig.RecoveryType = {
    PutFurniture = 1, -- 放置家具
    PutCharacter = 2, -- 放置构造体
}

XDormConfig.DormSecondEnter = {
    Task = 1, -- 任务
    Des = 2, -- 描述
    WareHouse = 3, --仓库
    ReName = 4, --改名
    FieldGuilde = 5, --图鉴
    Build = 6, --建造
    Shop = 7, --商店
    Person = 8, --人员
}

XDormConfig.DormAttDesIndex = {
    [1] = "DormScoreAttrADes",
    [2] = "DormScoreAttrBDes",
    [3] = "DormScoreAttrCDes",
}

-- 宿舍人物类型
XDormConfig.DormSex = {
    Man = 1, -- 男构造体
    Woman = 2, -- 女构造体
    Infect = 3, -- 侵蚀体
    Human = 4, -- 人类男
    Huwoman = 5, -- 人类女
    InfestorMale = 6, -- 授格体男
    InfestorFemale = 7, -- 授格体女
    NIER = 8, -- 授格体女
}

-- 宿舍角色性别
XDormConfig.DormCharGender = {
    None = 0,
    Male = 1,
    Female = 2,
    Gan = 3,
    Max = 4,
}

-- 宿舍空间站枚举
XDormConfig.SenceType = {
    One = 1,
    Tow = 2,
}

XDormConfig.DORM_VITALITY_MAX_VALUE = math.floor(CS.XGame.Config:GetInt("DormVitalityMaxValue") / 100)
XDormConfig.DORM_MOOD_MAX_VALUE = math.floor(CS.XGame.Config:GetInt("DormMoodMaxValue") / 100)
XDormConfig.DORM_DRAFT_SHOP_ID = CS.XGame.ClientConfig:GetInt("DormDraftShopId")

XDormConfig.TOUCH_LENGTH = CS.XGame.ClientConfig:GetInt("DormCharacterTouchLength")
XDormConfig.WATERGUN_TIME = CS.XGame.ClientConfig:GetInt("DormCharacterWaterGunTime")
XDormConfig.PLAY_TIME = CS.XGame.ClientConfig:GetInt("DormCharacterPlayTime")
XDormConfig.DISPPEAR_TIME = CS.XGame.ClientConfig:GetInt("DormDetailDisppearTime")
XDormConfig.DRAFT_DIS = CS.XGame.ClientConfig:GetInt("DormDraftDistance")
XDormConfig.TOUCH_CD = CS.XGame.ClientConfig:GetFloat("DormCharacterTouchCD")
XDormConfig.TOUCH_PROP = CS.XGame.ClientConfig:GetFloat("DormCharacterTouchProportion")
XDormConfig.GET_SHARE_ID_INTERVAL = CS.XGame.ClientConfig:GetInt("DormShareWaitTime")
XDormConfig.MAX_SHARE_COUNT = CS.XGame.ClientConfig:GetInt("DormMaxShareCount")

XDormConfig.DormComfortTime = CS.XGame.ClientConfig:GetInt("DormComfortTime") or 1
XDormConfig.CaptureAngleX = CS.XGame.ClientConfig:GetFloat("DormTemplateCaptureAngleX")
XDormConfig.CaptureAngleY = CS.XGame.ClientConfig:GetFloat("DormTemplateCaptureAngleY")
XDormConfig.CaptureDistance = CS.XGame.ClientConfig:GetFloat("DormTemplateCaptureDistance")
XDormConfig.ProvisionalMaXCount = CS.XGame.ClientConfig:GetInt("DormProvisionalMaxCount")
XDormConfig.ShareName = CS.XGame.ClientConfig:GetString("DormTemplateShareName")

local TABLE_DORM_CHARACTER_EVENT_PATH = "Share/Dormitory/Character/DormCharacterEvent.tab"
local TABLE_DORM_CHARACTER_BEHAVIOR_PATH = "Share/Dormitory/Character/DormCharacterBehavior.tab"
local TABLE_DORMITORY_PATH = "Share/Dormitory/Dormitory.tab"
local TABLE_DORMCHARACTERWORK_PATH = "Share/Dormitory/Character/DormCharacterWork.tab"
local TABLE_DORM_CHARACTER_RECOVERY_PATH = "Share/Dormitory/Character/DormCharacterRecovery.tab"
local TABLE_DORM_CHARACTER_FONDLE_PATH = "Share/Dormitory/Character/DormCharacterFondle.tab"
local TABLE_CHARACTER_STYLE_PATH = "Share/Dormitory/Character/DormCharacterStyle.tab"
local TABLE_CHARACTER_REWARD_PATH = "Share/Dormitory/Character/DormCharacterReward.tab"
local TABLE_DORM_BGM_PATH = "Share/Dormitory/DormBgm.tab"
local TABLE_DORM_TEMPLATE_PATH = "Share/Dormitory/DormTemplate.tab"

local TABLE_CHARACTER_MOOD_PATH = "Client/Dormitory/DormCharacterMood.tab"
local TABLE_MOOD_EFFECT_PATH = "Client/Dormitory/DormCharacterEffect.tab"
local TABLE_CHARACTER_DIALOG_PATH = "Client/Dormitory/DormCharacterDialog.tab"
local TABLE_CHARACTER_ACTION_PATH = "Client/Dormitory/DormCharacterAction.tab"
local TABLE_CHARACTER_INTERACTIVE_PATH = "Client/Dormitory/DormInteractiveEvent.tab"
local TABLE_SHOW_EVENT_PATH = "Client/Dormitory/DormShowEvent.tab"
local TABLE_DORM_GUIDE_TASK_PATH = "Client/Dormitory/DormGuideTask.tab"
local TABLE_DORM_TEMPLATE_COLLECT_PATH = "Client/Dormitory/DormTemplateCollect.tab"
local TABLE_DORM_TEMPLATE_GROUP_PATH = "Client/Dormitory/DormTemplateGroup.tab"
local TABLE_DORM_F2C_RELATION_PATH = "Client/Dormitory/DormF2CBehaviorRelation.tab"

local CharacterEventTemplate = {}
local CharacterBehaviorTemplate = {}
local DormitoryTemplate = {}        --宿舍配置表
local CharacterBehaviorStateIndex = {}
local DormCharacterWork = {}        --宿舍打工工位配置表
local DormCharacterRecovery = {}    --构造体回复配置表 table = {characterId = {config1, config2, ...}}
local CharacterStyleTemplate = {}       --客户端构造体风格配置表
local CharacterMoodTemplate = {}        --客户端构造体心情配置表
local MoodEffectTemplate = {}       --构造体表情特效配置表
local CharacterFondleTemplate = {}       -- 爱抚配置表
local ChaarcterShowEventTemplate = {}       -- 事件客户端表现配置表
local DormTaskGuideCfg = {}       -- 宿舍指引任务
local DormCharacterRewardCfg = {}
local DormTemplateCfg = {}        -- 宿舍模板配置表
local DormTemplateCollectCfg = {} -- 宿舍收藏模板配置表
local DormTemplateGroupCfg = {}  -- 宿舍模板组配置表
local DormCharTypeCountDic = {}   -- 可获得各类角色总数字典

local CharacterActionTemplate = {} --动作
local CharacterInteractiveTemplate = {} --动作

local CharacterDialogTemplate = {}       -- 构造体对话表
local CharacterDialogStateIndex = {}
local CharacterActionIndex = {}
local CharacterInteractiveIndex = {}
local DormTaskGuideDic = nil

local DormBgmTemplate = {}
local DormTemplateData = nil  -- 宿舍模板数据

local DormF2CRelationConfig = {}
local DormF2CRelationDic = {}
-- 初始化构造体恢复表，并排序
local function InitDormCharacterRecovery()
    local recoverys = XTableManager.ReadByIntKey(TABLE_DORM_CHARACTER_RECOVERY_PATH, XTable.XTableDormCharacterRecovery, "Id")
    for _, recovery in pairs(recoverys) do
        if not DormCharacterRecovery[recovery.CharacterId] then
            DormCharacterRecovery[recovery.CharacterId] = {}
        end

        table.insert(DormCharacterRecovery[recovery.CharacterId], recovery)
    end

    for _, recovery in pairs(DormCharacterRecovery) do
        table.sort(recovery, function(a, b)
            return a.Pre < b.Pre
        end)
    end
end
--=================
--构建家具-人物行为关系字典
--=================
local function CreateDormF2CRelationDic()
    for _, config in pairs(DormF2CRelationConfig) do
        if not DormF2CRelationDic[config.FurnitureId] then
            DormF2CRelationDic[config.FurnitureId] = {}
        end
        if not DormF2CRelationDic[config.FurnitureId][config.CharacterId] then
            DormF2CRelationDic[config.FurnitureId][config.CharacterId] = {}
        end
        if config.PositionId then
            DormF2CRelationDic[config.FurnitureId][config.CharacterId][config.PositionId] = config
        else
            DormF2CRelationDic[config.FurnitureId][config.CharacterId][1] = config
        end
    end
end

function XDormConfig.Init()
    CharacterEventTemplate = XTableManager.ReadByIntKey(TABLE_DORM_CHARACTER_EVENT_PATH, XTable.XTableDormCharacterEvent, "EventId")
    CharacterBehaviorTemplate = XTableManager.ReadByIntKey(TABLE_DORM_CHARACTER_BEHAVIOR_PATH, XTable.XTableDormCharacterBehavior, "Id")
    DormitoryTemplate = XTableManager.ReadByIntKey(TABLE_DORMITORY_PATH, XTable.XTableDormitory, "Id")
    DormCharacterWork = XTableManager.ReadByIntKey(TABLE_DORMCHARACTERWORK_PATH, XTable.XTableDormCharacterWork, "DormitoryNum")
    CharacterStyleTemplate = XTableManager.ReadByIntKey(TABLE_CHARACTER_STYLE_PATH, XTable.XTableDormCharacterStyle, "Id")
    CharacterMoodTemplate = XTableManager.ReadByIntKey(TABLE_CHARACTER_MOOD_PATH, XTable.XTableDormCharacterMood, "Id")
    MoodEffectTemplate = XTableManager.ReadByIntKey(TABLE_MOOD_EFFECT_PATH, XTable.XTableDormCharacterEffect, "Id")
    CharacterDialogTemplate = XTableManager.ReadByIntKey(TABLE_CHARACTER_DIALOG_PATH, XTable.XTableDormCharacterDialog, "Id")
    CharacterActionTemplate = XTableManager.ReadByIntKey(TABLE_CHARACTER_ACTION_PATH, XTable.XTableDormCharacterAction, "Id")
    CharacterFondleTemplate = XTableManager.ReadByIntKey(TABLE_DORM_CHARACTER_FONDLE_PATH, XTable.XTableDormCharacterFondle, "CharacterId")
    --CharacterActionTemplate = XTableManager.ReadByIntKey(TABLE_CHARACTER_ACTION_PATH, XTable.XTableDormCharacterAction, "Id")
    CharacterInteractiveTemplate = XTableManager.ReadByIntKey(TABLE_CHARACTER_INTERACTIVE_PATH, XTable.XTableDormInteractiveEvent, "Id")
    ChaarcterShowEventTemplate = XTableManager.ReadByIntKey(TABLE_SHOW_EVENT_PATH, XTable.XTableDormShowEvent, "Id")
    DormBgmTemplate = XTableManager.ReadByIntKey(TABLE_DORM_BGM_PATH, XTable.XTableDormBgm, "Id")
    DormTemplateCollectCfg = XTableManager.ReadByIntKey(TABLE_DORM_TEMPLATE_COLLECT_PATH, XTable.XTableDormTemplateCollect, "Id")
    DormTemplateGroupCfg = XTableManager.ReadByIntKey(TABLE_DORM_TEMPLATE_GROUP_PATH, XTable.XTableDormTemplateGroup, "Id")
    DormTemplateCfg = XTableManager.ReadByIntKey(TABLE_DORM_TEMPLATE_PATH, XTable.XTableDormTemplate, "Id")
    DormTaskGuideCfg = XTableManager.ReadByIntKey(TABLE_DORM_GUIDE_TASK_PATH, XTable.XTableDormGuideTask, "Id")
    DormCharacterRewardCfg = XTableManager.ReadByIntKey(TABLE_CHARACTER_REWARD_PATH, XTable.XTableDormCharacterReward, "Id")
    DormF2CRelationConfig = XTableManager.ReadByIntKey(TABLE_DORM_F2C_RELATION_PATH, XTable.XTableDormF2CBehaviorRelation, "Id")
    InitDormCharacterRecovery()

    CharacterBehaviorStateIndex = {}

    for _, v in pairs(CharacterBehaviorTemplate) do
        CharacterBehaviorStateIndex[v.CharacterId] = CharacterBehaviorStateIndex[v.CharacterId] or {}
        CharacterBehaviorStateIndex[v.CharacterId][v.State] = v
    end

    for _, v in pairs(CharacterDialogTemplate) do
        CharacterDialogStateIndex[v.CharacterId] = CharacterDialogStateIndex[v.CharacterId] or {}
        CharacterDialogStateIndex[v.CharacterId][v.State] = CharacterDialogStateIndex[v.CharacterId][v.State] or {}
        table.insert(CharacterDialogStateIndex[v.CharacterId][v.State], v)
    end

    for _, v in pairs(CharacterActionTemplate) do
        CharacterActionIndex[v.CharacterId] = CharacterActionIndex[v.CharacterId] or {}
        CharacterActionIndex[v.CharacterId][v.Name] = v.State
    end

    for _, v in pairs(CharacterInteractiveTemplate) do
        local cha1 = v.CharacterIds[1]
        local cha2 = v.CharacterIds[2]
        CharacterInteractiveIndex[cha1] = CharacterInteractiveIndex[cha1] or {}
        CharacterInteractiveIndex[cha1][cha2] = v
    end

    for _, v in pairs(CharacterStyleTemplate) do
        local count = DormCharTypeCountDic[v.Type] or 0
        count = count + 1
        DormCharTypeCountDic[v.Type] = count
    end

    XDormConfig.DormAnimationMoveTime = CS.XGame.ClientConfig:GetInt("DormMainAnimationMoveTime") or 0
    XDormConfig.DormAnimationStaicTime = CS.XGame.ClientConfig:GetInt("DormMainAnimationStaicTime") or 0
    XDormConfig.DormSecondAnimationDelayTime = CS.XGame.ClientConfig:GetInt("DormSecondAnimationDelayTime") or 0

    local collectMaxCount = CS.XGame.Config:GetInt("DormLayoutMaxCount") or 0
    local cfgCount = 0
    for _, _ in pairs(DormTemplateCollectCfg) do
        cfgCount = cfgCount + 1
    end

    if collectMaxCount ~= cfgCount then
        XLog.Error("XDormConfig.Init错误，错误原因: DormTemplateCollectCfg表(路径：" .. TABLE_DORM_TEMPLATE_COLLECT_PATH .. ")的表项个数与Share/Config/Config.tab表中DormLayoutMaxCount这一项的最大数量不同")
    end
    --构建家具-人物行为关系字典
    CreateDormF2CRelationDic()
end

-- 获取构造体奖励名字
function XDormConfig.GetDormCharacterRewardNameById(id)
    local data = XDormConfig.GetDormCharacterRewardData(id)
    if not data or not data.Name then
        XLog.ErrorTableDataNotFound("XDormConfig.GetDormCharacterRewardNameById", "Name", TABLE_CHARACTER_REWARD_PATH, "id", tostring(id))
        return nil
    end

    return data.Name
end

-- 获取构造体奖励品质
function XDormConfig.GetDormCharacterRewardQualityById(id)
    local data = XDormConfig.GetDormCharacterRewardData(id)
    if not data or not data.Quality then
        XLog.ErrorTableDataNotFound("XDormConfig.GetDormCharacterRewardQualityById", "Quality", TABLE_CHARACTER_REWARD_PATH, "id", tostring(id))
        return nil
    end

    return data.Quality
end

-- 获取构造体奖励Icon
function XDormConfig.GetDormCharacterRewardIconById(id)
    local data = XDormConfig.GetDormCharacterRewardData(id)
    if not data or not data.Icon then
        XLog.ErrorTableDataNotFound("XDormConfig.GetDormCharacterRewardIconById", "Icon", TABLE_CHARACTER_REWARD_PATH, "id", tostring(id))
        return nil
    end

    return data.Icon
end

-- 获取构造体奖励SmallIcon
function XDormConfig.GetDormCharacterRewardSmallIconById(id)
    local data = XDormConfig.GetDormCharacterRewardData(id)
    if not data or not data.SmallIcon then
        XLog.ErrorTableDataNotFound("XDormConfig.GetDormCharacterRewardSmallIconById", "SmallIcon", TABLE_CHARACTER_REWARD_PATH, "id", tostring(id))
        return nil
    end

    return data.SmallIcon
end

-- 获取构造体奖励CharacterId
function XDormConfig.GetDormCharacterRewardCharIdById(id)
    local data = XDormConfig.GetDormCharacterRewardData(id)
    if not data or not data.CharacterId then
        XLog.ErrorTableDataNotFound("XDormConfig.GetDormCharacterRewardCharIdById", "CharacterId", TABLE_CHARACTER_REWARD_PATH, "id", tostring(id))
        return nil
    end

    return data.CharacterId
end

-- 获取构造体奖励Description
function XDormConfig.GetDormDescriptionRewardCharIdById(id)
    local data = XDormConfig.GetDormCharacterRewardData(id)
    if not data or not data.Description then
        XLog.ErrorTableDataNotFound("XDormConfig.GetDormDescriptionRewardCharIdById", "Description", TABLE_CHARACTER_REWARD_PATH, "id", tostring(id))
        return nil
    end

    return data.Description
end

-- 获取构造体奖励WorldDescription
function XDormConfig.GetDormWorldDescriptionRewardCharIdById(id)
    local data = XDormConfig.GetDormCharacterRewardData(id)
    if not data or not data.WorldDescription then
        XLog.ErrorTableDataNotFound("XDormConfig.GetDormWorldDescriptionRewardCharIdById",
        "WorldDescription", TABLE_CHARACTER_REWARD_PATH, "id", tostring(id))
        return nil
    end

    return data.WorldDescription
end

-- 获取模板宿舍Ishow
function XDormConfig.GetDormTemplateIsSwhoById(id)
    local data = XDormConfig.GetDormTemplateCfg(id)
    return data.IsShow
end

function XDormConfig.GetDormTemplateCollectList()
    local list = {}
    for _, info in pairs(DormTemplateCollectCfg) do
        table.insert(list, info)
    end

    table.sort(list, function(a, b)
        return a.Order < b.Order
    end)

    return list
end

function XDormConfig.GetDormTemplateGroupList()
    local list = {}
    for _, info in pairs(DormTemplateGroupCfg) do
        table.insert(list, info)
    end
    return list
end

function XDormConfig.GetDormTemplateSelecIndex(connectId)
    local index = 0
    local default = 1
    for _, info in pairs(DormTemplateGroupCfg) do
        index = index + 1
        for _, id in ipairs(info.DormId) do
            if connectId == id then
                return index
            end
        end
    end
    return default
end

function XDormConfig.GetDormTemplateCfg(id)
    local data = DormTemplateCfg[id]
    if not data then
        XLog.ErrorTableDataNotFound("XDormConfig.GetDormTemplateCfg", "data", TABLE_DORM_TEMPLATE_PATH, "id", tostring(id))
        return nil
    end

    return data
end

function XDormConfig.GetDormCharacterRewardData(id)
    local data = DormCharacterRewardCfg[id]
    return data
end

-- 宿舍指引任务Dic
function XDormConfig.GetDormitoryGuideTaskCfg()
    if DormTaskGuideDic then
        return DormTaskGuideDic
    end

    DormTaskGuideDic = {}
    for _, v in pairs(DormTaskGuideCfg) do
        DormTaskGuideDic[v.TaskId] = v.TaskId
    end
    return DormTaskGuideDic
end

-- 获取所有宿舍
function XDormConfig.GetTotalDormitoryCfg()
    local t = DormitoryTemplate
    return t
end

function XDormConfig.DormCharSexTypeToGender(sexType)
    if sexType == XDormConfig.DormSex.Man or sexType == XDormConfig.DormSex.Human or sexType == XDormConfig.DormSex.InfestorMale then
        return XDormConfig.DormCharGender.Male
    elseif sexType == XDormConfig.DormSex.Woman or sexType == XDormConfig.DormSex.Huwoman or sexType == XDormConfig.DormSex.InfestorFemale then
        return XDormConfig.DormCharGender.Female
    elseif sexType == XDormConfig.DormSex.Infect then
        return XDormConfig.DormCharGender.Gan
    elseif sexType == XDormConfig.DormSex.NIER then
        return XDormConfig.DormCharGender.None
    else
        return XDormConfig.DormCharGender.None
    end
end

function XDormConfig.GetDormCharacterType(dormCharIndex)
    if dormCharIndex == XDormConfig.DORM_CHAR_INDEX.CHARACTER then
        return XDormConfig.DormSex.Man, XDormConfig.DormSex.Woman
    elseif dormCharIndex == XDormConfig.DORM_CHAR_INDEX.EMNEY then
        return XDormConfig.DormSex.Infect
    -- elseif dormCharIndex == XDormConfig.DORM_CHAR_INDEX.HUMAN then
    --     return XDormConfig.DormSex.Human, XDormConfig.DormSex.Huwoman
    elseif dormCharIndex == XDormConfig.DORM_CHAR_INDEX.INFESTOR then
        return XDormConfig.DormSex.InfestorMale, XDormConfig.DormSex.InfestorFemale
    elseif dormCharIndex == XDormConfig.DORM_CHAR_INDEX.NIER then
        return XDormConfig.DormSex.NIER
    else
        return
    end
end

-- 通过类型，获取宿舍角色总数量
function XDormConfig.GetDormCharacterTemplatesCountByType(...)
    local count = 0
    local types = { ... }
    for _, k in ipairs(types) do
        local t = DormCharTypeCountDic[k] or 0
        count = count + t
    end
    return count
end

-- 配置的宿舍总数
function XDormConfig.GetTotalDormitortCountCfg()
    local count = 0
    local t = DormitoryTemplate or {}
    for _, _ in pairs(t) do
        count = count + 1
    end

    return count
end

-- 获取宿舍配置
function XDormConfig.GetDormitoryCfgById(id)
    if not id then
        return nil
    end

    local t = DormitoryTemplate[id]
    if not t then
        XLog.ErrorTableDataNotFound("XDormConfig.GetDormitoryCfgById", "t", TABLE_DORMITORY_PATH, "id", tostring(id))
        return nil
    end

    return t
end

-- 获取宿舍配置
function XDormConfig.GetDefaultDormitory()
    for _, v in pairs(DormitoryTemplate) do
        return v
    end
end

-- 获取宿舍空间转向
function XDormConfig.GetDormSenceVector(dormitoryId)
    local dormitoryConfig = XDormConfig.GetDormitoryCfgById(dormitoryId)
    local v3 = CS.UnityEngine.Vector3.zero
    if dormitoryConfig.SceneId == XDormConfig.SenceType.One then
        v3 = CS.UnityEngine.Vector3(0, -180, 0)
    elseif dormitoryConfig.SceneId == XDormConfig.SenceType.Tow then
        v3 = CS.UnityEngine.Vector3(0, -180, 0)
    end

    return v3
end

-- 获取宿舍号
function XDormConfig.GetDormitoryNumById(dormitoryId)
    local dormitoryConfig = XDormConfig.GetDormitoryCfgById(dormitoryId)
    return dormitoryConfig.InitNumber
end

-- 获取宿舍空间ID
function XDormConfig.GetDormitorySenceById(dormitoryId)
    local dormitoryConfig = XDormConfig.GetDormitoryCfgById(dormitoryId)
    return dormitoryConfig.SceneId
end

-- 宿舍可住人数
-- 获取宿舍配置
function XDormConfig.GetDormPersonCount(id)
    local t = XDormConfig.GetDormitoryCfgById(id)
    if not t then
        return 0
    end

    return t.CharCapacity or 0
end

--获取行为节点Id
function XDormConfig.GetCharacterBehavior(charId, state)
    if not CharacterBehaviorStateIndex or not CharacterBehaviorStateIndex[charId] then
        XLog.ErrorTableDataNotFound("XDormConfig.GetCharacterBehavior", "CharacterBehaviorStateIndex",
        TABLE_DORM_CHARACTER_BEHAVIOR_PATH, "charId", tostring(charId))
        return
    end

    if not CharacterBehaviorStateIndex[charId][state] then
        --也用于检测有无角色行为，这里的报错日志注释掉
        --XLog.ErrorTableDataNotFound("XDormConfig.GetCharacterBehavior", "state", TABLE_DORM_CHARACTER_BEHAVIOR_PATH, "charId", tostring(charId))
        return
    end

    return CharacterBehaviorStateIndex[charId][state]
end


--获取行为表
function XDormConfig.GetCharacterBehaviorById(id)
    if not CharacterBehaviorTemplate then
        XLog.Error("配置表：" .. TABLE_DORM_CHARACTER_BEHAVIOR_PATH .. "读取失败")
        return
    end

    if not CharacterBehaviorTemplate[id] then
        XLog.ErrorTableDataNotFound("XDormConfig.GetCharacterBehaviorById", "配置表项", TABLE_DORM_CHARACTER_BEHAVIOR_PATH, "id", tostring(id))
        return
    end


    return CharacterBehaviorTemplate[id]
end


--获取角色交互
function XDormConfig.GetCharacterInteractiveIndex(id1, id2)
    if not CharacterInteractiveIndex then
        return false
    end

    if CharacterInteractiveIndex[id1] and CharacterInteractiveIndex[id1][id2] then
        local temp = CharacterInteractiveIndex[id1][id2]
        return true, temp, temp.State[1], temp.State[2]
    elseif CharacterInteractiveIndex[id2] and CharacterInteractiveIndex[id2][id1] then
        local temp = CharacterInteractiveIndex[id2][id1]
        return true, temp, temp.State[2], temp.State[1]
    end

    return false
end

--获取动作状态机
function XDormConfig.GetCharacterActionState(charId, name)
    if not CharacterActionIndex or not CharacterActionIndex[charId] or not CharacterActionIndex[charId][name] then
        XLog.Error(string.format("CharacterActionIndex不存在 charId:%s name:%s 路径：%s", charId, name, TABLE_CHARACTER_ACTION_PATH))
        name = "QR2YongyechaoExcessiveBase01"
    end

    return CharacterActionIndex[charId][name]
end

--获取事件
function XDormConfig.GetCharacterEventById(id)
    if not CharacterEventTemplate then
        XLog.Error("配置表：" .. TABLE_DORM_CHARACTER_EVENT_PATH .. "读取失败")
        return
    end

    if not CharacterEventTemplate[id] then
        XLog.ErrorTableDataNotFound("XDormConfig.GetCharacterEventById", "配置表项", TABLE_DORM_CHARACTER_EVENT_PATH, "id", tostring(id))
        return
    end

    return CharacterEventTemplate[id]
end

function XDormConfig.GetDormCharacterWorkById(id)
    if not id then
        return
    end

    return DormCharacterWork[id]
end

function XDormConfig.GetDormCharacterWorkData()
    return DormCharacterWork
end

-- 获取构造体回复配置表
function XDormConfig.GetCharRecoveryConfig(charId)
    local t = DormCharacterRecovery[charId]
    if not t then
        XLog.ErrorTableDataNotFound("XDormConfig.GetCharRecoveryConfig", "配置表项", TABLE_DORM_CHARACTER_RECOVERY_PATH, "charId", tostring(charId))
        return nil
    end

    return t
end

-- 获取构造体表情特效
function XDormConfig.GetMoodEffectConfig(id)
    local t = MoodEffectTemplate[id]
    if not t then
        XLog.ErrorTableDataNotFound("XDormConfig.GetMoodEffectConfig", "配置表项", TABLE_MOOD_EFFECT_PATH, "id", tostring(id))
        return nil
    end

    return t
end

-- 获取构造体对话配置表
function XDormConfig.GetCharacterDialogConfig(id)
    local t = CharacterDialogTemplate[id]
    if not t then
        XLog.ErrorTableDataNotFound("XDormConfig.GetCharacterDialogConfig", "配置表项", TABLE_CHARACTER_DIALOG_PATH, "id", tostring(id))
        return nil
    end

    return t
end

-- 获取构造体信息配置
function XDormConfig.GetCharacterStyleConfigById(id)
    local t = CharacterStyleTemplate[id]
    if not t then
        XLog.ErrorTableDataNotFound("XDormConfig.GetCharacterStyleConfigById", "配置表项", TABLE_CHARACTER_STYLE_PATH, "id", tostring(id))
        return nil
    end

    return t
end

-- 获取构造体Q版头像(圆形)
function XDormConfig.GetCharacterStyleConfigQIconById(id)
    local t = CharacterStyleTemplate[id]
    if not t or not t.HeadRoundIcon then
        XLog.ErrorTableDataNotFound("XDormConfig.GetCharacterStyleConfigQIconById",
        "配置表项或者HeadRoundIcon", TABLE_CHARACTER_STYLE_PATH, "id", tostring(id))
        return nil
    end

    return t.HeadRoundIcon
end

-- 获取构造体Q版头像(圆形)
function XDormConfig.GetCharacterStyleConfigQSIconById(id)
    local t = CharacterStyleTemplate[id]
    if not t or not t.HeadIcon then
        XLog.ErrorTableDataNotFound("XDormConfig.GetCharacterStyleConfigQSIconById", "配置表项或者HeadIcon", TABLE_CHARACTER_STYLE_PATH, "id", tostring(id))
        return nil
    end

    return t.HeadIcon
end

-- 获取构造体性别类型
function XDormConfig.GetCharacterStyleConfigSexById(id)
    local t = CharacterStyleTemplate[id]
    if not t or not t.Type then
        XLog.ErrorTableDataNotFound("XDormConfig.GetCharacterStyleConfigSexById", "配置表项或者Type", TABLE_CHARACTER_STYLE_PATH, "id", tostring(id))
        return nil
    end

    return t.Type
end

function XDormConfig.GetCharacterNameConfigById(id)
    local t = CharacterStyleTemplate[id]
    if not t then
        XLog.ErrorTableDataNotFound("XDormConfig.GetCharacterNameConfigById", "配置表项", TABLE_CHARACTER_STYLE_PATH, "id", tostring(id))
        return nil
    end

    return t.Name
end

-- 获取构造体爱抚配置表
function XDormConfig.GetCharacterFondleByCharId(characterId)
    local t = CharacterFondleTemplate[characterId]
    if not t then
        XLog.ErrorTableDataNotFound("XDormConfig.GetCharacterFondleByCharId",
        "配置表项", TABLE_DORM_CHARACTER_FONDLE_PATH, "characterId", tostring(characterId))
        return nil
    end

    return t
end

-- 获取构造体爱总次数
function XDormConfig.GetCharacterFondleCount(characterId)
    local t = XDormConfig.GetCharacterFondleByCharId(characterId)
    return t.MaxCount
end

-- 获取构造体爱恢复一次时间
function XDormConfig.GetCharacterFondleRecoveryTime(characterId)
    local t = XDormConfig.GetCharacterFondleByCharId(characterId)
    return t.RecoveryTime
end

-- 获取构造体事件客户表现表
function XDormConfig.GetCharacterShowEvent(id)
    local t = ChaarcterShowEventTemplate[id]
    if not t then
        XLog.ErrorTableDataNotFound("XDormConfig.GetCharacterShowEvent", "配置表项", TABLE_SHOW_EVENT_PATH, "id", tostring(id))
        return nil
    end

    return t
end

-- 获取构造体事件状态
function XDormConfig.GetCharacterShowEventState(id)
    local t = XDormConfig.GetCharacterShowEvent(id)
    return t.State
end

-- 获取构造体心情状态
function XDormConfig.GetMoodStateByMoodValue(moodValue)
    local t

    for _, v in pairs(CharacterMoodTemplate) do
        if moodValue > v.MoodMinValue and moodValue <= v.MoodMaxValue then
            t = v
            break
        end
    end

    if not t then
        XLog.Error("XDormConfig.GetMoodStateByMoodValue 参数不符合规范，moodValue: " .. tostring(moodValue))
        return nil
    end

    return t
end

-- 获取构造体心情状态描述
function XDormConfig.GetMoodStateDesc(moodValue)
    local desc = ""

    for _, v in pairs(CharacterMoodTemplate) do
        if moodValue > v.MoodMinValue and moodValue <= v.MoodMaxValue then
            desc = v.Describe
            break
        end
    end

    return desc
end

-- 获取构造体心情状态颜色值
function XDormConfig.GetMoodStateColor(moodValue)
    local color = "FFFFFFFF"

    for _, v in pairs(CharacterMoodTemplate) do
        if moodValue > v.MoodMinValue and moodValue <= v.MoodMaxValue then
            color = v.Color
            break
        end
    end

    return XUiHelper.Hexcolor2Color(color)
end

-- 获取图纸商店跳转ID
function XDormConfig.GetDraftShopId()
    return XDormConfig.DORM_DRAFT_SHOP_ID
end


--获取对话表
function XDormConfig.GetCharacterDialog(charData, state)

    local charId = charData.CharacterId

    if not CharacterDialogStateIndex or not CharacterDialogStateIndex[charId] then
        XLog.ErrorTableDataNotFound("XDormConfig.GetCharacterDialog", "配置表项", TABLE_CHARACTER_DIALOG_PATH, "charId", tostring(charId))
        return
    end

    if not CharacterDialogStateIndex[charId][state] then
        XLog.ErrorTableDataNotFound("XDormConfig.GetCharacterDialog", "配置表项或者state", TABLE_CHARACTER_DIALOG_PATH, "charId", tostring(charId))
        return
    end

    local dialogList = CharacterDialogStateIndex[charId][state]

    if not dialogList then
        return
    end

    local fitterList = {}

    for _, v in ipairs(dialogList) do
        if charData.Mood >= v.MoodMinValue and charData.Mood <= v.MoodMaxValue then
            table.insert(fitterList, v)
        end
    end

    if #fitterList <= 0 then
        return
    end

    math.randomseed(os.time())
    local index = math.random(0, #fitterList)

    return fitterList[index]

end

--获取套装的音乐信息
function XDormConfig.GetDormSuitBgmInfo(suitId)
    for _, v in pairs(DormBgmTemplate) do
        if v.SuitId == suitId then
            return v
        end
    end

    return nil
end

--获取背景音乐
function XDormConfig.GetDormBgm(furnitureList)
    local musicList = {}

    for _, v in pairs(DormBgmTemplate) do
        if v.SuitId == -1 then
            table.insert(musicList, v)
        end
    end


    if not furnitureList then
        return false, musicList
    end


    local suitDic = {}
    for _, v in pairs(furnitureList) do
        suitDic[v.SuitId] = suitDic[v.SuitId] or {}
        local isExist = false
        for _, id in ipairs(suitDic[v.SuitId]) do
            if id == v.Id then
                isExist = true
                break
            end
        end

        if not isExist then
            table.insert(suitDic[v.SuitId], v.Id)
        end
    end


    for _, v in pairs(DormBgmTemplate) do
        if suitDic[v.SuitId] and #suitDic[v.SuitId] >= v.SuitNum then
            table.insert(musicList, v)
        end
    end


    if #musicList <= 1 then
        return false, musicList
    end


    table.sort(musicList, function(a, b)
        return a.Order > b.Order
    end)


    return true, musicList
end

-- 是否是模板宿舍
function XDormConfig.IsTemplateRoom(dormDataType)
    if dormDataType == XDormConfig.DormDataType.Template or
    dormDataType == XDormConfig.DormDataType.Collect or
    dormDataType == XDormConfig.DormDataType.CollectNone or
    dormDataType == XDormConfig.DormDataType.Provisional then
        return true
    end

    return false
end

-- 初始化宿舍模板列表
local function InitDormTemplate()
    DormTemplateData = {}
    for _, v in pairs(DormTemplateCfg) do
        DormTemplateData[v.Id] = XHomeRoomData.New(v.Id)
        DormTemplateData[v.Id]:SetPlayerId(XPlayer.Id)
        DormTemplateData[v.Id]:SetRoomName(v.Name)
        DormTemplateData[v.Id]:SetRoomUnlock(true)
        DormTemplateData[v.Id]:SetRoomDataType(XDormConfig.DormDataType.Template)
        DormTemplateData[v.Id]:SetRoomOrder(v.Order)
        DormTemplateData[v.Id]:SetRoomPicturePath(v.PicturePath)

        for i = 1, #v.FurnitureId do
            if not v.FurniturePos[i] then
                XLog.ErrorTableDataNotFound("InitDormTemplate", "FurniturePos", TABLE_DORM_TEMPLATE_PATH, "Id", tostring(v.Id))
                break
            end

            local posList = string.Split(v.FurniturePos[i], "|")
            if not posList then
                XLog.ErrorTableDataNotFound("InitDormTemplate", "FurnitureId", TABLE_DORM_TEMPLATE_PATH, "Id", tostring(v.Id))
                break
            end

            local id = XGlobalVar.GetIncId()
            local x = posList[1] and tonumber(posList[1]) or 0
            local y = posList[2] and tonumber(posList[2]) or 0
            local r = posList[3] and tonumber(posList[3]) or 0
            DormTemplateData[v.Id]:AddFurniture(id, v.FurnitureId[i], x, y, r)
        end
    end
end

function XDormConfig.GetDormTemplateData()
    InitDormTemplate()
    return DormTemplateData
end

function XDormConfig.GetDormitoryTablePath()
    return TABLE_DORMITORY_PATH
end
--===================
--获取家具-角色行为对照关系配置
--@param furnitureId:家具Id
--@param characterId:角色Id
--@param positionId:接触点序号(不填默认为1，只有1个接触点的家具接触点序号默认1)
--===================
function XDormConfig.GetDormF2CBehaviorRelative(furnitureId, characterId, positionId)
    local config = DormF2CRelationDic[furnitureId]
    if not config then return nil end
    if not config[characterId] then return nil end
    return config[characterId][positionId or 1]
end