local XUiPanelTop = XClass(nil, "XUiPanelTop")
local XUiGridBuff = require("XUi/XUiGuildWar/Map/XUiGridBuff")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiPanelTop:Ctor(ui, base, battleManager)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.BattleManager = battleManager
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
    self.GridBuffList = {}
    self.GridBuff.gameObject:SetActiveEx(false)
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
    
    local buffNodeLest = self.BattleManager:GetBuffNodes()
    for index,buffNode in pairs(buffNodeLest or {}) do
        if not self.GridBuffList[index] then
            local obj = CS.UnityEngine.Object.Instantiate(self.GridBuff,self.PanelBuffList)
            local grid = XUiGridBuff.New(obj, self)
            self.GridBuffList[index] = grid
        end
        
        self.GridBuffList[index]:UpdateGrid(buffNode)
        self.GridBuffList[index].GameObject:SetActiveEx(true)
    end
    
    for index = #buffNodeLest + 1, #self.GridBuffList do
        self.GridBuffList[index].GameObject:SetActiveEx(false)
    end

    local IsNotEmpty = (buffNodeLest and next(buffNodeLest)) and true
    self.BuffTitle.gameObject:SetActiveEx(IsNotEmpty)
end

function XUiPanelTop:UpdateTime(time)
    if XDataCenter.GuildWarManager.CheckRoundIsInTime() then
        self.TxtTime.text = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.ACTIVITY)
    else
        self.TxtTime.text = XUiHelper.GetText("GuildWarRoundTimeOut")
    end
end

function XUiPanelTop:ShowPanel()
    self.GameObject:SetActiveEx(true)
end

function XUiPanelTop:HidePanel()
    self.GameObject:SetActiveEx(false)
end

return XUiPanelTop