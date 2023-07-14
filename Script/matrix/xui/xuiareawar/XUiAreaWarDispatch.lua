local XUiAreaWarBattleRoomRoleDetail = require("XUi/XUiAreaWar/XUiAreaWarBattleRoomRoleDetail")

local XUiAreaWarDispatch = XLuaUiManager.Register(XLuaUi, "UiAreaWarDispatch")

function XUiAreaWarDispatch:OnAwake()
    self.Grid128.gameObject:SetActiveEx(false)
    self.GridCondition.gameObject:SetActiveEx(false)
    self:AutoAddListener()
end

function XUiAreaWarDispatch:OnStart(blockId)
    self.BlockId = blockId
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
    self:UpdateView()
end

function XUiAreaWarDispatch:OnDestroy()
    XDataCenter.AreaWarManager.ClearDispatchTeam()
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

    local args = {...}
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
end

function XUiAreaWarDispatch:InitView()
    local blockId = self.BlockId

    --派遣消耗行动点
    local costCount = XAreaWarConfigs.GetBlockDetachActionPoint(blockId)
    self.TxtCost.text = costCount

    local icon = XDataCenter.AreaWarManager.GetActionPointItemIcon()
    self.RImgCost:SetRawImage(icon)

    --派遣奖励（基础）
    local rewardItems = XAreaWarConfigs.GetBlockDetachBasicRewardItems(blockId)
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
            XLuaUiManager.Open("UiBattleRoomRoleDetail", self.BlockId, self.Team, pos, XUiAreaWarBattleRoomRoleDetail)
        end
    end
end

function XUiAreaWarDispatch:UpdateView()
    self.IsConditionAllReach = true

    local blockId = self.BlockId
    local entityIds = self.Team:GetEntityIds()
    local conditionIdCheckDic = XAreaWarConfigs.GetDispatchCharacterCondtionIdCheckDic(entityIds)

    --派遣条件
    local conditions = XDataCenter.AreaWarManager.GetDispatchConditions(blockId)
    for index, conditionId in ipairs(conditions) do
        local grid = self.ConditionGrids[index]
        if not grid then
            local go = index == 1 and self.GridCondition or CSObjectInstantiate(self.GridCondition, self.PanelList)
            grid = XTool.InitUiObjectByUi({}, go)
            self.ConditionGrids[index] = grid
        end

        --条件满足状态
        local isReach = conditionIdCheckDic[conditionId]
        grid.Normal.gameObject:SetActiveEx(not isReach)
        grid.Reach.gameObject:SetActiveEx(isReach)
        if not isReach then
            self.IsConditionAllReach = false
        end

        --派遣奖励（额外,只展示奖励物品的第一个）
        local extraRewards = XAreaWarConfigs.GetBlockDetachDetachExtraRewardItems(blockId, index)
        local item = extraRewards[1]
        local itemId, count = item.TemplateId, item.Count
        local icon = XItemConfigs.GetItemIconById(itemId)
        grid.RImgIcon:SetRawImage(icon)
        grid.RImgIcon2:SetRawImage(icon)
        grid.TxtNumber.text = "+" .. count
        grid.TxtNumber2.text = "+" .. count

        --条件描述
        local conditionDesc = XAreaWarConfigs.GetDispatchConditionDesc(conditionId)
        conditionDesc = CsXTextManagerGetText("AreaWarDisapatchCondition", index, conditionDesc)
        grid.TxtCondition.text = conditionDesc
        grid.TxtCondition2.text = conditionDesc

        grid.GameObject:SetActiveEx(true)
    end
    for index = #conditions + 1, #self.ConditionGrids do
        self.ConditionGrids[index].GameObject:SetActiveEx(false)
    end
end

function XUiAreaWarDispatch:OnClickBtnDispatch()
    local blockId = self.BlockId

    --检查消耗体力
    local costCount = XAreaWarConfigs.GetBlockDetachActionPoint(blockId)
    if not XDataCenter.AreaWarManager.CheckActionPoint(costCount) then
        XUiManager.TipText("AreaWarActionPointNotEnought")
        return
    end

    --检查队伍为空
    if self.Team:GetIsEmpty() then
        XUiManager.TipText("AreaWarDisapatchEmptyTeam")
        return
    end

    local callFunc = function()
        local characterIds, robotIds = self.Team:SpiltCharacterAndRobotIds()
        XDataCenter.AreaWarManager.AreaWarDetachRequest(
            blockId,
            characterIds,
            robotIds,
            function(rewardGoodsList)
                if not XTool.IsTableEmpty(rewardGoodsList) then
                    XUiManager.OpenUiObtain(rewardGoodsList)
                end
            end
        )
        self:Close()
    end

    --检查条件是否全部满足
    if self.IsConditionAllReach then
        callFunc()
    else
        local title = CsXTextManagerGetText("AreaWarDisapatchConfirmTitle")
        local content = CsXTextManagerGetText("AreaWarDisapatchConfirmContent")
        XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, callFunc)
    end
end
