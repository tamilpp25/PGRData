local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiAreaWarBattleRoomRoleDetail = require("XUi/XUiAreaWar/XUiAreaWarBattleRoomRoleDetail")

local XUiAreaWarDispatch = XLuaUiManager.Register(XLuaUi, "UiAreaWarDispatch")

local ColorEnum = {
    Enough = XUiHelper.Hexcolor2Color("ffffff"),
    NotEnough = XUiHelper.Hexcolor2Color("A6A6A6")
}

function XUiAreaWarDispatch:OnAwake()
    self.Grid128.gameObject:SetActiveEx(false)
    self.GridCondition.gameObject:SetActiveEx(false)
    self.PanelCondition.gameObject:SetActiveEx(false)
    self:AutoAddListener()
end

function XUiAreaWarDispatch:OnStart(id, isQuest)
    self.Id = id
    self.IsQuest = isQuest
    self.ConditionGrids = {}
    self.RewardGrids = {}
    self.TeamGrids = {}
    self.Team = XDataCenter.AreaWarManager.GetDispatchTeam()

    self:InitView()
end

function XUiAreaWarDispatch:OnEnable()
    if self.IsEnd then
        return
    end
    if XDataCenter.AreaWarManager.OnActivityEnd() then
        self.IsEnd = true
        return
    end
    self:UpdateTeam()
end

function XUiAreaWarDispatch:OnDestroy()
    XDataCenter.AreaWarManager.SaveTeam()
end

function XUiAreaWarDispatch:OnGetEvents()
    return {
        XEventId.EVENT_AREA_WAR_ACTIVITY_END
    }
end

function XUiAreaWarDispatch:OnNotify(evt, ...)
    if self.IsEnd then
        return
    end

    local args = { ... }
    if evt == XEventId.EVENT_AREA_WAR_ACTIVITY_END then
        if XDataCenter.AreaWarManager.OnActivityEnd() then
            self.IsEnd = true
            return
        end
    end
end

function XUiAreaWarDispatch:AutoAddListener()
    self.BtnTanchuangCloseBig.CallBack = function()
        self:Close()
    end
    self.BtnDispatch.CallBack = function()
        self:OnClickBtnDispatch()
    end
    self.BtnAdd.CallBack = function()
        self:OnClickBtnAdd()
    end
    self.BtnSub.CallBack = function()
        self:OnClickBtnSub()
    end
    self.BtnMax.CallBack = function()
        self:OnClickBtnMax()
    end
end

function XUiAreaWarDispatch:InitView()
    --派遣消耗行动点
    local costCount
    local icon
    local isShowChangeNum
    local minCount, maxCount = 0, 0
    --根据不同时期，获取不同的奖励配置
    local rewardItems = {}
    local showCost = false
    self.PanelFull.gameObject:SetActiveEx(false)
    if self.IsQuest then
        local questId = self.Id
        local rewardId = XDataCenter.AreaWarManager.GetAreaWarQuest(questId):GetRewardId()
        if rewardId < 0 then
            rewardItems = {}
            self.PanelFull.gameObject:SetActiveEx(true)
        elseif rewardId == 0 then
            rewardItems = {}
        else
            rewardItems = XRewardManager.GetRewardList(rewardId)
        end

        local itemId = XAreaWarConfigs.GetSkipItemId()
        costCount = 1
        icon = XDataCenter.ItemManager.GetItemIcon(itemId)
        isShowChangeNum = false
        showCost = false

    else
        local blockId = self.Id
        if XDataCenter.AreaWarManager.IsRepeatChallengeTime() then
            rewardItems = XAreaWarConfigs.GetBlockDetachWhippingPeriodRewardItems(blockId)
        else
            rewardItems = XAreaWarConfigs.GetBlockDetachBasicRewardItems(blockId)
        end
        costCount = XAreaWarConfigs.GetBlockDetachActionPoint(blockId)
        icon = XDataCenter.AreaWarManager.GetActionPointItemIcon()
        local personal = XDataCenter.AreaWarManager.GetPersonal()
        isShowChangeNum = personal:IsOpenMultiChallenge()
        minCount = personal:GetSelectSkipNum(costCount)
        maxCount = personal:GetSkipNum()
        showCost = true
    end
    self.TxtCost.gameObject:SetActiveEx(showCost)
    self.RImgCost.gameObject:SetActiveEx(showCost)
    self.DispatchCount = minCount
    self.MaxDispatchCount = maxCount

    self.PanelNumBtn.gameObject:SetActiveEx(isShowChangeNum)
    if showCost then
        self.TxtCost.text = costCount * self.DispatchCount
        self.RImgCost:SetRawImage(icon)
    end
    self:RefreshReward(rewardItems)
    if isShowChangeNum then
        self:RefreshSelectCount()
    end
end

function XUiAreaWarDispatch:RefreshReward(rewardItems)
    for index, item in ipairs(rewardItems) do
        local grid = self.RewardGrids[index]
        if not grid then
            local go = index == 1 and self.Grid128 or CSObjectInstantiate(self.Grid128, self.RewardParent)
            grid = XUiGridCommon.New(self, go)
            self.RewardGrids[index] = grid
        end
        grid:Refresh(item)
        grid.GameObject:SetActiveEx(true)
    end
    for index = #rewardItems + 1, #self.RewardGrids do
        self.RewardGrids[index].GameObject:SetActiveEx(false)
    end
end

function XUiAreaWarDispatch:RefreshSelectCount()
    local lessOne = self.DispatchCount <= 0
    self.BtnSub:SetDisable(lessOne, not lessOne)
    self.BtnDispatch:SetDisable(lessOne, not lessOne)
    local biggerMax = self.DispatchCount >= self.MaxDispatchCount
    self.BtnAdd:SetDisable(biggerMax, not biggerMax)

    self.TxtChallengeNum.text = self.DispatchCount

    local costCount = XAreaWarConfigs.GetBlockDetachActionPoint(self.Id) * self.DispatchCount
    local isEnough = XDataCenter.AreaWarManager.CheckActionPoint(costCount)

    self.TxtCost.text = costCount
    self.TxtCost.color = isEnough and ColorEnum.Enough or ColorEnum.NotEnough
    
    self.BtnMax:ShowReddot(XDataCenter.AreaWarManager.GetPersonal():CheckMaxRedPoint())
end

function XUiAreaWarDispatch:UpdateTeam()
    local entityIds = self.Team:GetEntityIds()
    for pos, entityId in ipairs(entityIds) do
        local grid = self.TeamGrids[pos]
        if not grid then
            local go = self["TeamMember" .. pos]
            grid = XTool.InitUiObjectByUi({}, go)
            self.TeamGrids[pos] = grid
        end

        if not XTool.IsNumberValid(entityId) then
            --未上阵
            grid.ImgJia.gameObject:SetActiveEx(true)
            grid.PanelGrid1.gameObject:SetActiveEx(false)
        else
            local icon = XEntityHelper.GetCharacterHalfBodyImage(entityId)
            grid.RImgRole:SetRawImage(icon)

            grid.ImgJia.gameObject:SetActiveEx(false)
            grid.PanelGrid1.gameObject:SetActiveEx(true)
        end

        grid.BtnJoin1.CallBack = function()
            self:OnBtnJoinClick(pos)
        end
    end
end

function XUiAreaWarDispatch:OnClickBtnDispatch()
    --检查队伍为空
    if self.Team:GetIsEmpty() then
        XUiManager.TipText("AreaWarDisapatchEmptyTeam")
        return
    end

    --是否满足3人
    if not self.Team:GetIsFullMember() then
        XUiManager.TipCode(XCode.AreaWarDetachCountError)
        return
    end

    if self.IsQuest then
        self:DoDispatchQuest()
    else
        self:DoDispatchBlock()
    end
end

function XUiAreaWarDispatch:DoDispatchBlock()
    local blockId = self.Id

    --检查消耗体力
    local costCount = XAreaWarConfigs.GetBlockDetachActionPoint(blockId)
    if not XDataCenter.AreaWarManager.CheckActionPoint(costCount * self.DispatchCount) then
        XUiManager.TipText("AreaWarActionPointNotEnought")
        return
    end

    local characterIds, robotIds = self.Team:SpiltCharacterAndRobotIds()
    XDataCenter.AreaWarManager.AreaWarDetachRequest(blockId, characterIds, robotIds, self.DispatchCount, function(rewardGoodsList)
        local personal = XDataCenter.AreaWarManager.GetPersonal()
        if personal:IsOpenMultiChallenge() then
            personal:SetSelectLocal(self.DispatchCount)
        end
        self:SyncWhenResponse(rewardGoodsList, false)
    end
    )
end

function XUiAreaWarDispatch:DoDispatchQuest()
    local questId = self.Id
    local characterIds, robotIds = self.Team:SpiltCharacterAndRobotIds()
    XDataCenter.AreaWarManager.RequestQuestDetach(questId, characterIds, robotIds, function(rewardGoodsList)
        self:SyncWhenResponse(rewardGoodsList, true)
    end)
end

function XUiAreaWarDispatch:SyncWhenResponse(rewardGoodsList, isCloseDetail)
    local closeUi = asynTask(function(cb)
        XLuaUiManager.CloseWithCallback("UiAreaWarDispatch", cb)
    end)
    RunAsyn(function()
        closeUi()
        if not XTool.IsTableEmpty(rewardGoodsList) then
            local openObtain = asynTask(function(cb)
                XUiManager.OpenUiObtain(rewardGoodsList, nil, cb)
            end)

            openObtain()
        end

        if isCloseDetail then
            XLuaUiManager.Close("UiAreaWarStageDetail")
        end
    end)
end

function XUiAreaWarDispatch:OnBtnJoinClick(pos)
    local stageId
    if self.IsQuest then
        stageId = XDataCenter.AreaWarManager.GetAreaWarQuest(self.Id):GetStageId()
    else
        stageId = XAreaWarConfigs.GetBlockStageId(self.Id)
    end
    XLuaUiManager.Open("UiBattleRoomRoleDetail", stageId, self.Team, pos, XUiAreaWarBattleRoomRoleDetail)
end

function XUiAreaWarDispatch:OnClickBtnAdd()
    if self.DispatchCount >= self.MaxDispatchCount then
        self.DispatchCount = self.MaxDispatchCount
        return
    end
    self.DispatchCount = self.DispatchCount + 1
    if self.DispatchCount >= self.MaxDispatchCount then
        XDataCenter.AreaWarManager.GetPersonal():MarkMaxRedPoint()
    end
    self:RefreshSelectCount()
end

function XUiAreaWarDispatch:OnClickBtnSub()
    if self.DispatchCount <= 1 then
        self.DispatchCount = 1
        return
    end
    self.DispatchCount = self.DispatchCount - 1
    self:RefreshSelectCount()
end

function XUiAreaWarDispatch:OnClickBtnMax()
    self.DispatchCount = self.MaxDispatchCount
    XDataCenter.AreaWarManager.GetPersonal():MarkMaxRedPoint()
    self:RefreshSelectCount()
end

