---@class XUiRogueSimStory : XLuaUi
---@field private _Control XRogueSimControl
local XUiRogueSimStory = XLuaUiManager.Register(XLuaUi, "UiRogueSimStory")
local CSInstantiate = CS.UnityEngine.Object.Instantiate

function XUiRogueSimStory:OnAwake()
    self.StroyGroups = self:GetStroyGroups()
    self.TabBtns = {}
    self.StoryGos = {self.GridStory}

    self:RegisterUiEvents()
    self:InitTimes()
    self:InitTabButton()
end

function XUiRogueSimStory:OnStart()
    self.UnlockStoryIdDic = self:GetUnlockStoryIdDic()
    self.RedDic = self:GetRedDic()

    -- 刷新页签红点
    for _, btn in ipairs(self.TabBtns) do
        btn:ShowReddot(false)
    end
    for groupId, redDic in pairs(self.RedDic) do
        if next(redDic) then
            local tabIndex = groupId
            self.TabBtns[tabIndex]:ShowReddot(true)
        end
    end

    -- 选中第一个页签
    if #self.TabBtns > 0 then
        self.PanelTabList:SelectIndex(1)
    end
end

function XUiRogueSimStory:OnEnable()
    self.Super.OnEnable(self)
end

function XUiRogueSimStory:OnDisable()
    self.Super.OnDisable(self)
end

function XUiRogueSimStory:InitTimes()
    self.EndTime = self._Control:GetActivityEndTime()
    self:SetAutoCloseInfo(self.EndTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)
end

function XUiRogueSimStory:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
end

function XUiRogueSimStory:InitTabButton()
    self.TabBtns = {}
    for i, stroyGroup in ipairs(self.StroyGroups) do
        local btn = i == 1 and self.BtnTab or CSInstantiate(self.BtnTab, self.TabContent)
        btn:SetName(stroyGroup.Name)
        table.insert(self.TabBtns, btn)
    end

    self.PanelTabList:Init(self.TabBtns, function(index)
        self:SelectTab(index)
    end)
end

function XUiRogueSimStory:SelectTab(index)
    if self.CurTabIndex ~= index then
        self:PlayAnimation("QieHuan")
        self.CurTabIndex = index
        self.CurGroupRedDic = self.RedDic[self.CurTabIndex] or {}
        self.RedDic[self.CurTabIndex] = {}
        self.TabBtns[self.CurTabIndex]:ShowReddot(false)
        self:RefreshStoryGroup()

        -- 移除红点记录
        local ids = {}
        for illId, _  in pairs(self.CurGroupRedDic) do
            table.insert(ids, illId)
        end
        self._Control:RemoveIllustratesRed(ids)
    end
end

-- 刷新一个故事组
function XUiRogueSimStory:RefreshStoryGroup()
    local storyGroup = self.StroyGroups[self.CurTabIndex]
    table.sort(storyGroup.StoryList, function(a, b)
        return a.Id < b.Id
    end)

    self.TxtTitle.text = storyGroup.Name
    for _, storyGo in ipairs(self.StoryGos) do
        storyGo.gameObject:SetActiveEx(false)
    end

    local unlockText = self._Control:GetClientConfig("StoryLockText")
    for i, story in ipairs(storyGroup.StoryList) do
        local storyGo = self.StoryGos[i]
        if not storyGo then
            storyGo = CSInstantiate(self.GridStory, self.StoryContent)
            table.insert(self.StoryGos, storyGo)
        end
        storyGo.gameObject:SetActiveEx(true)
        local isUnlock = self.UnlockStoryIdDic[story.Id]
        local isNew = self.CurGroupRedDic[story.Id]
        local txtStoryDesc = storyGo:GetObject("TxtStoryDesc")
        txtStoryDesc.gameObject:SetActiveEx(isUnlock)
        storyGo:GetObject("Lock").gameObject:SetActiveEx(not isUnlock)
        if isUnlock then
            storyGo:GetObject("TxtStoryDesc").text = XUiHelper.ConvertLineBreakSymbol(story.StoryDesc)
            storyGo:GetObject("NewTag").gameObject:SetActiveEx(isNew)
        else
            local txtLock = XUiHelper.TryGetComponent(storyGo.transform, "Lock/PanelLock/TxtLock", "Text")
            txtLock.text = story.UnlockTips
        end
    end
end

-- 获取故事组
function XUiRogueSimStory:GetStroyGroups()
    local storyGroupDic = {}
    local illustrates = self._Control:GetRogueSimIllustrateConfigs()
    for _, illustrate in pairs(illustrates) do
        if illustrate.StoryGroupId ~= 0 then
            local storyGroup = storyGroupDic[illustrate.StoryGroupId]
            if not storyGroup then
                storyGroup = { Id = illustrate.StoryGroupId, Name = "", StoryList = {} }
                storyGroupDic[illustrate.StoryGroupId] = storyGroup
            end
            if illustrate.StoryGroupName then
                storyGroup.Name = illustrate.StoryGroupName
            end
            table.insert(storyGroup.StoryList, illustrate)
        end
    end

    local storyGroups = {}
    for _, storyGroup in ipairs(storyGroupDic) do
        table.insert(storyGroups, storyGroup)
    end
    return storyGroups
end

-- 获取已解故事列表
function XUiRogueSimStory:GetUnlockStoryIdDic()
    local unlockIdDic = {}
    local illustrates = self._Control:GetIllustrates()
    for _, illId in ipairs(illustrates) do
        local config = self._Control:GetRogueSimIllustrateConfig(illId)
        if config.Type == XEnumConst.RogueSim.IllustrateType.Event then
            unlockIdDic[config.Id] = true
        end
    end

    return unlockIdDic
end

-- 获取红点哈希表
function XUiRogueSimStory:GetRedDic()
    local redDic = {}

    local illIds = self._Control:GetShowRedIllustrates()
    for _, illId in ipairs(illIds) do
        local config = self._Control:GetRogueSimIllustrateConfig(illId)
        if config.Type == XEnumConst.RogueSim.IllustrateType.Event then
            redDic[config.StoryGroupId] = redDic[config.StoryGroupId] or {}
            redDic[config.StoryGroupId][config.Id] = true
        end
    end
    return redDic
end

return XUiRogueSimStory