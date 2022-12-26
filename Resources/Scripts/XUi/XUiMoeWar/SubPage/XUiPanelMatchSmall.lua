local XUiPanelMatchSmall = XClass(nil, "XUiPanelMatchSmall")

local XUiScheduleGridPair = require("XUi/XUiMoeWar/ChildItem/XUiScheduleGridPair")
local tableInsert = table.insert
local ipairs = ipairs

local MAX_PAIRS = 3

function XUiPanelMatchSmall:Ctor(uiRoot, ui, sessionId, modelUpdater)
    self.UiRoot = uiRoot
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.ModelUpdater = modelUpdater

    self.ObjGroup = {}
    self.PairList = {}
    self.SessionId = sessionId
    XTool.InitUiObject(self)
    self:InitGroup()
end

function XUiPanelMatchSmall:InitGroup()
    for i in ipairs(XMoeWarConfig.GetGroups()) do
        local grpName = XDataCenter.MoeWarManager.GetActivityInfo().GroupName[i]
        local txtName = self["PanelTeam"..i]:Find("TextTeam"):GetComponent("Text")
        txtName.text = grpName
    end
end

function XUiPanelMatchSmall:InitPairGroup()
    -- 整理数据 分组
    self.PairGroup = {}
    local match = XDataCenter.MoeWarManager.GetMatch(self.SessionId)
    for _, v in ipairs(match.PairList) do
        tableInsert(self.PairGroup, v)
    end

    table.sort(self.PairGroup, function(pairA, pairB)
        return pairA.Players[1] < pairB.Players[1]
    end)
end

function XUiPanelMatchSmall:Refresh(isForce)
    if isForce or not self.PairGroup then
        self:InitPairGroup()
    end
    local match = XDataCenter.MoeWarManager.GetMatch(self.SessionId)
    for teamNo, pair in ipairs(self.PairGroup) do
        if teamNo > MAX_PAIRS then break end
        if not self.PairList[teamNo] then
            self.PairList[teamNo] = XUiScheduleGridPair.New(self["PanelTeam"..teamNo], teamNo, self.ModelUpdater)
        end
        self.PairList[teamNo]:Refresh(pair, match)
    end
    self.TxtRefreshTip.text = match:GetRefreshVoteText()
end


return XUiPanelMatchSmall