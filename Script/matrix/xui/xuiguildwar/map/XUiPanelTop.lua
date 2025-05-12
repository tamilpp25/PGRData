---@class XUiGuildWarMainPanelTop: XUiNode
---@field private _Control XGuildWarControl
local XUiPanelTop = XClass(XUiNode, "XUiPanelTop")
local XUiGridBuff = require("XUi/XUiGuildWar/Map/XUiGridBuff")

function XUiPanelTop:OnStart(battleManager)
    self.BattleManager = battleManager
    self:SetButtonCallBack()
    self.GridBuffList = {}
    self.GridBuff.gameObject:SetActiveEx(false)
    ---@type XPool
    self.GridBuffPool = XPool.New(function()
        local obj = CS.UnityEngine.Object.Instantiate(self.GridBuff,self.PanelBuffList)
        local grid = XUiGridBuff.New(obj, self)
        return grid
    end, function(grid) 
        grid:Close()
        grid:OnBackPool()
    end, false)
end

function XUiPanelTop:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTIONLIST_OVER, self.UpdatePanel, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_NODEDATA_CHANGE, self.UpdatePanel, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ATTACKINFO_UPDATE, self.UpdatePanel, self)
end

function XUiPanelTop:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTIONLIST_OVER, self.UpdatePanel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_NODEDATA_CHANGE, self.UpdatePanel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ATTACKINFO_UPDATE, self.UpdatePanel, self)

end

function XUiPanelTop:SetButtonCallBack()

end

function XUiPanelTop:UpdatePanel()
    self.TxtName.text = self.BattleManager:GetDifficultyName()
    
    -- 回收Buff
    if not XTool.IsTableEmpty(self.GridBuffList) then
        for i = #self.GridBuffList, 1, -1 do
            self.GridBuffPool:ReturnItemToPool(self.GridBuffList[i])
            table.remove(self.GridBuffList, i)
        end
    end
    
    -- 刷新buff节点的buff显示
    local buffNodeLest = self.BattleManager:GetBuffNodes()
    for index,buffNode in pairs(buffNodeLest or {}) do
        local grid = self.GridBuffPool:GetItemFromPool()
        grid:Open()
        grid:UpdateGrid(buffNode)

        table.insert(self.GridBuffList, grid)
    end
    
    -- 刷新龙怒周目buff
    if self._Control.DragonRageControl:GetIsOpenDragonRage() then
        local buffId = self._Control.DragonRageControl:GetGameThroughBuffId()

        if XTool.IsNumberValid(buffId) then
            local grid = self.GridBuffPool:GetItemFromPool()
            grid:Open()
            grid:UpdateGridByBuffId(buffId)
            grid:SetIsDragonRageBuff()
            table.insert(self.GridBuffList, grid)
        end
    end

    local IsNotEmpty = not XTool.IsTableEmpty(self.GridBuffList)
    self.BuffTitle.gameObject:SetActiveEx(IsNotEmpty)
end

function XUiPanelTop:UpdateTime(time)
    if XDataCenter.GuildWarManager.CheckRoundIsInTime() then
        self.TxtTime.text = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.ACTIVITY)
    else
        self.TxtTime.text = XUiHelper.GetText("GuildWarRoundTimeOut")
    end
end

return XUiPanelTop