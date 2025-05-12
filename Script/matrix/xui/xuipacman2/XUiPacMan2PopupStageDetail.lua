local XUiPacMan2Target = require("XUi/XUiPacMan2/XUiPacMan2Target")
local XUiPacMan2IconNode = require("XUi/XUiPacMan2/XUiPacMan2IconNode")
local XUiPacMan2StageBubble = require("XUi/XUiPacMan2/XUiPacMan2StageBubble")

---@class XUiPacMan2PopupStageDetail : XLuaUi
---@field _Control XPacMan2Control
local XUiPacMan2PopupStageDetail = XLuaUiManager.Register(XLuaUi, "UiPacMan2PopupStageDetail")

function XUiPacMan2PopupStageDetail:OnAwake()
    self:BindExitBtns(self.BtnTanchuangCloseBig)
    XUiHelper.RegisterClickEvent(self, self.BtnNext, self.OnClickStart, nil, true)
    self.GridTarget.gameObject:SetActiveEx(false)
    ---@type XUiPacMan2Target[]
    self._GridsTarget = {}
    ---@type XUiPacMan2IconNode[]
    self._GridsProp = {}
    self.GridProp.gameObject:SetActiveEx(false)
    ---@type XUiPacMan2IconNode[]
    self._GridGhost = {}
    self.GridMonster.gameObject:SetActiveEx(false)

    self.PanelBubbleProp.gameObject:SetActiveEx(false)
    ---@type XUiPacMan2StageBubble
    self._BubbleProp = XUiPacMan2StageBubble.New(self.PanelBubbleProp, self)
    self.PanelBubbleMonster.gameObject:SetActiveEx(false)
    ---@type XUiPacMan2StageBubble
    self._BubbleGhost = XUiPacMan2StageBubble.New(self.PanelBubbleMonster, self)
    XUiHelper.RegisterClickEvent(self, self.BtnCloseBubble, self.CloseBubble)
end

function XUiPacMan2PopupStageDetail:OnStart(stageId)
    self._StageId = stageId
end

function XUiPacMan2PopupStageDetail:OnEnable()
    self:Update()
end

function XUiPacMan2PopupStageDetail:OnDisable()

end

function XUiPacMan2PopupStageDetail:Update()
    local data = self._Control:GetStageDetail(self._StageId)
    if not data then
        XLog.Error("[XUiPacMan2PopupStageDetail] Update stageId = " .. tostring(self._StageId) .. " not found")
        return
    end
    self.TxtTitle.text = data.Name
    for i = 1, #data.Target do
        local targetData = data.Target[i]
        local target = self._GridsTarget[i]
        if not target then
            ---@type UnityEngine.GameObject
            local gridTarget = self.GridTarget
            local ui = XUiHelper.Instantiate(gridTarget, gridTarget.transform.parent)
            target = XUiPacMan2Target.New(ui, self)
            self._GridsTarget[i] = target
        end
        target:Open()
        target:Update(targetData)
    end

    for i = 1, #data.ShowProp do
        local prop = data.ShowProp[i]
        local gridProp = self._GridsProp[i]
        if not gridProp then
            ---@type UnityEngine.GameObject
            local uiGridProp = self.GridProp
            local ui = XUiHelper.Instantiate(uiGridProp, uiGridProp.transform.parent)
            gridProp = XUiPacMan2IconNode.New(ui, self)
            self._GridsProp[i] = gridProp
        end
        gridProp:Open()
        gridProp:Update(prop)
    end

    for i = 1, #data.ShowGhost do
        local ghost = data.ShowGhost[i]
        local gridGhost = self._GridGhost[i]
        if not gridGhost then
            ---@type UnityEngine.GameObject
            local uiGridGhost = self.GridMonster
            local ui = XUiHelper.Instantiate(uiGridGhost, uiGridGhost.transform.parent)
            gridGhost = XUiPacMan2IconNode.New(ui, self)
            self._GridGhost[i] = gridGhost
        end
        gridGhost:Open()
        gridGhost:Update(ghost)
    end
end

function XUiPacMan2PopupStageDetail:OnClickStart()
    self:Close()
    XLuaUiManager.Open("UiPacMan2Game", self._StageId)
end

---@param data XUiPacMan2IconNodeData
function XUiPacMan2PopupStageDetail:OpenDetail(data)
    if data.IsProp then
        self.BtnCloseBubble.gameObject:SetActiveEx(true)
        self._BubbleProp:Open()
        self._BubbleProp:Update(data)
    else
        self.BtnCloseBubble.gameObject:SetActiveEx(true)
        self._BubbleGhost:Open()
        self._BubbleGhost:Update(data)
    end
end

function XUiPacMan2PopupStageDetail:CloseBubble()
    self._BubbleProp:Close()
    self._BubbleGhost:Close()
    self.BtnCloseBubble.gameObject:SetActiveEx(false)
end

return XUiPacMan2PopupStageDetail