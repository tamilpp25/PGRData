local XUiPanelMatchLarge = XClass(nil, "XUiPanelMatchLarge")

local XUiScheduleGridPair = require("XUi/XUiMoeWar/ChildItem/XUiScheduleGridPair")
local tableInsert = table.insert
local ipairs = ipairs

local MAX_TAB_INDEX = 3
local MAX_PAIRS_IN_ONE_TAB = 4

function XUiPanelMatchLarge:Ctor(uiRoot, ui, sessionId)
    self.UiRoot = uiRoot
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.TabList = {}
    self.PairList = {}
    self.SessionId = sessionId
    XTool.InitUiObject(self)
    --self.GridMonster.gameObject:SetActiveEx(false)
    self:InitTabList()
    self:InitDefaultGroupIndex()
end

function XUiPanelMatchLarge:InitTabList()
    local actInfo = XDataCenter.MoeWarManager.GetActivityInfo()
    if not actInfo then
        XLog.Error("未获取到活动信息")
    end
    for i in ipairs(XMoeWarConfig.GetGroups()) do
        local grpName = actInfo.GroupName[i]
        local btn = self["Btn"..i]
        btn:SetNameByGroup(0, grpName)
        tableInsert(self.TabList, btn)
    end

    for i = #self.TabList + 1, MAX_TAB_INDEX do
        self["Btn"..i].gameObject:SetActiveEx(false)
    end

    self.BtnGrpGroup:Init(self.TabList ,function(index) self:SwitchTab(index) end)
end

function XUiPanelMatchLarge:InitPairGroup()
    -- 整理数据 分组
    self.PairGroup = {}
    local match = XDataCenter.MoeWarManager.GetMatch(self.SessionId)
    for _, v in ipairs(match.PairList) do
        local group = XMoeWarConfig.GetPlayerGroup(v.Players[1])
        if not self.PairGroup[group] then
            self.PairGroup[group] = {}
        end
        tableInsert(self.PairGroup[group], v)
    end

    for _, pairList in ipairs(self.PairGroup) do
        table.sort(pairList, function(pairA, pairB)
            return pairA.Players[1] < pairB.Players[1]
        end)
    end
end

function XUiPanelMatchLarge:InitDefaultGroupIndex()
    local userSupportPlayer = XDataCenter.MoeWarManager.GetUserSupportPlayer(self.SessionId)
    if userSupportPlayer ~= 0 then
        self.CurrentGroup = XMoeWarConfig.GetPlayerGroup(userSupportPlayer)
    else
        -- 无投票的情况下 选择假匹配的组 或者 1、2、3顺序循环
        self.CurrentGroup = XDataCenter.MoeWarManager.GetDefaultSelectGroup() or XDataCenter.MoeWarManager.GetNextTabIndex(self.SessionId)
    end
end

-- 默认选中的页签序号 defaultGroup
function XUiPanelMatchLarge:Refresh(isForce, selectIndex)
    if isForce or not self.PairGroup then
        self:InitPairGroup()
    end
    if selectIndex then
        self.CurrentGroup = selectIndex
    end
    self.BtnGrpGroup:SelectIndex(self.CurrentGroup, false)
    local match = XDataCenter.MoeWarManager.GetMatch(self.SessionId)
    if not self.PairGroup[self.CurrentGroup] then
        XLog.Error("defaultGroup is invalid", self.CurrentGroup, self.SessionId, self.PairGroup)
        return
    end
    for teamNo, pair in ipairs(self.PairGroup[self.CurrentGroup]) do
        if teamNo > MAX_PAIRS_IN_ONE_TAB then break end
        self["PanelTeam"..teamNo].gameObject:SetActiveEx(true)
        if not self.PairList[teamNo] then
            self.PairList[teamNo] = XUiScheduleGridPair.New(self["PanelTeam"..teamNo])
        end
        self.PairList[teamNo]:Refresh(pair, match)
    end

    for i = #self.PairList + 1, MAX_PAIRS_IN_ONE_TAB do
        if self["PanelTeam"..i] then
            self["PanelTeam"..i].gameObject:SetActiveEx(false)
        end
    end

    self.TxtRefreshTip.text = match:GetRefreshVoteText()
end

function XUiPanelMatchLarge:SwitchTab(index, isFromOtherUi)
    if self.CurrentGroup == index then
        return
    else
        self.CurrentGroup = index
        self:Refresh()
        if not isFromOtherUi then
            self.UiRoot:PlayAnimation("QieHuan2")
        end
    end
end

return XUiPanelMatchLarge