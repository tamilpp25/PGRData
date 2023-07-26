local CsXTextManager = CS.XTextManager

--######################## XUiReformList ########################
local XUiReformList = XLuaUiManager.Register(XLuaUi, "UiReformList")

function XUiReformList:OnAwake()
    -- XReformBaseStage
    self.BaseStage = nil
    -- XReformEvolvableStage
    self.CurrentEvolvableStage = nil
    self.CurrentElementBtnIndex = nil
    -- 当前改造等级选中的index
    self.CurEvolvableLevelBtnGroupIndex = nil
    self.ElementBtnGroupDic = {
        [XReformConfigs.EvolvableGroupType.Enemy] = self.BtnEnemy,
        -- [XReformConfigs.EvolvableGroupType.Member] = self.BtnChar,
        [XReformConfigs.EvolvableGroupType.Environment] = self.BtnScene,
        -- [XReformConfigs.EvolvableGroupType.Buff] = self.BtnBuff,
        [XReformConfigs.EvolvableGroupType.EnemyBuff] = self.BtnEnemyBuff,
        [XReformConfigs.EvolvableGroupType.StageTime] = self.BtnTimer,
    }
    self:RegisterUiEvents()
    -- 子面板信息配置
    self.ChildPanelInfoDic = {
        [XReformConfigs.EvolvableGroupType.Enemy] = {
            uiParent = self.PanelReformEnemy,
            assetPath = XUiConfigs.GetComponentUrl("UiReformEnemyPanel"),
            proxy = require("XUi/XUiReform/XUiReformEnemyPanel"),
            proxyArgs = { "BaseStage", "CurrentEvolvableStage"},
        },
        [XReformConfigs.EvolvableGroupType.Member] = {
            uiParent = self.PanelReformChar,
            assetPath = XUiConfigs.GetComponentUrl("UiReformMemberPanel"),
            proxy = require("XUi/XUiReform/XUiReformMemberPanel"),
            proxyArgs = { "BaseStage", "CurrentEvolvableStage" },
        },
        [XReformConfigs.EvolvableGroupType.Buff] = {
            uiParent = self.PanelReformBuff,
            assetPath = XUiConfigs.GetComponentUrl("UiReformBuffPanel"),
            proxy = require("XUi/XUiReform/XUiReformBuffPanel"),
            proxyArgs = { "BaseStage", "CurrentEvolvableStage" },
        },
        [XReformConfigs.EvolvableGroupType.Environment] = {
            uiParent = self.PanelReformScene,
            assetPath = XUiConfigs.GetComponentUrl("UiReformEnvironmentPanel"),
            proxy = require("XUi/XUiReform/XUiReformEnvironmentPanel"),
            proxyArgs = { "BaseStage", "CurrentEvolvableStage" },
        },
        [XReformConfigs.EvolvableGroupType.EnemyBuff] = {
            uiParent = self.PanelReformEnemyBuff,
            assetPath = XUiConfigs.GetComponentUrl("UiReformEnemyBuffPanel"),
            proxy = require("XUi/XUiReform/XUiReformEnemyBuffPanel"),
            proxyArgs = { "BaseStage", "CurrentEvolvableStage" },
        },
        [XReformConfigs.EvolvableGroupType.StageTime] = {
            uiParent = self.PanelReformTimer,
            assetPath = XUiConfigs.GetComponentUrl("UiReformTimePanel"),
            proxy = require("XUi/XUiReform/XUiReformTimePanel"),
            proxyArgs = { "BaseStage", "CurrentEvolvableStage" },
        },
    }
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem
        , XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    -- 自动关闭
    local endTime = XDataCenter.ReformActivityManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XDataCenter.ReformActivityManager.HandleActivityEndTime()
        end
    end)
end

-- baseStage : XReformBaseStage
function XUiReformList:OnStart(baseStage)
    self.BaseStage = baseStage
    if baseStage:GetMaxDiffCount() > 1 and baseStage:GetCurrentDifficulty() == 1 then
        baseStage:SetCurrentDiffIndex(2)
        XDataCenter.ReformActivityManager.ChageStageDiffRequest(baseStage:GetId(), 2)
    end
    -- 处理顶部细节
    local tabBtn = nil
    local isOpen = nil
    local maxDiffCount = baseStage:GetMaxDiffCount()
    for i = 1, 3 do
        tabBtn = self["Tab" .. i]
        tabBtn.gameObject:SetActiveEx(i < maxDiffCount)
        if i < maxDiffCount then
            isOpen = self.BaseStage:GetDifficultyIsOpen(i + 1)
            self["Tab" .. i .. "RedPoint"].gameObject:SetActiveEx(XDataCenter.ReformActivityManager.CheckEvolvableDiffIsShowRedDot(self.BaseStage:GetId(), i + 1))
            tabBtn:SetNameByGroup(0, CsXTextManager.GetText("ReformEvolvableStageName" .. i))
            tabBtn:SetNameByGroup(2, "0" .. i)
            tabBtn:SetButtonState(isOpen and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
            if not isOpen then
                tabBtn.transform:Find("Disable/TextCost"):GetComponent("Text").text = baseStage:GetEvolvableStageByDiffIndex(i):GetName()
                tabBtn.transform:Find("Disable/TextCost/TxtCost"):GetComponent("Text").text = baseStage:GetEvolvableStageByDiffIndex(i + 1):GetUnlockScore()
            end
        end
    end
    -- 默认打开最后通关的难度
    local currentEvolvableLevelIndex = math.max(baseStage:GetCurrentDifficulty() - 1, 1)
    self.EvolvableLevelBtnGroup:SelectIndex(currentEvolvableLevelIndex)
    self.CurEvolvableLevelBtnGroupIndex = currentEvolvableLevelIndex
    -- 初始化改造相关按钮
    local btnResult = {}
    for groupType, btn in pairs(self.ElementBtnGroupDic) do
        table.insert(btnResult, {
            groupType = groupType,
            btn = btn,
        })
    end
    table.sort(btnResult, function(dataA, dataB)
        return XReformConfigs.GetGroupTypeSortWeight(dataA.groupType) < XReformConfigs.GetGroupTypeSortWeight(dataB.groupType)
    end)
    for index, data in pairs(btnResult) do
        data.btn.gameObject:SetActiveEx(self.CurrentEvolvableStage:GetEvolvableGroupByType(data.groupType) ~= nil)
        data.btn.transform:SetSiblingIndex(index)
    end
    -- 更新改造等级下的积分
    self:RefreshEvolvableLevelScores()
    -- 更新挑战积分
    self:RefreshChallengeScore(false)
    self.BtnSaveReform:SetNameByGroup(0, CsXTextManager.GetText("ReformListSaveBtnName"))
end

function XUiReformList:OnEnable()
    XUiReformList.Super.OnEnable(self)
    self:RegisterEventListeners()
end

function XUiReformList:OnDisable()
    XUiReformList.Super.OnDisable(self)
    self:ClearEventListeners()
end

--######################## 私有方法 ########################

function XUiReformList:RefreshEvolvableLevelScores()
    local evolvableStages = self.BaseStage:GetEvolvableStages()
    local tabBtn = nil
    for index, evolvableStage in ipairs(evolvableStages) do
        tabBtn = self["Tab" .. index]
        tabBtn.transform:Find("Normal/TextCost/TxtCost"):GetComponent("Text").text = evolvableStage:GetMaxScore()
        tabBtn.transform:Find("Press/TextCost/TxtCost"):GetComponent("Text").text = evolvableStage:GetMaxScore()
        tabBtn.transform:Find("Select/TextCost/TxtCost"):GetComponent("Text").text = evolvableStage:GetMaxScore()
        -- tabBtn.transform:Find("Disable/TextCost/TxtCost"):GetComponent("Text").text = evolvableStage:GetMaxScore()
    end
end

function XUiReformList:RefreshChallengeScore(showEffect, enemyGroupIndex)
    if enemyGroupIndex == nil then enemyGroupIndex = 1 end
    if showEffect == nil then showEffect = true end
    local scoreContent
    local currentScore = self.CurrentEvolvableStage:GetEvolvableGroupCurrentScore(self.CurrentElementBtnIndex)
    if self.CurrentElementBtnIndex == XReformConfigs.EvolvableGroupType.Member
        or self.CurrentElementBtnIndex == XReformConfigs.EvolvableGroupType.Buff then
        scoreContent = string.format( "<color=#BC0F27>%s</color>", currentScore)
    else
        local maxScore = self.CurrentEvolvableStage:GetEvolvableGroupMaxScore(self.CurrentElementBtnIndex)
        scoreContent = string.format( "<color=#0E70BD>%s</color> / %s", currentScore, maxScore)
        if currentScore >= maxScore then
            scoreContent = scoreContent .. "(max)"
        end
    end
    self.TxtScore.text = scoreContent
    self.EffectScore.gameObject:SetActiveEx(false)
    if showEffect then
        self.EffectScore.gameObject:SetActiveEx(true)
    end
end

function XUiReformList:RegisterEventListeners()
    XEventManager.AddEventListener(XEventId.EVENT_REFORM_EVOLVABLE_GROUP_UPDATE, self.OnReformEvolvableGroupUpdate, self)
end

function XUiReformList:ClearEventListeners()
    XEventManager.RemoveEventListener(XEventId.EVENT_REFORM_EVOLVABLE_GROUP_UPDATE, self.OnReformEvolvableGroupUpdate, self)
end

function XUiReformList:RegisterUiEvents()
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnSaveReform.CallBack = function() self:OnBtnSaveReformClicked() end
    self.BtnScoreIcon.CallBack = function() self:OnBtnScoreIconClicked() end
    -- 初始化改造等级按钮组
    self.EvolvableLevelBtnGroup:Init({
        [1] = self.Tab1,
        [2] = self.Tab2,
        [3] = self.Tab3,
    }, function(tabIndex) self:OnEvolvableLevelBtnGroupClicked(tabIndex) end)
    -- 初始化改造元素按钮组
    self.EvolvableElementBtnGroup:Init(self.ElementBtnGroupDic, function(tabIndex) self:OnEvolvableElementBtnGroupClicked(tabIndex) end)
    self.BtnPreview.CallBack = function() self:OnBtnPreviewClicked() end
    self:BindHelpBtn(self.BtnHelp, XDataCenter.ReformActivityManager.GetHelpName())
end

function XUiReformList:OnBtnPreviewClicked()
    XLuaUiManager.Open("UiReformPreview", self.CurrentEvolvableStage)
end

function XUiReformList:OnBtnScoreIconClicked()
    XLuaUiManager.Open("UiTip", XDataCenter.ReformActivityManager.GetScoreItemId())
end

-- 改造等级难度点击
function XUiReformList:OnEvolvableLevelBtnGroupClicked(index)
    local selectDiffIndex
    if self.BaseStage:GetMaxDiffCount() <= 1 then
        selectDiffIndex = index
    else
        selectDiffIndex = index + 1
    end
    if not self.BaseStage:GetDifficultyIsOpen(selectDiffIndex) then
        local evolvableStage = self.BaseStage:GetEvolvableStageByDiffIndex(selectDiffIndex)
        XUiManager.TipError(CsXTextManager.GetText("ReformEvolvableStageUnlockTip", evolvableStage:GetUnlockScore()))
        self.EvolvableLevelBtnGroup:SelectIndex(self.CurEvolvableLevelBtnGroupIndex)
        return
    end
    XDataCenter.ReformActivityManager.SetEvolableStageRedDotHistory(self.BaseStage:GetId(), selectDiffIndex)
    self["Tab" .. index .. "RedPoint"].gameObject:SetActiveEx(false)
    if self.CurEvolvableLevelBtnGroupIndex == index then
        return
    end
    self.CurEvolvableLevelBtnGroupIndex = index
    self.CurrentEvolvableStage = self.BaseStage:GetEvolvableStageByDiffIndex(selectDiffIndex)
    -- 隐藏当前改造关卡没有的改造元素页签按钮
    local isExist = false
    for groupType, btnGo in pairs(self.ElementBtnGroupDic) do
        isExist = self.CurrentEvolvableStage:GetEvolvableGroupByType(groupType) ~= nil
        btnGo.gameObject:SetActiveEx(isExist)
    end
    self.EvolvableElementBtnGroup:SelectIndex(self.CurrentEvolvableStage:GetDefaultFirstGroupType())
end

function XUiReformList:OnEvolvableElementBtnGroupClicked(index)
    self:PlayAnimation("QieHuan")
    self.CurrentElementBtnIndex = index
    local childPanelData = self.ChildPanelInfoDic[index]
    if childPanelData == nil then return end
    -- 隐藏其他的子面板
    for key, data in pairs(self.ChildPanelInfoDic) do
        data.uiParent.gameObject:SetActiveEx(key == index)
    end
    -- 加载子面板实体
    local instanceGo = childPanelData.instanceGo
    if instanceGo == nil then
        instanceGo = childPanelData.uiParent:LoadPrefab(childPanelData.assetPath)
        childPanelData.instanceGo = instanceGo
    end
    -- 加载子面板代理
    local instanceProxy = childPanelData.instanceProxy
    if instanceProxy == nil then
        instanceProxy = childPanelData.proxy.New(instanceGo)
        childPanelData.instanceProxy = instanceProxy
        if CheckClassSuper(instanceProxy, XSignalData) then
            instanceProxy:ConnectSignal("RefreshChallengeScore", self, self.RefreshChallengeScore)
        end
    end
    -- 设置子面板代理参数
    local proxyArgs = {}
    if childPanelData.proxyArgs then
        for _, argName in ipairs(childPanelData.proxyArgs) do
            if type(argName) == "string" then
                proxyArgs[#proxyArgs + 1] = self[argName]
            else
                proxyArgs[#proxyArgs + 1] = argName
            end
        end
    end
    instanceProxy:SetData(table.unpack(proxyArgs))
    local groupIndex
    if index == XReformConfigs.EvolvableGroupType.Enemy 
        or index == XReformConfigs.EvolvableGroupType.EnemyBuff then
        groupIndex = instanceProxy:GetCurrentGroupIndex()
    end
    self:RefreshChallengeScore(nil, groupIndex)
end

function XUiReformList:OnBtnSaveReformClicked()
    self:Close()
    XUiManager.TipMsg(CsXTextManager.GetText("ReformSaveEvolableStageTip", self.BaseStage:GetName(), self.CurrentEvolvableStage:GetName()))    
    -- XDataCenter.ReformActivityManager.ChageStageDiffRequest(self.BaseStage:GetId(), self.CurEvolvableLevelBtnGroupIndex + 1, function()
    --     self.BaseStage:SetCurrentDiffIndex(self.CurEvolvableLevelBtnGroupIndex + 1)
    --     self:Close()
    --     XUiManager.TipMsg(CsXTextManager.GetText("ReformSaveEvolableStageTip", self.BaseStage:GetName(), self.CurrentEvolvableStage:GetName()))
    -- end)
end

-- evolvableGroupType : XReformConfigs.EvolvableGroupType
function XUiReformList:OnReformEvolvableGroupUpdate(evolvableGroupType, data)
    local groupIndex
    if self.ChildPanelInfoDic[evolvableGroupType].instanceProxy then
        self.ChildPanelInfoDic[evolvableGroupType].instanceProxy:RefreshEvolvableData(data)
        if evolvableGroupType == XReformConfigs.EvolvableGroupType.Enemy 
            or evolvableGroupType == XReformConfigs.EvolvableGroupType.EnemyBuff then
            groupIndex = self.ChildPanelInfoDic[evolvableGroupType].instanceProxy:GetCurrentGroupIndex()
        end
    end
    self:RefreshChallengeScore(nil, groupIndex)
end

return XUiReformList
