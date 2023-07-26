--射击玩法配置类
XMaverickConfigs = XMaverickConfigs or {}

--    ===================表地址
local SHARE_TABLE_PATH = "Share/Fuben/Maverick/"
local CLIENT_TABLE_PATH = "Client/Fuben/Maverick/"

local TABLE_ACTIVITY = SHARE_TABLE_PATH .. "MaverickActivity.tab"
local TABLE_LEVEL_UP = SHARE_TABLE_PATH .. "MaverickLevelUp.tab"
local TABLE_MEMBER = SHARE_TABLE_PATH .. "MaverickMember.tab"
local TABLE_PATTERN = SHARE_TABLE_PATH .. "MaverickPattern.tab"
local TABLE_STAGE = SHARE_TABLE_PATH .. "MaverickStage.tab"
local TABLE_TALENT = SHARE_TABLE_PATH .. "MaverickTalent.tab"
local TABLE_NUM_ICON = CLIENT_TABLE_PATH .. "MaverickNumIcon.tab"
local TABLE_SKILL_DESC = CLIENT_TABLE_PATH .. "MaverickSkillDesc.tab"
local TABLE_DISPLAY_ATTRIB = CLIENT_TABLE_PATH .. "MaverickDisplayAttrib.tab"

--=======原表数据======
local TableMaverickActivity
local TableMaverickLevelUp
local TableMaverickMember
local TableMaverickPattern
local TableMaverickStage
local TableMaverickTalent
local TableMaverickNumIcon
local TableMaverickSkillDesc
local TableMaverickDisplayAttrib

--========变量========
--MaverickPattern和MaverickStage合并后的产物
local MaverickPatternWithStage = { }
--每关对应解锁的角色
local MaverickStageUnlockMember = { }
--角色升级表
local MaverickMemberLevel = { }

--升级消耗的道具Id
local XMaverickLvUpConsumeItemId = 60840
local XMaverickStageTypes = { Normal = 1, Endless = 2 }
local XMaverickSaveKeys = { 
    Pattern = "MaverickPatternEnterFlag_%d_%d_%d",
    LastUsedCharacterId = "LastUsedCharacterIdFlag_%d_%d",
}
local XMaverickMemberPropertyTypes = {
    Life = 1,
    Attack = 2,
    Defense = 3,
    Crit = 4,
}
local XMaverickResultKeys = { Score = 1, killCount = 2 }
--================
--玩法养成界面的镜头枚举
--================
local XMaverickCameraTypes = {
    MAIN = 1, -- 主页面镜头
    ADAPT = 2, --改造镜头
    PREPARE = 3, --作战准备镜头
}

--[[
================
初始化Config
================
]]
function XMaverickConfigs.Init()
    --初始化表格 step1
    TableMaverickActivity = XTableManager.ReadByIntKey(TABLE_ACTIVITY, XTable.XTableMaverickActivity, "Id")
    TableMaverickLevelUp = XTableManager.ReadByIntKey(TABLE_LEVEL_UP, XTable.XTableMaverickLevelUp, "Id")
    TableMaverickMember = XTableManager.ReadByIntKey(TABLE_MEMBER, XTable.XTableMaverickMember, "Id")
    TableMaverickPattern = XTableManager.ReadByIntKey(TABLE_PATTERN, XTable.XTableMaverickPattern, "Id")
    TableMaverickStage = XTableManager.ReadByIntKey(TABLE_STAGE, XTable.XTableMaverickStage, "StageId")
    TableMaverickTalent = XTableManager.ReadByIntKey(TABLE_TALENT, XTable.XTableMaverickTalent, "Id")
    TableMaverickNumIcon = XTableManager.ReadByIntKey(TABLE_NUM_ICON, XTable.XTableMaverickNumIcon, "Num")
    TableMaverickSkillDesc = XTableManager.ReadByIntKey(TABLE_SKILL_DESC, XTable.XTableMaverickSkillDesc, "Id")
    TableMaverickDisplayAttrib = XTableManager.ReadByIntKey(TABLE_DISPLAY_ATTRIB, XTable.XTableMaverickDisplayAttrib, "Id")

    --初始化MaverickPatternWithStage step2
    for id, pattern in pairs(TableMaverickPattern) do
        MaverickPatternWithStage[id] = { Pattern = pattern, Stages = { } }
    end
    
    --MaverickStage合并进MaverickPattern step3
    for _, stage in pairs(TableMaverickStage) do
        local pattern = MaverickPatternWithStage[stage.PatternId]
        if pattern then
            pattern.Stages[stage.GridIndex] = stage
        else
            XLog.Error(string.format("二周年射击玩法模式Id不存在！ patternId:%d", stage.PatternId))
        end
    end

    --每关对应解锁的角色
    for _, member in pairs(TableMaverickMember) do
        local tempList = MaverickStageUnlockMember[member.UnlockStageId]
        if not tempList then
            tempList = { }
            MaverickStageUnlockMember[member.UnlockStageId] = tempList
        end
        
        table.insert(tempList, member.Id)
    end

    --角色升级表
    for _, member in pairs(TableMaverickLevelUp) do
        local tempList = MaverickMemberLevel[member.MemberId]
        if not tempList then
            tempList = { }
            MaverickMemberLevel[member.MemberId] = tempList
        end

        tempList[member.Level] = member
    end
    --按等级排序
    for _, levelList in pairs(MaverickMemberLevel) do
        table.sort(levelList, function(a, b) return a.Level < b.Level end)
    end
end

function XMaverickConfigs.GetActivity(activityId)
    if not activityId then
        return
    end

    if activityId <= 0 then
        return
    end
    
    local activity = TableMaverickActivity[activityId]

    if not activity then
        XLog.Error(string.format("找不到二周年射击玩法活动配置！ ActivityId:%d", activityId))
    end

    return activity
end

function XMaverickConfigs.GetDefaultActivity()
    --找到第一个配置了时间的活动
    for _, activity in pairs(TableMaverickActivity) do
        if activity.TimeId and activity.TimeId > 0 then
            return activity
        end
    end 
end

function XMaverickConfigs.GetPatternWithStageById(patternId)
    if not patternId then
        return
    end
    
    return MaverickPatternWithStage[patternId]
end

function XMaverickConfigs.GetStages(patternId)
    if not patternId then
        return
    end

    local patternWithStage = XMaverickConfigs.GetPatternWithStageById(patternId)
    return patternWithStage.Stages
end

function XMaverickConfigs.GetStage(stageId)
    if not stageId then
        return
    end
    
    return TableMaverickStage[stageId]
end

function XMaverickConfigs.GetNumIcon(num)
    return TableMaverickNumIcon[num].Icon
end 

function XMaverickConfigs.GetRobotId(member)
    local tempList = MaverickMemberLevel[member.MemberId]
    if not tempList then
        return 0
    end
    
    return tempList[member.Level].RobotId or 0
end 

function XMaverickConfigs.GetCombatScore(member)
    local tempList = MaverickMemberLevel[member.MemberId]
    if not tempList then
        return 0
    end
    
    return tempList[member.Level].CombatScore or 0
end

function XMaverickConfigs.GetAttributes(memberId)
    return TableMaverickMember[memberId].Attributes
end 

function XMaverickConfigs.GetMaxMemberLevel(memberId)
    local list = MaverickMemberLevel[memberId]
    if type(list) ~= "table" or #list == 0 then
        return 0
    end
    return list[#list].Level
end

function XMaverickConfigs.GetMinMemberLevel(memberId)
    local list = MaverickMemberLevel[memberId]
    if type(list) ~= "table" or #list == 0 then
        return 0
    end
    return list[1].Level
end

function XMaverickConfigs.GetMemberLvUpConsumeInfo(member)
    local info = { }
    local tempList = MaverickMemberLevel[member.MemberId]
    if tempList then
        info.ConsumeItemId = tempList[member.Level].ConsumeItemId or 0
        info.ConsumeItemCount = tempList[member.Level].ConsumeItemCount or 0
    end
    
    return info
end

function XMaverickConfigs.GetMemberTalentIds(memberId)
    return TableMaverickMember[memberId].TalentIds
end

function XMaverickConfigs.GetTalentConfig(talentId)
    return TableMaverickTalent[talentId]
end

function XMaverickConfigs.GetLvUpConsumeItemId()
    return XMaverickLvUpConsumeItemId
end 

function XMaverickConfigs.GetSaveKeys()
    return XMaverickSaveKeys
end 

function XMaverickConfigs.GetMemberPropertyTypes()
    return XMaverickMemberPropertyTypes
end 

function XMaverickConfigs.GetStageTypes()
    return XMaverickStageTypes
end 

function XMaverickConfigs.GetResultKeys()
    return XMaverickResultKeys
end 

function XMaverickConfigs.GetCameraTypes()
    return XMaverickCameraTypes
end 

function XMaverickConfigs.GetPatternImagePath(patternId)
    return TableMaverickPattern[patternId].Icon
end 

function XMaverickConfigs.GetDisplayAttribs(member)
    local result = { }
    local tempList = MaverickMemberLevel[member.MemberId]
    if not tempList then
        return result
    end

    local id = tempList[member.Level].DisplayAttribId
    local displayAttribs = TableMaverickDisplayAttrib[id]
    if not displayAttribs then
        return result
    end

    for name, value in pairs(displayAttribs) do
        if name ~= "Id" then
            result[name] = value
        end
    end
    
    return result
end

function XMaverickConfigs.GetSkills(memberId)
    local skillIds = TableMaverickMember[memberId].SkillIds
    local skills = { }
    for _, id in ipairs(skillIds) do
        table.insert(skills, TableMaverickSkillDesc[id])
    end
    
    return skills
end

function XMaverickConfigs.GetAllStageIds()
    local stageIds = { }
    for stageId, _ in pairs(TableMaverickStage) do
        table.insert(stageIds, stageId)
    end
    return stageIds
end 