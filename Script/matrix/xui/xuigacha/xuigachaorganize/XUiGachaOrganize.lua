local XUiGachaOrganize = XLuaUiManager.Register(XLuaUi, "UiGachaOrganize")

local XUiGridGacha = require("XUi/XUiGacha/XUiGachaOrganize/XUiGridGacha")

local MAX_GACHA_BTN_COUNT = 2   -- 抽卡按钮的数量

local NewUnlockGachaId          -- 新解锁卡池的Id

function XUiGachaOrganize:OnAwake()
    self.IsCanGacha = true

    self.PreviewGridPool = {}       -- XUiGridCommon池子
    self.UsePreviewGrid = {}        -- 正在使用的XUiGridCommon
    self.DrawButtonComponent = {}   -- 抽卡按钮的控件{ Btn, TxtDrawDesc, TxtUseItemCount, ImgUseItemIcon}

    self:InitComponent()
    self:AddListener()
end

function XUiGachaOrganize:OnStart(organizeId, curGachaId, organizeRule)
    self.OrganizeId = organizeId
    self.OrganizeRule = organizeRule
    self.TextName.text = organizeRule.GachaName or ""
    if self.TextName2 then
        self.TextName2.text = organizeRule.GachaName2 or ""
    end
    self.BtnDrawRule.gameObject:SetActiveEx(organizeRule.UiType == XGachaConfigs.UiType.Pay)

    self:GenerateGachas(curGachaId)
    self:ChangeGacha(curGachaId)
end

function XUiGachaOrganize:InitComponent()
    for i = 1, MAX_GACHA_BTN_COUNT do
        local btnName = "BtnDraw" .. i
        local btn = XUiHelper.TryGetComponent(self.PanelDrawButtons, btnName, "Button")
        if btn then
            if not self.DrawButtonComponent[i] then
                self.DrawButtonComponent[i] = {}
            end
            self.DrawButtonComponent[i].Btn = btn
            self.DrawButtonComponent[i].TxtDrawDesc = btn.transform:Find("TxtDrawDesc"):GetComponent("Text")
            self.DrawButtonComponent[i].TxtUseItemCount = btn.transform:Find("TxtUseItemCount"):GetComponent("Text")
            self.DrawButtonComponent[i].ImgUseItemIcon = btn.transform:Find("ImgUseItemIcon"):GetComponent("RawImage")
        end
    end
    self.TextTip.text = CS.XTextManager.GetText("GachaOrganizeRankTip")

    self.PanelGet.gameObject:SetActiveEx(false)
    self.GridGacha.gameObject:SetActiveEx(false)
    self.GridDrawActivity.gameObject:SetActiveEx(false)
    self:InitDynamicTable()
end

function XUiGachaOrganize:InitDynamicTable()
    self.DynamicTable = XDynamicTableCurve.New(self.PanelGachaList)
    self.DynamicTable:SetProxy(XUiGridGacha)
    self.DynamicTable:SetDelegate(self)
end


-----------------------------------------------按钮响应函数---------------------------------------------------------------
function XUiGachaOrganize:AddListener()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self.BtnMore.CallBack = function()
        self:OnBtnMore()
    end
    self.BtnUseItem.CallBack = function()
        self:OnBtnUseItemClick()
    end
    self.BtnDrawRule.CallBack = function()
        self:OnBtnDrawRuleClick()
    end
    if self.BtnSwitchNext then
        self.BtnSwitchNext.CallBack = function()
            self:OnSwitchGachaClick(true)
        end
    end
    if self.BtnSwitchPre then
        self.BtnSwitchPre.CallBack = function()
            self:OnSwitchGachaClick()
        end
    end
    for i, btnComponent in ipairs(self.DrawButtonComponent) do
        btnComponent.Btn.CallBack = function()
            self:OnDrawClick(i)
        end
    end
end

function XUiGachaOrganize:OnBtnBackClick()
    self:Close()
end

function XUiGachaOrganize:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiGachaOrganize:OnBtnMore()
    XLuaUiManager.Open("UiGachaPanelPreview", self.CurGachaId)
end

function XUiGachaOrganize:OnBtnUseItemClick()
    local data = XDataCenter.ItemManager.GetItem(self.GachaCfg.ConsumeId)
    XLuaUiManager.Open("UiTip", data)
end

function XUiGachaOrganize:OnBtnDrawRuleClick()
    XLuaUiManager.Open("UiDrawActivityLog", self.CurGachaId, nil, self.OrganizeRule)
end

function XUiGachaOrganize:OnSwitchGachaClick(isNext)
    local index
    if isNext then
        index = self.SelectedIndex
    else
        index = self.SelectedIndex - 2
    end
    self.DynamicTable.Imp:TweenToIndex(index)
end

---
--- 'btnIndex'是抽卡按钮在DrawButtonComponent上的索引，用来获取配置表上的抽卡次数配置
function XUiGachaOrganize:OnDrawClick(btnIndex)
    -- 卡池是否处于开放时间
    if not XDataCenter.GachaManager.CheckGachaIsOpenById(self.GachaCfg.Id, true, true) then
        return
    end

    -- 卡池状态是否正常
    local status = XDataCenter.GachaManager.GetOrganizeGachaStatus(self.OrganizeId, self.CurGachaId)
    if status ~= XGachaConfigs.OrganizeGachaStatus.Normal then
        if self.DrawButtonComponent[btnIndex].Btn.ButtonState == CS.UiButtonState.Normal then
            XLog.Error("XUiGachaOrganize:OnDrawClick函数错误，卡池的状态为非正常，抽卡按钮的状态不应该是Normal")
        end
        if status == XGachaConfigs.OrganizeGachaStatus.Lock then
            XUiManager.TipText("GachaOrganizeLockNotDraw")
        elseif status == XGachaConfigs.OrganizeGachaStatus.SoldOut then
            XUiManager.TipText("GachaOrganizeSoldOutNotDraw")
        end
        return
    end

    -- 武器意识的背包容量是否足够
    if XDataCenter.EquipManager.CheckBoxOverLimitOfDraw() then
        return
    end

    local gachaCount = self.GachaCfg.BtnGachaCount[btnIndex]
    local ownItemCount = XDataCenter.ItemManager.GetItem(self.GachaCfg.ConsumeId).Count
    local lackItemCount = self.GachaCfg.ConsumeCount * gachaCount - ownItemCount

    -- 剩余次数是否足够
    local dtCount = XDataCenter.GachaManager.GetMaxCountOfAll() - XDataCenter.GachaManager.GetCurCountOfAll()
    if dtCount < gachaCount and not XDataCenter.GachaManager.GetIsInfinite() then
        XUiManager.TipMsg(CS.XTextManager.GetText("GachaIsNotEnough"))
        return
    end

    -- 货币是否足够
    if lackItemCount > 0 then
        if self.OrganizeRule.ItemNotEnoughSkipId > 0 then
            XLuaUiManager.Open("UiDialog", CS.XTextManager.GetText("TipTitle"),
            CS.XTextManager.GetText("GachaOrganizeNotEnoughSkipHint"), XUiManager.DialogType.Normal, nil, function()
                XFunctionManager.SkipInterface(self.OrganizeRule.ItemNotEnoughSkipId)
            end)
        else
            XUiManager.TipError(CS.XTextManager.GetText("GachaOrganizeDrawNotEnoughError"))
        end
        return
    end

    if self.IsCanGacha then
        self.IsCanGacha = false
        XLuaUiManager.SetMask(true)

        local asyncPlayAnim = asynTask(self.PlayAnimation, self)
        local cb = function(rewardList, newUnlockGachaId)
            XDataCenter.AntiAddictionManager.BeginDrawCardAction()
            RunAsyn(function()
                asyncPlayAnim("PanelGetEnable")

                XLuaUiManager.Open("UiGachaOrganizeDrawResult", rewardList, function()
                    self:WhetherUnLockNewGacha()
                end)

                NewUnlockGachaId = newUnlockGachaId
                self.IsCanGacha = true
                XLuaUiManager.SetMask(false)
                self:RefreshItemCount()
                self:RefreshGachaAfterDraw()
                self:RefreshPreviewData()
                self:RefreshDrawButton()
            end)
        end
        local errorCb = function()
            XLuaUiManager.SetMask(false)
            self.IsCanGacha = true
        end

        XDataCenter.GachaManager.DoGacha(self.GachaCfg.Id, gachaCount, cb, errorCb, self.OrganizeId)
    end
end
------------------------------------------------------------------------------------------------------------------------
---
--- 设置动态列表的DataSource，生成卡池
function XUiGachaOrganize:GenerateGachas(curGachaId)
    self.DataSource = XGachaConfigs.GetOrganizeGahcaIdList(self.OrganizeId)

    -- SelectedIndex为打开时默认选择的卡池在DataSource中的索引
    for index, id in ipairs(self.DataSource) do
        if id == curGachaId then
            self.SelectedIndex = index
            break
        end
    end
    if not self.SelectedIndex then
        self.SelectedIndex = 1
    end

    self.DynamicTable:SetDataSource(self.DataSource)
    self.DynamicTable:ReloadData(#self.DataSource > 0 and (self.SelectedIndex - 1) or -1)
end


-----------------------------------------------刷新界面------------------------------------------------------------------
---
--- 动态列表的index从0开始
--- self.SelectedIndex从1开始
function XUiGachaOrganize:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local i = index + 1
        grid:Refresh(self.OrganizeId, self.DataSource[i])

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.DynamicTable.Imp:TweenToIndex(index)

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_TWEEN_OVER then
        -- 切换卡池时请求卡池的奖励库存与掉落信息
        local startIndex = self.DynamicTable.Imp.StartIndex
        local selectIndex = startIndex + 1
        XDataCenter.GachaManager.GetGachaRewardInfoRequest(self.DataSource[selectIndex], function()
            -- 先更改SelectIndex，再更改CurGachaId，最后刷新界面，有GET_GACHA_DATA_INTERVAL秒的间隔时间限制
            if self.SelectedIndex ~= selectIndex then
                self.SelectedIndex = selectIndex
                self:ChangeGacha(self.DataSource[selectIndex])
            end
        end)
    end
end

---
--- 抽卡后检测是否解锁了新卡池
function XUiGachaOrganize:WhetherUnLockNewGacha()
    if NewUnlockGachaId then
        -- SelectedIndex比动态列表的Index多1，所以会跳去下一个新解锁的卡池中
        self.DynamicTable.Imp:TweenToIndex(self.SelectedIndex)
        NewUnlockGachaId = nil
    end
end

---
--- 切换卡池，刷新界面
---@param gachaId number
function XUiGachaOrganize:ChangeGacha(gachaId)
    self.CurGachaId = gachaId
    self.GachaCfg = XGachaConfigs.GetGachaCfgById(gachaId)

    -- 刷新序号
    local index
    if self.SelectedIndex < 10 then
        index = string.format("%s%s", "0", tostring(self.SelectedIndex))
    else
        index.tostring(self.SelectedIndex)
    end
    self.TxtRank.text = index

    if self.BtnSwitchNext then
        self.BtnSwitchNext.gameObject:SetActiveEx(not (self.SelectedIndex >= #self.DataSource))
    end

    if self.BtnSwitchPre then
        self.BtnSwitchPre.gameObject:SetActiveEx(not (self.SelectedIndex <= 1))
    end

    -- 刷新代币
    local icon = XDataCenter.ItemManager.GetItemBigIcon(self.GachaCfg.ConsumeId)
    self.ImgUseItemIcon:SetRawImage(icon)
    self:RefreshItemCount()

    -- 刷新抽奖按钮
    self:RefreshDrawButton()

    -- 生成奖励
    self:GeneratePreview()
    self:PlayAnimation("QieHuan")
end

---
--- 刷新代币数量
--- 抽卡、切换卡池时刷新
function XUiGachaOrganize:RefreshItemCount()
    self.TxtUseItemCount.text = XDataCenter.ItemManager.GetItem(self.GachaCfg.ConsumeId).Count
end

---
--- 刷新抽奖按钮
--- 抽卡、切换卡池时刷新
function XUiGachaOrganize:RefreshDrawButton()
    local isLock = false
    local status = XDataCenter.GachaManager.GetOrganizeGachaStatus(self.OrganizeId, self.CurGachaId)
    if status ~= XGachaConfigs.OrganizeGachaStatus.Normal then
        isLock = true
    end
    for i, btnComponent in ipairs(self.DrawButtonComponent) do
        local gachaCount = self.GachaCfg.BtnGachaCount[i]
        btnComponent.TxtDrawDesc.text = CS.XTextManager.GetText("GachaOrganizeDrawCount", gachaCount)
        btnComponent.TxtUseItemCount.text = gachaCount * self.GachaCfg.ConsumeCount

        local useItemIcon = XDataCenter.ItemManager.GetItemBigIcon(self.GachaCfg.ConsumeId)
        btnComponent.ImgUseItemIcon:SetRawImage(useItemIcon)
        btnComponent.Btn:SetDisable(isLock)
    end
end

---
--- 生成预览奖励
--- 更换卡池时刷新
function XUiGachaOrganize:GeneratePreview()
    -- 回收格子
    for _, grid in pairs(self.UsePreviewGrid) do
        local gridGO = grid.GameObject
        if gridGO.activeSelf then
            gridGO:SetActiveEx(false)
        end
    end
    self.UsePreviewGrid = {}

    -- 生成奖励预览
    local count = 1
    local gachaRewardInfo = XDataCenter.GachaManager.GetGachaRewardInfoById(self.CurGachaId)
    for k, v in pairs(gachaRewardInfo) do
        if count > self.OrganizeRule.PreviewShowCount then
            break
        end

        if v.Rare then
            -- 取出格子
            local grid = self.PreviewGridPool[count]
            if not grid then
                local obj = CS.UnityEngine.Object.Instantiate(self.GridDrawActivity, self.PreviewContent)
                grid = XUiGridCommon.New(self, obj)
                self.PreviewGridPool[count] = grid
            end

            -- 刷新信息
            if grid then
                local tmpData = {}
                tmpData.TemplateId = v.TemplateId
                tmpData.Count = v.Count

                local curCount
                if v.RewardType == XGachaConfigs.RewardType.Count then
                    curCount = v.CurCount
                end
                grid:Refresh(tmpData, nil, nil, nil, curCount)
                grid.GameObject:SetActiveEx(true)

                self.UsePreviewGrid[k] = grid
                count = count + 1
            end
        end
    end

    -- 刷新次数
    self:RefreshPreviewCount()
    self.PanelNumber.gameObject:SetActiveEx(not XDataCenter.GachaManager.GetIsInfinite())
end

---
--- 刷新奖励库存
--- 抽卡时刷新
function XUiGachaOrganize:RefreshPreviewData()
    local gachaRewardInfo = XDataCenter.GachaManager.GetGachaRewardInfoById(self.CurGachaId)

    -- 刷新奖励格子
    for k, v in pairs(self.UsePreviewGrid or {}) do
        local tmpData = {}
        tmpData.TemplateId = gachaRewardInfo[k].TemplateId
        tmpData.Count = gachaRewardInfo[k].Count

        local curCount
        if gachaRewardInfo[k].RewardType == XGachaConfigs.RewardType.Count then
            curCount = gachaRewardInfo[k].CurCount
        end
        v:Refresh(tmpData, nil, nil, nil, curCount)
    end

    -- 刷新次数
    self:RefreshPreviewCount()
end

---
--- 刷新卡池奖励进度
--- 抽卡、切换卡池时刷新
function XUiGachaOrganize:RefreshPreviewCount()
    local curCount = XDataCenter.GachaManager.GetCurCountOfAll()
    local maxCount = XDataCenter.GachaManager.GetMaxCountOfAll()
    local countStr = CS.XTextManager.GetText("GachaAlreadyobtainedCount", curCount, maxCount)

    self.TxtNumber.text = countStr
    self.ImgJd.fillAmount = curCount / maxCount
end

---
--- 刷新所有卡池
--- 抽卡时刷新
function XUiGachaOrganize:RefreshGachaAfterDraw()
    local grids = self.DynamicTable:GetGrids()
    for _, grid in pairs(grids) do
        grid:AfterDrawRefresh()
    end
end