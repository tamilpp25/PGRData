local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiRogueSimHandbook: XLuaUi
---@field private _Control XRogueSimControl
local XUiRogueSimHandbook = XLuaUiManager.Register(XLuaUi, "UiRogueSimHandbook")

function XUiRogueSimHandbook:OnAwake()
    self.Grid.gameObject:SetActiveEx(false)

    self:RegisterUiEvents()
    self:InitTimes()
    self:InitTabButton()
    self:InitDynamicTable()
end

function XUiRogueSimHandbook:OnStart()
    self.RedDic = self:GetRedDic()

    -- 刷新页签红点
    for type, redDic in pairs(self.RedDic) do
        local isRed = next(redDic)
        self.TabBtns[type]:ShowReddot(isRed)
    end

    -- 选中第一个页签
    self.PanelTab:SelectIndex(XEnumConst.RogueSim.IllustrateType.Props)
end

function XUiRogueSimHandbook:OnEnable()
    self.Super.OnEnable(self)
end

function XUiRogueSimHandbook:OnDisable()
    self.Super.OnDisable(self)
end

function XUiRogueSimHandbook:InitTimes()
    self.EndTime = self._Control:GetActivityEndTime()
    self:SetAutoCloseInfo(self.EndTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)
end

function XUiRogueSimHandbook:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
end

function XUiRogueSimHandbook:InitTabButton()
    self.TabBtns = {self.BtnProp, self.BtnBuild}
    self.PanelTab:Init(self.TabBtns, function(index)
        self:SelectTab(index)
    end)
end

function XUiRogueSimHandbook:SelectTab(index)
    if self.CurIllType ~= index then
        self:PlayAnimation("QieHuan")
        self.CurIllType = index
        self.TabBtns[index]:ShowReddot(false)
        self.CurTypeRedDic = self.RedDic[self.CurIllType]
        self.RedDic[self.CurIllType] = {}
        self:RefreshDynamicList()
        self:RefreshProgress()

        -- 移除红点记录
        local ids = {}
        for _, illId  in pairs(self.CurTypeRedDic) do
            table.insert(ids, illId)
        end
        self._Control:RemoveIllustratesRed(ids)
    end
end

function XUiRogueSimHandbook:InitDynamicTable()
    local XUiGridRogueSimHandbook = require("XUi/XUiRogueSim/Handbook/XUiGridRogueSimHandbook")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelPropList)
    self.DynamicTable:SetProxy(XUiGridRogueSimHandbook, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiRogueSimHandbook:RefreshDynamicList()
    local illustrates = self._Control:GetIllustrates()

    -- 解锁对应类型的key列表
    self.UnlockKeyDic = {}
    for _, illId in ipairs(illustrates) do
        local config = self._Control:GetRogueSimIllustrateConfig(illId)
        if config.Type == self.CurIllType then
            for _, key in ipairs(config.Key) do
                self.UnlockKeyDic[key] = true
            end
        end
    end

    -- 有配置图鉴的才显示
    local showKeyDic = {}
    local configs = self._Control:GetRogueSimIllustrateConfigs()
    for _, config in pairs(configs) do
        if config.Type == self.CurIllType then
            for _, key in ipairs(config.Key) do
                showKeyDic[key] = true
            end
        end
    end

    -- 取道具/建筑所有配置
    self.Datas = {}
    local isProp = self.CurIllType == XEnumConst.RogueSim.IllustrateType.Props
    local configs = isProp and self._Control.MapSubControl:GetPropConfigs() or self._Control.MapSubControl:GetBuildingConfigs()
    for _, config in pairs(configs) do
        if showKeyDic[config.Id] then
            table.insert(self.Datas, config)
        end
    end
    table.sort(self.Datas, function(a, b)
        local isUnlockA = self.UnlockKeyDic[a.Id] and 1 or 0
        local isUnlockB = self.UnlockKeyDic[b.Id] and 1 or 0
        if isUnlockA ~= isUnlockB then
            return isUnlockA > isUnlockB
        end

        if isProp then
            if a.Rare ~= b.Rare then
                return a.Rare > b.Rare
            end
        end

        return a.Id > b.Id
    end)

    -- 刷新列表
    self.DynamicTable:SetDataSource(self.Datas)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiRogueSimHandbook:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local config = self.Datas[index]
        local isUnlock = self.UnlockKeyDic[config.Id] == true
        grid:Refresh(self.CurIllType, config, isUnlock)

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:Recycle()
    end
end

-- 获取红点哈希表
function XUiRogueSimHandbook:GetRedDic()
    local redDic = {}
    redDic[XEnumConst.RogueSim.IllustrateType.Props] = {}
    redDic[XEnumConst.RogueSim.IllustrateType.Build] = {}

    local illIds = self._Control:GetShowRedIllustrates()
    for _, illId in ipairs(illIds) do
        local config = self._Control:GetRogueSimIllustrateConfig(illId)
        if config.Type == XEnumConst.RogueSim.IllustrateType.Props or config.Type == XEnumConst.RogueSim.IllustrateType.Build then
            for _, key in ipairs(config.Key) do
                redDic[config.Type][key] = illId
            end
        end
    end
    return redDic
end

function XUiRogueSimHandbook:IsShowRed(id)
    return self.CurTypeRedDic[id] ~= nil
end

function XUiRogueSimHandbook:RefreshProgress()
    local curCnt = 0
    local illustrates = self._Control:GetIllustrates()
    for _, illId in ipairs(illustrates) do
        local config = self._Control:GetRogueSimIllustrateConfig(illId)
        if config.Type == self.CurIllType then
            curCnt = curCnt + 1
        end
    end

    local allCnt = #self.Datas
    local progressStr = self._Control:GetClientConfig("HandbookProgress")
    self.TxtPercent.text = string.format(progressStr, curCnt, allCnt)
end

return XUiRogueSimHandbook