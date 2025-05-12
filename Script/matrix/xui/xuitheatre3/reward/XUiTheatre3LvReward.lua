local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridTheatre3LvReward = require("XUi/XUiTheatre3/Reward/XUiGridTheatre3LvReward")
local XUiGridTheatre3RewardFloatFrame = require("XUi/XUiTheatre3/Reward/XUiGridTheatre3RewardFloatFrame")

---@class XUiTheatre3LvReward : XLuaUi
---@field _Control XTheatre3Control
local XUiTheatre3LvReward = XLuaUiManager.Register(XLuaUi, "UiTheatre3LvReward")

function XUiTheatre3LvReward:OnAwake()
    self:RegisterUiEvents()
    self.PanelGrid.gameObject:SetActiveEx(false)
    
    ---@type XUiGridTheatre3RewardFloatFrame
    self.GridLeftFloatFrame = nil
    ---@type XUiGridTheatre3RewardFloatFrame
    self.GridRightFloatFrame = nil
end

function XUiTheatre3LvReward:OnStart()
    self:InitDynamicTable()
end

function XUiTheatre3LvReward:OnEnable()
    self:Refresh(true)
    self:AddEventListener()
end

function XUiTheatre3LvReward:OnDisable()
    self:RemoveEventListener()
end

function XUiTheatre3LvReward:Refresh(isJump)
    self:RefreshCurLevel()
    self:SetupDynamicTable(isJump and self:GetDynamicIndex() or -1)
    self:RefreshBtnGetPoint()
    self:RefreshProgress()
    self:RefreshRedPoint()
end

function XUiTheatre3LvReward:GetDynamicIndex()
    local index = self.CurLevel
    local list = self._Control:GetCanReceiveBattlePassIds(self.CurLevel)
    if not XTool.IsTableEmpty(list) then
        index = list[1]
    end
    return index
end

function XUiTheatre3LvReward:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelReward)
    self.DynamicTable:SetProxy(XUiGridTheatre3LvReward, self, handler(self, self.Refresh))
    self.DynamicTable:SetDelegate(self)
    self:SetFloatFrameColumn()
end

function XUiTheatre3LvReward:SetupDynamicTable(index)
    local list = self._Control:GetCanReceiveBattlePassIds(self.CurLevel)
    self.DataList = self._Control:GetBattlePassIdList()
    self.BtnReward.gameObject:SetActiveEx(#list > 0)
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(index)
end

---@param grid XUiGridTheatre3LvReward
function XUiTheatre3LvReward:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DataList[index], self.CurLevel)
    end
end

-- 刷新当前等级
function XUiTheatre3LvReward:RefreshCurLevel()
    self.CurLevel = self._Control:GetCurBattlePassLevel()
    -- 刷新左侧浮框
    if not self.GridLeftFloatFrame then
        self.GridLeftFloatFrame = XUiGridTheatre3RewardFloatFrame.New(self.BtnGridfloatLeft, self, true, handler(self, self.GotoDynamicIndex))
        self.GridLeftFloatFrame:Open()
    end
    self.GridLeftFloatFrame:Refresh(self.CurLevel)
end

function XUiTheatre3LvReward:SetFloatFrameColumn()
    local imp = self.DynamicTable:GetImpl()
    local viewSize = imp.ViewSize
    local gridSize = imp.OriginGridSize
    local spacing = imp.Spacing
    local padding = imp.Padding
    local width = viewSize.x - padding.left - padding.right
    local column = math.max(1, math.ceil(width / (gridSize.x + spacing.x)))
    imp.ScrRect.onValueChanged:AddListener(function(offset)
        self:OnScrollRectValueChanged(offset, column)
    end)
end

function XUiTheatre3LvReward:OnScrollRectValueChanged(offset, column)
    local imp = self.DynamicTable:GetImpl()
    if not imp then
        return
    end
    local startIndex = imp:GetStartIndexByOffest(offset)
    local endIndex = startIndex + column
    self:RefreshFloatFrame(startIndex, endIndex)
end

function XUiTheatre3LvReward:RefreshFloatFrame(startLevel, endLevel)
    if not self.GridLeftFloatFrame then
        return
    end
    -- 左侧浮框
    if XTool.IsNumberValid(self.CurLevel) and (self.CurLevel < startLevel or self.CurLevel > endLevel) then
        self.GridLeftFloatFrame:Open()
    else
        self.GridLeftFloatFrame:Close()
    end
    -- 右侧浮框
    self:RefreshRightFloatFrame(endLevel)
end

function XUiTheatre3LvReward:RefreshBtnGetPoint()
    local isMaxLevel = self._Control:CheckBattlePassMaxLevel(self.CurLevel)
    self.BtnGetPoints.gameObject:SetActiveEx(not isMaxLevel)
end

function XUiTheatre3LvReward:RefreshProgress()
    -- 当前奖励等级
    self.PanelLv:SetNameByGroup(1, self.CurLevel)
    -- 进度
    local isMaxLevel = self._Control:CheckBattlePassMaxLevel(self.CurLevel)
    local progressDesc, progress
    if isMaxLevel then
        progressDesc = self._Control:GetClientConfig("RewardTips", 3)
        progress = 1
    else
        local curLevelExp = self._Control:GetCurLevelExp(self.CurLevel)
        local nextLevelExp = self._Control:GetNextLevelExp(self.CurLevel + 1)
        progressDesc = string.format("%s/%s", curLevelExp, nextLevelExp)
        progress = XTool.IsNumberValid(nextLevelExp) and curLevelExp / nextLevelExp or 1
    end
    self.PanelLv:SetNameByGroup(0, progressDesc)
    self.ImgPercentNormal.fillAmount = progress
    self.ImgPercentPress.fillAmount = progress
end

function XUiTheatre3LvReward:RefreshRightFloatFrame(level)
    -- 下一大奖等级
    local nextDisplayLevel = self._Control:GetNextDisplayLevel(level)
    if not self.GridRightFloatFrame then
        self.GridRightFloatFrame = XUiGridTheatre3RewardFloatFrame.New(self.BtnGridfloatRight, self, false, handler(self, self.GotoDynamicIndex))
    end
    self.GridRightFloatFrame:Open()
    self.GridRightFloatFrame:Refresh(nextDisplayLevel)
end

-- 移动动态列表
function XUiTheatre3LvReward:GotoDynamicIndex(battlePassId)
    local contain, index = table.contains(self.DataList, battlePassId)
    if contain then
        index = index - 1
        if index <= 0 then
            index = 1
        end
        self.DynamicTable:ScrollToIndex(index, 0.5, function()
            XLuaUiManager.SetMask(true)
        end, function()
            XLuaUiManager.SetMask(false)
        end)
    end
end

function XUiTheatre3LvReward:RefreshRedPoint()
    -- 一键领取红点
    local isRewardRedPoint = self._Control:CheckIsHaveReward(self.CurLevel)
    self.BtnReward:ShowReddot(isRewardRedPoint)
end

function XUiTheatre3LvReward:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.BtnReward, self.OnBtnRewardClick)
    XUiHelper.RegisterClickEvent(self, self.BtnGetPoints, self.OnBtnGetPointsClick)
end

function XUiTheatre3LvReward:OnBtnBackClick()
    self:Close()
end

function XUiTheatre3LvReward:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

-- 一键领取
function XUiTheatre3LvReward:OnBtnRewardClick()
    local isHaveReward = self._Control:CheckIsHaveReward(self.CurLevel)
    if not isHaveReward then
        XUiManager.TipMsg(self._Control:GetClientConfig("RewardTips", 1))
        return
    end
    self._Control:GetBattlePassRewardRequest(XEnumConst.THEATRE3.GetBattlePassRewardType.GetAll, nil, function()
        self:Refresh()
    end)
end

-- 获取积分
function XUiTheatre3LvReward:OnBtnGetPointsClick()
    XLuaUiManager.Open("UiTheatre3Task")
end

--region Event
function XUiTheatre3LvReward:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE3_BATTLE_PASS_EXP_CHANGE, self.Refresh, self)
end

function XUiTheatre3LvReward:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE3_BATTLE_PASS_EXP_CHANGE, self.Refresh, self)
end
--endregion

return XUiTheatre3LvReward