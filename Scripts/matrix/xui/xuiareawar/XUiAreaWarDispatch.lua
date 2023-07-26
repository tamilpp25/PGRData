local XUiAreaWarBattleRoomRoleDetail = require("XUi/XUiAreaWar/XUiAreaWarBattleRoomRoleDetail")

local XUiAreaWarDispatch = XLuaUiManager.Register(XLuaUi, "UiAreaWarDispatch")

function XUiAreaWarDispatch:OnAwake()
    self.Grid128.gameObject:SetActiveEx(false)
    self.GridCondition.gameObject:SetActiveEx(false)
    self.PanelCondition.gameObject:SetActiveEx(false)
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

    
    --根据不同时期，获取不同的奖励配置
    local rewardItems = {}
    if XDataCenter.AreaWarManager.IsRepeatChallengeTime() then
        rewardItems=XAreaWarConfigs.GetBlockDetachWhippingPeriodRewardItems(blockId)
    else
        rewardItems = XAreaWarConfigs.GetBlockDetachBasicRewardItems(blockId)
    end
    
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
            self:OnBtnJoinClick(pos)
        end
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

    --是否满足3人
    if not self.Team:GetIsFullMember() then
        XUiManager.TipCode(XCode.AreaWarDetachCountError)
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
                    self:Close()
                    XUiManager.OpenUiObtain(rewardGoodsList)
                end
            end
        )
    end
    callFunc()
end

function XUiAreaWarDispatch:OnBtnJoinClick(pos)
    local stageId = XAreaWarConfigs.GetBlockStageId(self.BlockId)
    XLuaUiManager.Open("UiBattleRoomRoleDetail", stageId, self.Team, pos, XUiAreaWarBattleRoomRoleDetail)
end

