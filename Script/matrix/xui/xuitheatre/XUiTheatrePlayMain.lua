--######################## XUiTheatreNode ########################
local XUiTheatreNode = XClass(nil, "XUiTheatreNode")
local NodeRewardMaxShowCount = 1

function XUiTheatreNode:Ctor(ui, rootUi)
    XUiHelper.InitUiClass(self, ui)
    self.Node = nil
    self.RootUi = rootUi
    XUiHelper.RegisterClickEvent(self, self.BtnConfirm, self.OnBtnComfirmClicked)
end

-- node : XANode
function XUiTheatreNode:SetData(node)
    self.Node = node
    -- 类型图标
    self.RImgIcon:SetRawImage(node:GetNodeTypeIcon())
    -- 节点显示名字
    self.TxtName.text = node:GetNodeTypeName()
    local nodeType = node:GetNodeType()
    local isBattleType = node:GetIsBattle()
    self.TxtPowerNumber.gameObject:SetActiveEx(isBattleType)
    self.TxtTeamNumber.gameObject:SetActiveEx(isBattleType)
    self.PanelPower.gameObject:SetActiveEx(isBattleType)
    self.ImgWarning.gameObject:SetActiveEx(isBattleType)
    if isBattleType then
        local suggestPower = node:GetSuggestPower()
        -- 战力警告
        self.ImgWarning.gameObject:SetActiveEx(
            suggestPower > XDataCenter.TheatreManager.GetCurrentAdventureManager():GeRoleAveragePower())
        -- 更新推荐战力
        self.TxtPowerNumber.text = suggestPower
        -- 多队伍数量
        self.TxtTeamNumber.text = XUiHelper.GetText("TheatreTeamCountTip", node:GetTeamCount())
    end
    -- 节点详情
    local simpleDesc = node:GetNodeTypeDesc()
    self.TxtDetail.gameObject:SetActiveEx(simpleDesc ~= nil)
    if simpleDesc ~= nil then
        self.TxtDetail.text = simpleDesc
    end
    -- 是否已被禁用
    self.PanelDisable.gameObject:SetActiveEx(node:GetIsDisable())
    -- 底下图标显示显示
    local childCount = self.PanelReward.childCount
    for i = 0, childCount - 1 do
        self.PanelReward:GetChild(i).gameObject:SetActiveEx(false)
    end
    local showDatas = node:GetShowDatas()
    for i = 1, #showDatas do
        local showData = showDatas[i]
        local child = nil
        if i > NodeRewardMaxShowCount then break end
        if i > childCount then
            child = XUiHelper.Instantiate(self.GridReward.gameObject, self.PanelReward)
        else
            child = self.PanelReward:GetChild(i - 1)
        end
        child.gameObject:SetActiveEx(true)
        local uiObject = child:GetComponent("UiObject")
        -- 选择技能和升级特殊处理
        if showData.rewardType == XTheatreConfigs.AdventureRewardType.SelectSkill
            or showData.rewardType == XTheatreConfigs.AdventureRewardType.LevelUp then
            XUiGridCommon.New(self.RootUi, child):Refresh(1) -- hack ： 避免重复创建导致错误状态
            uiObject:GetObject("RImgIcon"):SetRawImage(showData.showIcon)
            XUiHelper.RegisterClickEvent(self, uiObject:GetObject("BtnClick"), function()
                self:OnRewardClicked(showData)
            end)
            if uiObject:GetObject("ImgQuality") then
                uiObject:GetObject("ImgQuality").gameObject:SetActiveEx(false)
            end
        else -- 好感度，装修点，奖励
            local itemId = nil
            local needCustomClick = false
            if showData.rewardType == XTheatreConfigs.AdventureRewardType.PowerFavor then
                itemId = XTheatreConfigs.TheatreFavorCoin
            elseif showData.rewardType == XTheatreConfigs.AdventureRewardType.Decoration then
                itemId = XTheatreConfigs.TheatreDecorationCoin
            elseif showData.rewardType == XTheatreConfigs.AdventureRewardType.RewardId then
                itemId = XEntityHelper.GetRewardItemId(showData.rewardId)
                needCustomClick = true
            end
            XUiGridCommon.New(self.RootUi, child):Refresh(itemId)
            if needCustomClick then
                XUiHelper.RegisterClickEvent(self, uiObject:GetObject("BtnClick"), function()
                    self:OnRewardClicked(showData)
                end)
            end
        end
    end
    return self
end

function XUiTheatreNode:OnRewardClicked(data)
    if data.rewardType == XTheatreConfigs.AdventureRewardType.RewardId then
        XUiManager.OpenUiTipRewardByRewardId(data.rewardId)
        return
    end
    local configNname
    if data.rewardType == XTheatreConfigs.AdventureRewardType.SelectSkill then
        configNname = "SelectSkillDetail"
    elseif data.rewardType == XTheatreConfigs.AdventureRewardType.LevelUp then
        configNname = "LevelUpDetail"
    end
    local name = XTheatreConfigs.GetRewardTypeName(data.rewardType, data.powerId)
    local icon = XTheatreConfigs.GetClientConfig(configNname, 1)
    local title = XTheatreConfigs.GetClientConfig(configNname, 2)
    local content = XTheatreConfigs.GetClientConfig(configNname, 3)
    if data.rewardType == XTheatreConfigs.AdventureRewardType.SelectSkill then
        icon = string.format(icon, XTheatreConfigs.GetClientConfig("SelectSkillDetailIcon", data.powerId))
        content = string.format(content, XTheatreConfigs.GetClientConfig("SelectSkillDetailDesc", data.powerId))
    end
    XLuaUiManager.Open("UiTheatreGroupTip", icon, name, title, content
        , data.rewardType == XTheatreConfigs.AdventureRewardType.SelectSkill)
end

function XUiTheatreNode:OnBtnComfirmClicked()
    self.Node:Trigger()
end

function XUiTheatreNode:PlaySelectAnim()
    self.AnimSelect:Play()
end

function XUiTheatreNode:StopSelectAnim()
    self.AnimSelect:Stop()
    self.AnimSelect:Evaluate()
end

--######################## XUiTheatrePlayMain ########################
local CORE_SKILL_COUNT = 4
local XUiTheatreSkillGrid = require("XUi/XUiTheatre/XUiTheatreSkillGrid")
local XUiTheatrePlayMain = XLuaUiManager.Register(XLuaUi, "UiTheatrePlayMain")

function XUiTheatrePlayMain:OnAwake()
    self.TheatreManager = XDataCenter.TheatreManager
    self.AdventureManager = self.TheatreManager.GetCurrentAdventureManager()
    self.CurrentChapter = self.AdventureManager:GetCurrentChapter()
    -- 注册资源面板
    XUiHelper.NewPanelActivityAsset(self.TheatreManager.GetAdventureAssetItemIds(), self.PanelAssetitems)
    self:RegisterUiEvents()
    -- 当前节点 XUiTheatreNode
    self.CurrentNodeItems = {}
    self.BuffGrids = {}
    self.TxtNone = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelDown/PanelKeepsake/TxtNone")
end

function XUiTheatrePlayMain:OnEnable()
    self.Super.OnEnable(self)
    self:Refresh()
    -- 处理下一个操作
    self.AdventureManager:ShowNextOperation(function()
        -- 特殊处理，有剧情节点时直接播放剧情到达下一步
        for _, node in ipairs(self.CurrentChapter:GetCurrentNodes()) do
            if node:GetNodeType() == XTheatreConfigs.NodeType.Movie 
                and not node:GetIsPlayed() 
                and self.CurrentChapter:GetIsReady() then
                XDataCenter.MovieManager.PlayMovie(node:GetStoryId())
                node:RequestEnd(function()
                    if XLuaUiManager.IsUiShow("UiTheatrePlayMain") and self.GameObject then
                        self:Refresh()
                    end
                end)
                break
            end
        end
    end)
end

function XUiTheatrePlayMain:OnDisable()
    XDataCenter.TheatreManager.SetSceneActive(false)
end

--######################## 私有方法 ########################

function XUiTheatrePlayMain:RegisterUiEvents()
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterHelpButton(self.BtnHelp, self.TheatreManager.GetHelpKey())
    XUiHelper.RegisterHelpButton(self.BtnReopenTip, self.TheatreManager.GetReopenHelpKey())
    XUiHelper.RegisterClickEvent(self, self.BtnTeam, self.OnBtnTeamClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnBuff, self.OnBtnBuffClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnKeepsake, self.OnBtnKeepsakeClicked)
end

function XUiTheatrePlayMain:OnBtnTeamClicked()
    XLuaUiManager.Open("UiTheatreMainMassage")
end

function XUiTheatrePlayMain:OnBtnBuffClicked()
    XLuaUiManager.Open("UiTheatreFieldGuide")
end

function XUiTheatrePlayMain:OnBtnKeepsakeClicked()
    local defaultTabIndex = XTheatreConfigs.FieldGuideIds.Item
    XLuaUiManager.Open("UiTheatreFieldGuide", nil, nil, defaultTabIndex)
end

function XUiTheatrePlayMain:RefreshCurrentNodes()
    self.GridStage.gameObject:SetActiveEx(false)
    local child
    local childCount = self.PanelChooseStage.transform.childCount
    for i = 0, childCount - 1 do
        child = self.PanelChooseStage.transform:GetChild(i)
        child.gameObject:SetActiveEx(false)
    end
    local button
    local buttons = {}
    local nodes = self.CurrentChapter:GetCurrentNodes()
    local node = nil
    self.CurrentNodeItems = {}
    for i = 1, #nodes do
        node = nodes[i]
        if i > childCount then
            child = XUiHelper.Instantiate(self.GridStage, self.PanelChooseStage.transform)
        else
            child = self.PanelChooseStage.transform:GetChild(i - 1)
        end
        child.gameObject:SetActiveEx(node:GetNodeType() ~= XTheatreConfigs.NodeType.Movie)
        button = child:GetComponent("XUiButton")
        button:SetDisable(node:GetIsDisable())
        table.insert(buttons, button)
        table.insert(self.CurrentNodeItems, XUiTheatreNode.New(child, self):SetData(node))
        -- 默认恢复已选中的状态
        if node:GetIsSelected() then
            button:SetButtonState(CS.UiButtonState.Select)
            self.CurrentNodeItems[i]:PlaySelectAnim()
        else
            self.CurrentNodeItems[i]:StopSelectAnim()
        end
    end
    self.PanelChooseStage:Init(buttons, function(index)
        self:OnNodeClicked(index)
    end)
end

function XUiTheatrePlayMain:RefreshCoreSkills()
    local coreSkills, additionalSkillCount = self.AdventureManager:GetCoreSkills()
    for i = 1, CORE_SKILL_COUNT do
        local grid = self.BuffGrids[i]
        if not grid then
            local gridObj = i == 1 and self.GridBuff or XUiHelper.Instantiate(self.GridBuff, self.PanelBuffList)
            grid = XUiTheatreSkillGrid.New(gridObj)
            self.BuffGrids[i] = grid
        end

        local data = self.AdventureManager:GetCoreSkillByPos(i)
        grid:SetData(data, nil, i)
        if not data then
            grid:SetLevel(1)    --未激活的技能显示等级1
        end
    end

    self.TxtAdditionSkillCount.text = additionalSkillCount
end

function XUiTheatrePlayMain:OnNodeClicked(index)
    if self.CurrentChapter:GetCurrentNodes()[index]:GetIsDisable() then
        return
    end
    for i, v in ipairs(self.CurrentNodeItems) do
        if index == i then
            self.CurrentNodeItems[i]:PlaySelectAnim()
        else
            self.CurrentNodeItems[i]:StopSelectAnim()
        end
    end
end

function XUiTheatrePlayMain:UpdateSceneUrl()
    XDataCenter.TheatreManager.UpdateSceneUrl(self)
    XScheduleManager.ScheduleOnce(function()
        XDataCenter.TheatreManager.ShowRoleModelCamera(self, "FarCameraPlayMain", "NearCameraPlayMain", true)
    end, 1)
end

function XUiTheatrePlayMain:Refresh()
    -- 标题
    self.TxtTitle.text = self.CurrentChapter:GetTitle()
    -- 选择难度的图标
    self.RImgDifficultyIcon:SetRawImage(
            self.AdventureManager:GetCurrentDifficulty():GetTitleIcon())
    -- 当前可重开的次数
    self.TxtReopenCount.text = self.AdventureManager:GetPlayableCount()
    -- 刷新当前节点
    self:RefreshCurrentNodes()
    -- 成员数量
    self.TxtRoleNumber.text = #self.AdventureManager:GetCurrentRoles(false)
    -- 成员等级
    self.TxtRoleLevel.text = self.AdventureManager:GetCurrentLevel()
    -- 成员平均战力
    self.TxtRolePower.text = self.AdventureManager:GeRoleAveragePower()
    -- 刷新信物
    local currentToken = self.AdventureManager:GetCurrentToken()
    self.GridToken.gameObject:SetActiveEx(currentToken ~= nil)
    self.TxtNone.gameObject:SetActiveEx(currentToken == nil)
    if currentToken then
        self.RImgTokenIcon:SetRawImage(currentToken:GetIcon())
        self.ImgTokenQuality:SetSprite(currentToken:GetItemQualityIcon())
    end
    -- 刷新核心技能
    self:RefreshCoreSkills()
    XDataCenter.TheatreManager.CheckUnlockOwnRole()
    -- 更新当前通过的节点数量
    if self.TxtCurrentPassNodeCount then
        self.TxtCurrentPassNodeCount.text = self.CurrentChapter:GetCurrentPassNodeCount()
    end
    --背景图片
    local chapterId = self.CurrentChapter:GetCurrentChapterId()
    if self.RImgBgA then
        local bgA = XTheatreConfigs.GetChapterBgA(chapterId)
        self.RImgBgA:SetRawImage(bgA)
    end
    if self.RImgBgB then
        local bgB = XTheatreConfigs.GetChapterBgB(chapterId)
        self.RImgBgB:SetRawImage(bgB)
    end
    self:UpdateSceneUrl()
    XDataCenter.TheatreManager.SetSceneActive(true)
end

return XUiTheatrePlayMain