local XTempleConfigControl = require("XModule/XTemple/XTempleConfigControl")
local XTempleEnumConst = require("XEntity/XTemple/XTempleEnumConst")

---@class XTempleControl : XTempleConfigControl
---@field private _Model XTempleModel
local XTempleControl = XClass(XTempleConfigControl, "XTempleControl")

function XTempleControl:OnInit()
    self._UiData = {
        Rule = {},
    }

    ---@type XTempleGameControl
    self._GameControl = nil

    ---@type XTempleGameEditorControl
    self._GameEditorControl = nil

    ---@type XTempleGameEditorControl
    self._GameEditorTempControl = nil

    ---@type XTempleUiControl
    self._UiControl = nil

    ---@type XTempleCoupleGameControl
    self._CoupleGameControl = nil

    self._IsEditor = false

    self._Chapter = XTempleEnumConst.CHAPTER.SPRING

    self:InstantiateServerData()
end

function XTempleControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XTempleControl:RemoveAgencyEvent()
end

function XTempleControl:OnRelease()
    self._IsEditor = false

    ---@type XTempleGameControl
    self._GameControl = nil

    ---@type XTempleGameEditorControl
    self._GameEditorControl = nil

    ---@type XTempleGameEditorControl
    self._GameEditorTempControl = nil

    ---@type XTempleUiControl
    self._UiControl = nil

    ---@type XTempleCoupleGameControl
    self._CoupleGameControl = nil

end

function XTempleControl:SetEditor(value)
    self._IsEditor = value
end

function XTempleControl:SetChapter(chapter)
    self._Chapter = chapter
end

---@return XTempleGameControl
function XTempleControl:GetGameControl()
    if self._IsEditor then
        return self:GetGameEditorControl()
    end
    if self._Chapter == XTempleEnumConst.CHAPTER.COUPLE then
        return self:GetCoupleGameControl()
    end
    self._GameControl = self._GameControl or self:AddSubControl(require("XModule/XTemple/XTempleGameControl"))
    return self._GameControl
end

---@return XTempleGameEditorControl
function XTempleControl:GetGameEditorControl()
    self._GameEditorControl = self._GameEditorControl or self:AddSubControl(require("XModule/XTemple/XTempleGameEditorControl"))
    return self._GameEditorControl
end

function XTempleControl:GetGameEditorTempControl()
    self._GameEditorTempControl = self._GameEditorTempControl or self:AddSubControl(require("XModule/XTemple/XTempleGameEditorTempControl"))
    return self._GameEditorTempControl
end

---@return XTempleUiControl
function XTempleControl:GetUiControl()
    self._UiControl = self._UiControl or self:AddSubControl(require("XModule/XTemple/XTempleUiControl"))
    return self._UiControl
end

function XTempleControl:GetCoupleGameControl()
    self._CoupleGameControl = self._CoupleGameControl or self:AddSubControl(require("XModule/XTemple/XTempleCoupleGameControl"))
    return self._CoupleGameControl
end

function XTempleControl:GetGameUiName(stageId)
    if self._Model:IsCoupleStage(stageId) then
        return "UiTempleBattleCouple"
    end
    return "UiTempleBattle"
end

function XTempleControl:OpenNewGame(stageId, callback)
    XMVCA.XTemple:RequestStart(stageId, function()
        XLuaUiManager.Open(self:GetGameUiName(stageId), stageId)
        if callback then
            callback()
        end
    end)
end

function XTempleControl:ContinueGame()
    local activityData = self._Model:GetActivityData()
    if activityData:HasStage2Continue(self:GetChapter()) then
        local data = activityData:GetStage2Continue(self:GetChapter())
        local stageId = data.StageId
        XLuaUiManager.Open(self:GetGameUiName(stageId), stageId)
        return true
    end
    return false
end

function XTempleControl:GetChapter()
    return self._Chapter
end

function XTempleControl:IsCoupleChapter()
    return self:GetChapter() == XTempleEnumConst.CHAPTER.COUPLE
end

function XTempleControl:IsSpringChapter()
    return self:GetChapter() == XTempleEnumConst.CHAPTER.SPRING
end

function XTempleControl:IsLanternChapter()
    return self:GetChapter() == XTempleEnumConst.CHAPTER.LANTERN
end

function XTempleControl:_StartGame(callback)
    local stageId = self:GetGameControl():GetStageId()
    self:OpenNewGame(stageId, callback)
end

function XTempleControl:StartGame(callback)
    if self:IsCoupleChapter() then
        local characterId = self:GetUiControl():GetSelectedCharacterId()
        if self._Model:GetActivityData():HasPhotoData(characterId) then
            --XUiManager.DialogTip(nil, XUiHelper.GetText("TempleRechallengeStage"), nil, nil, )
            XLuaUiManager.Open("UiTempleTips", function()
                self:_StartGame(callback)
            end, XUiHelper.GetText("TempleRechallengeStage"))
            return
        end
    end
    self:_StartGame(callback)
end

function XTempleControl:ReleaseGameControl()
    if self._GameControl then
        self:RemoveSubControl(self._GameControl)
        self._GameControl = nil
    end
    if self._CoupleGameControl then
        self:RemoveSubControl(self._CoupleGameControl)
        self._CoupleGameControl = nil
    end
end

function XTempleControl:InstantiateServerData()
    self._Model:InstantiateServerData()
end

function XTempleControl:IsEditor()
    return self._IsEditor
end

function XTempleControl:GetTaskReward4Show()
    --local chapter = self:GetChapter()
    --local groupId
    --if chapter == XTempleEnumConst.CHAPTER.SPRING then
    --    groupId = XTempleEnumConst.TASK.SPRING
    --elseif chapter == XTempleEnumConst.CHAPTER.COUPLE then
    --    groupId = XTempleEnumConst.TASK.COUPLE
    --elseif chapter == XTempleEnumConst.CHAPTER.LANTERN then
    --    groupId = XTempleEnumConst.TASK.LANTERN
    --end
    --local taskDatas = XDataCenter.TaskManager.GetTaskByTypeAndGroup(XDataCenter.TaskManager.TaskType.TimeLimit, groupId)
    --local target
    --for i, taskData in pairs(taskDatas) do
    --    if not target then
    --        target = taskData
    --    end
    --    if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
    --        target = taskData
    --        break
    --    end
    --end
    --if target then
    --end
    local rewardId = self._Model:GetRewardId()
    return XRewardManager.GetRewardList(rewardId) or {}
end

function XTempleControl:GetHelpKey()
    return "Temple"
end

function XTempleControl:GetHelpKeyCouple()
    return "TempleCouple"
end

return XTempleControl