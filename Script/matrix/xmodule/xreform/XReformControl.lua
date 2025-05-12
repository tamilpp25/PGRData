---@class XReformControl : XControl
---@field private _Model XReformModel
local XReformControl = XClass(XControl, "XReformControl")
function XReformControl:OnInit()
    --初始化内部变量
    self._Model:InitWithServerData()
end

function XReformControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
    self:GetAgency():AddEventListener(XEventId.EVENT_REFORM_SERVER_DATA, self.UpdateServerData, self)
    XEventManager.AddEventListener(XEventId.EVENT_REFORM_ON_ENVIRONMENT_CLOSE, self.SetUiEnvironmentAutoOpened, self)
end

function XReformControl:RemoveAgencyEvent()
    self:GetAgency():RemoveEventListener(XEventId.EVENT_REFORM_SERVER_DATA, self.UpdateServerData, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_REFORM_ON_ENVIRONMENT_CLOSE, self.SetUiEnvironmentAutoOpened, self)
end

function XReformControl:OnRelease()
end

function XReformControl:UpdateServerData()
    self._Model:InitWithServerData()
end

---@return XViewModelReform2ndList
function XReformControl:GetViewModel()
    return self._Model:GetViewModel()
end

---@return XViewModelReform2ndList
function XReformControl:GetViewModelList()
    return self._Model:GetViewModelList()
end

function XReformControl:GetActivityTime()
    return self._Model:GetActivityTime()
end

function XReformControl:GetActivityEndTime()
    return self._Model:GetActivityEndTime()
end

function XReformControl:GetActivityTime()
    return self._Model:GetActivityTime()
end

function XReformControl:GetHelpKey()
    return self._Model:GetHelpKey()
end

function XReformControl:GetChapterStarDesc(chapter)
    return self._Model:GetChapterStarDesc(chapter)
end

function XReformControl:IsChapterFinished(chapter)
    return self._Model:IsChapterFinished(chapter)
end

---@param chapter XReform2ndChapter
function XReformControl:IsChapterStageFinished(chapter, isHardMode)
    local stage = chapter:GetStageByDifficulty(self._Model, isHardMode)
    if stage then
        if stage:GetIsPassed() then
            return true
        end
    end
    return false
end

function XReformControl:GetChapterName(chapter)
    return self._Model:GetChapterName(chapter)
end

function XReformControl:GetStageName(stageId)
    return self._Model:GetStageName(stageId)
end

---@param chapter XReform2ndChapter
function XReformControl:IsChapterShowToggleHard(chapter)
    local isShowToggleHard = chapter:IsShowToggleHard(self._Model)
    return isShowToggleHard
end

function XReformControl:IsUnlockAllStageHard()
    return self._Model:IsUnlockAllStageHard()
end

---@param chapter XReform2ndChapter
function XReformControl:IsHasStageHard(chapter)
    return chapter:IsHasStageHard(self._Model)
end

---@param stage XReform2ndStage
function XReformControl:IsHardStage(stage)
    return stage:IsHardStage(self._Model)
end

function XReformControl:IsSuperior()
    return self._Model:IsSuperior()
end

function XReformControl:GetKeyChapterJustUnlockToggleHard(chapterId)
    return "XReformJustUnlockToggleHard" .. XPlayer.Id .. chapterId
end

function XReformControl:GetCurrentChapterId()
    local viewModel = self._Model:GetViewModelList()
    local chapter = viewModel:GetCurrentChapter()
    return chapter:GetId()
end

--function XReformControl:IsChapterJustUnlockToggleHard(chapterId)
--    chapterId = chapterId or self:GetCurrentChapterId()
--    local key = self:GetKeyChapterJustUnlockToggleHard(chapterId)
--    local value = XSaveTool.GetData(key)
--    return value == nil
--end

--function XReformControl:IsHasChapterJustUnlockToggleHard()
--    local allChapter = self._Model:GetChapterConfig()
--    for i, config in pairs(allChapter) do
--        if self:IsChapterJustUnlockToggleHard(config.Id) then
--            return true
--        end
--    end
--    return false
--end

--function XReformControl:SetNotJustUnlockToggleHard(chapterId)
--    chapterId = chapterId or self:GetCurrentChapterId()
--    local key = self:GetKeyChapterJustUnlockToggleHard(chapterId)
--    XSaveTool.SaveData(key, true)
--end

--function XReformControl:SetAllChapterCanChallengeNotJustUnlockToggleHard()
--    local viewModel = self._Model:GetViewModel()
--    local totalNumber = viewModel:GetChapterTotalNumber()
--    for i = 1, totalNumber do
--        ---@type XReform2ndChapter
--        local chapter = viewModel:GetChapterByIndex(i)
--        local chapterId = chapter:GetId()
--        if self:IsChapterJustUnlockToggleHard(chapterId) then
--            local isHasStageHard = self:IsHasStageHard(chapter)
--            local isUnlockStageHard = self:IsChapterShowToggleHard(chapter)
--            if isHasStageHard and isUnlockStageHard then
--                self:SetNotJustUnlockToggleHard(chapterId)
--            end
--        end
--    end
--end

---@param stage XReform2ndStage
function XReformControl:CheckUiEnvironmentAutoOpen(stage)
    local key = self._Model:GetReformAutoEnvironmentKey(stage:GetId())
    local value = XSaveTool.GetData(key)
    if value == nil then
        -- 为了指引，延迟到关闭界面之时
        --XSaveTool.SaveData(key, true)
        self:OpenUiEnvironment()
    end
end

function XReformControl:SetUiEnvironmentAutoOpened()
    local stageId = self._Model:GetUiCurrentStageId()
    if stageId then
        local key = self._Model:GetReformAutoEnvironmentKey(stageId)
        local value = XSaveTool.GetData(key)
        if value == nil then
            XSaveTool.SaveData(key, true)
        end
    end
end

function XReformControl:OpenUiEnvironment()
    local XReformEnvironmentData = require("XEntity/XReform/Environment/XReformEnvironmentData")
    local viewModel = self:GetViewModelList()
    viewModel:UpdateEnvironment()
    local uiData = viewModel:GetUiDataEnvironment()
    local data = XReformEnvironmentData.New(uiData.List)
    XLuaUiManager.Open("UiTransfiniteEnvironmentDetail", data)
end

return XReformControl