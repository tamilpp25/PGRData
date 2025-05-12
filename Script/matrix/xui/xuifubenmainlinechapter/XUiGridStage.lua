local ComponentScriptPath = "XUi/XUiFubenMainLineChapter/%s"

local stringFormat = string.format

local XUiGridStage = XClass(nil, "XUiGridStage")

function XUiGridStage:Ctor(rootUi, ui, cb, fubenType, IsMainLineExplore, isOnZhouMu)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.ClickCb = cb
    self.Components = {}
    self.FubenType = fubenType
    self.IsMainLineExplore = IsMainLineExplore
    self.IsOnZhouMu = isOnZhouMu
    self:InitAutoScript()
    self:OnEnable()
end

function XUiGridStage:OnEnable()
    if self.Stage then
        self:UpdateFightControl()
    end

    if self.Enabled then
        return
    end

    self.Enabled = true
end

function XUiGridStage:OnDisable()
    if not self.Enabled then
        return
    end

    for _, component in pairs(self.Components) do
        if component.OnDisable then component:OnDisable() end
    end

    self.Enabled = false
end

--[[设置组件显隐，第一次设置显示时若组件不存在则加载组件prefab]]
--componentName:组件名称字符串
--isActive:是否显示
--notScript:是否不需要加载组件脚本
function XUiGridStage:SetComponentActive(componentName, isActive, notScript, ...)
    local component = self.Components[componentName]
    local go = component and (component.GameObject or component.gameObject)
    if not XTool.UObjIsNil(go) then
        go:SetActiveEx(isActive)

        if isActive then
            if component.OnEnable then component:OnEnable(...) end
            if self.Stage and component.UpdateStageId then
                component:UpdateStageId(self.Stage.StageId)
            end
        else
            if component.OnDisable then component:OnDisable() end
        end
    elseif isActive then
        local parent = self[componentName .. "Parent"]
        if XTool.UObjIsNil(parent) then return end
        local prefab = self.Obj:Instantiate(componentName, parent.gameObject)
        if XTool.UObjIsNil(prefab) then return end

        local scriptPath = stringFormat(ComponentScriptPath, "XUi" .. componentName)
        if notScript then
            self.Components[componentName] = prefab
        else
            component = require(scriptPath).New(prefab, ...)
            self.Components[componentName] = component
            if component.OnEnable then component:OnEnable(...) end
        end
    end
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiGridStage:InitAutoScript()
    XTool.InitUiObject(self)
    self:AutoAddListener()
end

function XUiGridStage:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiGridStage:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiGridStage:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiGridStage:AutoAddListener()
    self:RegisterClickEvent(self.BtnStage, self.OnBtnStageClick)
end
-- auto
function XUiGridStage:OnBtnStageClick()
    if self.ClickCb then
        self.ClickCb(self)
    end

    local stageId = self.Stage.StageId
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)

    -- if self.FubenType == XFubenConfigs.FUBENTYPE_NORMAL then
    --     self:NormalStageClick(stageId, stageCfg, stageInfo)
    -- else
    if self.FubenType == XFubenConfigs.FUBENTYPE_PREQUEL then
        self:PrequelStageClick(stageId, stageCfg, stageInfo)
    end
end

-- function XUiGridStage:NormalStageClick(stageId, stageCfg, stageInfo)
--     if stageCfg.StageType == XFubenConfigs.STAGETYPE_STORY or stageCfg.StageType == XFubenConfigs.STAGETYPE_STORYEGG then
--     elseif stageCfg.StageType == XFubenConfigs.STAGETYPE_FIGHT or stageCfg.StageType == XFubenConfigs.STAGETYPE_FIGHTEGG then
--     end
-- end
function XUiGridStage:PrequelStageClick(stageId, stageCfg, stageInfo)
    --普通副本格子点击
    if stageCfg.StageType == XFubenConfigs.STAGETYPE_STORY or stageCfg.StageType == XFubenConfigs.STAGETYPE_STORYEGG then
        if not XDataCenter.PrequelManager.CheckPrequelStageOpen(stageId) then
            if stageCfg.RequireLevel > 0 and XPlayer.Level < stageCfg.RequireLevel then
                XUiManager.TipError(CS.XTextManager.GetText("TeamLevelToOpen", stageCfg.RequireLevel))
                return
            end
            for _, conditionId in pairs(stageCfg.ForceConditionId or {}) do
                local ret, desc = XConditionManager.CheckCondition(conditionId)
                if not ret then
                    XUiManager.TipError(desc)
                    return
                end
            end
            return
        end

        local beginStoryId = XMVCA.XFuben:GetBeginStoryId(stageId)
        if stageInfo.Passed then
            self.RootUi:OnEnterStory(stageId, function()
                XDataCenter.MovieManager.PlayMovie(beginStoryId, function()
                    XDataCenter.PrequelManager.UpdateShowChapter(stageId)
                end)
            end)
        else
            self.RootUi:OnEnterStory(stageId, function()
                XDataCenter.PrequelManager.FinishStoryRequest(stageId, function()
                    XDataCenter.MovieManager.PlayMovie(beginStoryId, function()
                        --self.RootUi:RefreshRegional()
                        XDataCenter.PrequelManager.UpdateShowChapter(stageId)
                    end)
                end)
            end)
        end
        --前传战斗点击
    elseif stageCfg.StageType == XFubenConfigs.STAGETYPE_FIGHT or stageCfg.StageType == XFubenConfigs.STAGETYPE_FIGHTEGG then
        if not XDataCenter.PrequelManager.CheckPrequelStageOpen(stageId) then
            if stageCfg.RequireLevel > 0 and XPlayer.Level < stageCfg.RequireLevel then
                XUiManager.TipError(CS.XTextManager.GetText("TeamLevelToOpen", stageCfg.RequireLevel))
                return
            end
            for _, conditionId in pairs(stageCfg.ForceConditionId or {}) do
                local ret, desc = XConditionManager.CheckCondition(conditionId)
                if not ret then
                    XUiManager.TipError(desc)
                    return
                end
            end
            return
        end

        self.RootUi:OnEnterFight(stageId, function()
            XDataCenter.FubenManager.EnterPrequelFight(stageId)
        end)
    end
end

function XUiGridStage:UpdateStageMapGrid(stage, chapterOrderId)
    self.Stage = stage
    self.ChapterOrderId = chapterOrderId
    self:Refresh()
end

function XUiGridStage:Refresh()
    if not self.Enabled then return end

    local stageId = self.Stage.StageId
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    local nextStageInfo = XDataCenter.FubenManager.GetStageInfo(stageInfo.NextStageId)
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    local txtName = self.Transform.parent:Find("TxtName")
    if txtName then
        txtName:GetComponent("Text").text = stageCfg.Name
    end
    if stageCfg.StageType == XFubenConfigs.STAGETYPE_COMMON then
        self:SetNormalStage(stageInfo, nextStageInfo, stageCfg, stageId, stageCfg.StageType)
    else
        if self.FubenType == XFubenConfigs.FUBENTYPE_NORMAL then
            --[主线副本/据点战/支线活动]
            self:SetNormalStage(stageInfo, nextStageInfo, stageCfg, stageId, stageCfg.StageType)
        elseif self.FubenType == XFubenConfigs.FUBENTYPE_PREQUEL then
            --[前传]
            self:SetPrequelStage(stageId, stageInfo, stageCfg.StageType, stageCfg.StoryUiStyle)
        end
    end
end

function XUiGridStage:SetPrequelStage(stageId, stageInfo, stageType, storyUiStyle)
    if stageType == XFubenConfigs.STAGETYPE_STORY then
        local isStageUnlock = XDataCenter.PrequelManager.CheckPrequelStageOpen(stageId)
        self:SetPrequelStageComponent("PanelFightActive", false)
        self:SetPrequelStageComponent("PanelFightUnactive", false)
        self:SetPrequelStageComponent("PanelStoryActive", isStageUnlock, nil, storyUiStyle, stageId, self.ChapterOrderId)
        self:SetPrequelStageComponent("PanelStoryUnactive", not isStageUnlock, nil, storyUiStyle, stageId, self.ChapterOrderId)
        self:SetPrequelStageComponent("PanelHideTagNor", false)
        self:SetPrequelStageComponent("PanelHideTagLock", false)
        self:SetPrequelStageComponent("PanelKill", stageInfo.Passed, true)
        self:SetPrequelStageComponent("PanelHideStageNor", false)

        -- 迁移位置测试
        self:AdjustStoryPanelKillPosition(self.Components["PanelStoryActive"], self.Components["PanelKill"])

    elseif stageType == XFubenConfigs.STAGETYPE_FIGHT then
        local isStageUnlock = XDataCenter.PrequelManager.CheckPrequelStageOpen(stageId)
        self:SetPrequelStageComponent("PanelStoryActive", false)
        self:SetPrequelStageComponent("PanelStoryUnactive", false)
        self:SetPrequelStageComponent("PanelFightActive", isStageUnlock, nil, storyUiStyle, stageId, function()
            self:OnBtnStageClick()
        end)
        self:SetPrequelStageComponent("PanelFightUnactive", not isStageUnlock, true, storyUiStyle)
        self:SetPrequelStageComponent("PanelHideTagNor", false)
        self:SetPrequelStageComponent("PanelHideTagLock", false)
        self:SetPrequelStageComponent("PanelKill", stageInfo.Passed, true)
        self:SetPrequelStageComponent("PanelHideStageNor", false)

        -- 迁移位置测试
        self:AdjustFightPanelKillPosition(self.Components["PanelFightActive"], self.Components["PanelKill"])

    elseif stageType == XFubenConfigs.STAGETYPE_FIGHTEGG then
        local isStageUnlock = XDataCenter.PrequelManager.CheckPrequelStageOpen(stageId)
        self:SetPrequelStageComponent("PanelHideStageNor", isStageUnlock, nil, storyUiStyle, stageId, self.RootUi)
        self:SetPrequelStageComponent("PanelHideTagNor", false)
        self:SetPrequelStageComponent("PanelHideTagLock", false)
        self:SetPrequelStageComponent("PanelStoryActive", false)
        self:SetPrequelStageComponent("PanelStoryUnactive", false)
        self:SetPrequelStageComponent("PanelFightActive", false)
        self:SetPrequelStageComponent("PanelFightUnactive", false)

    elseif stageType == XFubenConfigs.STAGETYPE_STORYEGG then
        local isStageUnlock = XDataCenter.PrequelManager.CheckPrequelStageOpen(stageId)
        self:SetPrequelStageComponent("PanelHideTagNor", isStageUnlock, false, storyUiStyle, stageId, self.RootUi)
        self:SetPrequelStageComponent("PanelHideTagLock", not isStageUnlock, true, storyUiStyle, stageId, self.RootUi)
        self:SetPrequelStageComponent("PanelStoryActive", false)
        self:SetPrequelStageComponent("PanelStoryUnactive", false)
        self:SetPrequelStageComponent("PanelFightActive", false)
        self:SetPrequelStageComponent("PanelFightUnactive", false)
        self:SetPrequelStageComponent("PanelHideStageNor", false)
    end
end

function XUiGridStage:SetPrequelStageComponent(componentName, isActive, notScript, uiStyle, ...)
    local component = self.Components[componentName]
    local go = component and (component.GameObject or component.gameObject)
    if not XTool.UObjIsNil(go) then
        go:SetActiveEx(isActive)

        if isActive then
            if component.OnEnable then component:OnEnable(...) end
            if self.Stage and component.UpdateStageId then
                component:UpdateStageId(self.Stage.StageId)
            end
        else
            if component.OnDisable then component:OnDisable() end
        end
    elseif isActive then
        local parent = self[componentName .. "Parent"]
        if XTool.UObjIsNil(parent) then return end
        local prefab
        local prefabName = componentName
        if uiStyle and uiStyle > 1 then
            prefabName = prefabName .. tostring(uiStyle)
            prefab = self.Obj:Instantiate(prefabName, parent.gameObject)
        else
            prefab = self.Obj:Instantiate(componentName, parent.gameObject)
        end
        if XTool.UObjIsNil(prefab) then return end

        local scriptPath = stringFormat(ComponentScriptPath, "XUi" .. componentName)
        if notScript then
            self.Components[componentName] = prefab
        else
            component = require(scriptPath).New(prefab, ...)
            self.Components[componentName] = component
            if component.OnEnable then component:OnEnable(...) end
        end
    end
end

function XUiGridStage:AdjustStoryPanelKillPosition(storyUi, panelkillUi)
    if not storyUi or not panelkillUi then return end
    if storyUi["GetKillPos"] then
        panelkillUi.transform.position = storyUi:GetKillPos()
    end
end

function XUiGridStage:AdjustFightPanelKillPosition(fightUi, panelkillUi)
    if not fightUi or not panelkillUi then return end
    if fightUi["GetKillPos"] then
        panelkillUi.transform.position = fightUi:GetKillPos()
    end
end

function XUiGridStage:SetNormalStage(stageInfo, nextStageInfo, stageCfg, stageId, stageType)
    local IsEgg = false
    if stageType == XFubenConfigs.STAGETYPE_FIGHTEGG or stageType == XFubenConfigs.STAGETYPE_STORYEGG then
        IsEgg = true
    end
    local chapter
    if stageInfo.Type == XDataCenter.FubenManager.StageType.ExtraChapter then
        chapter = XDataCenter.ExtraChapterManager.GetChapterDetailsCfg(stageInfo.ChapterId)
    elseif stageInfo.Type == XDataCenter.FubenManager.StageType.Mainline then
        chapter = XDataCenter.FubenMainLineManager.GetChapterCfg(stageInfo.ChapterId)
    elseif stageInfo.Type == XDataCenter.FubenManager.StageType.ShortStory then
        local chapterId = XFubenShortStoryChapterConfigs.GetShortStoryChapterIdByStageId(stageId)
        chapter = XFubenShortStoryChapterConfigs.CheckChapterDetailsByChapterId(chapterId)
    end
    if stageType == XFubenConfigs.STAGETYPE_STORY or stageType == XFubenConfigs.STAGETYPE_STORYEGG then
        local isUnlock = self:CheckCurrentStageUnlock(stageCfg, stageInfo)
        if isUnlock then
            self:SetStoryStageActive()
            if (not (nextStageInfo and nextStageInfo.Unlock or stageInfo.Passed)) and not IsEgg then
                if not self.IsMainLineExplore then
                    self:SetComponentActive("PanelEffect", true, true)
                end
            else
                self:SetComponentActive("PanelEffect", false)
            end
        else
            self:SetStoryStageLock()
        end

        if chapter or self.IsOnZhouMu then
            local stagePassed = stageInfo.Passed
            self:SetComponentActive("PanelKill", stagePassed, true)
        end

    elseif stageType == XFubenConfigs.STAGETYPE_FIGHT or stageType == XFubenConfigs.STAGETYPE_FIGHTEGG or stageType == XFubenConfigs.STAGETYPE_COMMON then
        local isUnlock = self:CheckCurrentStageUnlock(stageCfg, stageInfo)
        if isUnlock then
            self:SetStageActive()
            local isShowEffect = self:CheckCurrentStageEffect(stageCfg, stageInfo, nextStageInfo)
            if isShowEffect and not IsEgg then
                if not self.IsMainLineExplore then
                    self:SetComponentActive("PanelEffect", true, true)
                end
            else
                self:SetComponentActive("PanelEffect", false)
            end
        elseif stageInfo.IsOpen or self.IsMainLineExplore or self.IsOnZhouMu then
            self:SetStageLock()
        end

        local stagePassed
        if XDataCenter.BfrtManager.CheckStageTypeIsBfrt(stageId) then
            stagePassed = XDataCenter.BfrtManager.IsGroupPassedByStageId(stageId)
            self:SetComponentActive("PanelKill", stagePassed, true)
        else
            stagePassed = self:CheckCurrentStagePassed(stageCfg, stageInfo)
            if chapter or self.IsOnZhouMu then
                self:SetComponentActive("PanelKill", stagePassed, true)
            end
        end
        if stageInfo.Type == XDataCenter.FubenManager.StageType.ActivtityBranch then
            self:SetComponentActive("PanelKill", stagePassed, true)
        elseif stageInfo.Type == XDataCenter.FubenManager.StageType.ActivityBossSingle then
            self:SetComponentActive("PanelKill", XDataCenter.FubenActivityBossSingleManager.IsChallengePassedByStageId(stageId), true)
            if not XDataCenter.FubenActivityBossSingleManager.IsChallengeUnlockByStageId(stageId) then
                self:SetStageLock()
            end
        end

        local rewardTipId = stageCfg.RewardTipId or 0
        self:SetComponentActive("PanelRewardTips", rewardTipId ~= 0, nil, self.RootUi, stageId)
        self:SetComponentActive("PanelAutoFight", stageCfg.AutoFightId > 0, nil, stageId)
        self:SetComponentActive("PanelStoryActive", false)
        self:SetComponentActive("PanelStoryUnactive", false)

        --赏金任务
        local IsBountyTaskPreFight, task = XDataCenter.BountyTaskManager.CheckBountyTaskPreFight(stageId)
        self:SetComponentActive("PanelBountyTaskInGrid", IsBountyTaskPreFight and task.Status ~= XDataCenter.BountyTaskManager.BountyTaskStatus.AcceptReward, nil, task)

        --战力警告
        self:UpdateFightControl()

        --关卡进度
        local clearEventId = stageCfg.ClearEventId or {}
        if not XTool.IsTableEmpty(clearEventId) then
            self:SetComponentActive("PanelProgress", true, nil, stageId)
        end
    end

    if not IsEgg then
        if self.ImageNorHideBg then
            self.ImageNorHideBg.gameObject:SetActive(false)
        end
        if self.Line then
            self.Line.gameObject:SetActive(false)
        end
    end
end

function XUiGridStage:UpdateFightControl()
    local stageId = self.Stage.StageId
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)

    local clearFightControl = true
    if stageInfo.Unlock and not stageInfo.Passed then
        if stageCfg.FightControlId > 0 then
            local data = XFubenConfigs.GetStageFightControl(stageCfg.FightControlId)
            local charlist = XMVCA.XCharacter:GetCharacterList()
            local maxAbility = 0
            for _, v in pairs(charlist) do
                if v.Ability and v.Ability > maxAbility then
                    maxAbility = v.Ability
                end
            end
            if maxAbility < data.RecommendFight then
                self:SetComponentActive("PanelStageFightControlHard", false)
                self:SetComponentActive("PanelStageFightControlEx", true, true)
                clearFightControl = false
            elseif maxAbility >= data.RecommendFight and maxAbility < data.ShowFight then
                self:SetComponentActive("PanelStageFightControlHard", true, true)
                self:SetComponentActive("PanelStageFightControlEx", false)
                clearFightControl = false
            end
        end
    end
    if clearFightControl then
        self:SetComponentActive("PanelStageFightControlEx", false)
        self:SetComponentActive("PanelStageFightControlHard", false)
    end
end

function XUiGridStage:SetStageTypePanelActive(isActive)
    if isActive then
        local stageId = self.Stage.StageId
        if XDataCenter.BfrtManager.CheckStageTypeIsBfrt(stageId) then
            self:SetComponentActive("PanelEchelon", true, nil, stageId)
            self:SetComponentActive("PanelStars", false)
        else
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            local isFalseStage = XDataCenter.FubenMainLineManager.CheckFalseStageByStageId(stageId)
            if self.IsOnZhouMu or isFalseStage then
                self:SetComponentActive("PanelStars", false)
            else
                self:SetComponentActive("PanelStars", true, nil, stageInfo.StarsMap, self.RootUi.StarColor, self.RootUi.StarDisColor)
            end
            self:SetComponentActive("PanelEchelon", false)
        end
    else
        self:SetComponentActive("PanelStars", false)
        self:SetComponentActive("PanelEchelon", false)
    end
end

function XUiGridStage:SetStoryStageSelect()
    local tmp_2 = self.Stage.StageType == XFubenConfigs.STAGETYPE_STORY
    or self.Stage.StageType == XFubenConfigs.STAGETYPE_STORYEGG
    and self.FubenType == XFubenConfigs.FUBENTYPE_NORMAL

    if not (tmp_2) then return end
    self:SetComponentActive("PanelStorySelected", true, nil, self.Stage.StageId, self.ChapterOrderId)
    self:SetComponentActive("PanelStoryActive", false)
    self:SetComponentActive("PanelStoryUnactive", false)
    --self:SetComponentActive("PanelEffect", false)
end

function XUiGridStage:SetStoryStageActive()
    local tmp_2 = self.Stage.StageType == XFubenConfigs.STAGETYPE_STORY
    or self.Stage.StageType == XFubenConfigs.STAGETYPE_STORYEGG
    and self.FubenType == XFubenConfigs.FUBENTYPE_NORMAL

    if not (tmp_2) then return end
    self:SetComponentActive("PanelStoryActive", true, nil, self.Stage.StageId, self.ChapterOrderId)
    self:SetComponentActive("PanelStoryUnactive", false)
    self:SetComponentActive("PanelStorySelected", false)
    --self:SetComponentActive("PanelEffect", false)
end

function XUiGridStage:SetStoryStageLock()
    local tmp_2 = self.Stage.StageType == XFubenConfigs.STAGETYPE_STORY
    or self.Stage.StageType == XFubenConfigs.STAGETYPE_STORYEGG
    and self.FubenType == XFubenConfigs.FUBENTYPE_NORMAL

    if not (tmp_2) then return end
    self:SetComponentActive("PanelStoryUnactive", true, nil, self.Stage.StageId, self.ChapterOrderId)
    self:SetComponentActive("PanelStoryActive", false)
    self:SetComponentActive("PanelStorySelected", false)
    self:SetComponentActive("PanelEffect", false)
end

function XUiGridStage:SetStageSelect()
    local tmp_1 = self.Stage.StageType == XFubenConfigs.STAGETYPE_COMMON
    local tmp_2 = self.Stage.StageType == XFubenConfigs.STAGETYPE_FIGHT
    or self.Stage.StageType == XFubenConfigs.STAGETYPE_FIGHTEGG
    and self.FubenType == XFubenConfigs.FUBENTYPE_NORMAL

    if not (tmp_1 or tmp_2) then return end

    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.Stage.StageId)
    if stageInfo.Type == XDataCenter.FubenManager.StageType.ActivtityBranch
    or stageInfo.Type == XDataCenter.FubenManager.StageType.ActivityBossSingle
    or stageInfo.Type == XDataCenter.FubenManager.StageType.RepeatChallenge
    then return end

    self:SetComponentActive("PanelStageSelected", true, nil, self.Stage.StageId, self.ChapterOrderId)
    self:SetComponentActive("PanelStageActive", false)
    self:SetComponentActive("PanelStageLock", false)
    --self:SetComponentActive("PanelEffect", false)
    self:SetStageTypePanelActive(true)
end

function XUiGridStage:SetStageActive()
    local tmp_1 = self.Stage.StageType == XFubenConfigs.STAGETYPE_COMMON
    local tmp_2 = self.Stage.StageType == XFubenConfigs.STAGETYPE_FIGHT
    or self.Stage.StageType == XFubenConfigs.STAGETYPE_FIGHTEGG
    and self.FubenType == XFubenConfigs.FUBENTYPE_NORMAL

    if not (tmp_1 or tmp_2) then return end

    self:SetComponentActive("PanelStageActive", true, nil, self.Stage.StageId, self.ChapterOrderId)
    self:SetComponentActive("PanelStageLock", false)
    self:SetComponentActive("PanelStageSelected", false)
    --self:SetComponentActive("PanelEffect", false)
    self:SetStageTypePanelActive(true)
end

function XUiGridStage:SetStageLock()
    local tmp_1 = self.Stage.StageType == XFubenConfigs.STAGETYPE_COMMON
    local tmp_2 = self.Stage.StageType == XFubenConfigs.STAGETYPE_FIGHT
    or self.Stage.StageType == XFubenConfigs.STAGETYPE_FIGHTEGG
    and self.FubenType == XFubenConfigs.FUBENTYPE_NORMAL

    if not (tmp_1 or tmp_2) then return end

    self:SetComponentActive("PanelStageLock", true, nil, self.Stage.StageId, self.ChapterOrderId)
    self:SetComponentActive("PanelStageActive", false)
    self:SetComponentActive("PanelStageSelected", false)
    self:SetComponentActive("PanelRewardTips", false)
    self:SetComponentActive("PanelEffect", false)
    self:SetStageTypePanelActive(false)
end

function XUiGridStage:CheckCurrentStageUnlock(stageCfg, stageInfo)
    -- 关卡是否解锁
    local isUnlock = stageInfo.Unlock
    -- 是否存在解锁事件Id
    local isUnlockEventId = true
    local unlockEventId = stageCfg.UnlockEventId or {}
    if not XTool.IsTableEmpty(unlockEventId) then
        isUnlockEventId = XDataCenter.FubenManager.GetUnlockHideStageById(stageCfg.StageId)
    end
    return isUnlock and isUnlockEventId
end

function XUiGridStage:CheckCurrentStageEffect(stageCfg, stageInfo, nextStageInfo)
    local isStagePass = stageInfo.Passed
    if XDataCenter.BfrtManager.CheckStageTypeIsBfrt(stageCfg.StageId) then
        isStagePass = XDataCenter.BfrtManager.IsGroupPassedByStageId(stageCfg.StageId)
    end
    -- 是否显示特效
    local isShowEffect = not (nextStageInfo and nextStageInfo.Unlock or isStagePass)
    -- 是否存在完成事件Id
    local isClearEventId = false
    local clearEventId = stageCfg.ClearEventId or {}
    if not XTool.IsTableEmpty(clearEventId) then
        isClearEventId = not XDataCenter.FubenMainLineManager.CheckStageClearEventIdPassed(stageCfg.StageId)
    end
    return isShowEffect or isClearEventId
end

function XUiGridStage:CheckCurrentStagePassed(stageCfg, stageInfo)
    -- 关卡是否通关
    local isPassed = stageInfo.Passed
    -- 是否存在完成事件Id
    local isClearEventId = true
    local clearEventId = stageCfg.ClearEventId or {}
    if not XTool.IsTableEmpty(clearEventId) then
        isClearEventId = XDataCenter.FubenMainLineManager.CheckStageClearEventIdPassed(stageCfg.StageId)
    end
    return isPassed and isClearEventId
end

return XUiGridStage