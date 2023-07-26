local XUiGridCostItem = require("XUi/XUiEquipBreakThrough/XUiGridCostItem")

local MAX_BREAKTHROUGH_POINT_NUM = 4 --最大突破点个数
local TIP_COLOR = XUiHelper.Hexcolor2Color("EE2323FF") --文本警示色

local ToInt = XMath.ToInt

--一键培养UI
local XUiEquipCulture = XLuaUiManager.Register(XLuaUi, "UiEquipCulture")

function XUiEquipCulture:OnAwake()
    self:AutoAddListener()

    self.AssetPanel =
        XUiPanelAsset.New(
        self,
        self.PanelAsset,
        XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.ActionPoint,
        XDataCenter.ItemManager.ItemId.Coin
    )

    --记录文本初始颜色
    self.ColorTxtCost = self.TxtCost.color
    self.ColorTxtExp = self.TxtExp.color
    self.ColorTxtLv = self.TxtLv.color

    self.GridCostItem.gameObject:SetActiveEx(false)
    self.SafeAreaContentPane = self.PanelAsset.transform.parent:GetComponent("XUiSafeAreaAdapter")
end

function XUiEquipCulture:OnStart(equipId)
    self.EquipId = equipId
    self.TargetLevelUnit = 1
    self.GridCostItems = {}
    self.IsDestroy = false

    self:InitView()
end

function XUiEquipCulture:OnEnable()
    self:UpdateView()
end

function XUiEquipCulture:OnDestroy()
    self.IsDestroy = true
end

function XUiEquipCulture:OnGetEvents()
    return {
        XEventId.EVENT_EQUIP_QUICK_STRENGTHEN_NOTYFY,
        XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XDataCenter.ItemManager.ItemId.Coin
    }
end

function XUiEquipCulture:OnNotify(evt, ...)
    local args = {...}

    if evt == XEventId.EVENT_EQUIP_QUICK_STRENGTHEN_NOTYFY then
        self:UpdateView()
        --强化后更新可消耗道具
        self:UpdateRecommendConsumeItems()
    elseif evt == XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XDataCenter.ItemManager.ItemId.Coin then
        self:UpdateConsume()
    end
end

--异形屏适配
function XUiEquipCulture:SetScreenAdaptorCache()
    if not XTool.UObjIsNil(self.SafeAreaContentPane) then
        self.SafeAreaContentPane:UpdateSpecialScreenOff()
    end
end

function XUiEquipCulture:InitView()
    self.Initing = true

    self:SetScreenAdaptorCache()
    local equipId = self.EquipId
    local templateId = XDataCenter.EquipManager.GetEquipTemplateId(equipId)
    self.EquipId = equipId
    self.TemplateId = templateId
    self.MaxLevelUnit = XDataCenter.EquipManager.GetEquipMaxLevelUnit(templateId)
    self.MaxBreakthrough = XDataCenter.EquipManager.GetEquipMaxBreakthrough(templateId)
    self.ConsumeTypeDic = {} --消耗种类（0代表道具类型，1-5代表装备星级）

    --图文教程
    local helpKey = XDataCenter.EquipManager.IsWeapon(equipId) and "UiEquipCultureWeapon" or "UiEquipCultureAwareness"
    self:BindHelpBtn(self.BtnHelp, helpKey)

    --名称
    self.TxtName.text = XDataCenter.EquipManager.GetEquipName(templateId)

    --图标
    self.RImgIcon:SetRawImage(XDataCenter.EquipManager.GetEquipIconPath(templateId))

    --星星
    local star = XDataCenter.EquipManager.GetEquipStar(templateId)
    for i = 1, XEquipConfig.MAX_STAR_COUNT do
        if self["ImgStar" .. i] then
            self["ImgStar" .. i].gameObject:SetActiveEx(i <= star)
        end
    end

    --滑动条底下突破点的位置
    local maxLevelUnit = self.MaxLevelUnit
    local width = self.PanelBreach.rect.width
    local tf, posX, levelUnit
    for i = 1, MAX_BREAKTHROUGH_POINT_NUM do
        tf = self["PanelBreakPoint" .. i]
        if i <= self.MaxBreakthrough then
            levelUnit = XDataCenter.EquipManager.ConvertToLevelUnit(templateId, i)
            posX = width * (levelUnit - 1) / (maxLevelUnit - 1)

            tf.anchoredPosition = Vector2(posX, tf.anchoredPosition.y)
            tf.gameObject:SetActiveEx(true)
        else
            tf.gameObject:SetActiveEx(false)
        end
    end

    --强化消耗范围复选框（勾选除了【5星】外的所有素材种类）
    self.TgDaoJu.isOn = true
    self.Tg3Xing.isOn = true
    self.Tg4Xing.isOn = true

    self.Initing = nil
end

function XUiEquipCulture:UpdateView()
    local equipId = self.EquipId

    local isMaxLevel = XDataCenter.EquipManager.IsMaxLevelAndBreakthrough(equipId)
    if isMaxLevel then
        self:Close()
        return
    end

    self.MinLevelUnit = XDataCenter.EquipManager.GetEquipLevelUnit(equipId)

    --更新滑动条
    local minLevelUnit = self.MinLevelUnit
    local maxLevelUnit = self.MaxLevelUnit
    self.Slider:SetBorderValue(minLevelUnit, maxLevelUnit) --可滑动区域等级单位范围

    -- local targetLevelUnit = XMath.Clamp(self.TargetLevelUnit, minLevelUnit, maxLevelUnit)
    --重新进入界面，滑动条都到装备当前等级处
    local targetLevelUnit = self.MinLevelUnit
    self.Slider.minValue = 1 --最小值代表等级单位
    self.Slider.maxValue = maxLevelUnit --最大值代表等级单位
    self.Slider.value = targetLevelUnit
    self.TargetLevelUnit = targetLevelUnit

end

function XUiEquipCulture:AutoAddListener()
    self.BtnMainUi.CallBack = function()
        XLuaUiManager.RunMain()
    end
    self.BtnBack.CallBack = handler(self, self.Close)
    self.BtnPreview.CallBack = handler(self, self.OnClickBtnPreview)
    self.BtnEvoConfirm.CallBack = handler(self, self.OnClickBtnEvoConfirm)
    self.BtnAdd.CallBack = function()
        self:SetSliderValue(self.TargetLevelUnit + 1)
    end
    self.BtnSub.CallBack = function()
        self:SetSliderValue(self.TargetLevelUnit - 1)
    end
    self.BtnMax.CallBack = function()
        -- local maxTargetLevelUnit = XDataCenter.EquipManager.GetMultiStrengthenMaxTarget(self.EquipId, self.Consumes)
        local maxTargetLevelUnit = XDataCenter.EquipManager.GetStrengthenMaxTarget(self.EquipId, self.Consumes)
        self:SetSliderValue(maxTargetLevelUnit)
    end
    self.Slider.onValueChanged:AddListener(handler(self, self.OnSliderValueChanged))
    self.TgDaoJu.onValueChanged:AddListener(
        function()
            self:OnSelectConsumeType({0}, self.TgDaoJu.isOn)
        end
    )
    self.Tg3Xing.onValueChanged:AddListener(
        function()
            self:OnSelectConsumeType({1, 2, 3}, self.Tg3Xing.isOn)
        end
    )
    self.Tg4Xing.onValueChanged:AddListener(
        function()
            self:OnSelectConsumeType({4}, self.Tg4Xing.isOn)
        end
    )
    self.Tg5Xing.onValueChanged:AddListener(
        function()
            self:OnSelectConsumeType({5}, self.Tg5Xing.isOn)
        end
    )
end

--选择目标升级单位
function XUiEquipCulture:OnSliderValueChanged()
    self.TargetLevelUnit = ToInt(self.Slider.value)

    local targetLevelUnit = self.TargetLevelUnit
    local templateId = self.TemplateId
    local isReach

    --突破点状态（滑动覆盖后显示蓝色）
    for i = 1, self.MaxBreakthrough do
        isReach = targetLevelUnit >= XDataCenter.EquipManager.ConvertToLevelUnit(templateId, i)
        self["LockedImgBreach" .. i].gameObject:SetActiveEx(not isReach)
        self["UnlockedImgBreach" .. i].gameObject:SetActiveEx(isReach)
    end

    --等级，突破显示
    local breakthrough, level = XDataCenter.EquipManager.ConvertToBreakThroughAndLevel(templateId, targetLevelUnit)
    local levelLimit = XDataCenter.EquipManager.GetBreakthroughLevelLimitByTemplateId(templateId, breakthrough)
    self.ImgBreak:SetSprite(XEquipConfig.GetEquipBreakThroughIcon(breakthrough))
    self.TxtLv.text = level
    self.TxtLvMax.text = "/" .. levelLimit

    --调整按钮状态
    local minLevelUnit = self.MinLevelUnit
    local maxLevelUnit = self.MaxLevelUnit
    isReach = targetLevelUnit <= minLevelUnit
    self.BtnSub:SetDisable(isReach, not isReach)
    isReach = targetLevelUnit >= maxLevelUnit
    self.BtnAdd:SetDisable(isReach, not isReach)

    --更新消耗
    self:UpdateConsume()
end

--更新消耗
function XUiEquipCulture:UpdateConsume()
    if self.Initing then
        return
    end

    local equipId = self.EquipId
    local templateId = self.TemplateId
    local targetLevelUnit = self.TargetLevelUnit
    local targetBreakthrough, targetLevel =
        XDataCenter.EquipManager.ConvertToBreakThroughAndLevel(templateId, targetLevelUnit)

    local costMoney = 0 --总消耗货币

    --突破条件
    local tmpBreakthrough = targetBreakthrough
    if tmpBreakthrough == self.MaxBreakthrough then
        --突破次数达到上限后已经没有条件限制，但策划要求以第一次突破的条件作为默认显示
        tmpBreakthrough = 0
    end
    local passCondition, conditionDesc =
        XDataCenter.EquipManager.CheckBreakthroughCondition(templateId, tmpBreakthrough)
    local isEmpty = string.IsNilOrEmpty(conditionDesc)
    if not isEmpty then
        self.ImgPass.gameObject:SetActiveEx(passCondition)
        self.ImgNotPass.gameObject:SetActiveEx(not passCondition)
        self.TxtPass.text = conditionDesc
        self.TxtNotPass.text = conditionDesc
    end
    self.PanelBreachNeed.gameObject:SetActiveEx(not isEmpty)
    self.PanelBreachNeedEmpty.gameObject:SetActiveEx(isEmpty)

    --突破消耗
    local breakthroughCostMoney = XDataCenter.EquipManager.GetMutiBreakthroughUseMoney(equipId, targetBreakthrough)
    costMoney = costMoney + breakthroughCostMoney
    local consumeItems, canBreakThrough =
        XDataCenter.EquipManager.GetMutiBreakthroughConsumeItems(equipId, targetBreakthrough)
    local isEmpty = XTool.IsTableEmpty(consumeItems)
    if not isEmpty then
        for index, item in ipairs(consumeItems) do
            local grid = self.GridCostItems[index]
            if not grid then
                local ui = CSObjectInstantiate(self.GridCostItem, self.PanelCostItem)
                grid = XUiGridCostItem.New(self, ui)
                self.GridCostItems[index] = grid
            end
            grid:Refresh(item.Id, item.Count)
            grid.GameObject:SetActiveEx(true)
        end
        for i = #consumeItems + 1, #self.GridCostItems do
            self.GridCostItems[i].GameObject:SetActiveEx(false)
        end
    end
    self.PanelBreachConsume.gameObject:SetActiveEx(not isEmpty)
    self.PanelBreachConsumeEmpty.gameObject:SetActiveEx(isEmpty)

    --升级消耗
    local curLevelUnit = self.MinLevelUnit
    local canLevelUp, totalExp, levelUpCostMoney, realTargetLevel, operations =
        XDataCenter.EquipManager.TryMultiLevelUp(equipId, targetBreakthrough, targetLevel, self.Consumes)
    costMoney = costMoney + levelUpCostMoney
    self.TxtExp.text = totalExp

    --总消耗货币文本
    self.TxtCost.text = costMoney

    --警示文本颜色
    --货币不足
    local moneyEnough = XDataCenter.ItemManager.GetCoinsNum() >= costMoney
    if not moneyEnough then
        self.TxtCost.color = TIP_COLOR
    else
        self.TxtCost.color = self.ColorTxtCost
    end
    --不可培养
    local canDo = passCondition and canBreakThrough and moneyEnough and canLevelUp
    if not canDo then
        self.TxtLv.color = TIP_COLOR
    else
        self.TxtLv.color = self.ColorTxtLv
    end
    --强化素材不足
    if not canLevelUp then
        self.TxtExp.color = TIP_COLOR
    else
        self.TxtExp.color = self.ColorTxtExp
    end

    --UI缓存
    self.CostMoney = costMoney --总消耗货币
    self.RealTargetLevel = realTargetLevel --溢出经验达到真实等级
    self.CanBreakThrough = canBreakThrough --突破素材是否足够
    self.CanLevelUp = canLevelUp --升级素材是否足够
    self.PassCondition = passCondition --突破条件是否通过
    self.ConditionDesc = conditionDesc --突破条件描述
    self.Operations = operations --单次突破下升级消耗操作列表（服务端要求）
end

--更新可消耗列表
function XUiEquipCulture:UpdateRecommendConsumeItems()
    if self.IsDestroy then
        return
    end
    self.Consumes = XDataCenter.EquipManager.GetMutiLevelUpRecommendItems(self.EquipId, self.ConsumeTypeDic)

    --更新消耗
    self:UpdateConsume()
end

function XUiEquipCulture:SetSliderValue(value)
    if value < self.MinLevelUnit or value > self.MaxLevelUnit then
        return
    end
    self.Slider.value = value
end

--选择消耗类型
function XUiEquipCulture:OnSelectConsumeType(consumeTypes, value)
    for _, consumeType in pairs(consumeTypes) do
        if not value then
            self.ConsumeTypeDic[consumeType] = nil
        else
            self.ConsumeTypeDic[consumeType] = true
        end
    end

    --更新可消耗列表
    self:UpdateRecommendConsumeItems()
end

function XUiEquipCulture:OnClickBtnPreview()
    --未选择目标等级
    if self.TargetLevelUnit == self.MinLevelUnit then
        XUiManager.TipText("EquipMultiStrengthenNotSelectLevel")
        return
    end

    --升级素材不足
    if not self.CanLevelUp then
        local skipIds = XDataCenter.EquipManager.GetEquipEatSkipIds(XEquipConfig.EatType.Item, self.EquipId)
        XLuaUiManager.Open("UiEquipStrengthenSkip", skipIds)
        return
    end

    local sortedConsumes = XDataCenter.EquipManager.GetSortedConsumes(self.Consumes)
    XLuaUiManager.Open("UiEquipStrengthenConsumption", sortedConsumes)
end

function XUiEquipCulture:OnClickBtnEvoConfirm()
    --未选择目标等级
    if self.TargetLevelUnit == self.MinLevelUnit then
        XUiManager.TipText("EquipMultiStrengthenNotSelectLevel")
        return
    end

    --未达到突破条件
    if not self.PassCondition then
        XUiManager.TipMsg(self.ConditionDesc)
        return
    end

    --强化/突破素材不足
    if not self.CanBreakThrough or not self.CanLevelUp then
        XUiManager.TipText("EquipMultiStrengthenItemNotEnough")
        return
    end

    --货币不足
    if
        not XDataCenter.ItemManager.DoNotEnoughBuyAsset(
            XDataCenter.ItemManager.ItemId.Coin,
            self.CostMoney,
            1,
            function()
                self:OnClickBtnEvoConfirm()
            end,
            "EquipMultiStrengthenCoinNotEnough"
        )
     then
        return
    end

    if XLuaUiManager.IsUiShow("UiEquipCultureConfirm") then
        return
    end

    --打开确认培养弹窗
    XLuaUiManager.Open(
        "UiEquipCultureConfirm",
        self.EquipId,
        self.MinLevelUnit,
        self.TargetLevelUnit,
        self.RealTargetLevel,
        self.Operations
    )
end
