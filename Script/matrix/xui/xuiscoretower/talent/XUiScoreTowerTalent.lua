local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
---@class XUiScoreTowerTalent : XLuaUi
---@field private _Control XScoreTowerControl
---@field PanelConsume XUiComponent.XUiButton
local XUiScoreTowerTalent = XLuaUiManager.Register(XLuaUi, "UiScoreTowerTalent")

function XUiScoreTowerTalent:OnAwake()
    self:RegisterUiEvents()
    self.GridChapter.gameObject:SetActiveEx(false)
    self.PanelRight.gameObject:SetActiveEx(false)
end

function XUiScoreTowerTalent:OnStart()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.ScoreTowerCoin)
    self:SetAutoCloseInfo(XMVCA.XScoreTower:GetActivityEndTime(), function(isClose)
        if isClose then
            XMVCA.XScoreTower:HandleActivityEnd()
        end
    end)

    ---@type XUiGridScoreTowerStrengthenChapter[]
    self.GridStrengthenChapterList = {}
    -- 当前选择的强化Id
    self.SelectStrengthenId = 0
    -- 当前选择的强化格子
    ---@type XUiGridScoreTowerStrengthen
    self.SelectStrengthenGrid = false
    -- 天赋强化UI动画播放间隔
    self.AnimInterval = self._Control:GetClientConfig("GridStrengthenAnimInterval", 1, true)
end

function XUiScoreTowerTalent:OnEnable()
    self.Super.OnEnable(self)
    self:RefreshStrengthen()
    self:SimulateClick()
end

function XUiScoreTowerTalent:OnDisable()
    self.Super.OnDisable(self)
    self.SelectStrengthenId = 0
    self.SelectStrengthenGrid = false
end

-- 模拟点击
function XUiScoreTowerTalent:SimulateClick()
    -- 默认选中第一个
    local grid = self.GridStrengthenChapterList[1]
    if grid then
        grid:SimulateClick()
    end
end

-- 刷新强化列表
function XUiScoreTowerTalent:RefreshStrengthen()
    local belongChapterIds = self._Control:GetAllBelongChapterIds()
    local belongChapterCount = #belongChapterIds
    self.PanelLeft.gameObject:SetActiveEx(belongChapterCount > 0)
    local enableAnimDelay = 0
    for index = 1, XEnumConst.ScoreTower.MaxBelongChapterCount do
        local grid = self.GridStrengthenChapterList[index]
        local parent = self[string.format("Chapter%d", index)]
        if index <= belongChapterCount then
            if not grid then
                local go = XUiHelper.Instantiate(self.GridChapter, parent)
                grid = require("XUi/XUiScoreTower/Talent/XUiGridScoreTowerStrengthenChapter").New(go, self, handler(self, self.OnSelectStrengthenClick))
                self.GridStrengthenChapterList[index] = grid
            end
            parent.gameObject:SetActiveEx(true)
            grid:Open()
            grid:Refresh(belongChapterIds[index], enableAnimDelay)
            enableAnimDelay = enableAnimDelay + self.AnimInterval
        else
            if grid then
                grid:Close()
            end
            parent.gameObject:SetActiveEx(false)
        end
    end
end

-- 选中强化
---@param chapterId number 章节Id
---@param strengthenId number 强化Id
---@param grid XUiGridScoreTowerStrengthen
---@param isNotTips boolean 是否不提示
function XUiScoreTowerTalent:OnSelectStrengthenClick(chapterId, strengthenId, grid, isNotTips)
    -- 是否通关
    local isPass = self._Control:IsChapterPass(chapterId)
    if not isPass then
        if not isNotTips then
            local desc = self._Control:GetClientConfig("StrengthenChapterUnlockDesc")
            XUiManager.TipMsg(XUiHelper.FormatText(desc, self._Control:GetChapterName(chapterId)))
        end
        return
    end
    if self.SelectStrengthenId == strengthenId then
        return
    end
    -- 取消上一个选中
    if self.SelectStrengthenGrid then
        self.SelectStrengthenGrid:SetSelect(false)
    end
    -- 选中当前
    self.SelectStrengthenId = strengthenId
    self.SelectStrengthenGrid = grid
    self.SelectStrengthenGrid:SetSelect(true)
    self:RefreshStrengthenDetail()
    if not isNotTips then
        -- 播放动画
        self:PlayAnimation("Refresh")
        -- 播放音效
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.Fight_PageSwitch_Up)
    end
end

-- 刷新强化详情
function XUiScoreTowerTalent:RefreshStrengthenDetail()
    self.PanelRight.gameObject:SetActiveEx(true)
    if not self.GridStrengthenUi then
        ---@type XUiGridScoreTowerStrengthen
        self.GridStrengthenUi = require("XUi/XUiScoreTower/Talent/XUiGridScoreTowerStrengthen").New(self.GridTalent, self)
    end
    self.GridStrengthenUi:Open()
    self.GridStrengthenUi:Refresh(self.SelectStrengthenId)
    local curLevel = self._Control:GetStrengthenBuffCurLv(self.SelectStrengthenId)
    local fightEventId = self._Control:GetStrengthenBuffFightEventId(self.SelectStrengthenId, curLevel)
    local isMaxLv = self._Control:IsStrengthenBuffMaxLv(self.SelectStrengthenId, curLevel)
    -- 名称
    self.TxtName.text = self._Control:GetFightEventName(fightEventId)
    -- 当前描述
    self.PanelTitle.gameObject:SetActiveEx(curLevel > 0)
    self.PanelNow.gameObject:SetActiveEx(curLevel > 0)
    if curLevel > 0 then
        self.TxtNowDetail.text = XUiHelper.FormatText(XUiHelper.ReplaceTextNewLine(self._Control:GetClientConfig('BuffPowerAddsLabel')), self._Control:GetFightEventDesc(fightEventId), self._Control:GetStrengthenBuffPower(self.SelectStrengthenId, curLevel))
    end
    -- 下一级描述
    self.PanelNextTitle.gameObject:SetActiveEx(not isMaxLv)
    self.PanelNext.gameObject:SetActiveEx(not isMaxLv)
    if not isMaxLv then
        local nextFightEventId = self._Control:GetStrengthenBuffFightEventId(self.SelectStrengthenId, curLevel + 1)
        self.TxtNextDetail.text = XUiHelper.FormatText(XUiHelper.ReplaceTextNewLine(self._Control:GetClientConfig('BuffPowerAddsLabel')), self._Control:GetFightEventDesc(nextFightEventId), self._Control:GetStrengthenBuffPower(self.SelectStrengthenId, curLevel + 1))
    end
    self.PanelUpgrade.gameObject:SetActiveEx(not isMaxLv)
    self.PanelMax.gameObject:SetActiveEx(isMaxLv)
    if not isMaxLv then
        -- 消耗
        local cost = self._Control:GetStrengthenBuffNextLvCost(self.SelectStrengthenId, curLevel)
        self.PanelConsume:SetNameByGroup(0, cost)
        -- 货币图标
        local coinId = XDataCenter.ItemManager.ItemId.ScoreTowerCoin
        self.PanelConsume:SetRawImageEx(XDataCenter.ItemManager.GetItemIcon(coinId))
        -- 是否足够
        local isEnough = XDataCenter.ItemManager.CheckItemCountById(coinId, cost)
        self.PanelConsume:SetDisable(not isEnough)
        -- 概率
        --self.TxtTips.gameObject:SetActiveEx(curLevel > 0)
        --if curLevel > 0 then
        --    local rate = self._Control:GetStrengthenBuffNextLvRate(self.SelectStrengthenId, curLevel)
        --    self.TxtChanceNum.text = string.format("%s%%", rate / 100)
        --end
        -- 强化按钮
        local btnName = self._Control:GetClientConfig("StrengthenRelatedTips", curLevel > 0 and 2 or 1)
        self.BtnStart:SetNameByGroup(0, btnName)
        self.BtnStart:SetDisable(not isEnough)
    end
end

function XUiScoreTowerTalent:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnStart, self.OnBtnStartClick)
    self:BindHelpBtn(self.BtnHelp, self._Control:GetClientConfig("HelpKey"))
end

function XUiScoreTowerTalent:OnBtnBackClick()
    self:Close()
end

function XUiScoreTowerTalent:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

-- 强化
function XUiScoreTowerTalent:OnBtnStartClick()
    if not XTool.IsNumberValid(self.SelectStrengthenId) then
        return
    end
    local curLevel = self._Control:GetStrengthenBuffCurLv(self.SelectStrengthenId)
    local isMaxLv = self._Control:IsStrengthenBuffMaxLv(self.SelectStrengthenId, curLevel)
    if isMaxLv then
        XUiManager.TipMsg(self._Control:GetClientConfig("StrengthenRelatedTips", 3))
        return
    end
    local cost = self._Control:GetStrengthenBuffNextLvCost(self.SelectStrengthenId, curLevel)
    local coinId = XDataCenter.ItemManager.ItemId.ScoreTowerCoin
    local isEnough = XDataCenter.ItemManager.CheckItemCountById(coinId, cost)
    if not isEnough then
        local desc = self._Control:GetClientConfig("StrengthenRelatedTips", 4)
        local itemName = XDataCenter.ItemManager.GetItemName(coinId)
        XUiManager.TipMsg(XUiHelper.FormatText(desc, itemName))
        return
    end
    self._Control:StrengthenRequest(self.SelectStrengthenId, function()
        -- 刷新选择的强化格子
        if self.SelectStrengthenGrid then
            self.SelectStrengthenGrid:RefreshInfo()
        end
        -- 刷新红点
        for _, grid in pairs(self.GridStrengthenChapterList) do
            if grid:IsNodeShow() then
                grid:RefreshRedPoint()
            end
        end
        -- 刷新强化详情
        self:RefreshStrengthenDetail()
    end)
end

return XUiScoreTowerTalent
