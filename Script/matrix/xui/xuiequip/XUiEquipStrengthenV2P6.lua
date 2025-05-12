local XUiEquipStrengthenV2P6 = XLuaUiManager.Register(XLuaUi, "UiEquipStrengthenV2P6")
local XEquipLevelUpConsume = require("XEntity/XEquip/XEquipLevelUpConsume")

local XUiGridCostItem = require("XUi/XUiEquipBreakThrough/XUiGridCostItem")
local XUiGridEquipReplaceAttr = require("XUi/XUiEquipReplaceNew/XUiGridEquipReplaceAttr")
local TIP_COLOR = XUiHelper.Hexcolor2Color("EE2323FF") --文本警示色
local ToInt = XMath.ToInt
local SELECT = CS.UiButtonState.Select
local NORMAL = CS.UiButtonState.Normal

function XUiEquipStrengthenV2P6:OnAwake()
    -- 强化消耗范围复选框（勾选除了【5星】外的所有素材种类）
    self.BtnSelectDic = {
        TgDaoJu = true,
        Tg3Xing = true,
        Tg4Xing = true,
        Tg5Xing = false,
    }
    for btnName, isSelect in pairs(self.BtnSelectDic) do
        local state = isSelect and SELECT or NORMAL
        local btn = self[btnName]
        btn:SetButtonState(state)
    end

    self.GridCostItem.gameObject:SetActiveEx(false)
    self.Slider.value = 0

    self.GridCostItems = {}
    self:SetButtonCallBack()
end

function XUiEquipStrengthenV2P6:OnStart(parent)
    self.Parent = parent
end

function XUiEquipStrengthenV2P6:OnEnable()
    self.EquipId = self.Parent.EquipId
    self.TemplateId = XMVCA:GetAgency(ModuleId.XEquip):GetEquipTemplateId(self.EquipId)
    self.MaxLevelUnit = self._Control:GetEquipMaxLevelUnit(self.TemplateId)
    self.MaxBreakthrough = self._Control:GetEquipMaxBreakthrough(self.TemplateId)

    self:InitSliderBg()
    self:UpdateView()
end

function XUiEquipStrengthenV2P6:OnGetEvents()
    return {
        XEventId.EVENT_EQUIP_QUICK_STRENGTHEN_NOTYFY,
        XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XDataCenter.ItemManager.ItemId.Coin
    }
end

function XUiEquipStrengthenV2P6:OnNotify(evt, ...)
    local args = {...}

    if evt == XEventId.EVENT_EQUIP_QUICK_STRENGTHEN_NOTYFY then
        self:UpdateView()
    elseif evt == XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XDataCenter.ItemManager.ItemId.Coin then
        self:UpdateCostMoney()
        self:UpdateLevel()
    end
end

function XUiEquipStrengthenV2P6:SetButtonCallBack()
    self:RegisterClickEvent(self.BtnPreview, self.OnClickBtnPreview)
    self:RegisterClickEvent(self.BtnGetMaterial, self.OnClickBtnGetMaterial)
    self:RegisterClickEvent(self.BtnStrengthen, self.OnClickBtnStrengthen)
    self:RegisterClickEvent(self.BtnAdd, self.OnClickBtnAdd)
    self:RegisterClickEvent(self.BtnSub, self.OnClickBtnSub)
    self:RegisterClickEvent(self.BtnMax, self.OnClickBtnMax)

    self.Slider.onValueChanged:AddListener(handler(self, self.OnSliderValueChanged))
    self:RegisterClickEvent(self.TgDaoJu, function() self:OnClickTag("TgDaoJu") end)
    self:RegisterClickEvent(self.Tg3Xing, function() self:OnClickTag("Tg3Xing") end)
    self:RegisterClickEvent(self.Tg4Xing, function() self:OnClickTag("Tg4Xing") end)
    self:RegisterClickEvent(self.Tg5Xing, function() self:OnClickTag("Tg5Xing") end)
end

-- 设置滑动条
function XUiEquipStrengthenV2P6:SetSliderValue(value)
    if value < self.MinLevelUnit or value > self.MaxLevelUnit then
        return
    end
    local isSame = self.TargetLevelUnit == value
    self.Slider.value = value
    if isSame then
        self:OnSliderValueChanged()
    end
end

-- 预览
function XUiEquipStrengthenV2P6:OnClickBtnPreview()
    if #self.AllConsumeItems == 0 then
        XUiManager.TipText("EquipStrengthenNoItemTips")
        return
    end

    local cloneCosumes = XTool.Clone(self.AllConsumeItems)
    XLuaUiManager.Open("UiEquipStrengthenConsumptionV2P6", self.EquipId, cloneCosumes, function(consumes, breakthrough, level, addExp, costMoney, operations, showExpOverflowConfirm)
        self:OnCosumesChange(consumes, breakthrough, level, addExp, costMoney, operations, showExpOverflowConfirm)
    end)
end

function XUiEquipStrengthenV2P6:OnClickBtnGetMaterial()
    local site = self._Control:GetEquipSite(self.TemplateId)
    local skipIds = self._Control:GetEquipEatSkipIds(XEnumConst.EQUIP.EAT_TYPE.EQUIP, site)
    XLuaUiManager.Open("UiEquipStrengthenSkip", skipIds)
end

function XUiEquipStrengthenV2P6:OnClickBtnStrengthen()
    --未选择目标等级
    if not self.Operations or #self.Operations == 0 then
        XUiManager.TipText("EquipMultiStrengthenNotSelectLevel")
        return
    end

    --未达到突破条件
    if self.TargetBreakthrough ~= 0 and not self.ReachBreakCondition then
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
                self:OnClickBtnStrengthen()
            end,
            "EquipMultiStrengthenCoinNotEnough"
        )
     then
        return
    end

    if XLuaUiManager.IsUiShow("UiEquipCultureConfirm") then
        return
    end

    self:OpenConsumeStarConfirm()
end

-- 二次确认 消耗装备星级太高
function XUiEquipStrengthenV2P6:OpenConsumeStarConfirm()
    local needComfirm = false
    for _, operation in ipairs(self.Operations) do
        for equipId in pairs(operation.UseEquipIdDic) do
            local equipTemplateId = XMVCA:GetAgency(ModuleId.XEquip):GetEquipTemplateId(equipId)
            local star = XMVCA:GetAgency(ModuleId.XEquip):GetEquipStar(equipTemplateId)
            if star >= XEnumConst.EQUIP.CAN_NOT_AUTO_EAT_STAR then
                needComfirm = true
                break
            end
        end
    end
    if needComfirm then
        local title = XUiHelper.GetText("EquipStrengthenPreciousTipTitle")
        local content = XUiHelper.GetText("EquipStrengthenPreciousTipContent")
        XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
            self:OpenkExpOverflowConfirm()
        end)
    else
        self:OpenkExpOverflowConfirm()
    end
end

-- 二次确认 经验溢出
function XUiEquipStrengthenV2P6:OpenkExpOverflowConfirm()
    if self.ShowExpOverflowConfirm then
        local title = XUiHelper.GetText("EquipStrengthenPreciousTipTitle")
        local content = XUiHelper.GetText("EquipStrengthenExpOverflowTips")
        XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
            self:OpenUiEquipCultureConfirm()
        end)
    else
        self:OpenUiEquipCultureConfirm()
    end
end

function XUiEquipStrengthenV2P6:OpenUiEquipCultureConfirm()
    XLuaUiManager.Open("UiEquipCultureConfirm", self.EquipId, self.MinLevelUnit, self.TargetLevelUnit, self.RealLevel, self.Operations)
end

function XUiEquipStrengthenV2P6:OnClickBtnAdd()
    self:SetSliderValue(self.TargetLevelUnit + 1)
end

function XUiEquipStrengthenV2P6:OnClickBtnSub()
    self:SetSliderValue(self.TargetLevelUnit - 1)
end

function XUiEquipStrengthenV2P6:OnClickBtnMax()
    local maxTargetLevelUnit = self:GetStrengthenMaxTarget(self.EquipId, self.AllConsumeItems)
    self:SetSliderValue(maxTargetLevelUnit)
end

function XUiEquipStrengthenV2P6:OnClickTag(btnName)
    self.BtnSelectDic[btnName] = not self.BtnSelectDic[btnName]
    local state = self.BtnSelectDic[btnName] and SELECT or NORMAL
    self[btnName]:SetButtonState(state)
    self[btnName].TempState = state
    self:UpdateSelectConsumeType()
end

function XUiEquipStrengthenV2P6:InitSliderBg()
    local star = XMVCA:GetAgency(ModuleId.XEquip):GetEquipQuality(self.TemplateId)
    local sliderPath = CS.XGame.ClientConfig:GetString("EquipStrengthenProgressStar" .. star)
    self.SliderBackground:SetSprite(sliderPath)
    self.ImgSliderFil:SetSprite(sliderPath)
end

-- 刷新界面
function XUiEquipStrengthenV2P6:UpdateView()
    local equipId = self.EquipId

    local isMaxLevel = XMVCA.XEquip:IsMaxLevelAndBreakthrough(equipId)
    if isMaxLevel then
        self.Parent:CloseWithSelectCurEquip()
        return
    end

    local equip = XMVCA.XEquip:GetEquip(self.EquipId)
    local curLevelUnit = self._Control:GetEquipLevelUnit(equipId)
    self.MinLevelUnit = curLevelUnit
    self.TargetLevelUnit = curLevelUnit
    self:UpdateSelectConsumeType()

    --更新滑动条可滑动区域等级单位范围
    self.Slider:SetBorderValue(self.MinLevelUnit, self.MaxLevelUnit) 

    --重新进入界面，滑动条都到装备当前等级处
    self.Slider.minValue = 1 --最小值代表等级单位
    self.Slider.maxValue = self.MaxLevelUnit --最大值代表等级单位
    self.Slider.value = curLevelUnit
end

--#region 根据等级刷新预览

--滑动条变化回调
function XUiEquipStrengthenV2P6:OnSliderValueChanged()
    --手动修改消耗道具，只刷新进度条，不触发事件
    if self.IgnoreSliderEvent then 
        return
    end

    self.TargetLevelUnit = ToInt(self.Slider.value)

    --更新消耗
    self:UpdateByLevel()
end

-- 刷新选中的消耗类型
function XUiEquipStrengthenV2P6:UpdateSelectConsumeType()
    local isConsumeItem = self.BtnSelectDic["TgDaoJu"] --是否消耗道具
    local consumeStarDic = {} --消耗星级，1-5代表装备星级

    if self.BtnSelectDic["Tg3Xing"] then
        consumeStarDic[1] = true
        consumeStarDic[2] = true
        consumeStarDic[3] = true
    end

    if self.BtnSelectDic["Tg4Xing"] then
        consumeStarDic[4] = true
    end

    if self.BtnSelectDic["Tg5Xing"] then
        consumeStarDic[5] = true
    end

    --更新可消耗列表
    self.AllConsumeItems = self:GetAllConsumeItems(isConsumeItem, consumeStarDic)
    table.sort(self.AllConsumeItems, self.EatOrderSort)

    --通过等级刷新界面
    self:UpdateByLevel()
end

--通过目标等级刷新消耗界面
function XUiEquipStrengthenV2P6:UpdateByLevel()
    local equipId = self.EquipId
    local targetBreakthrough, targetLevel = self._Control:ConvertToBreakThroughAndLevel(self.TemplateId, self.TargetLevelUnit)

    -- 突破消耗
    local breakthroughCostMoney, canBreakThrough = self:UpdateBreakthrough(targetBreakthrough)

    --升级消耗
    local canLevelUp, totalExp, levelUpCostMoney, realLevel, operations, showExpOverflowConfirm, needExp
        = self:TryMultiLevelUp(equipId, targetBreakthrough, targetLevel, self.AllConsumeItems)

    -- 缓存变量
    self.TargetBreakthrough = targetBreakthrough --对应突破阶段
    self.TargetLevel = targetLevel
    self.RealLevel = realLevel --对应突破阶段的真实等级

    self.CanBreakThrough = canBreakThrough --突破素材是否足够
    self.CanLevelUp = canLevelUp --升级素材是否足够
    self.CostMoney = breakthroughCostMoney + levelUpCostMoney --总消耗货币
    self.Operations = operations --升级/突破 消耗操作列表
    self.ShowExpOverflowConfirm = showExpOverflowConfirm -- 经验溢出二次确认

    self:UpdateCostMoney()
    self:UpdateLevel()
    self:UpdateEquipAttr()
    self:UpdateCostExp(totalExp, needExp)
end

--根据传入的已排序消耗物品列表，计算出满足目标等级的最终经验及升级消耗（只计算升级消耗，不计算突破）
function XUiEquipStrengthenV2P6:TryMultiLevelUp(equipId, targetBreakthrough, targetLevel, consumes)
    --是否满足消耗条件, 总经验（包含溢出）, 升级总消耗货币, 实际到达等级, 记录每单次突破下升级消耗操作列表（服务端要求）
    local canLevelUp, totalExp, levelUpCostMoney, realTargetLevel, operations, showExpOverflowConfirm = true, 0, 0, targetLevel, {}, false
    local needExp = 0

    --重置选择消耗列表
    for _, consume in pairs(consumes) do
        consume:Reset()
    end

    local templateId = XMVCA:GetAgency(ModuleId.XEquip):GetEquipTemplateId(equipId)
    local equip = XMVCA.XEquip:GetEquip(equipId)
    local curLevel = equip.Level
    local curExp = equip.Exp
    local tmpTargeLv, tmpMaxLv
    local curBreakthrough = equip.Breakthrough
    for breakthrough = curBreakthrough, targetBreakthrough do
        tmpMaxLv = XMVCA.XEquip:GetEquipBreakthroughLevelLimit(templateId, breakthrough)
        if breakthrough ~= targetBreakthrough then
            tmpTargeLv = tmpMaxLv
        else
            tmpTargeLv = targetLevel
        end
        --遍历时，阶段与装备当前阶段不同，装备的当前经验不参与计算
        if curBreakthrough ~= breakthrough then
            curExp = 0
        end

        local tempCanLevelUp, tmpTotalExp, tmpCostMoney, tmpNeedExp = self:DoSingleLevelUp(templateId, breakthrough, curLevel, curExp, tmpTargeLv, consumes, operations)
        local needComfirm = self:CheckExpOverflowConfirm(breakthrough, tmpMaxLv, tmpTotalExp)
        if needComfirm then
            showExpOverflowConfirm = true
        end
        if tmpNeedExp > tmpTotalExp then
            needExp = needExp + (tmpNeedExp - tmpTotalExp)
        end

        --若不是最终突破次数, 修正总经验至当前突破次数满等级所需经验, 否则检查溢出经验是否足够再次升级
        if tmpTotalExp > tmpNeedExp then
            if breakthrough == targetBreakthrough then
                --尝试用溢出经验再次升级
                local level = tmpTargeLv
                local overExp = tmpTotalExp - tmpNeedExp
                while true do
                    if level == tmpMaxLv then
                        break
                    end
                    local levelUpCfg = self._Control:GetLevelUpCfg(templateId, breakthrough, level)
                    overExp = overExp - levelUpCfg.Exp
                    if overExp < 0 then
                        break
                    end
                    realTargetLevel = realTargetLevel + 1
                    level = level + 1
                end
            end
        end

        --将本次突破操作插入操作列表
        if breakthrough ~= targetBreakthrough then
            table.insert(
                operations,
                {
                    OperationType = 2,
                    UseEquipIdDic = {},
                    UseItems = {}
                }
            )
        end

        canLevelUp = canLevelUp and tempCanLevelUp
        totalExp = totalExp + tmpTotalExp
        levelUpCostMoney = levelUpCostMoney + tmpCostMoney
        curLevel = 1
        curExp = 0
    end
    totalExp = XMath.ToInt(totalExp)

    --是否满足消耗条件, 总经验（包含溢出）, 升级总消耗货币, 实际到达等级, 记录每单次突破下升级消耗操作列表（服务端要求）
    return canLevelUp, totalExp, levelUpCostMoney, realTargetLevel, operations, showExpOverflowConfirm, needExp
end

--单突破次数下强化到指定等级
function XUiEquipStrengthenV2P6:DoSingleLevelUp(templateId, breakthrough, curLevel, curExp, targetLevel, consumes, operations)
    --是否满足升级条件（经验达到目标等级）,消耗总提供经验（考虑溢出）,总消耗货币, 升到指定等级总所需经验,实际可到达等级（考虑所有消耗）
    local tmpCanLevelUp, tmpTotalExp, tmpCostMoney, needExp, canReachLevel = false, 0, 0, 0, 0

    --升级操作记录
    local operation = {
        OperationType = 1,
        UseEquipIdDic = {},
        UseItems = {},
        ConsumeInfoDic = {} --消耗信息字典
    }

    --先计算需要总经验
    for level = curLevel, targetLevel - 1 do
        local levelUpCfg = self._Control:GetLevelUpCfg(templateId, breakthrough, level)
        needExp = needExp + levelUpCfg.Exp
    end
    needExp = needExp - curExp
    --从消耗队列中顺序消耗，直至累积经验达到/超过所需总经验
    for index, consume in ipairs(consumes) do
        local id = consume.Id
        local canEatItemCount = consume:GetLeftCount()

        -- 不可被自动选取消耗
        if not consume.CanAutoSelect then
            goto CONTINUE_ONE
        end

        --检查是否已被操作过
        for _, inOperation in pairs(operations) do
            --上一轮操作已经吃过这个装备
            if inOperation.UseEquipIdDic[id] then
                goto CONTINUE_ONE
            end
        end

        --依次消耗
        for i = 1, canEatItemCount do
            if tmpTotalExp >= needExp then
                goto CONTINUE_ONE
            end

            consume:Eat()
            tmpTotalExp = tmpTotalExp + consume:GetAddExp()
            tmpCostMoney = tmpCostMoney + consume:GetCostMoney()

            --记录消耗
            local count = 0
            if consume:IsEquip() then
                count = 1
                operation.UseEquipIdDic[id] = true
            else
                count = operation.UseItems[id] or 0
                count = count + 1
                operation.UseItems[id] = count
            end
            operation.ConsumeInfoDic[index] = count
        end

        ::CONTINUE_ONE::
    end
    --尝试从消耗队列中顺序去除多余的消耗，直至累积经验刚好满足所需总经验
    for index, consume in ipairs(consumes) do
        local id = consume.Id
        local hasEatItemCount  --本轮强化吃掉的数量

        if consume:IsEquip() then
            --检查本轮是否有吃掉这个装备
            if not operation.UseEquipIdDic[id] then
                goto CONTINUE_TWO
            end
            hasEatItemCount = 1
        else
            --检查本轮是否有吃掉这个道具
            hasEatItemCount = operation.UseItems[id]
            if not hasEatItemCount then
                goto CONTINUE_TWO
            end
        end

        --依次去除消耗
        while true do
            if hasEatItemCount < 1 then
                goto CONTINUE_TWO
            end

            --经验已经满足
            local exp = consume:GetAddExp()
            if tmpTotalExp - exp < needExp then
                goto CONTINUE_TWO
            end

            consume:Vomit()
            tmpTotalExp = tmpTotalExp - exp
            tmpCostMoney = tmpCostMoney - consume:GetCostMoney()

            --记录去除消耗
            if consume:IsEquip() then
                hasEatItemCount = 0
                operation.UseEquipIdDic[consume.Id] = nil
                operation.ConsumeInfoDic[index] = nil
            else
                hasEatItemCount = hasEatItemCount - 1
                operation.UseItems[consume.Id] = hasEatItemCount
                operation.ConsumeInfoDic[index] = hasEatItemCount
                if hasEatItemCount < 1 then
                    operation.UseItems[consume.Id] = nil
                    operation.ConsumeInfoDic[index] = nil
                end
            end
        end

        ::CONTINUE_TWO::
    end

    --是否满足升级条件（经验达到目标等级）
    tmpCanLevelUp = tmpTotalExp >= needExp

    --将本次升级操作插入操作列表
    if needExp > 0 then
        table.insert(operations, operation)
    end

    return tmpCanLevelUp, tmpTotalExp, tmpCostMoney, needExp
end

function XUiEquipStrengthenV2P6:CheckExpOverflowConfirm(breakthrough, levelLimit, allExp)
    local levelCfg = self._Control:GetLevelUpCfg(self.TemplateId, breakthrough, levelLimit)
    local needComfirm = (allExp - levelCfg.AllExp) > XEnumConst.EQUIP.STRENGTHEN_EXP_OVERFLOW_CONFIRM
    return needComfirm
end

-- 获取强化的最高目标等级
function XUiEquipStrengthenV2P6:GetStrengthenMaxTarget(equipId, consumes)
    local templateId = self.TemplateId
    --装备信息
    local equip = XMVCA.XEquip:GetEquip(equipId)
    --当前等级单元
    local curLevelUnit = self._Control:ConvertToLevelUnit(templateId, equip.Breakthrough, equip.Level)
    --最大突破阶段
    local maxBreakthrough = XMVCA.XEquip:GetEquipMaxBreakthrough(templateId)
    --最大突破阶段的最大等级
    local maxLevel = XMVCA.XEquip:GetEquipBreakthroughLevelLimit(templateId, maxBreakthrough)
    --最大等级单元
    local maxLevelUnit = self._Control:ConvertToLevelUnit(templateId, maxBreakthrough, maxLevel)
    --当前剩余的螺母
    local leftMoney = XDataCenter.ItemManager.GetCoinsNum()

    -- 检查是否能够升到对应等级
    local CheckEnoughLevelUp = function(levelUnit)
        local targetBreakthrough, targetLevel = self._Control:ConvertToBreakThroughAndLevel(templateId, levelUnit)
        local canLevelUp, totalExp, levelUpCostMoney, realTargetLevel, operations = self:TryMultiLevelUp(equipId, targetBreakthrough, targetLevel, consumes)
        
        -- 强化素材不足
        if not canLevelUp then
            return false
        end

        -- 消耗的总金币不足
        local breakthroughCostMoney = self._Control:GetMutiBreakthroughUseMoney(equipId, targetBreakthrough)
        local costMoney = breakthroughCostMoney + levelUpCostMoney
        if leftMoney < costMoney then
            return false
        end

        --突破条件
        local passCondition, _ = self._Control:CheckBreakthroughCondition(templateId, targetBreakthrough)
        local _, canBreakThrough = self._Control:GetMutiBreakthroughConsumeItems(equipId, targetBreakthrough)
        if not (passCondition and canBreakThrough) then -- 不满足培养条件
            return false
        end

        return true
    end

    -- 二分查找最高等级
    local low = curLevelUnit
    local high = maxLevelUnit
    while(low < high)
    do
        local levelUnit = math.ceil((low + high) / 2)
        local isEnough = CheckEnoughLevelUp(levelUnit)
        if isEnough then
            low = levelUnit
        else
            high = levelUnit - 1
        end
    end

    return low
end

-- 根据消耗优先级排序
function XUiEquipStrengthenV2P6.EatOrderSort(consumeA, consumeB)
    --提供经验从小到大
    if consumeA.AddExp ~= consumeB.AddExp then
        return consumeA.AddExp < consumeB.AddExp
    end

    --货币消耗从小到大
    if consumeA.CostMoney ~= consumeB.CostMoney then
        return consumeA.CostMoney < consumeB.CostMoney
    end

    --消耗类型（装备优先于道具）
    if consumeA.Type ~= consumeB.Type then
        return consumeA:IsEquip()
    end

    --Id从小到大
    return consumeA.Id < consumeB.Id
end
--#endregion 根据等级刷新预览


--#region 根据消耗列表刷新预览
-- 手动改变消耗列表
function XUiEquipStrengthenV2P6:OnCosumesChange(consumes, breakthrough, level, addExp, levelUpCostMoney, operations, showExpOverflowConfirm)
    self.AllConsumeItems = consumes
    local breakthroughCostMoney, canBreakThrough = self:UpdateBreakthrough(breakthrough)

    -- 缓存变量
    self.TargetLevelUnit = self._Control:ConvertToLevelUnit(self.TemplateId, breakthrough, level) --目标总等级
    self.TargetBreakthrough = breakthrough --对应突破阶段
    self.TargetLevel = level -- 对应等级
    self.RealLevel = level -- 对应突破阶段的真实等级

    self.CanLevelUp = true --升级素材是否足够
    self.CanBreakThrough = canBreakThrough --突破素材是否足够
    self.CostMoney = levelUpCostMoney + breakthroughCostMoney

    self.Operations = operations --升级/突破 消耗操作列表
    self.ShowExpOverflowConfirm = showExpOverflowConfirm -- 经验溢出二次确认

    self:UpdateCostMoney()
    self:UpdateLevel()
    self:UpdateEquipAttr()
    self.IgnoreSliderEvent = true
    self:SetSliderValue(self.TargetLevelUnit)
    self.IgnoreSliderEvent = false
    self:UpdateCostExp(addExp)
end
--#endregion 根据消耗列表刷新预览

--根据传入的消耗类型字典 返回可消耗物品/装备排序列表
function XUiEquipStrengthenV2P6:GetAllConsumeItems(isConsumeItem, consumeStarDic)
    local result = {}

    if isConsumeItem then 
        local itemIdList = XMVCA.XEquip:GetCanEatItemIds(self.EquipId)
        for _, itemId in pairs(itemIdList) do
            local obj = XEquipLevelUpConsume.New()
            obj:InitItem(itemId)
            table.insert(result, obj)
        end
    end

    local CheckStar = function(equipId)
        local templateId = XMVCA:GetAgency(ModuleId.XEquip):GetEquipTemplateId(equipId)
        local star = XMVCA.XEquip:GetEquipStar(templateId)
        return consumeStarDic[star] == true
    end

    local equipIds = XMVCA.XEquip:GetCanEatEquipIds(self.EquipId)
    for _, equipId in pairs(equipIds) do
        if CheckStar(equipId) then
            -- 是否可被自动选取
            local canAutoSelect = XMVCA.XEquip:IsEquipRecomendedToBeEat(self.EquipId, equipId, true)

            local obj = XEquipLevelUpConsume.New()
            obj:InitEquip(equipId, canAutoSelect)
            table.insert(result, obj)
        end
    end
    return result
end

-- 刷新等级
function XUiEquipStrengthenV2P6:UpdateLevel()
    if self.ColorTxtLv == nil then
        self.ColorTxtLv = self.TxtLv.color
    end

    --等级，突破显示
    local breakThroughIcon = self._Control:GetEquipBreakThroughIcon(self.TargetBreakthrough)
    self.ImgBreak:SetSprite(breakThroughIcon)
    local levelLimit = XMVCA.XEquip:GetEquipBreakthroughLevelLimit(self.TemplateId, self.TargetBreakthrough)
    self.TxtLv.text = self.TargetLevel
    self.TxtLvMax.text = "/" .. levelLimit

    local notStrengthen = not self.IsMoneyEnough or
        (self.TargetLevelUnit ~= self.MinLevelUnit and not self.CanLevelUp) or
        (self.TargetBreakthrough ~= 0 and not self.CanBreakThrough)
    self.TxtLv.color = notStrengthen and TIP_COLOR or self.ColorTxtLv

    -- 刷新加减按钮状态
    local isReach = self.TargetLevelUnit <= self.MinLevelUnit
    self.BtnSub:SetDisable(isReach, not isReach)
    isReach = self.TargetLevelUnit >= self.MaxLevelUnit
    self.BtnAdd:SetDisable(isReach, not isReach)
end

-- 刷新属性
function XUiEquipStrengthenV2P6:UpdateEquipAttr()
    local curAttrMap = XMVCA:GetAgency(ModuleId.XEquip):GetEquipAttrMap(self.EquipId)
    local targetBreakthrough, targetLevel = self._Control:ConvertToBreakThroughAndLevel(self.TemplateId, self.TargetLevelUnit)
    local preAttrMap = XMVCA:GetAgency(ModuleId.XEquip):GetEquipAttrMap(self.EquipId, targetBreakthrough, targetLevel)

    for attrIndex, attrInfo in pairs(curAttrMap) do
        local uiObj = self["PanelAttr" .. attrIndex]
        uiObj:GetObject("TxtName").text = attrInfo.Name
        uiObj:GetObject("TxtCurAttr").text = attrInfo.Value

        local preAttrInfo = preAttrMap[attrIndex]
        local isShowArrow = attrInfo.Value ~= preAttrInfo.Value
        uiObj:GetObject("ImgArrow").gameObject:SetActiveEx(isShowArrow)
        local txtNextAttr = uiObj:GetObject("TxtNextAttr")
        txtNextAttr.gameObject:SetActiveEx(isShowArrow)
        if isShowArrow then 
            txtNextAttr.text = preAttrInfo.Value
        end
    end
end

-- 刷新强化消耗的经验
function XUiEquipStrengthenV2P6:UpdateCostExp(totalExp, needExp)
    if self.ColorTxtExp == nil then
        self.ColorTxtExp = self.TxtExp.color
    end

    if needExp and needExp > 0 then
        self.TxtExp.text = string.format("%s(-%s)", math.floor(totalExp), math.floor(needExp))
        self.TxtExp.color = TIP_COLOR
    else
        self.TxtExp.text = tostring(math.floor(totalExp))
        self.TxtExp.color = self.ColorTxtExp
    end
end

-- 刷新突破
function XUiEquipStrengthenV2P6:UpdateBreakthrough(targetBreakthrough)
    --突破需要的螺母
    local breakthroughCostMoney = self._Control:GetMutiBreakthroughUseMoney(self.EquipId, targetBreakthrough)

    -- 下一突破条件
    local equip = XMVCA.XEquip:GetEquip(self.EquipId)
    local nextReach, nextDesc = self._Control:CheckBreakthroughCondition(self.TemplateId, equip.Breakthrough + 1)

    -- 目标突破条件
    self.ReachBreakCondition, self.ConditionDesc = self._Control:CheckBreakthroughCondition(self.TemplateId, targetBreakthrough)
    
    -- 刷新突破条件/突破消耗
    self.PanelBreachNeed.gameObject:SetActiveEx(not nextReach)
    self.PanelBreachConsume.gameObject:SetActiveEx(nextReach)
    if not nextReach then
        self.TxtNotPass.text = nextDesc
        local canBreakThrough = targetBreakthrough == equip.Breakthrough -- 当前等级不用突破
        return breakthroughCostMoney, canBreakThrough
    else
        -- 目标突破的消耗
        local consumeItems, canBreakThrough = self._Control:GetMutiBreakthroughConsumeItems(self.EquipId, targetBreakthrough)
        local isEmpty = XTool.IsTableEmpty(consumeItems)
        self.PanelBreakthroughConsume.gameObject:SetActiveEx(not isEmpty)
        if not isEmpty then
            for index, item in ipairs(consumeItems) do
                local grid = self.GridCostItems[index]
                if not grid then
                    local ui = CSObjectInstantiate(self.GridCostItem, self.PanelCostItem)
                    grid = XUiGridCostItem.New(self, ui)
                    table.insert(self.GridCostItems, grid)
                end
                grid:Refresh(item.Id, item.Count)
                grid.GameObject:SetActiveEx(true)
            end
            for i = #consumeItems + 1, #self.GridCostItems do
                self.GridCostItems[i].GameObject:SetActiveEx(false)
            end
        end

        return breakthroughCostMoney, canBreakThrough
    end
end

-- 刷新需要的螺母
function XUiEquipStrengthenV2P6:UpdateCostMoney()
    if self.ColorTxtCost == nil then
        self.ColorTxtCost = self.TxtCost.color
    end

    self.IsMoneyEnough = XDataCenter.ItemManager.GetCoinsNum() >= self.CostMoney
    self.TxtCost.text = self.CostMoney
    self.TxtCost.color = self.IsMoneyEnough and self.ColorTxtCost or TIP_COLOR
end

return XUiEquipStrengthenV2P6
