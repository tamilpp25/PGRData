---@class QuestBase
local QuestBase = require("class")()
function QuestBase:Ctor(proxy)
    self._proxy = proxy
    self._activeObjectiveIds = {}
    self._activeObjectiveCount = 0
end

function QuestBase:InitQuestObjective(id, desc)
    local success = self._proxy:InitQuestObjective(id, desc)
    if not success then
        return false
    end
    self._objectives[id] = Quest1002Objective.New(self)
    self._objectiveEnterFuncs[id] = desc.EnterFunc
    self._objectiveExitFuncs[id] = desc.ExitFunc
    return true
end

function QuestBase:ExecObjectiveEnter()
    for i = 1, self._activeObjectiveCount do
        local id = self._activeObjectiveIds[i]
        local objective = self._objectives[id]
        self._objectiveEnterFuncs[id](objective, self._proxy)
    end
end

---@class Quest1002 : QuestBase
local Quest1002 = require("class")()

function Quest1002:Ctor(proxy)
end

EQuestStepExecMode = {
    Serial = 1, --线性执行下属objective
    Parallel = 2, --并行执行下属objective
}

EQuestObjectiveType = {
    None = 0,
    DramaPlayFinish = 1, --剧情播放完成
    EnterLevel = 2, --进入关卡
    InstanceComplete = 3, --副本完成
    CheckRimSystemCondition = 4, --检查外围系统条件
    ReadShortMessageComplete = 5, --阅读短信完成
    InteractComplete = 6,
}

function Quest1002:Init()
    self._proxy:SetQuestStepExecMode(100201, EQuestStepExecMode.Serial)
    
    --阅读露西亚发来的短信
    self._proxy:SetQuestObjectiveType(10020101, EQuestObjectiveType.ReadShortMessageComplete)
    self._proxy:SetQuestObjectiveArgs(10020101, {
        ShortMessageId = 100201,
        AutoSend = true, --enter时，自动发送短信
    })
    self._proxy:SetQuestObjectiveLevelId(10020101, 4001)

    --无文本的目标
    self._proxy:SetQuestObjectiveType(10020102, EQuestObjectiveType.DramaPlayFinish)
    self._proxy:SetQuestObjectiveArgs(10020102, {
        DramaName = "Lucia_Date_1002_01",
        AutoPlay = true, --enter时，自动播放剧情
    })
    self._proxy:SetQuestObjectiveLevelId(10020102, 4001)
    
    --回宿舍
    self._proxy:SetQuestObjectiveType(10020103, EQuestObjectiveType.EnterLevel)
    self._proxy:SetQuestObjectiveArgs(10020103, {
        LevelId = 4003,
    })
    self._proxy:SetQuestObjectiveLevelId(10020103, 4001)
    --[[
        Enter:
            np1 = AddQuestNavPoint(targetPlaceId:51)
        Exit:
            RemoveQuestNavPoint(navPointId:np1)
    ]]

    --拿走兔子点心
    self._proxy:SetQuestObjectiveType(10020104, EQuestObjectiveType.InteractComplete)
    self._proxy:SetQuestObjectiveArgs(10020104, {
        TargetPlaceId = 3,
        TargetType = "SceneObject",
    })
    self._proxy:SetQuestObjectiveLevelId(10020104, 4003)
    --[[
        Enter:
            LoadSceneObject(placeId:2)
        Exit:
            UnloadSceneObject(placeId:2)
    ]]

    --阅读休闲桌上的新闻
    self._proxy:SetQuestObjectiveType(10020105, EQuestObjectiveType.InteractComplete)
    self._proxy:SetQuestObjectiveArgs(10020105, {
        TargetPlaceId = 4,
        TargetType = "SceneObject",
    })
    self._proxy:SetQuestObjectiveLevelId(10020105, 4003)

    --看看吧台上的报纸
    self._proxy:SetQuestObjectiveType(10020106, EQuestObjectiveType.InteractComplete)
    self._proxy:SetQuestObjectiveArgs(10020106, {
        TargetPlaceId = 5,
        TargetType = "SceneObject",
    })
    self._proxy:SetQuestObjectiveLevelId(10020106, 4003)

    --前往时序广场
    self._proxy:SetQuestObjectiveType(10020107, EQuestObjectiveType.EnterLevel)
    self._proxy:SetQuestObjectiveArgs(10020107, {
        LevelId = 4001,
    })
    self._proxy:SetQuestObjectiveLevelId(10020107, 4003)
    --[[
        Enter:
            np1 = AddQuestNavPoint(targetPlaceId:6)
        Exit:
            RemoveQuestNavPoint(navPointId:np1)
    ]]

    --前往咖啡厅，询问服务员露西亚坐在哪儿了
    self._proxy:SetQuestObjectiveType(10020108, EQuestObjectiveType.DramaPlayFinish)
    self._proxy:SetQuestObjectiveArgs(10020108, {
        DramaName = "Lucia_Date_1002_02",
        AutoPlay = false, --不自动播放剧情，剧情会通过和npc交互播放
    })
    self._proxy:SetQuestObjectiveLevelId(10020108, 4001)
    --[[
        Enter:
            np1 = AddQuestNavPoint(targetPlaceId:102003)
            OverrideNpcInteractReaction(npcPlaceId:102003, reactCb:function()
                PlayDrama("Lucia_Date_1002_02")
            end)
        Exit:
            RemoveQuestNavPoint(navPointId:np1)
            RestoreNpcInteractReaction(npcPlaceId:102003)
    ]]

    --去见露西亚
    self._proxy:SetQuestObjectiveType(10020109, EQuestObjectiveType.InteractComplete)
    self._proxy:SetQuestObjectiveArgs(10020109, {
        TargetPlaceId = 102072,
        TargetType = "Npc",
    })
    self._proxy:SetQuestObjectiveLevelId(10020109, 4001)
    --[[
        Enter:
            OverrideNpcInteractReaction(npcPlaceId:102072, reactCb:function()
                PlayDrama("Lucia_Date_1002_03")
            end)
        Exit:
            RestoreNpcInteractReaction(npcPlaceId:102072)
    ]]


    --其实可以再简化一下
    self:InitQuestObjective(10020108,
        {
            Type = EQuestObjectiveType.DramaPlayFinish,
            Args = {
                DramaName = "Lucia_Date_1002_02",
                AutoPlay = false, --不自动播放剧情，剧情会通过和npc交互播放
            },
            LevelId = 4001,
            ---@param obj QuestObjective10020108
            EnterFunc = function(obj, proxy)
                proxy:OverrideNpcInteractReaction(102072, function()
                    proxy:PlayDrama("Lucia_Date_1002_03")
                end)
            end,
            ---@param obj QuestObjective10020108
            ExitFunc = function(obj, proxy)
                proxy:RestoreNpcInteractReaction(102072)
            end,
        }
    )
    self:InitQuestObjective(10020109, 
        {
            Type = EQuestObjectiveType.InteractComplete,
            Args = {
                TargetPlaceId = 102072,
                TargetType = "Npc",
            },
            LevelId = 4001,
            ---@param obj QuestObjective10020109
            EnterFunc = function(obj, proxy)
                obj.np1 = proxy:AddQuestNavPoint(6)
            end,
            ---@param obj QuestObjective10020109
            ExitFunc = function(obj, proxy)
                proxy:RemoveQuestNavPoint(obj.np1)
            end,
        }
    )

    --然后下一步就该编辑器了。。。
    --DlcQuestEditor
    --给每个字段都加上相应的编辑支持。。
    --需要的时间和人力再次UP↑。。。。

end

---@class Quest1002Objective
local Quest1002Objective = require("class")()

---@param quest Quest1002
function Quest1002Objective:Ctor(quest)
    self.quest = quest
end

---@class QuestObjective10020108 : Quest1002Objective
---@class QuestObjective10020109 : Quest1002Objective