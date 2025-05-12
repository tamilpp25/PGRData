--######################## XGridCondition 条件格子 ########################
local XGridCondition = XClass(nil, "XGridCondition")

function XGridCondition:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XUiHelper.InitUiClass(self, ui)
end

function XGridCondition:Refresh(theatreDecorationId)
    local conditionId = XTheatreConfigs.GetDecorationConditionId(theatreDecorationId)
    local ret, conditionDesc
    if XTool.IsNumberValid(conditionId) then
        ret, conditionDesc = XConditionManager.CheckCondition(conditionId)
        self.TxtON.text = conditionDesc
        self.TxtOFF.text = conditionDesc
        self.PanelON.gameObject:SetActiveEx(ret)
        self.PanelOFF.gameObject:SetActiveEx(not ret)
    else
        self.PanelON.gameObject:SetActiveEx(true)
        self.PanelOFF.gameObject:SetActiveEx(false)
    end
end

--装修项详情弹窗
local XUiTheatreDetail = XLuaUiManager.Register(XLuaUi, "UiTheatreDetail")

function XUiTheatreDetail:OnAwake()
    self.BtnLevelEnter.CallBack = handler(self, self.OnBtnLevelEnterClick)
    self:RegisterClickEvent(self.BtnTanchuangCloseBig, self.Close)
    self.DecorationManager = XDataCenter.TheatreManager.GetDecorationManager()
    self.ConditionGrid = XGridCondition.New(self.GridCondition)
end

function XUiTheatreDetail:OnStart(decorationId, closeCb)
    self.DecorationId = decorationId
    self.CloseCallback = closeCb
end

function XUiTheatreDetail:OnEnable()
    self:Refresh()
end

function XUiTheatreDetail:OnDestroy()
    if self.CloseCallback then
        self.CloseCallback()
    end
end

function XUiTheatreDetail:Refresh()
    local decorationId = self.DecorationId
    local theatreDecorationId = self.DecorationManager:GetTheatreDecorationId(decorationId)
    local lv = self.DecorationManager:GetDecorationLv(decorationId)
    local isMaxLv = self.DecorationManager:IsMaxLv(decorationId)

    --图标
    local icon = XTheatreConfigs.GetDecorationIcon(theatreDecorationId)
    self.RImgSkillIcon:SetRawImage(icon)

    --名称
    self.TxtSkillName.text = XTheatreConfigs.GetDecorationName(theatreDecorationId)

    --描述
    self.TxtDesc.text = XTheatreConfigs.GetDecorationDesc(theatreDecorationId)

    --条件描述和达成状态
    local conditionId = XTheatreConfigs.GetDecorationConditionId(theatreDecorationId)
    local ret, conditionDesc
    if XTool.IsNumberValid(conditionId) then
        ret, conditionDesc = XConditionManager.CheckCondition(conditionId)
        self.TxtActiveDesc.text = conditionDesc
        self.TxtActiveState.text = ret and XUiHelper.GetText("TheatreDecorationTipsUnLockDesc") or XUiHelper.GetText("TheatreDecorationTipsLockDesc")
        self.PanelCondition.gameObject:SetActiveEx(true)
    else
        ret = true
        self.PanelCondition.gameObject:SetActiveEx(false)
    end
    self.ConditionGrid:Refresh(theatreDecorationId)

    --消耗道具
    local costItemId = XTheatreConfigs.GetDecorationUpgradeCostItemId(theatreDecorationId)
    local isHaveItem = XTool.IsNumberValid(costItemId)
    local costItemName = XItemConfigs.GetItemNameById(costItemId)
    local costItemIcon = XItemConfigs.GetItemIconById(costItemId)
    local costUpgradeCost = XTheatreConfigs.GetDecorationUpgradeCost(theatreDecorationId)
    local costCostCount = XDataCenter.ItemManager.GetCount(costItemId)
    self.TextItemName.text = XUiHelper.GetText("RebootCostText", costItemName)
    self.RImgCostIcon:SetRawImage(costItemIcon)
    self.TxtNeedNums.text = costCostCount
    self.TxtTotalNums.text = "/" .. costUpgradeCost
    self.RImgCostIcon.gameObject:SetActiveEx(isHaveItem)
    self.TxtTotalNums.gameObject:SetActiveEx(not isMaxLv)
    self.TextItemName.gameObject:SetActiveEx(not isMaxLv)

    --改造按钮
    local isCanLevelUp = (not isMaxLv and costCostCount >= costUpgradeCost and ret) or false
    self.BtnLevelEnter:SetDisable(not isCanLevelUp, isCanLevelUp)

    --当前技能等级
    local curLv = XTheatreConfigs.GetDecorationLv(theatreDecorationId)
    self.TxtSkillLevel.text = XUiHelper.GetText("TheatreDecorationTipsLevel", curLv)
end

function XUiTheatreDetail:OnBtnLevelEnterClick()
    local manager = XDataCenter.TheatreManager.GetDecorationManager()
    local theatreDecorationId = self.DecorationManager:GetActiveTheatreDecorationId(self.DecorationId)
    manager:RequestTheatreDecorationUpgrade(theatreDecorationId)
end

function XUiTheatreDetail:OnGetEvents()
    return { XEventId.EVENT_THEATRE_DECORATION_UPGRADE }
end

function XUiTheatreDetail:OnNotify(evt, ...)
    if evt == XEventId.EVENT_THEATRE_DECORATION_UPGRADE then
        self:Refresh()
    end
end