local XUiGridObtain = require("XUi/XUiFurnitureRecycleObtain/XUiGridObtain")
local XUiFurnitureObtain = XLuaUiManager.Register(XLuaUi, "UiFurnitureObtain")
local FurnitureState

function XUiFurnitureObtain:OnAwake()
    self:AddListener()
    FurnitureState = XFurnitureConfigs.FURNITURE_STATE
end

function XUiFurnitureObtain:AddListener()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnReset, self.OnBtnResetClick)
    self:RegisterClickEvent(self.BtnRecovery, self.OnBtnRecoveryClick)
    self:RegisterClickEvent(self.BtnRefit, self.OnBtnRefitClick)
    self:RegisterClickEvent(self.BtnBatchReset, self.OnBtnBatchResetClick)
    self:RegisterClickEvent(self.BtnBatchRecovery, self.OnBtnBatchRecoveryClick)
    self:RegisterClickEvent(self.BtnBatchRefit, self.OnBtnBatchRefitClick)
    self:RegisterClickEvent(self.TogLevelA, self.OnTogLevelAClick)
    self:RegisterClickEvent(self.TogLevelB, self.OnTogLevelBClick)
    self:RegisterClickEvent(self.TogLevelC, self.OnTogLevelCClick)
end

function XUiFurnitureObtain:OnStart(gainType, furnitueList, refitCallBack, createCoinCount, createPos, resetCallBack)
    self.ResetCallBack = resetCallBack
    self.RefitCallBack = refitCallBack
    self.FurnitureState = FurnitureState.DETAILS
    self.IsRecovery = false
    self.GainType = gainType
    self.CreateCoinCount = createCoinCount or 0
    self.CreatePos = createPos or 0

    self:InitFurnitureDatas(furnitueList)
    self:InitDynamicTable()
    self:InitBtnState()
end

function XUiFurnitureObtain:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_CLICKFURNITURE_GRID, self.OnObtainGridClick, self)
end

function XUiFurnitureObtain:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_CLICKFURNITURE_GRID, self.OnObtainGridClick, self)
end

function XUiFurnitureObtain:InitFurnitureDatas(furnitueList)
    self.FurnitureIds = {}
    self.FurnitureLevelDic = {}

    if not furnitueList or #furnitueList <= 0 then
        return
    end

    local white = XGoodsCommonManager.QualityType.White
    local greed = XGoodsCommonManager.QualityType.Greed
    local blue = XGoodsCommonManager.QualityType.Blue
    local purple = XGoodsCommonManager.QualityType.Purple
    local gold = XGoodsCommonManager.QualityType.Gold

    for _, furniture in ipairs(furnitueList) do
        table.insert(self.FurnitureIds, furniture.Id)

        local furnitureType = XDataCenter.FurnitureManager.GetFurnitureConfigByUniqueId(furniture.Id).TypeId
        local totalScore = XDataCenter.FurnitureManager.GetFurnitureScore(furniture.Id)
        local quality = XFurnitureConfigs.GetFurnitureTotalAttrLevel(furnitureType, totalScore)

        local insert = function(color, id)
            if not self.FurnitureLevelDic[color] then
                self.FurnitureLevelDic[color] = {}
            end
            table.insert(self.FurnitureLevelDic[color], id)
        end

        if quality == white then
            insert(white, furniture.Id)
        elseif quality == greed then
            insert(greed, furniture.Id)
        elseif quality == blue then
            insert(blue, furniture.Id)
        elseif quality == purple then
            insert(purple, furniture.Id)
        elseif quality >= gold then
            insert(gold, furniture.Id)
        end
    end
end

function XUiFurnitureObtain:InitDynamicTable()
    self.ObtainGrid.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamic)
    self.DynamicTable:SetProxy(XUiGridObtain)
    self.DynamicTable:SetDelegate(self)
end

--动态列表事件
function XUiFurnitureObtain:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.FurnitureIds[index]
        grid:Refresh(data, self.SelectQualityList)
    end
end

function XUiFurnitureObtain:UpdateDynamicTable()
    self.DynamicTable:SetDataSource(self.FurnitureIds)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiFurnitureObtain:InitBtnState()
    local isCreate = self.GainType == XFurnitureConfigs.GainType.Create
    self.BtnBatchReset.gameObject:SetActiveEx(isCreate)
    self.BtnBatchRefit.gameObject:SetActiveEx(not isCreate)
    local icon = XDataCenter.ItemManager.GetItemIcon(XDataCenter.ItemManager.ItemId.FurnitureCoin)
    self.RImgIcon:SetRawImage(icon)

    self:ChangeUiState()
end

function XUiFurnitureObtain:ChangeUiState()
    self.FurnitureSelectList = {}
    self.FurnitureSelectCount = 0
    self.SelectQualityList = {}

    if self.FurnitureState == FurnitureState.DETAILS then
        self.PanelBatch.gameObject:SetActiveEx(true)
        self.PanelEdit.gameObject:SetActiveEx(false)
    elseif self.FurnitureState == FurnitureState.SELECT then
        self.PanelBatch.gameObject:SetActiveEx(false)
        self.PanelEdit.gameObject:SetActiveEx(true)
        self.TogLevelA.isOn = false
        self.TogLevelB.isOn = false
        self.TogLevelC.isOn = false

        local isCreate = self.GainType == XFurnitureConfigs.GainType.Create
        self.BtnReset.gameObject:SetActiveEx(not self.IsRecovery and isCreate)
        self.BtnRefit.gameObject:SetActiveEx(not self.IsRecovery and not isCreate)
        self.TxtDesc.gameObject:SetActiveEx(self.IsRecovery or isCreate)
        self.BtnRecovery.gameObject:SetActiveEx(self.IsRecovery)

        if self.IsRecovery or isCreate then
            local text = self.IsRecovery and CS.XTextManager.GetText("DormObtainRecovery") or CS.XTextManager.GetText("DormObtainReset")
            self.TxtDesc.text = text
        end
        self:SetCoinCount()
    end

    self:UpdateDynamicTable()
end

function XUiFurnitureObtain:SetCoinCount()
    self.IsRefitCoinEnough = true
    if self.FurnitureSelectCount <= 0 then
        self.TxtCoin.text = 0
        return
    end

    local isCreate = self.GainType == XFurnitureConfigs.GainType.Create
    local getRewardCount = function()
        local count = 0
        local rewards = XDataCenter.FurnitureManager.GetRecycleRewards(self:GetFurnitureList())
        local coinId = XDataCenter.ItemManager.ItemId.FurnitureCoin
        for _, reward in ipairs(rewards) do
            local templateId = (reward.TemplateId and reward.TemplateId > 0) and reward.TemplateId or reward.Id
            if templateId == coinId then
                count = count + reward.Count
            end
        end
        return count
    end
    if self.IsRecovery then
        self.TxtCoin.text = getRewardCount()
    elseif isCreate then
        local rewardCount = getRewardCount()
        local createCount = self.CreateCoinCount * self.FurnitureSelectCount
        local count = (createCount - rewardCount) > 0 and createCount - rewardCount or 0
        local currentOwn = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.FurnitureCoin) + rewardCount
        self.IsRefitCoinEnough = currentOwn >= createCount
        self.TxtCoin.text = self.IsRefitCoinEnough and CS.XTextManager.GetText("DormBuildEnoughCount", count)
        or CS.XTextManager.GetText("DormBuildNoEnoughCount", count)
    end
end

function XUiFurnitureObtain:CheckIncludeLevelS()
    for id, _ in pairs(self.FurnitureSelectList) do
        local furnitureType = XDataCenter.FurnitureManager.GetFurnitureConfigByUniqueId(id).TypeId
        local totalScore = XDataCenter.FurnitureManager.GetFurnitureScore(id)
        local quality = XFurnitureConfigs.GetFurnitureTotalAttrLevel(furnitureType, totalScore)

        if quality >= XGoodsCommonManager.QualityType.Gold then
            return true
        end
    end

    return false
end

function XUiFurnitureObtain:GetGridSelected(id)
    if self.FurnitureState == XFurnitureConfigs.FURNITURE_STATE.SELECT then
        if self.FurnitureSelectCount <= 0 then
            return false
        end

        for myId, _ in pairs(self.FurnitureSelectList) do
            if myId == id then
                return true
            end
        end

        return false
    end

    return false
end

function XUiFurnitureObtain:GetFurnitureList()
    local list = {}
    for id, _ in pairs(self.FurnitureSelectList) do
        table.insert(list, id)
    end
    return list
end

function XUiFurnitureObtain:RemoveSelectQuality(quality, closeTog)
    local removeIndex
    for i, k in ipairs(self.SelectQualityList) do
        if k == quality then
            removeIndex = i
            break
        end
    end

    if removeIndex then
        table.remove(self.SelectQualityList, removeIndex)
    end

    if not closeTog then return end
    local white = XGoodsCommonManager.QualityType.White
    local greed = XGoodsCommonManager.QualityType.Greed
    local blue = XGoodsCommonManager.QualityType.Blue
    local purple = XGoodsCommonManager.QualityType.Purple

    if (quality == white or quality == greed) and self.TogLevelC.isOn then
        self.TogLevelC.isOn = false
    elseif quality == blue and self.TogLevelB.isOn then
        self.TogLevelB.isOn = false
    elseif quality == purple and self.TogLevelA.isOn then
        self.TogLevelA.isOn = false
    end
end

--------------------------------- 点击事件相关(Start) ---------------------------------
function XUiFurnitureObtain:OnObtainGridClick(furnitureId, furnitureConfigId, grid)
    if self.FurnitureState == FurnitureState.DETAILS then
        XLuaUiManager.Open("UiFurnitureDetail", furnitureId, furnitureConfigId, nil, nil, true, true)
    elseif self.FurnitureState == FurnitureState.SELECT then
        grid:SetSelected(not grid:IsSelected())
        for myId, _ in pairs(self.FurnitureSelectList) do
            if myId == furnitureId then
                self.FurnitureSelectCount = self.FurnitureSelectCount - 1
                self.FurnitureSelectList[myId] = nil
                self:RemoveSelectQuality(grid.Quality, true)
                self:SetCoinCount()
                return
            end
        end

        self.FurnitureSelectList[furnitureId] = true
        self.FurnitureSelectCount = self.FurnitureSelectCount + 1
        self:SetCoinCount()
    end
end

function XUiFurnitureObtain:OnBtnCloseClick()
    if self.FurnitureState == FurnitureState.DETAILS then
        self:Close()
    elseif self.FurnitureState == FurnitureState.SELECT then
        self.FurnitureState = FurnitureState.DETAILS
        self:ChangeUiState()
    end
end

function XUiFurnitureObtain:OnBtnBatchResetClick()
    self.IsRecovery = false
    self.FurnitureState = FurnitureState.SELECT
    self:ChangeUiState()
end

function XUiFurnitureObtain:OnBtnBatchRefitClick()
    self.IsRecovery = false
    self.FurnitureState = FurnitureState.SELECT
    self:ChangeUiState()
end

function XUiFurnitureObtain:OnBtnBatchRecoveryClick()
    self.IsRecovery = true
    self.FurnitureState = FurnitureState.SELECT
    self:ChangeUiState()
end

function XUiFurnitureObtain:OnTogLevelAClick()
    local purple = XGoodsCommonManager.QualityType.Purple
    self:OnTogLevelClick(self.TogLevelA, purple, true)
end

function XUiFurnitureObtain:OnTogLevelBClick()
    local blue = XGoodsCommonManager.QualityType.Blue
    self:OnTogLevelClick(self.TogLevelB, blue, true)
end

function XUiFurnitureObtain:OnTogLevelCClick()
    local greed = XGoodsCommonManager.QualityType.Greed
    local white = XGoodsCommonManager.QualityType.White
    self:OnTogLevelClick(self.TogLevelC, white)
    self:OnTogLevelClick(self.TogLevelC, greed, true)
end

function XUiFurnitureObtain:OnTogLevelClick(tog, quality, isFresh)
    if not tog.isOn then
        self:RemoveSelectQuality(quality)

        -- 从选择列表中移除
        local levelIdList = self.FurnitureLevelDic[quality] or {}
        for _, id in ipairs(levelIdList) do
            if self.FurnitureSelectList[id] then
                self.FurnitureSelectCount = self.FurnitureSelectCount - 1
                self.FurnitureSelectList[id] = nil
            end
        end
    else
        table.insert(self.SelectQualityList, quality)

        -- 添加到选择列表
        local levelIdList = self.FurnitureLevelDic[quality] or {}
        for _, id in ipairs(levelIdList) do
            if not self.FurnitureSelectList[id] then
                self.FurnitureSelectList[id] = true
                self.FurnitureSelectCount = self.FurnitureSelectCount + 1
            end
        end
    end

    if not isFresh then return end
    self:UpdateDynamicTable()
    self:SetCoinCount()
end

-- 重新建造
function XUiFurnitureObtain:OnBtnResetClick()
    if not self.IsRefitCoinEnough then
        XUiManager.TipMsg(CS.XTextManager.GetText("FurnitureZeroCoin"))
        return
    end

    local func = function()
        local furnitureList = self:GetFurnitureList()
        if #furnitureList <= 0 then
            XUiManager.TipMsg(CS.XTextManager.GetText("DormFurnitureRecycelNull"), XUiManager.UiTipType.Tip)
            return
        end

        if #furnitureList > XFurnitureConfigs.MaxCreateCount then
            XUiManager.TipMsg(CS.XTextManager.GetText("DormBuildMaxCount", XFurnitureConfigs.MaxCreateCount))
            return
        end
        for _, furnitureId in pairs(furnitureList) do
            if XDataCenter.FurnitureManager.GetFurnitureIsLocked(furnitureId) then
                XUiManager.TipMsg(CS.XTextManager.GetText("DormCannotRemakeLockFurniture"))
                return
            end
        end
        XDataCenter.FurnitureManager.FurnitureRemake(self.CreatePos, furnitureList, function()
            self:Close()

            if self.ResetCallBack then
                self.ResetCallBack(self.CreatePos)
            end
        end)
    end

    if self:CheckIncludeLevelS() then
        local titletext = CS.XTextManager.GetText("TipTitle")
        local contenttext = CS.XTextManager.GetText("DormObtainLevelSReset")

        XUiManager.DialogTip(titletext, contenttext, XUiManager.DialogType.Normal, nil, function()
            func()
        end)
    else
        func()
    end
end

-- 回收
function XUiFurnitureObtain:OnBtnRecoveryClick()
    local func = function()
        local furnitureList = self:GetFurnitureList()
        if #furnitureList <= 0 then
            XUiManager.TipMsg(CS.XTextManager.GetText("DormFurnitureRecycelNull"), XUiManager.UiTipType.Tip)
            return
        end
        for _, furnitureId in pairs(furnitureList) do
            if XDataCenter.FurnitureManager.GetFurnitureIsLocked(furnitureId) then
                XUiManager.TipMsg(CS.XTextManager.GetText("DormCannotRecycleLockFurniture"))
                return
            end
        end

        XDataCenter.FurnitureManager.DecomposeFurniture(furnitureList, function(rewardItems, successIds)
            -- 打开回收界面
            XLuaUiManager.Open("UiDormBagRecycle", furnitureList, rewardItems, nil, function()
                self:Close()
            end)

            -- 将分解成功的家具从缓存中移除
            for _, id in ipairs(successIds) do
                -- local configId = XDataCenter.FurnitureManager.GetFurnitureConfigId(id)
                XDataCenter.FurnitureManager.RemoveFurniture(id)
            end

            -- 删除红点
            XDataCenter.FurnitureManager.DeleteNewHint(successIds)
        end)
    end

    if self:CheckIncludeLevelS() then
        local titletext = CS.XTextManager.GetText("TipTitle")
        local contenttext = CS.XTextManager.GetText("DormObtainLevelSRecovery")

        XUiManager.DialogTip(titletext, contenttext, XUiManager.DialogType.Normal, nil, function()
            func()
        end)
    else
        func()
    end
end

-- 重新改造
function XUiFurnitureObtain:OnBtnRefitClick()
    local func = function()
        self:Close()

        if self.RefitCallBack then
            local furnitureList = self:GetFurnitureList()
            if #furnitureList <= 0 then
                XUiManager.TipMsg(CS.XTextManager.GetText("DormFurnitureRecycelNull"), XUiManager.UiTipType.Tip)
                return
            end

            self.RefitCallBack(furnitureList)
        end
    end
    for id, _ in pairs(self.FurnitureSelectList) do
        if XDataCenter.FurnitureManager.GetFurnitureIsLocked(id) then
            XUiManager.TipMsg(CS.XTextManager.GetText("DormCannotRemakeLockFurniture"))
            return
        end
    end
    if self:CheckIncludeLevelS() then
        local titletext = CS.XTextManager.GetText("TipTitle")
        local contenttext = CS.XTextManager.GetText("DormObtainLevelSRefit")

        XUiManager.DialogTip(titletext, contenttext, XUiManager.DialogType.Normal, nil, function()
            func()
        end)
    else
        func()
    end
end
--------------------------------- 点击事件相关(End) ---------------------------------