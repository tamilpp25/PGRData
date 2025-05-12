local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridConsumption = require("XUi/XUiEquip/XUiGridEquipStrengthenConsumptionV2P6")

--一键培养消耗预览弹窗
local XUiEquipStrengthenConsumptionV2P6 = XLuaUiManager.Register(XLuaUi, "UiEquipStrengthenConsumptionV2P6")

function XUiEquipStrengthenConsumptionV2P6:OnAwake()
    self:SetButtonCallBack()

    self.GridConsume.gameObject:SetActiveEx(false)

    self.DynamicTable = XDynamicTableNormal.New(self.PanelEquipScroll)
    self.DynamicTable:SetProxy(XUiGridConsumption)
    self.DynamicTable:SetDelegate(self)
end

function XUiEquipStrengthenConsumptionV2P6:OnStart(equipId, consumes, changeCb)
    self.EquipId = equipId
    self.TemplateId = XMVCA.XEquip:GetEquipTemplateId(equipId)
    self.Consumes = consumes
    self.ChangeCb = changeCb

    -- 展示用的列表
    self.ShowConsumes = {}
    for _, consume in ipairs(consumes) do
        table.insert(self.ShowConsumes, consume)
    end
    table.sort(self.ShowConsumes, self.ShowOrderSort)

    -- 刷新列表
    self.DynamicTable:SetDataSource(self.ShowConsumes)
    self.DynamicTable:ReloadDataSync()
end

function XUiEquipStrengthenConsumptionV2P6:OnEnable()
    self:RefreshStrengthPreviewInfo()
end

function XUiEquipStrengthenConsumptionV2P6:SetButtonCallBack()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnCloseMask, self.Close)
    self:RegisterClickEvent(self.BtnDetermine, self.OnClickBtnDetermine)
end

function XUiEquipStrengthenConsumptionV2P6:OnClickBtnDetermine()
    if self.ChangeCb then
        local isConsumeOverflow, breakthrough, level, addExp, costMoney, operations, showExpOverflowConfirm = self:CalculateCosumes(self.Consumes)
        self.ChangeCb(self.Consumes, breakthrough, level, addExp, costMoney, operations, showExpOverflowConfirm)
    end
    self:Close()
end

function XUiEquipStrengthenConsumptionV2P6:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self, index, self.ShowConsumes[index])
    end
end

function XUiEquipStrengthenConsumptionV2P6:OnReduceConsume(index)
    local cosume = self.ShowConsumes[index]
    if cosume:IsSelect() then
        cosume:Vomit()
        local grid = self.DynamicTable:GetGridByIndex(index)
        grid:Refresh(self, index, cosume)
        self:RefreshStrengthPreviewInfo()
    end
end

function XUiEquipStrengthenConsumptionV2P6:OnAddConsume(index)
    local isMaxLevel = self:CalculateCosumes(self.Consumes)
    if isMaxLevel then
        XUiManager.TipText("EquipStrengthenMaxLevel")
        return
    end

    local cosume = self.ShowConsumes[index]
    if cosume:CheckSelectCount() then
        cosume:Eat()
        local grid = self.DynamicTable:GetGridByIndex(index)
        grid:Refresh(self, index, cosume)
        self:RefreshStrengthPreviewInfo()
    end
end

-- 计算消耗材料
function XUiEquipStrengthenConsumptionV2P6:CalculateCosumes(allConsumes)
    -- 筛选出已选中的材料，减少多层嵌套遍历的时间复杂度
    local selConsumes = {}
    for _, consume in ipairs(allConsumes) do
        if consume:IsSelect() then
            table.insert(selConsumes, consume)
        end
    end

    -- 从当前突破阶段开始计算到最大突破阶段
    local equip = XMVCA.XEquip:GetEquip(self.EquipId)
    local maxBreakthrough = self._Control:GetEquipMaxBreakthrough(self.TemplateId)
    local maxLevelLimit = self._Control:GetBreakthroughLevelLimit(self.TemplateId, maxBreakthrough)
    local eatCntDic = {}

    local reachBreakthrough = equip.Breakthrough
    local reachLevel = equip.Level
    local totalAddExp = 0
    local totalCostMoney = 0
    local operations = {}
    local showExpOverflowConfirm = false

    for breakthrough = equip.Breakthrough, maxBreakthrough do
        local curExp = 0
        local curLevel = 1
        if breakthrough == equip.Breakthrough then
            local levelCfg = self._Control:GetLevelUpCfg(self.TemplateId, equip.Breakthrough, equip.Level)
            curExp = equip.Exp + levelCfg.AllExp
            local curLevel = equip.Level
        end
        local levelLimit = self._Control:GetBreakthroughLevelLimit(self.TemplateId, breakthrough)

        local isReachLimit = curLevel >= levelLimit
        if not isReachLimit then
            local addExp, costMoney, operation
            reachLevel, isReachLimit, addExp, costMoney, operation = self:CalculateLevelUp(breakthrough, levelLimit, curExp, curLevel, selConsumes, eatCntDic)
            local needComfirm = self:CheckExpOverflowConfirm(breakthrough, levelLimit, (curExp + addExp))
            if needComfirm then
                showExpOverflowConfirm = true
            end
            
            reachBreakthrough = breakthrough
            totalAddExp = totalAddExp + addExp
            totalCostMoney = totalCostMoney + costMoney
            table.insert(operations, operation)
        end

        if isReachLimit then
            if breakthrough ~= maxBreakthrough then
                -- 刚好吃完所有东西，但是不满足突破条件，不进行此次突破
                local passCondition, _ = self._Control:CheckBreakthroughCondition(self.TemplateId, breakthrough + 1)
                local isEatAllConsume = self:IsEatAllConsume(selConsumes, eatCntDic)
                if isEatAllConsume and not passCondition then
                    break
                end

                -- 将本次突破操作插入操作列表
                local operation = { OperationType = 2, UseEquipIdDic = {}, UseItems = {} }
                table.insert(operations, operation)
            end
        else
            break
        end
    end

    -- 是否达到最大等级
    local isMaxLevel = reachBreakthrough == maxBreakthrough and reachLevel == maxLevelLimit

    return isMaxLevel, reachBreakthrough, reachLevel, totalAddExp, totalCostMoney, operations, showExpOverflowConfirm
end

-- 计算当前等级升级到等级，不考虑突破
function XUiEquipStrengthenConsumptionV2P6:CalculateLevelUp(breakthrough, levelLimit, curExp, curLevel, consumes, eatCntDic)
    -- 升级操作记录
    local operation = { OperationType = 1, UseEquipIdDic = {}, UseItems = {} }
    -- 缓存本次升级吃过的材料数量
    local tempEatIndexCntDic = {} 
    -- 消耗螺母
    local costMoney = 0
    -- 增加的经验
    local addExp = 0

    for index, consume in ipairs(consumes) do
        local id = consume.Id
        eatCntDic[id] = eatCntDic[id] or 0
        local leftCnt = consume.SelectCount - eatCntDic[id]
        while(leftCnt > 0) do
            -- 记录消耗
            if consume:IsEquip() then
                operation.UseEquipIdDic[id] = true
            else
                operation.UseItems[id] = (operation.UseItems[id] or 0) + 1
            end
            eatCntDic[id] = eatCntDic[id] + 1
            tempEatIndexCntDic[index] = (tempEatIndexCntDic[index] or 0) + 1
            leftCnt = leftCnt - 1

            -- 计算加上这1个材料能否升级
            addExp = addExp + consume:GetAddExp()
            costMoney = costMoney + consume:GetCostMoney()
            for level = curLevel+1, levelLimit do
                local levelCfg = self._Control:GetLevelUpCfg(self.TemplateId, breakthrough, level)
                if curExp + addExp >= levelCfg.AllExp then
                    curLevel = level
                    if curLevel >= levelLimit then
                        goto CONTINUE
                    end
                else
                    break
                end
            end
        end
    end

    ::CONTINUE::

    -- 尝试从消耗队列中顺序去除多余的消耗，即去掉消耗但是经验依旧满足所需总经验
    local isReachLimit = curLevel >= levelLimit
    if isReachLimit then
        local levelCfg = self._Control:GetLevelUpCfg(self.TemplateId, breakthrough, levelLimit)
        for index, cnt in pairs(tempEatIndexCntDic) do
            local consume = consumes[index]
            local exp = consume:GetAddExp()
            while(cnt > 0 and curExp + addExp - exp >= levelCfg.AllExp) do
                -- 更新消耗
                local id = consume.Id
                if consume:IsEquip() then
                    operation.UseEquipIdDic[id] = nil
                else
                    operation.UseItems[id] = operation.UseItems[id] - 1
                end
                eatCntDic[id] = eatCntDic[id] - 1
                cnt = cnt - 1

                addExp = addExp - consume:GetAddExp()
                costMoney = costMoney - consume:GetCostMoney()
            end
        end
    end

    -- 无材料可消耗，清空operation
    if addExp == 0 then
        operation = nil
    end
    return curLevel, isReachLimit, addExp, costMoney, operation
end

-- 根据展示的优先级排序
function XUiEquipStrengthenConsumptionV2P6.ShowOrderSort(consumeA, consumeB)
    --消耗类型（道具优先于装备）
    if consumeA.Type ~= consumeB.Type then
        return consumeA:IsItem()
    end
    
    --提供经验从小到大
    if consumeA.AddExp ~= consumeB.AddExp then
        return consumeA.AddExp < consumeB.AddExp
    end

    --货币消耗从小到大
    if consumeA.CostMoney ~= consumeB.CostMoney then
        return consumeA.CostMoney < consumeB.CostMoney
    end

    -- 配置表id
    if consumeA.TemplateId ~= consumeB.TemplateId then 
        return consumeA.TemplateId < consumeB.TemplateId
    end

    --Id从小到大
    return consumeA.Id < consumeB.Id
end

-- 是否吃完所有的材料
function XUiEquipStrengthenConsumptionV2P6:IsEatAllConsume(selConsumes, eatCntDic)
    for _, consume in ipairs(selConsumes) do
        if consume.SelectCount ~= eatCntDic[consume.Id] then
            return false
        end
    end

    return true
end

-- 检测是否需要弹经验溢出二次确认
function XUiEquipStrengthenConsumptionV2P6:CheckExpOverflowConfirm(breakthrough, levelLimit, allExp)
    local levelCfg = self._Control:GetLevelUpCfg(self.TemplateId, breakthrough, levelLimit)
    local needComfirm = (allExp - levelCfg.AllExp) > XEnumConst.EQUIP.STRENGTHEN_EXP_OVERFLOW_CONFIRM
    return needComfirm
end

-- 刷新强化预览信息
function XUiEquipStrengthenConsumptionV2P6:RefreshStrengthPreviewInfo()
    local isConsumeOverflow, breakthrough, level, addExp, costMoney, operations, showExpOverflowConfirm = self:CalculateCosumes(self.Consumes)
    self.TxtExp.text = tostring(math.floor(addExp))
    self.TxtLv.text = XUiHelper.GetText("GuildLevelDes", level)
    local breakThroughIcon = self._Control:GetEquipBreakThroughIcon(breakthrough)
    self.ImgBreak:SetSprite(breakThroughIcon)
end

return XUiEquipStrengthenConsumptionV2P6
