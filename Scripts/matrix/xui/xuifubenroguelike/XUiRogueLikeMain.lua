local XUiRogueLikeMain = XLuaUiManager.Register(XLuaUi, "UiRogueLikeMain")
local XUiRogueLikeCharItem = require("XUi/XUiFubenRogueLike/XUiRogueLikeCharItem")
local XUiRogueLikeNode = require("XUi/XUiFubenRogueLike/XUiRogueLikeNode")

local XUiRogueLikeSetTeam = require("XUi/XUiFubenRogueLike/XUiRogueLikeSetTeam")

local NodeAnimTime = CS.XGame.ClientConfig:GetInt("RogueLikeNodeAnimTime")
local vectorOffset = CS.UnityEngine.Vector3(-2, 0, 0)
local lastSectionId

function XUiRogueLikeMain:OnAwake()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    -- self.TopicGroup.CallBack = function() self:OnTopicGroupClick() end
    self.BtnIllegalShop.CallBack = function() self:OnBtnIllegalShopClick() end

    if self.CharacterGroup then
        self.CharacterGroup.CallBack = function() self:OnTopicGroupClick() end
    end
    self:BindHelpBtn(self.BtnHelp, "RogueLike")
    
    self.BtnReset.CallBack = function () self:OnBtnResetClick() end
    
    self.BtnGroupLevel.CallBack = function () self:OnBtnGroupLevelClick() end

    self.BtnActionPoint.CallBack = function () self:OnBtnGroupLevelClick() end

    self.TopicList = {}
    self.CharacterList = {}
    self.HelpCHaracterList = {}

    self.BtnActivityTask.CallBack = function() self:OnBtnActivityTaskClick() end
    self.BtnBuff.CallBack = function() self:OnBtnBuffClick() end
    self.BtnHelpRole.CallBack = function() self:OnBtnHelpRoleClick() end

    self.TeamTips = XUiRogueLikeSetTeam.New(self.PanelTeamTips, self)

    self.RogueLikeNodeList = {}
    XEventManager.AddEventListener(XEventId.EVENT_ROGUELIKE_ACTIONPOINT_CHARACTER_CHANGED, self.OnActionPointAndCharacterChanged, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUELIKE_ASSISTROBOT_CHANGED, self.OnAssistRobotChanged, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUELIKE_REFRESH_ALLNODES, self.RefreshNodes, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUELIKE_BUFFIDS_CHANGES, self.OnBuffIdsChanged, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUELIKE_TEAMEFFECT_CHANGES, self.SetRogueLikeDayBuffs, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUELIKE_NODE_ADJUSTION, self.FocusOnNewest, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUELIKE_SECTIONTYPE_CHANGE, self.CheckTrialOpens, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUELIKE_SECTION_REFRESH, self.OnSectionRefresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROGUELIKE_TRIALPOINT_CHANGE, self.CheckClearanceOpen, self)
end

function XUiRogueLikeMain:OnDestroy()
    if self.TempNodeResource then
        self.TempNodeResource:Release()
    end
    if self.TempNodeBossResource then
        self.TempNodeBossResource:Release()
    end

    if self.DelayTimer then
        XScheduleManager.UnSchedule(self.DelayTimer)
        self.DelayTimer = nil
    end
    
    if self.TweenAnim then
        XScheduleManager.UnSchedule(self.TweenAnim)
        self.TweenAnim = nil
    end

    self:StopCounter()
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUELIKE_ACTIONPOINT_CHARACTER_CHANGED, self.OnActionPointAndCharacterChanged, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUELIKE_ASSISTROBOT_CHANGED, self.OnAssistRobotChanged, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUELIKE_REFRESH_ALLNODES, self.RefreshNodes, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUELIKE_BUFFIDS_CHANGES, self.OnBuffIdsChanged, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUELIKE_TEAMEFFECT_CHANGES, self.SetRogueLikeDayBuffs, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUELIKE_NODE_ADJUSTION, self.FocusOnNewest, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUELIKE_SECTIONTYPE_CHANGE, self.CheckTrialOpens, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUELIKE_SECTION_REFRESH, self.OnSectionRefresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROGUELIKE_TRIALPOINT_CHANGE, self.CheckClearanceOpen, self)
end

function XUiRogueLikeMain:OnStart()
    self.CurrentActivityId = XDataCenter.FubenRogueLikeManager.GetRogueLikeActivityId()
    self.ActivityTemplate = XFubenRogueLikeConfig.GetRougueLikeTemplateById(self.CurrentActivityId)
    local showBuffId = XFubenConfigs.GetLimitShowBuffId(self.ActivityTemplate.LimitBuffId)
    self.TeamTips:SetCharacterType(self.ActivityTemplate.CharacterLimitType, showBuffId)
    self.ActivityConfig = XFubenRogueLikeConfig.GetRogueLikeConfigById(self.CurrentActivityId)
    self.CurrentSecionInfo = XDataCenter.FubenRogueLikeManager.GetCurSectionInfo()
    if not self.CurrentSecionInfo then
        XLog.Error("CurrentSectionInfo is nil")
        return
    end
    self.CurrentSectionId = self.CurrentSecionInfo.Id
    self.GroupId = self.CurrentSecionInfo.Group
    lastSectionId = self.CurrentSectionId

    self.CurSectionTierType = XFubenRogueLikeConfig.GetTierSectionTierTypeById(self.CurrentSectionId)

    self:SetActivityInfo()
    self:SetRogueLikeDayBuffs()
    self:SetActivityAssistRobots()
    self:InitDragPanel()
    self:StartCounter()

    XRedPointManager.AddRedPointEvent(self.RedTask, self.RefreshRogueLikeTaskRedDot, self, { XRedPointConditions.Types.CONDITION_TASK_TYPE }, XDataCenter.TaskManager.TaskType.RogueLike)
end

function XUiRogueLikeMain:CheckTrialOpens()
    if self:IsSectionPurgatory() and XDataCenter.FubenRogueLikeManager.GetNeedShowTrialTips() and self.GameObject and self.GameObject.activeInHierarchy then
        self:OpenChildUi("UiRogueLikeTrialOpens", self)
    end  
end

function XUiRogueLikeMain:CheckClearanceOpen()
    if XDataCenter.FubenRogueLikeManager.GetNeedShowTrialPointView() and self.GameObject and self.GameObject.activeInHierarchy then
        self:OpenChildUi("UiRogueLikeClearance", self)
    end
end

function XUiRogueLikeMain:IsSectionPurgatory()
    return XDataCenter.FubenRogueLikeManager.IsSectionPurgatory()
end

function XUiRogueLikeMain:RefreshRogueLikeTaskRedDot(count)
    self.RedTask.gameObject:SetActive(count >= 0)
end

function XUiRogueLikeMain:OnEnable()
    self:CheckActivityEnd()
    self:CheckSectionIdChanged()
    self:CheckSetTeam()

    self:SetActivityInfo()
end

function XUiRogueLikeMain:OnDisable()
    self.PanelActionPointEffect.gameObject:SetActiveEx(false)
    for i = 1, #self.CharacterList do
        if self.CharacterList[i] then
            self.CharacterList[i]:StopFx()
        end
    end
end

function XUiRogueLikeMain:CheckSetTeam()
    XDataCenter.FubenRogueLikeManager.ShowRogueLikeTipsOnce()
end

function XUiRogueLikeMain:IsSectionChanged()
    if lastSectionId and self.CurrentSectionId and lastSectionId ~= self.CurrentSectionId then
        return true
    end
    return false
end

function XUiRogueLikeMain:CheckSectionIdChanged()
    
    if self:IsSectionChanged() then
        lastSectionId = self.CurrentSectionId
        self.PanelFullExplore.gameObject:SetActiveEx(true)
        self:PlayAnimation("PanelFullFinishEnable", function()
            self.PanelFullExplore.gameObject:SetActiveEx(false)
            self:RefreshNewChapter()
            XLuaUiManager.SetMask(false)
            self:PlayAnimation("BeiJingQieHuan", function()
                XLuaUiManager.SetMask(false)
            end, function()
                XLuaUiManager.SetMask(true)
            end)
            self:CheckTrialOpens()
        end,
        function()
            XLuaUiManager.SetMask(true)
        end)
    else
        if XDataCenter.FubenRogueLikeManager.IsFinalTier() then
            self.PanelFullExplore.gameObject:SetActiveEx(true)
            self:PlayAnimation("PanelFullFinishEnable", function()
                self.PanelFullExplore.gameObject:SetActiveEx(false)
                XLuaUiManager.SetMask(false)
            end,
            function()
                XLuaUiManager.SetMask(true)
            end)
            XDataCenter.FubenRogueLikeManager.ResetIsFinalTier()

            self:CheckClearanceOpen()
        end
        self:FocusOnNewest()
    end
end

function XUiRogueLikeMain:InitDragPanel()
    -- 初始化层级，需要考虑更新层级
    local sectionConfig = XFubenRogueLikeConfig.GetTierSectionConfigById(self.CurrentSecionInfo.Id)
    local prefabName = ""
    for i = 1, #sectionConfig.GroupId do
        if sectionConfig.GroupId[i] == self.CurrentSecionInfo.Group then
            prefabName = sectionConfig.GroupPrefab[i]
            break
        end
    end
    if prefabName == "" then
        XLog.Error("RogueLikeMain prefab not exist")
        return
    end

    self.CurrentPrefabName = prefabName
    self.DragPanel = self.PanelMap:LoadPrefab(self.CurrentPrefabName)
    self.PanelDragArea = self.DragPanel:GetComponentInChildren(typeof(CS.XDragArea))
    self.LayerLevel = self.PanelDragArea.gameObject.transform:Find("LayerLevel")

    -- 初始化节点，需要考虑更新节点信息
    self:InitNodes()
end

function XUiRogueLikeMain:InitNodes()
    self.AllNodeList, self.NodeIndexMap = XFubenRogueLikeConfig.GetNodesByGroupId(self.GroupId)
    self:GenerateChildNodeMap()

    if not self.TempNodeResource then
        self.TempNodeResource = CS.XResourceManager.Load(XFubenRogueLikeConfig.NORMAL_NODE)
    end
    if not self.TempNodeBossResource then
        self.TempNodeBossResource = CS.XResourceManager.Load(XFubenRogueLikeConfig.BOSS_NODE)
    end

    self.Curlen = 1
    self.Totallen = #self.AllNodeList
    self:LoadNodePerFrame(self.Curlen)

end

function XUiRogueLikeMain:LoadNodePerFrame(index)
    CS.XTool.WaitNativeCoroutine(CS.UnityEngine.WaitForEndOfFrame(), function()
        local endIndex = index + 5
        endIndex = (endIndex > self.Totallen) and self.Totallen or endIndex
        for i = index, endIndex do
            self:Loadfun(i)
        end
        if endIndex < self.Totallen then
            self:LoadNodePerFrame(endIndex + 1)
        end
    end)
end

function XUiRogueLikeMain:Loadfun(index)
    if not self.RogueLikeNodeList[index] then
        local nodeId = self.AllNodeList[index].NodeId
        local nodeConfig = XFubenRogueLikeConfig.GetNodeConfigteById(nodeId)
        local isBoss = nodeConfig.Param[1] == 1
        local tempNodeObj
        if isBoss then
            tempNodeObj = CS.UnityEngine.Object.Instantiate(self.TempNodeBossResource.Asset)
        else
            tempNodeObj = CS.UnityEngine.Object.Instantiate(self.TempNodeResource.Asset)
        end
        local tempParentTransform = self.LayerLevel.transform:Find(tostring(index))
        tempNodeObj.transform:SetParent(tempParentTransform, false)
        self.RogueLikeNodeList[index] = XUiRogueLikeNode.New(tempNodeObj, tempParentTransform, self)
    end
    self.RogueLikeNodeList[index]:UpdateNode(self.AllNodeList[index])
    if index == self.Totallen then
        -- self:CheckPossiblePath()
        self:FocusOnNewest()
    end
end

function XUiRogueLikeMain:CheckPossiblePath()
    self.PossibleNodes = {}
    self.UnpossibleNodes = {}

    for nodeId, _ in pairs(self.CurrentSecionInfo.FinishNode or {}) do
        local childNodes = self:GetChildNode(nodeId)

        local hasFinishChildNode = false

        local hasSelectChildNode = false
        local selectChildNodeId = 0

        for childNodeId, _ in pairs(childNodes or {}) do
            -- 是否有子节点是已完成的
            if self.CurrentSecionInfo.FinishNode[childNodeId] then
                hasFinishChildNode = true
            end
            -- 是否有子节点选中
            local selectNodeTemplate = XFubenRogueLikeConfig.GetNodeTemplateById(childNodeId)
            if self.CurrentSecionInfo.SelectNodeInfo[childNodeId] and
            (selectNodeTemplate.Type == XFubenRogueLikeConfig.XRLNodeType.Shop or
            selectNodeTemplate.Type == XFubenRogueLikeConfig.XRLNodeType.Event or 
            selectNodeTemplate.Type == XFubenRogueLikeConfig.XRLNodeType.Rest) then
                hasSelectChildNode = true
                selectChildNodeId = childNodeId
            end
        end

        -- 这个节点是最后完成的节点，需要查看有没有选中的子节点
        if not hasFinishChildNode then
            if hasSelectChildNode and selectChildNodeId > 0 then
                -- 有选中不可更改的子节点
                self:GetPossibleNodes(selectChildNodeId)
            else
                -- 没有选中不可更改的子节点
                self:GetPossibleNodes(nodeId)
            end
        end
        self.PossibleNodes[nodeId] = true
    end
    -- 选中了节点，应当使用这个子节点，
    for _, nodeInfo in pairs(self.AllNodeList or {}) do
        if not self.PossibleNodes[nodeInfo.NodeId] then
            self.UnpossibleNodes[nodeInfo.NodeId] = true
        end
    end

    -- 没有完成节点,return
    if not next(self.CurrentSecionInfo.FinishNode) then return end

    for index, nodeInfo in pairs(self.AllNodeList or {}) do
        self.RogueLikeNodeList[index].GameObject:SetActiveEx(self.PossibleNodes[nodeInfo.NodeId])
        if self.UnpossibleNodes[nodeInfo.NodeId] then
            self.RogueLikeNodeList[index]:HideAllLines()
        else
            local childNodes = self:GetChildNode(nodeInfo.NodeId)
            for childNodeId, _ in pairs(childNodes or {}) do
                if self.UnpossibleNodes[childNodeId] then
                    self.RogueLikeNodeList[index]:HideTargetLines(childNodeId)
                end
            end
        end
    end
end

function XUiRogueLikeMain:GetPossibleNodes(nodeId)
    if not nodeId then return end
    if not self.PossibleNodes[nodeId] then
        self.PossibleNodes[nodeId] = true

        local childNodes = self:GetChildNode(nodeId)
        for childNodeId, _ in pairs(childNodes or {}) do
            self:GetPossibleNodes(childNodeId)
        end
    end
end

-- 当前章节关键路线检查
function XUiRogueLikeMain:CheckAllLines()
    for i = 1, #self.AllNodeList do
        local curNode = self.AllNodeList[i]
        local childNodes = self:GetChildNode(curNode.NodeId)
        local curNodeIndex = curNode.Index
        for childNodeId, _ in pairs(childNodes or {}) do
            local childNodeIndex = self:GetNodeIndex(childNodeId)
            local cur2ChildLine = string.format("Line%d_%d", curNodeIndex, childNodeIndex)
            local nodeParent = self.LayerLevel.transform:Find(tostring(curNodeIndex))
            local needLine = nodeParent:Find(cur2ChildLine)
            local hasLine = needLine ~= nil
            local hasCanvasGroup = false
            if needLine then
                local lineCanvasGroup = needLine:GetComponent("CanvasGroup")
                hasCanvasGroup = lineCanvasGroup ~= nil
            end
            if (not hasLine) or (not hasCanvasGroup) then
                XLog.Error(string.format("层数：%d, 节点%d[%d] -> 节点%d[%d]  是否有连接线%s：%s,连接线是否有CanvasGroup组件：%s",
                curNode.TierIndex, curNode.NodeId, curNodeIndex, childNodeId, childNodeIndex, cur2ChildLine, tostring(hasLine), tostring(hasCanvasGroup)))
            end
        end
    end
end

function XUiRogueLikeMain:GetNodeIndex(nodeId)
    return self.NodeIndexMap[nodeId]
end

function XUiRogueLikeMain:GetChildNode(nodeId)
    return self.ChildNodeMap[nodeId]
end

function XUiRogueLikeMain:GenerateChildNodeMap()
    self.ChildNodeMap = {}
    for i = 1, #self.AllNodeList do
        local node = self.AllNodeList[i]
        for _, fatherNodeId in pairs(node.FatherNodes) do
            if not self.ChildNodeMap[fatherNodeId] then
                self.ChildNodeMap[fatherNodeId] = {}
            end
            self.ChildNodeMap[fatherNodeId][node.NodeId] = true
        end
    end
end

-- 当章节出现变化
function XUiRogueLikeMain:RefreshDragPanel()
    local sectionConfig = XFubenRogueLikeConfig.GetTierSectionConfigById(self.CurrentSecionInfo.Id)
    local prefabName = ""
    for i = 1, #sectionConfig.GroupId do
        if sectionConfig.GroupId[i] == self.CurrentSecionInfo.Group then
            prefabName = sectionConfig.GroupPrefab[i]
            break
        end
    end
    if prefabName == "" then
        XLog.Error("RogueLikeMain prefab not exist")
        return
    end
    if self.CurrentPrefabName and self.CurrentPrefabName ~= prefabName then
        self.DragPanel = self.PanelMap:LoadPrefab(prefabName)
        self.PanelDragArea = self.DragPanel:GetComponentInChildren(typeof(CS.XDragArea))
        self.LayerLevel = self.PanelDragArea.gameObject.transform:Find("LayerLevel")
    end
    self.CurrentPrefabName = prefabName
    self:InitNodes()
end

function XUiRogueLikeMain:RefreshNewChapter()
    self.RogueLikeNodeList = {}
    self:RefreshDragPanel()

    -- 主界面信息刷新
    self:SetActivityInfo()
    self:SetRogueLikeDayBuffs()
    self:SetActivityAssistRobots()
end

function XUiRogueLikeMain:OnSectionRefresh()
    
    if self:IsSectionChanged() then
        self:RefreshNewChapter()
    else
        self:FocusOnNewest()
    end
end

function XUiRogueLikeMain:RefreshNodes()
    local currentSectionInfo = XDataCenter.FubenRogueLikeManager.GetCurSectionInfo()
    local sectionId = currentSectionInfo.Id
    if sectionId ~= self.CurrentSectionId then
        self.CurrentSecionInfo = currentSectionInfo
        self.CurrentSectionId = self.CurrentSecionInfo.Id
        self.GroupId = self.CurrentSecionInfo.Group
        -- 章节刷新/放到开头
        self.CurSectionTierType = XFubenRogueLikeConfig.GetTierSectionTierTypeById(self.CurrentSectionId)
        
    else
        self.CurrentSecionInfo = currentSectionInfo
        self.CurrentSectionId = self.CurrentSecionInfo.Id
        self.GroupId = self.CurrentSecionInfo.Group
        -- 节点刷新
        if self.AllNodeList then
            for i = 1, #self.AllNodeList do
                if self.RogueLikeNodeList[i] then
                    self.RogueLikeNodeList[i]:UpdateNode(self.AllNodeList[i])
                end
            end
        end
        -- self:CheckPossiblePath()
        local index = XDataCenter.FubenRogueLikeManager.GetRogueLikeLevel()
        local maxTier = XDataCenter.FubenRogueLikeManager.GetMaxTier()
        self.TxtLevel.text = index
        self.TxtMaxTier.text = string.format("/%d", maxTier)
        self.Slider.value = index * 1.0 / maxTier
    end
end

function XUiRogueLikeMain:SetActivityInfo()
    if not self.GameObject.activeInHierarchy then return end
    self.TxtTitle.text = self.ActivityConfig.Name
    local index = XDataCenter.FubenRogueLikeManager.GetRogueLikeLevel()
    local maxTier = XDataCenter.FubenRogueLikeManager.GetMaxTier()
    self.TxtLevel.text = index
    self.TxtMaxTier.text = string.format("/%d", maxTier)
    self.Slider.value = index * 1.0 / maxTier
    
    if self:IsSectionPurgatory() then
        self.BtnIllegalShop.gameObject:SetActiveEx(false)
        self.BtnHelpRole.gameObject:SetActiveEx(false)
        self.BtnReset.gameObject:SetActiveEx(true)
        self.BtnGroupLevel.enabled = true
        self.BtnActionPoint.enabled = true
        self.TextLevelTitle1.gameObject:SetActiveEx(true)
        self.TextLevelTitle2.gameObject:SetActiveEx(false)
        local trialPoint = XDataCenter.FubenRogueLikeManager.GetRogueLikeTrialPoint()
        
        local startTweenPoint = XDataCenter.FubenRogueLikeManager.GetRogueLikeTrialPointShowByTween()

        if startTweenPoint ~= 0 then
            XDataCenter.FubenRogueLikeManager.SetRogueLikeTrialPointShowByTween(0)
            local time = CS.XGame.ClientConfig:GetFloat("RogueLikeTrialPointAnimaTime")
            local pointDifference = trialPoint - startTweenPoint
            local realTime = pointDifference / 30 
            if realTime < 1 then
                realTime = 1
            elseif realTime > time then
                realTime = time
            end
            self.TweenAnim = XUiHelper.Tween(realTime, function(f)
                if XTool.UObjIsNil(self.Transform) then
                    return
                end
                local allPoint = startTweenPoint + math.floor(f * pointDifference)
                self.TxtActionPoint.text = CS.XTextManager.GetText("RogueLikeTrialPoint", allPoint)
        
            end, function()
                if XTool.UObjIsNil(self.Transform) then
                    return
                end
                self.TxtActionPoint.text = CS.XTextManager.GetText("RogueLikeTrialPoint", trialPoint)
            end)
        else
            self.TxtActionPoint.text = CS.XTextManager.GetText("RogueLikeTrialPoint", trialPoint)
        end

        self.BtnReset:SetNameByGroup(0, 1 - XDataCenter.FubenRogueLikeManager.GetRogueLikeResetNum())
    else
        self.BtnIllegalShop.gameObject:SetActiveEx(true)
        self.BtnHelpRole.gameObject:SetActiveEx(true)
        self.BtnReset.gameObject:SetActiveEx(false)
        self.BtnGroupLevel.enabled = false
        self.BtnActionPoint.enabled = false
        self.TextLevelTitle1.gameObject:SetActiveEx(false)
        self.TextLevelTitle2.gameObject:SetActiveEx(true)

        local totalActionPoint = self.ActivityTemplate.ActionPoint
        local actionPoint = XDataCenter.FubenRogueLikeManager.GetRogueLikeActionPoint()
        self.TxtActionPoint.text = CS.XTextManager.GetText("RogueLikeCurretnActionPoint", tostring(actionPoint), tostring(totalActionPoint))
    end

    -- 锁定构造体
    local characterInfos = XDataCenter.FubenRogueLikeManager.GetCharacterInfos()
    for i = 1, XDataCenter.FubenRogueLikeManager.GetTeamMemberCount() do
        local charInfo = characterInfos[i]
        if not self.CharacterList[i] then
            local ui = CS.UnityEngine.Object.Instantiate(self.CharacterItem.gameObject)
            ui.gameObject:SetActiveEx(true)
            ui.transform:SetParent(self.CharacterContent, false)
            self.CharacterList[i] = XUiRogueLikeCharItem.New(ui, self)
        end
        self.CharacterList[i]:UpdateCharacterInfos(charInfo)
    end

    self:OnBuffIdsChanged()

end


function XUiRogueLikeMain:SetRogueLikeDayBuffs()

end

function XUiRogueLikeMain:OpenSetTeamView()
    local characters = XDataCenter.FubenRogueLikeManager.GetCharacterInfos()
    if #characters <= 0 then
        self.TeamTips:ShowSetTeamView()
        self:PlayAnimation("TeamTipsEnable", function()
            XLuaUiManager.SetMask(false)
        end, function()
            XLuaUiManager.SetMask(true)
        end)
        return true
    end
    return false
end

function XUiRogueLikeMain:OnTopicGroupClick()
    if self:OpenSetTeamView() then
        return
    end
    XLuaUiManager.Open("UiRogueLikeThemeTips")
end

function XUiRogueLikeMain:OnBtnResetClick()
    -- if self:OpenSetTeamView() then
    --     return
    -- end
    XLuaUiManager.Open("UiRogueLikeReset", CS.XTextManager.GetText("RogueLikePurgatoryResetTitle"), CS.XTextManager.GetText("RogueLikePurgatoryResetValue"))
end

function XUiRogueLikeMain:OnBtnGroupLevelClick()
    if self:IsSectionPurgatory() then
        XDataCenter.FubenRogueLikeManager.OpenTrialPoint(function()
            self:OpenChildUi("UiRogueLikeClearance", self)
        end)
    end
end

-- 获得的支援
function XUiRogueLikeMain:SetActivityAssistRobots()
    local assistRobots = XDataCenter.FubenRogueLikeManager.GetAssistRobots()
    self.BtnHelpRole:SetNameByGroup(0, #assistRobots)
    self.BtnHelpRole:SetNameByGroup(1, string.format("/%d", XDataCenter.FubenRogueLikeManager.GetMaxRobotCount()))
    self.HelpRoleRed.gameObject:SetActiveEx(XDataCenter.FubenRogueLikeManager.HasNewRobots())
end

function XUiRogueLikeMain:StartCounter()
    self:StopCounter()

    if not self.ActivityTemplate then return end
    local now = XTime.GetServerNowTimestamp()
    local endTime = XTime.ParseToTimestamp(self.ActivityTemplate.EndTimeStr)
    local weekEndTime = XDataCenter.FubenRogueLikeManager.GetWeekRefreshTime()
    if not endTime then return end

    local leftTimeDesc = CS.XTextManager.GetText("BabelTowerLeftTimeDesc")
    self.TxtTime.text = string.format("%s%s", leftTimeDesc, XUiHelper.GetTime(endTime - now, XUiHelper.TimeFormatType.ACTIVITY))
    self.TxtTaskTime.text = CS.XTextManager.GetText("RogueLikeTaskLeftTime", XUiHelper.GetTime(weekEndTime - now, XUiHelper.TimeFormatType.ACTIVITY))
    self.CountTimer = XScheduleManager.ScheduleForever(

        function()
            now = XTime.GetServerNowTimestamp()
            local rootIsNil = XTool.UObjIsNil(self.Transform)
            if not self.CountTimer or now > endTime or rootIsNil then
                self:StopCounter()
                self:CheckActivityEnd()
                return
            end
            self.TxtTime.text = string.format(
            "%s%s",
            leftTimeDesc,
            XUiHelper.GetTime(endTime - now, XUiHelper.TimeFormatType.ACTIVITY)
            )
            -- 周任务时间
            local weekTime = XDataCenter.FubenRogueLikeManager.GetWeekRefreshTime()
            if weekTime then
                self.TxtTaskTime.text = CS.XTextManager.GetText("RogueLikeTaskLeftTime", XUiHelper.GetTime(weekTime - now, XUiHelper.TimeFormatType.ACTIVITY))
            end
            -- 日更新时间
            local dayEndTime = XDataCenter.FubenRogueLikeManager.GetDayRefreshTime()
            if dayEndTime then
                self.TeamTips:UpdateResetTime(XUiHelper.GetTime(dayEndTime - now, XUiHelper.TimeFormatType.ACTIVITY))
            end
        end, 
        
    XScheduleManager.SECOND, 0)
end

function XUiRogueLikeMain:CheckActivityEnd()
    if not XDataCenter.FubenRogueLikeManager.IsInActivity() and XLuaUiManager.IsUiShow("UiRogueLikeMain") then
        XUiManager.TipMsg(CS.XTextManager.GetText("RougeLikeNotInActivityTime"))
        XLuaUiManager.RunMain()
    end
end

function XUiRogueLikeMain:StopCounter()
    if self.CountTimer ~= nil then
        XScheduleManager.UnSchedule(self.CountTimer)
        self.CountTimer = nil
    end
end

function XUiRogueLikeMain:OnBtnIllegalShopClick()
    if not XDataCenter.FubenRogueLikeManager.IsInActivity() then
        XUiManager.TipMsg(CS.XTextManager.GetText("RougeLikeNotInActivityTime"))
        return
    end
    if self:OpenSetTeamView() then
        return
    end
    XLuaUiManager.Open("UiRogueLikeIllegalShop")
end

function XUiRogueLikeMain:OnBtnActivityTaskClick()
    if not XDataCenter.FubenRogueLikeManager.IsInActivity() then
        XUiManager.TipMsg(CS.XTextManager.GetText("RougeLikeNotInActivityTime"))
        return
    end
    if self:OpenSetTeamView() then
        return
    end
    XLuaUiManager.Open("UiRogueLikeTask")
end

function XUiRogueLikeMain:OnBtnBuffClick()
    if not XDataCenter.FubenRogueLikeManager.IsInActivity() then
        XUiManager.TipMsg(CS.XTextManager.GetText("RougeLikeNotInActivityTime"))
        return
    end
    if #XDataCenter.FubenRogueLikeManager.GetMyBuffs() <= 0 then
        XUiManager.TipMsg(CS.XTextManager.GetText("RogueLikeNoneBuff"))
        return
    end

    XLuaUiManager.Open("UiRogueLikeMyBuff")
end

function XUiRogueLikeMain:OnBtnHelpRoleClick()
    local assistRobots = XDataCenter.FubenRogueLikeManager.GetAssistRobots()
    if #assistRobots <= 0 then
        XUiManager.TipMsg(CS.XTextManager.GetText("RogueLikeNoneSupport"))
        return
    end
    if self:OpenSetTeamView() then
        return
    end
    XLuaUiManager.Open("UiRogueLikeHelpRole")
end

function XUiRogueLikeMain:OnBtnBackClick()
    self:Close()
end

function XUiRogueLikeMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiRogueLikeMain:SelectNodeAnimation(nodeTransform, finishCallBack)

    XLuaUiManager.SetMask(true)
    self.PanelDragArea:FocusTarget(nodeTransform, 1, NodeAnimTime / 10, vectorOffset, function()
        XLuaUiManager.SetMask(false)
    end)
    XScheduleManager.ScheduleOnce(function()
        if finishCallBack then
            finishCallBack()
        end
    end, NodeAnimTime / 10 - 0.1)

end

function XUiRogueLikeMain:OnActionPointAndCharacterChanged(isAddActionPoint)
    self:SetActivityInfo()
    self:SetRogueLikeDayBuffs()

    if isAddActionPoint then
        if self.PanelActionPointEffect.gameObject.activeSelf then
            self.PanelActionPointEffect.gameObject:SetActiveEx(false)
        end
        self.PanelActionPointEffect.gameObject:SetActiveEx(true)
    end
end

function XUiRogueLikeMain:OnAssistRobotChanged()
    self:SetActivityAssistRobots()
    for i = 1, #self.AllNodeList do
        if self.RogueLikeNodeList[i] then
            self.RogueLikeNodeList[i]:UpdateNodeTab()
        end
    end
end

function XUiRogueLikeMain:OnBuffIdsChanged()
    self.BuffRed.gameObject:SetActiveEx(XDataCenter.FubenRogueLikeManager.HasNewBuffs() > 0)
    self.BtnBuff:SetNameByGroup(0, #XDataCenter.FubenRogueLikeManager.GetMyBuffs())
    self.TeamTips:UpdateBuffs()
end

-- 时机：节点完成，初始化完成
function XUiRogueLikeMain:FocusOnNewest()
    if self.PanelDragArea and self.AllNodeList and self.CurrentSecionInfo then
        if next(self.CurrentSecionInfo.FinishNode) then
            local focusNodeId
            for nodeId, _ in pairs(self.CurrentSecionInfo.FinishNode) do
                local childNodes = self:GetChildNode(nodeId)
                if childNodes then
                    local hasFinish = false
                    local hasSelect = false
                    for childNodeId, _ in pairs(childNodes or {}) do
                        if self.CurrentSecionInfo.FinishNode[childNodeId] then
                            hasFinish = true
                            break
                        end
                        if self.CurrentSecionInfo.SelectNodeInfo[childNodeId] then
                            hasSelect = true
                            focusNodeId = childNodeId
                            break
                        end
                    end
                    -- 存在完成的,下一个
                    -- 存在选中的,居中选中节点
                    -- 都不存在,默认第一个子节点
            
                    if not hasFinish and not hasSelect then
                        local key = next(childNodes)
                        if key then
                            focusNodeId = key
                        end
                    end
                end
            end
    
            if focusNodeId then
                for i = 1, #self.AllNodeList do
                    if self.AllNodeList[i].NodeId == focusNodeId and self.RogueLikeNodeList[i] then
                        self:FocusTargetDelay(self.RogueLikeNodeList[i].Transform)
                        break
                    end
                end
            end
        else
            -- 没有完成的节点
            for i = 1, #self.AllNodeList do
                local nodeInfo = self.AllNodeList[i]
                if #nodeInfo.FatherNodes <= 0 and self.RogueLikeNodeList[i] then
                    
                    self:FocusTargetDelay(self.RogueLikeNodeList[i].Transform)
                    break
                end
            end
        end
    end
end

function XUiRogueLikeMain:FocusTargetDelay(transform)
    self.DelayTimer = XScheduleManager.ScheduleOnce(function()
        self.PanelDragArea:FocusTarget(transform, 1, 1, CS.UnityEngine.Vector3.zero, function()
            XScheduleManager.UnSchedule(self.DelayTimer)
        end)
    end, 50)
end