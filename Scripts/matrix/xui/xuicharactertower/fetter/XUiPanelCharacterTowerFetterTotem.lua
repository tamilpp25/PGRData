---@class XUiPanelCharacterTowerFetterTotem
local XUiPanelCharacterTowerFetterTotem = XClass(nil, "XUiPanelCharacterTowerFetterTotem")

function XUiPanelCharacterTowerFetterTotem:Ctor(ui, rootUi, relationId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    
    self.RelationId = relationId
    ---@type XCharacterTowerRelation
    self.RelationViewModel = XDataCenter.CharacterTowerManager.GetCharacterTowerRelation(relationId)
    self:InitPanelRoute()
    self.JihuoEffect.gameObject:SetActiveEx(false)
    self.IsPlayAnimation = false
    self.RouteObject = nil
    self.LineEffectAnimationInfo = nil
end

function XUiPanelCharacterTowerFetterTotem:InitPanelRoute()
    self.GridLineEffectList = {}
    self.GridRouteList = {}
    self.GridStageList = {}
    
    self.FightEventIds = self.RelationViewModel:GetRelationFightEventIds()
    for index, _ in ipairs(self.FightEventIds) do
        local stage = XUiHelper.TryGetComponent(self.PanelRoute, string.format("Stage%s", index))
        self.GridStageList[index] = stage
    end
end

function XUiPanelCharacterTowerFetterTotem:Refresh()
    if not self.GameObject or not self.GameObject:Exist() then
        return
    end
    self.IsPlayAnimation = false
    self.JihuoEffect.gameObject:SetActiveEx(false)
    for index, eventId in pairs(self.FightEventIds) do
        local stage = self.GridStageList[index]
        local fetterActive = self.RelationViewModel:CheckRelationActive(eventId, index)
        if fetterActive then
            -- 光点
            self:CreateRoute(stage, index)
            if index > 1 then
                -- 特效
                self:CreateLineEffect(stage, index)
            end
        end
    end
end

function XUiPanelCharacterTowerFetterTotem:RefreshAndPlayAnimation(storyId, eventId)
    self.IsPlayAnimation = true
    local playEffectTime = XUiHelper.GetClientConfig("CharacterTowerFetterTotemPlayEffectTime", XUiHelper.ClientConfigType.Float)
    playEffectTime = getRoundingValue(playEffectTime, 1)
    local pathAnimTime = XUiHelper.GetClientConfig("CharacterTowerFetterTotemPathAnimTime", XUiHelper.ClientConfigType.Float)
    local playLineEffectAnimation = asynTask(self.PlayLineEffectAnimation, self)
    RunAsyn(function()
        -- 播放特效
        self.JihuoEffect.gameObject:SetActiveEx(false)
        self.JihuoEffect.gameObject:SetActiveEx(true)
        asynWaitSecond(playEffectTime)
        self.RouteObject = nil
        self.LineEffectAnimationInfo = nil
        -- 播放路径特效
        self:CreateNextRouteLineAndEffect(storyId, eventId)
        playLineEffectAnimation(pathAnimTime)
        if self.RouteObject then
            self.RouteObject.gameObject:SetActiveEx(true)
        end
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_CHARACTER_TOWER_CHECK_FETTER)
    end)
end

function XUiPanelCharacterTowerFetterTotem:PlayLineEffectAnimation(pathAnimTime, cb)
    self:StopLineEffectTimer()
    if not self.LineEffectAnimationInfo then
        if cb then
            cb()
        end
        return
    end
    local lineEffect, target = table.unpack(self.LineEffectAnimationInfo)
    self.LineEffectTimer = XUiHelper.DoWorldMove(lineEffect, target, pathAnimTime, XUiHelper.EaseType.Linear, cb)
end

function XUiPanelCharacterTowerFetterTotem:StopLineEffectTimer()
    if self.LineEffectTimer then
        XScheduleManager.UnSchedule(self.LineEffectTimer)
        self.LineEffectTimer = nil
    end
end

function XUiPanelCharacterTowerFetterTotem:CreateNextRouteLineAndEffect(storyId, eventId)
    local curIndex = -1
    for index, id in pairs(self.FightEventIds) do
        local tempStoryId = self.RelationViewModel:GetRelationStoryIdByIndex(index)
        if id == eventId and tempStoryId == storyId then
            curIndex = index
            break
        end
    end
    
    if curIndex < 0 then
        return
    end

    local fetterActive = self.RelationViewModel:CheckRelationActive(eventId, curIndex)
    local stage = self.GridStageList[curIndex]
    if fetterActive then
        -- 光点
        self:CreateRoute(stage, curIndex)
        if curIndex > 1 then
            -- 特效
            self:CreateLineEffect(stage, curIndex)
        end
    end
end

function XUiPanelCharacterTowerFetterTotem:CreateRoute(stage, index)
    -- 光点
    local goRoute = self.GridRouteList[index]
    if not goRoute then
        goRoute = XUiHelper.Instantiate(self.GridFetterStage, stage)
        self.GridRouteList[index] = goRoute
    end
    if self.IsPlayAnimation then
        self.RouteObject = goRoute
    else
        goRoute.gameObject:SetActiveEx(true)
    end
end

function XUiPanelCharacterTowerFetterTotem:CreateLineEffect(stage, index)
    -- 线特效
    local preStage = self.GridStageList[index - 1]
    local lineParent = self.GridLineEffectList[index]
    if not lineParent then
        lineParent = XUiHelper.Instantiate(self.LineEffect, self.PanelRoute)
        lineParent.gameObject:SetActiveEx(true)
        self.GridLineEffectList[index] = lineParent
    end
    local lineEffect = lineParent:LoadUiEffect(XFubenCharacterTowerConfigs.GetCharacterTowerConfigValueByKey("FxUiCharacterTowerFetterLine"))
    local lineEffectUi = {}
    XTool.InitUiObjectByUi(lineEffectUi, lineEffect)
    if self.IsPlayAnimation then
        lineEffectUi.Start.position = preStage.transform.position
        lineEffectUi.Target.position = preStage.transform.position
        self.LineEffectAnimationInfo = { lineEffectUi.Target, stage.transform.position }
    else
        lineEffectUi.Start.position = preStage.transform.position
        lineEffectUi.Target.position = stage.transform.position
    end
end

function XUiPanelCharacterTowerFetterTotem:OnDisable()
    self:StopLineEffectTimer()
end

return XUiPanelCharacterTowerFetterTotem