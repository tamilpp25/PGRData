local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridWheelChairManualPassportGrid = require("XUi/XUiWheelchairManual/UiPanelWheelChairManualPassport/XUiGridWheelChairManualPassportGrid")

---@field _Control XWheelchairManualControl
---@class XUiPanelWheelChairManualPassportPanel:XUiNode
local XUiPanelWheelChairManualPassportPanel = XClass(XUiNode, "XUiPanelWheelChairManualPassportPanel")

---@param rootUi XLuaUi
function XUiPanelWheelChairManualPassportPanel:OnStart(rootUi)
    self.RootUi = rootUi
    self:InitRightGrids()
    self:InitDynamicList()
    self:InitData()
    self._ActivityId = self._Control:GetCurActivityId()
    self.GridObjs = {}

    for i = 1, 10 do
        local manualUi = self['Manual'..i]

        if manualUi then
            manualUi.CallBack = handler(self, self.OnBuyClick)
        else
            break
        end
    end

    self.BtnSeniorUnlockLeftGrid.CallBack = handler(self, self.OnBuyClick)
end

function XUiPanelWheelChairManualPassportPanel:OnEnable()
    self:Refresh()
    XEventManager.AddEventListener(XEventId.EVENT_WHEELCHAIRMANUAL_REFRESH_PASSPORTLIST, self.Refresh, self)
end

function XUiPanelWheelChairManualPassportPanel:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_WHEELCHAIRMANUAL_REFRESH_PASSPORTLIST, self.Refresh, self)
end

function XUiPanelWheelChairManualPassportPanel:InitRightGrids()
    self.RightGrids = {}
    for i = 1, 3 do
        self.RightGrids[i] = XUiGridCommon.New(self.RootUi, self["GridCommonRight" .. i])
    end
end

function XUiPanelWheelChairManualPassportPanel:InitData()
    self._CommonRewardCfgIds = self._Control:GetCurActivityCommanManualRewardCfgIds()
    self._SeniorRewardCfgIds = self._Control:GetCurActivitySeniorManualRewardCfgIds()
end

function XUiPanelWheelChairManualPassportPanel:InitDynamicList()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGridWheelChairManualPassportGrid, self, self.RootUi)
    self.DynamicTable:SetDelegate(self)
    self.Grid01.gameObject:SetActiveEx(false)

    local gridWidth = self.Grid01:GetComponent("RectTransform").rect.size.x
    local panelWidth = self.PanelItemList:GetComponent("RectTransform").rect.size.x
    self.DynamicTableOffsetIndex = math.floor(panelWidth / gridWidth / 2)
end

function XUiPanelWheelChairManualPassportPanel:Refresh()
    self:UpdateDynamicTable()
    self:UpdateLeftGrid()
    -- 刷新列表，表示列表里道具的可领取状态可能有变化，同时需要刷新一键领取按钮的显示
    self.Parent:RefreshBtnRecieveAllState()
end

--遍历DynamicTable的Grid，根据最大等级的LevelId刷新
function XUiPanelWheelChairManualPassportPanel:UpdateRightGrid()
    local currMaxLevel = 0
    for _, v in pairs(self.DynamicTable:GetGrids()) do
        local level = v:GetLevel()
        if currMaxLevel < level then
            currMaxLevel = level
        end
    end

    local targetLevel = self._Control:GetCurActivityNextSpecialLevel(currMaxLevel)
    if not targetLevel then
        self.PanelRewardRight.gameObject:SetActiveEx(false)
        return
    else
        self.PanelRewardRight.gameObject:SetActiveEx(true)
    end

    self.TxtLevelRight.text = targetLevel and CS.XTextManager.GetText("PassportLevelDesc", targetLevel) or ""

    self:_UpdatePermitPanel(targetLevel)
end

--刷新物品格子
function XUiPanelWheelChairManualPassportPanel:_UpdatePermitPanel(level)
    if not XTool.IsNumberValid(level) then
        return
    end
    
    -- 显示普通手册奖励
    local nextUiIndex = self:_ShowRewardGoodsList(1, self._CommonRewardCfgIds[level], true, level)
    -- 显示高级手册奖励
    nextUiIndex = self:_ShowRewardGoodsList(nextUiIndex, self._SeniorRewardCfgIds[level], false, level)

    -- 隐藏剩余的奖励
    for i = nextUiIndex, nextUiIndex + 10 do
        local go = self["PanelPermit" .. i]
        if go then
            go.gameObject:SetActiveEx(false)
        else
            break
        end
    end
end

function XUiPanelWheelChairManualPassportPanel:_ShowRewardGoodsList(uiIndex, rewardCfgId, isCommon, level)
    local rewardId = self._Control:GetBPRewardIdById(rewardCfgId)
    local primeList = self._Control:GetBPIsDisplaysById(rewardCfgId)
    local grid

    local rewardGoodsList = XRewardManager.GetRewardList(rewardId)
    local isUnLock = isCommon and true or self._Control:GetIsSeniorManualUnLock()

    local isReceiveReward = self._Control:CheckManualRewardIsGet(rewardCfgId)
    local isCanReceiveReward = (not isReceiveReward) and (level <= self._Control:GetBpLevel()) and isUnLock

    for i, rewardData in ipairs(rewardGoodsList) do
        grid = self.GridObjs[uiIndex]
        if self["GridCommonRight" .. uiIndex] and not grid then
            grid = XUiGridCommon.New(self.RootUi, self["GridCommonRight" .. uiIndex])
            self.GridObjs[uiIndex] = grid
        end

        if XTool.IsNumberValid(rewardData) then
            if not isReceiveReward and isCanReceiveReward then
                grid:SetClickCallback(function() self:GridOnClick(isCommon) end)
                self:SetGridCommonPermitEffectActive(uiIndex, true)
            else
                grid:AutoAddListener()
                self:SetGridCommonPermitEffectActive(uiIndex, false)
            end

            grid:Refresh(rewardData)
            grid.GameObject:SetActive(true)
        else
            grid.GameObject:SetActive(false)
        end

        --已领取标志
        local getUi = self["ImgGetOutRight" .. uiIndex]
        if getUi then
            getUi.gameObject:SetActiveEx(isReceiveReward or false)
        end

        --未解锁标志
        local lockUi = self["ImgLockingRight" .. uiIndex]
        if lockUi then
            lockUi.gameObject:SetActiveEx(not isUnLock)

            local canvasGroup = self["GridCommonPermitCanvasGroup" .. uiIndex]
            if canvasGroup then
                canvasGroup.alpha = isUnLock and 1 or 0.5   --未解锁时半透明
            end
        end

        --贵重奖励
        local isPrimeReward = table.contains(primeList, i)

        local primeUi = self["RImgIsPrimeReward" .. uiIndex]
        if primeUi then
            primeUi.gameObject:SetActiveEx(isPrimeReward)
        end

        uiIndex = uiIndex + 1
    end

    return uiIndex
end

function XUiPanelWheelChairManualPassportPanel:SetGridCommonPermitEffectActive(index, isActive)
    local effectObj = self["GridCommonPermitEffect" .. index]
    if effectObj then
        effectObj.gameObject:SetActiveEx(isActive)
    end
end

function XUiPanelWheelChairManualPassportPanel:UpdateLeftGrid()
    -- 普通手册
    self.TxtCommonNameLeftGrid.text = self._Control:GetManualName(self._Control:GetCurActivityCommanManualId())
    -- 高级手册
    local isUnLock = self._Control:GetIsSeniorManualUnLock()
    self.TxtSeniorNameLeftGrid.text = self._Control:GetManualName(self._Control:GetCurActivitySeniorManualId())
    self.ImgSeniorLockLeftGrid.gameObject:SetActiveEx(not isUnLock)
    self.BtnSeniorUnlockLeftGrid.gameObject:SetActiveEx(true)
    self.BtnSeniorUnlockLeftGrid:SetDisable(isUnLock)
end

function XUiPanelWheelChairManualPassportPanel:UpdateDynamicTable()
    self.DynamicTable:SetDataSource(self._CommonRewardCfgIds)
    self.DynamicTable:ReloadDataASync(self._Control:GetBpLevel())
end

function XUiPanelWheelChairManualPassportPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(index, self._CommonRewardCfgIds[index], self._SeniorRewardCfgIds[index])
        self:UpdateRightGrid()
    end
end

function XUiPanelWheelChairManualPassportPanel:GridOnClick(isCommon)
    if XMVCA.XWheelchairManual:CheckManualAnyRewardCanGet() then
        XMVCA.XWheelchairManual:RequestWheelchairManualGetManualReward(isCommon and self._Control:GetCurActivityCommanManualId() or self._Control:GetCurActivitySeniorManualId(), function(success, rewardGoodsList)
            if success then
                self:Refresh()
                self._Control:ShowRewardList(rewardGoodsList)
            end
        end)
    end
end

function XUiPanelWheelChairManualPassportPanel:OnBuyClick()
    XLuaUiManager.Open('UiWheelChairManualPopupPassportCard')
    if self.Parent.RefreshBtnBuyReddot then
        self.Parent:RefreshBtnBuyReddot()
    end
end

return XUiPanelWheelChairManualPassportPanel
