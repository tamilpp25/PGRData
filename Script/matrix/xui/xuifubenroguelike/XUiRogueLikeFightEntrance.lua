local XUiRogueLikeFightEntrance = XClass(nil, "XUiRogueLikeFightEntrance")
local STAR_LENGTH = 3

function XUiRogueLikeFightEntrance:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
    self.BtnFightNormal.CallBack = function() self:OnBtnFightNormalClick() end
    self.BtnFightHard.CallBack = function() self:OnBtnFightHardClick() end
    self.GridList = {}
    self.StarList = {}
    self.StarGridList = {}
    for i = 1, STAR_LENGTH do
        self.StarList[i] = self[string.format("TxtStarActive%d", i)]
        self.StarGridList[i] = self[string.format("GridStageStar%d", i)]
    end
end

function XUiRogueLikeFightEntrance:UpdateByNode(node, eventNode)
    self.Node = node
    self.EventNode = (eventNode == nil) and node or eventNode
    self.NodeTemplate = XFubenRogueLikeConfig.GetNodeTemplateById(self.EventNode.Id)
    self.NodeConfig = XFubenRogueLikeConfig.GetNodeConfigteById(self.EventNode.Id)

    self.NormalStageId = self.NodeTemplate.Param[1]
    self.HardStageId = self.NodeTemplate.Param[2]

    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.NormalStageId)

    self.TxtName.text = self.NodeConfig.Name
    self.RImgIcon:SetRawImage(self.NodeConfig.Icon)
    self.TxtTarget.text = self.NodeConfig.Description

    self.RImgFightCost:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XDataCenter.ItemManager.ItemId.ActionPoint))
    local requireNum = XDataCenter.FubenManager.GetRequireActionPoint(self.NormalStageId)
    local ownNum = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.ActionPoint)
    local color = (requireNum > ownNum) and "#FF0000" or "#0E70BD"
    self.TxtOwn.text = string.format("%d/", ownNum)
    self.TxtConsumeAmount.text = string.format("<color=%s>%d</color>", color, requireNum)

    self.BtnFightHard.gameObject:SetActiveEx(self.HardStageId ~= nil and self.HardStageId > 0)

    self:UpdateNodeReward(stageCfg)
    for i = 1, STAR_LENGTH do
        local starDesc = (stageCfg.StarDesc[i] == nil) and "" or stageCfg.StarDesc[i]
        self.StarList[i].text = starDesc
        self.StarGridList[i].gameObject:SetActiveEx(starDesc ~= "")
    end
end

function XUiRogueLikeFightEntrance:UpdateNodeReward(stageCfg)
    local rewardId = 0
    local controlCfg = XDataCenter.FubenManager.GetStageLevelControl(stageCfg.NormalStageId)
    if controlCfg and controlCfg.FinishRewardShow > 0 then
        rewardId = controlCfg.FinishRewardShow
    elseif stageCfg.FinishRewardShow > 0 then
        rewardId = stageCfg.FinishRewardShow
    end
    local rewards = {}
    if rewardId > 0 then
        rewards = XRewardManager.GetRewardList(rewardId)
    end

    if rewards then
        for i, item in ipairs(rewards) do
            local grid
            if self.GridList[i] then
                grid = self.GridList[i]
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.Grid128)
                grid = XUiGridCommon.New(self.UiRoot, ui)
                grid.Transform:SetParent(self.PanelReward, false)
                self.GridList[i] = grid
            end
            grid:Refresh(item)
            grid:ShowCount(false)
            grid.GameObject:SetActive(true)
        end
    end

    local rewardsCount = 0
    if rewards then
        rewardsCount = #rewards
    end

    for j = 1, #self.GridList do
        if j > rewardsCount then
            self.GridList[j].GameObject:SetActive(false)
        end
    end
end

function XUiRogueLikeFightEntrance:OnBtnFightNormalClick()
    self:OnFightClick(self.NormalStageId)
end

function XUiRogueLikeFightEntrance:OnBtnFightHardClick()
    self:OnFightClick(self.HardStageId)
end

function XUiRogueLikeFightEntrance:OnFightClick(stageId)
    if not stageId or stageId <= 0 or not self.Node then return end
    -- 行动点是否足够
    local actionPoint = XDataCenter.FubenRogueLikeManager.GetRogueLikeActionPoint()

    local assistRobots = XDataCenter.FubenRogueLikeManager.GetAssistRobots()
    local hasAssist = #assistRobots >= XDataCenter.FubenRogueLikeManager.GetTeamMemberCount()

    if false and actionPoint <= 0 and not hasAssist then
        XUiManager.TipMsg(CS.XTextManager.GetText("RogueLikeNotEnoughActionPoint"))
        return
    end

    -- 是否在挑战时间内
    if not XDataCenter.FubenRogueLikeManager.IsInFight() then
        XUiManager.TipMsg(CS.XTextManager.GetText("RogueLikeNotInActivityFightTime"))
        return
    end

    self.UiRoot:Close()
    local data = {NodeId = self.Node.Id}
    XLuaUiManager.Open("UiNewRoomSingle", stageId, data)
end


return XUiRogueLikeFightEntrance