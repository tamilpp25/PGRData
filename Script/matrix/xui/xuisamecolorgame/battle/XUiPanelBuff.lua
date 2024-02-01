---@class XUiSCBattlePanelBuff
local XUiPanelBuff = XClass(nil, "XUiPanelBuff")
local XUiGridBuff = require("XUi/XUiSameColorGame/Battle/XUiGridBuff")
local MaxBuffCount = 5
function XUiPanelBuff:Ctor(ui, base)
    ---@type XUiSameColorGameBattle
    self.Base = base
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    
    self.BattleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    self.PanelBossBuffHint.gameObject:SetActiveEx(false)
    self:Init()
end

function XUiPanelBuff:OnEnable()
    self:AddEventListener()
end

function XUiPanelBuff:OnDisable()
    self:RemoveEventListener()
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
        self.BattleManager:DoActionFinish(data.ActionType)
        XEventManager.DispatchEvent(XEventId.EVENT_SC_GAME_SOUND_PLAY, "CharacterBuff")
    else
        XEventManager.DispatchEvent(XEventId.EVENT_SC_GAME_SOUND_PLAY, "BossBuff")
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

--region Event
function XUiPanelBuff:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_ADD_BUFF, self.BuffChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_SUB_BUFF, self.BuffChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_ROUND_CHANGE, self.DoBuffCountDown, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_BUFF_LEFT_TIME_CHANGE, self.DoBuffCountDown, self)
end

function XUiPanelBuff:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_ADD_BUFF, self.BuffChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_SUB_BUFF, self.BuffChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_ROUND_CHANGE, self.DoBuffCountDown, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_BUFF_LEFT_TIME_CHANGE, self.DoBuffCountDown, self)
end
--endregion

return XUiPanelBuff