---@class XUiGridBWQuestItem
---@field _Control XBigWorldQuestControl
---@field Parent XUiBigWorldTask
local XUiGridBWQuestItem = XClass(nil, "XUiGridBWQuestItem")

-- 这里不用XUiNode: 这个界面是战斗管理，生命周期可能会异常
function XUiGridBWQuestItem:Ctor(ui, parent)
    XTool.InitUiObjectByUi(self, ui)
    self.Parent = parent
    self._Control = parent._Control
    
    XUiHelper.RegisterCommonClickEvent(self.Parent, self.Transform, self.Parent.OnQuestClick)
end

---@param objective XBigWorldQuestObjective
function XUiGridBWQuestItem:Update(objective, i)
    local id = objective:GetId()
    local objectText = self._Control:GetObjectiveTitle(id)
    local progress = self._Control:GetObjectiveProgressDesc(id, objective:GetProgress())
    self.TxtContent.text = string.format("%s(%s)", objectText, progress)
    local isFinish = self._Control:IsObjectiveFinish(id, objective:GetProgress())
    self.Complete.gameObject:SetActiveEx(isFinish)
    self.UnComplete.gameObject:SetActiveEx(not isFinish)
end

function XUiGridBWQuestItem:Open()
    self.GameObject:SetActiveEx(true)
end

function XUiGridBWQuestItem:Close()
    self.GameObject:SetActiveEx(false)
end

function XUiGridBWQuestItem:IsNodeShow()
    return self.GameObject.activeInHierarchy
end


---@class XUiBigWorldTask : XLuaUi
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field _Control XBigWorldQuestControl
---@field _OpQueue XQueue
---@field _GridQuests table<number, XUiGridBWQuestItem>
local XUiBigWorldTask = XLuaUiManager.Register(XLuaUi, "UiBigWorldTask")

local BWEventId = XMVCA.XBigWorldService.DlcEventId
local QuestOpType = XMVCA.XBigWorldQuest.QuestOpType

function XUiBigWorldTask:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiBigWorldTask:OnStart()
    XEventManager.AddEventListener(BWEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, self.EnqueueOp, self)
end

function XUiBigWorldTask:OnEnable()
    self:UpdateByRefresh(self:GetOpData(QuestOpType.Refresh))
end

function XUiBigWorldTask:OnDisable()
    if self.GridQuestEnable then
        self.GridQuestEnable:StopTimelineAnimation(false, true)
    end

    if self.GridQuestFinish then
        self.GridQuestFinish:StopTimelineAnimation(false, true) 
    end

    if self.GridQuestStart then
        self.GridQuestStart:StopTimelineAnimation(false, true) 
    end
end

function XUiBigWorldTask:OnDestroy()
    XEventManager.RemoveEventListener(BWEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, self.EnqueueOp, self)
end

function XUiBigWorldTask:InitUi()
    self._GridQuests = {}
    
    self._OpQueue = XQueue.New()
    
    self._PopupCount = 0
    
    self.GridQuestEnable = self.Transform:Find("Animation/GridQuestEnable")
    self.GridQuestFinish = self.Transform:Find("Animation/GridQuestFinish")
    self.GridQuestStart = self.Transform:Find("Animation/GridQuestStart")
end

function XUiBigWorldTask:InitCb()
    self._CheckShow = handler(self, self.CheckObjectiveShow)
    self:RegisterClickEvent(self.PanelTitle, self.OnQuestClick)
end

function XUiBigWorldTask:EnqueueOp(op)
    if op == QuestOpType.PopupBegin then 
        self._PopupCount = self._PopupCount + 1
    elseif op == QuestOpType.PopupEnd then
        self._PopupCount = self._PopupCount - 1
    else
        self._OpQueue:Enqueue(self:GetOpData(op))
    end
    self:TryUpdateByOp()
end

function XUiBigWorldTask:TryUpdateByOp()
    --有弹窗
    if self._PopupCount > 0 then
        return
    end
    --上次操作还在进行
    if self._IsOping then
        return
    end
    
    if self._OpQueue:IsEmpty() then
        self._OpQueue:Clear()
        return
    end

    if self._OpQueue:Count() > 500 then
        self._OpQueue:ClearUnUsed()
    end
    
    self._IsOping = true
    local data = self._OpQueue:Dequeue()
    local op = data.Op
    if op == QuestOpType.Refresh then
        self:UpdateByRefresh(data)
    elseif op == QuestOpType.Complete then
        self:UpdateByFinish(data)
    elseif op == QuestOpType.Receive then
        self:UpdateByReceive(data)
    elseif op == QuestOpType.PopupBegin  then
        
    end
end

function XUiBigWorldTask:OnOpFinished()
    self._IsOping = false
    self:TryUpdateByOp()
end

function XUiBigWorldTask:UpdateByReceive(data)
    local objectiveList = self:UpdateViewAndGetList(data)
    if not objectiveList then
        self:UpdateDynamicItem(self._GridQuests, {})
        return self:OnOpFinished()
    end

    self:UpdateDynamicItem(self._GridQuests, objectiveList, true)
    self:OnOpFinished()
end

function XUiBigWorldTask:UpdateByFinish(data)
    if not data then
        return self:OnOpFinished()
    end
    if not self.PanelQuest.gameObject.activeInHierarchy then
        return self:OnOpFinished()
    end
    
    self:PlayGirdQuestFinish()
end

function XUiBigWorldTask:UpdateByRefresh(data)
    local objectiveList = self:UpdateViewAndGetList(data)
    if not objectiveList then
        self:UpdateDynamicItem(self._GridQuests, {})
        return self:OnOpFinished()
    end
    
    self:UpdateDynamicItem(self._GridQuests, objectiveList)
    
    self:OnOpFinished()
end

function XUiBigWorldTask:UpdateViewAndGetList(data)
    if not data then
        self.ImgTitle.gameObject:SetActiveEx(false)
        self.PanelQuest.gameObject:SetActiveEx(false)
        return
    end
    local questId = data.QuestId
    if not questId or questId < 0 then
        self.ImgTitle.gameObject:SetActiveEx(false)
        self.PanelQuest.gameObject:SetActiveEx(false)
        return
    end
   
    local stepId = data.StepId
    if not stepId or stepId < 0 then
        self.ImgTitle.gameObject:SetActiveEx(false)
        self.PanelQuest.gameObject:SetActiveEx(false)
        return
    end
    self.ImgTitle.gameObject:SetActiveEx(true)
    self.TxtTitle.text = self._Control:GetQuestName(questId)
    self.ImgTitle:SetSprite(self._Control:GetQuestIcon(questId))
    self.PanelQuest.gameObject:SetActiveEx(true)
    self.TxtStep.text = self._Control:GetStepText(stepId)
    return data.ObjectiveList
end

---@param data XBigWorldQuestObjective
function XUiBigWorldTask:CheckObjectiveShow(data)
    if not data then
        return false
    end
    local title = self._Control:GetObjectiveTitle(data:GetId())
    if string.IsNilOrEmpty(title) then
        return false
    end
    return true
end

function XUiBigWorldTask:UpdateDynamicItem(gridArray, dataArray, isPlayEnable)
    if #gridArray == 0 then
        self.GridQuest.gameObject:SetActiveEx(false)
    end
    for i = 1, #dataArray do
        local grid = gridArray[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridQuest, self.GridQuest.transform.parent)
            grid = XUiGridBWQuestItem.New(ui, self)
            gridArray[i] = grid
        end
        grid:Open()
        grid:Update(dataArray[i], i)
    end

    if isPlayEnable then
        self:PlayGridQuestEnable()
    end
end

function XUiBigWorldTask:PlayGridQuestEnable()
    self:PlayAnimation("GridQuestEnable", function() 
        self:OnOpFinished()
    end)
    self:PlayAnimation("GridQuestStart")
end

function XUiBigWorldTask:PlayGirdQuestFinish()
    self:PlayAnimation("GridQuestFinish", function()
        for _, grid in pairs(self._GridQuests) do
            grid:Close()
        end
        self:OnOpFinished()
    end)
end

function XUiBigWorldTask:GetOpData(op)
    local questId = self._Control:GetTrackQuestId()
    local stepId
    local objList
    local questData = XMVCA.XBigWorldQuest:GetQuestData(questId)
    if questData:IsShowInList() then
        local stepList = questData:GetActiveStepData()
        if not XTool.IsTableEmpty(stepList) then
            local step = stepList[1]
            stepId = step:GetId()
            objList = step:GetObjectiveList(self._CheckShow)
        end
    end
    return {
        Op = op,
        QuestId = questId,
        StepId = stepId,
        ObjectiveList = objList,
    }
end

function XUiBigWorldTask:OnQuestClick()
    local questId = self._Control:GetTrackQuestId()
    if not questId or questId <= 0 then
        return
    end
    XMVCA.XBigWorldGamePlay:GetCurrentAgency():OpenQuest(1, questId)
end