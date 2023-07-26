local XUiPanelBuff = XClass(nil, "XUiPanelBuff")
local XUiGridBuff = require("XUi/XUiSameColorGame/Battle/XUiGridBuff")
local CSTextManagerGetText = CS.XTextManager.GetText
local MaxBuffCount = 5
function XUiPanelBuff:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.BattleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    XTool.InitUiObject(self)
    self.PanelBossBuffHint.gameObject:SetActiveEx(false)
    self:Init()
end

function XUiPanelBuff:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_ADDBUFF, self.BuffChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_SUBBUFF, self.BuffChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_ROUND_CHANGE, self.DoBuffCountDown, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_BUFF_LEFTTIME_CHANGE, self.DoBuffCountDown, self)
end

function XUiPanelBuff:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_ADDBUFF, self.BuffChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_SUBBUFF, self.BuffChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_ROUND_CHANGE, self.DoBuffCountDown, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_BUFF_LEFTTIME_CHANGE, self.DoBuffCountDown, self)
end

function XUiPanelBuff:Init()
    self.GridBuffMore = {}
    self.GridBuffList = {}
    self.GridBuff.gameObject:SetActiveEx(false)
    self.GridMore.gameObject:SetActiveEx(false)
end

function XUiPanelBuff:CreateBuffGrid(gridObj)
    local obj = CS.UnityEngine.Object.Instantiate(gridObj,self.PanelBuffParent)
    obj.gameObject:SetActiveEx(true)
    local grid = XUiGridBuff.New(obj, self)
    return grid
end

function XUiPanelBuff:BuffChange(data)
    local buffList = self.BattleManager:GetShowBuffList()
    for index,buff in pairs(buffList) do
        if index < MaxBuffCount + 1 then
            local gridBuff = self.GridBuffList[index]
            if not gridBuff then
                gridBuff = self:CreateBuffGrid(self.GridBuff)
                self.GridBuffList[index] = gridBuff
            end
            gridBuff:UpdateGrid(buff,false)
        elseif index == MaxBuffCount + 1 then
            if not self.GridBuffMore or not next(self.GridBuffMore)then
                self.GridBuffMore = self:CreateBuffGrid(self.GridMore)
            end
            self.GridBuffMore:UpdateGrid(nil, false)
        end
    end
    
    for index = #buffList + 1, #self.GridBuffList do
        local gridBuff = self.GridBuffList[index]
        if gridBuff then
            gridBuff:UpdateGrid(nil, false)
        end
    end
    
    if data then
        self.Base:PlayGameSound("CharacterBuff")
        self.BattleManager:DoActionFinish(data.ActionType)
    else
        self.Base:PlayGameSound("BossBuff")
    end
    self:CheckNoBuff()
end

function XUiPanelBuff:DoBuffCountDown() 
    for _,gridBuff in pairs(self.GridBuffList or {}) do
        gridBuff:DoCountdown()
    end
end

function XUiPanelBuff:CheckNoBuff()
    local buffList = self.BattleManager:GetShowBuffList()
    local IsNoBuff = not buffList or not next(buffList)
    self.GridNone.gameObject:SetActiveEx(IsNoBuff)
    
    if self.GridBuffMore and next(self.GridBuffMore) then
        self.GridBuffMore.GameObject:SetActiveEx(buffList and #buffList > MaxBuffCount) 
    end
end

return XUiPanelBuff