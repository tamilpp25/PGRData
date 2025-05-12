
XSkinVoteConfigs = XSkinVoteConfigs or {}

--region   ------------------Path start-------------------
local TABLE_SKIN_VOTE_ACTIVITY_PATH             = "Share/SkinVote/SkinVoteActivity.tab"
local TABLE_SKIN_VOTE_NAME_GROUP_PATH           = "Share/SkinVote/SkinVoteNameGroup.tab"
local TABLE_SKIN_VOTE_ACTIVITY_CLIENT_PATH      = "Client/SkinVote/SkinVoteActivityClient.tab"
--endregion------------------Path finish------------------

--region   ------------------Cache start-------------------
local TableSkinVoteActivity             = {}
local TableSkinVoteNameGroup            = {}
local TableSkinVoteActivityClient       = {}
--endregion------------------Cache finish------------------

function XSkinVoteConfigs.Init()
    --活动配置
    TableSkinVoteActivity   = XTableManager.ReadByIntKey(TABLE_SKIN_VOTE_ACTIVITY_PATH, XTable.XTableSkinVoteActivity, "Id")
    --涂装名配置
    TableSkinVoteNameGroup  = XTableManager.ReadByIntKey(TABLE_SKIN_VOTE_NAME_GROUP_PATH, XTable.XTableSkinVoteNameGroup, "Id") 
    --活动配置（前端）
    TableSkinVoteActivityClient  = XTableManager.ReadByIntKey(TABLE_SKIN_VOTE_ACTIVITY_CLIENT_PATH, XTable.XTableSkinVoteActivityClient, "Id") 
end 

--region   ------------------NameGroupTemplate start-------------------
local function GetNameGroupTemplate(nameGroupId) 
    local template = TableSkinVoteNameGroup[nameGroupId]
    if not template then
        XLog.ErrorTableDataNotFound("XSkinVoteConfigs->GetNameGroupTemplate", 
                "SkinVoteNameGroup", TABLE_SKIN_VOTE_NAME_GROUP_PATH, "Id", tostring(nameGroupId))
        return {}
    end
    return template
end

function XSkinVoteConfigs.GetVoteName(nameGroupId)
    local template = GetNameGroupTemplate(nameGroupId)
    return template.Name
end

--- 获取当前活动的涂装命名列表
---@param activityId number 当前活动Id
---@return number[]
--------------------------
function XSkinVoteConfigs.GetVoteNameIds(activityId)
    local list = {}
    if not XTool.IsNumberValid(activityId) then
        return list
    end

    for id, template in pairs(TableSkinVoteNameGroup) do
        if template.ActivityId == activityId then
            table.insert(list, id)
        end
    end
    
    table.sort(list, function(a, b) 
        return a < b
    end)
    
    return list
end

--endregion------------------NameGroupTemplate finish------------------


--region   ------------------ActivityTemplate start-------------------
local function GetActivityTemplate(activityId) 
    local template = TableSkinVoteActivity[activityId]
    if not template then
        XLog.ErrorTableDataNotFound("XSkinVoteConfigs->GetActivityTemplate", 
                "SkinVoteActivity", TABLE_SKIN_VOTE_ACTIVITY_PATH, "Id", tostring(activityId))
        return {}
    end
    return template
end

local function GetActivityTimeId(activityId) 
    local template = GetActivityTemplate(activityId)
    return template.TimeId or 0
end

local function GetActivityVoteTimeId(activityId)
    local template = GetActivityTemplate(activityId)
    return template.VoteTimeId or 0
end

local function GetActivityClientTemplate(activityId)
    local template = TableSkinVoteActivityClient[activityId]
    if not template then
        XLog.ErrorTableDataNotFound("XSkinVoteConfigs->GetActivityClientTemplate",
                "SkinVoteActivityClient", TABLE_SKIN_VOTE_ACTIVITY_CLIENT_PATH, "Id", tostring(activityId))
        return {}
    end
    return template
end

function XSkinVoteConfigs.CheckActivityInTime(activityId)
    return XFunctionManager.CheckInTimeByTimeId(GetActivityTimeId(activityId))
end

function XSkinVoteConfigs.GetActivityStartTime(activityId)
    return XFunctionManager.GetStartTimeByTimeId(GetActivityTimeId(activityId))
end

function XSkinVoteConfigs.GetActivityEndTime(activityId)
    return XFunctionManager.GetEndTimeByTimeId(GetActivityTimeId(activityId))
end

function XSkinVoteConfigs.GetActivityVoteStartTime(activityId)
    return XFunctionManager.GetStartTimeByTimeId(GetActivityVoteTimeId(activityId))
end

function XSkinVoteConfigs.GetActivityVoteEndTime(activityId)
    return XFunctionManager.GetEndTimeByTimeId(GetActivityVoteTimeId(activityId))
end

function XSkinVoteConfigs.GetActivityDesc(activityId)
    local template = GetActivityClientTemplate(activityId)
    return template.Desc
end

function XSkinVoteConfigs.GetActivityVoteTips(activityId)
    local template = GetActivityClientTemplate(activityId)
    return template.VoteTips
end

function XSkinVoteConfigs.GetActivityPreviewImgSmall(activityId)
    local template = GetActivityClientTemplate(activityId)
    return template.PreviewImgSmall
end

function XSkinVoteConfigs.GetActivityPreviewImgFull(activityId)
    local template = GetActivityClientTemplate(activityId)
    return template.PreviewImgFull
end

function XSkinVoteConfigs.GetActivityPrefabPath(activityId)
    local template = GetActivityClientTemplate(activityId)
    return template.PrefabPath
end
--endregion------------------ActivityTemplate finish------------------