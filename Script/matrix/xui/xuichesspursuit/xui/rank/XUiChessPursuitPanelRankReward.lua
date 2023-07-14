local XUiChessPursuitPanelRankRewardGrid = require("XUi/XUiChessPursuit/XUi/Rank/XUiChessPursuitPanelRankRewardGrid")

local XUiChessPursuitPanelRankReward = XClass(nil, "XUiChessPursuitPanelRankReward")

function XUiChessPursuitPanelRankReward:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.GridRankList = {}
    XTool.InitUiObject(self)
    self:AutoAddListener()
    self.GridBossRankReward.gameObject:SetActiveEx(false)
end

function XUiChessPursuitPanelRankReward:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiChessPursuitPanelRankReward:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiChessPursuitPanelRankReward:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiChessPursuitPanelRankReward:AutoAddListener()
    self:RegisterClickEvent(self.BtnBlock, self.OnBtnBlockClick)
end

function XUiChessPursuitPanelRankReward:ShowPanel()
    local groupId = XChessPursuitConfig.GetCurrentGroupId()
    local idList = XChessPursuitConfig.GetMapGroupRewardByGroupIdToIdDic(groupId)
    if not idList then
        XUiManager.TipText("ChessPursuitNotRankReward")
        return
    end
    for _, gridRank in ipairs(self.GridRankList) do
        gridRank.GameObject:SetActiveEx(false)
    end

    for i, mapGroupRewardId in ipairs(idList) do
        local grid = self.GridRankList[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridBossRankReward)
            grid = XUiChessPursuitPanelRankRewardGrid.New(self.RootUi, ui)
            grid.Transform:SetParent(self.PanelRankContent, false)
            self.GridRankList[i] = grid
        end
        grid:Refresh(groupId, mapGroupRewardId)
        grid.GameObject:SetActiveEx(true)
    end

    self.GameObject:SetActiveEx(true)
    -- self.RootUi:PlayAnimation("AnimRankRewardEnable")
end

function XUiChessPursuitPanelRankReward:OnBtnBlockClick()
    self:HidePanel()
end

function XUiChessPursuitPanelRankReward:HidePanel()
    -- self.RootUi:PlayAnimation("AnimRankRewardDisable", function()
        self.GameObject:SetActiveEx(false)
    -- end)
end

return XUiChessPursuitPanelRankReward

