local XUiPacMan2Target = require("XUi/XUiPacMan2/XUiPacMan2Target")

---@class XUiPacMan2PopupSettlement : XLuaUi
---@field _Control XPacMan2Control
local XUiPacMan2PopupSettlement = XLuaUiManager.Register(XLuaUi, "UiPacMan2PopupSettlement")

function XUiPacMan2PopupSettlement:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnAgain1, self.OnClickAgain)
    XUiHelper.RegisterClickEvent(self, self.BtnAgain2, self.OnClickAgain)
    XUiHelper.RegisterClickEvent(self, self.BtnNext, self.OnClickNext)
    XUiHelper.RegisterClickEvent(self, self.BtnExit, self.OnClickExit)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangCloseBig, self.OnClickExit)
    self.GridTarget.gameObject:SetActiveEx(false)
    ---@type XUiPacMan2Target[]
    self._GridsTarget = {}

    self._StageId = 0
end

---@param data XPacMan2SettlementData
function XUiPacMan2PopupSettlement:OnStart(data)
    if data.IsWin then
        self.PanelWin.gameObject:SetActive(true)
        self.PanelLost.gameObject:SetActive(false)
        self.TxtScore.text = data.Score
        self.TxtNodeCount1.text = data.Orbs
        self.TxtNodeScore1.text = data.OrbScore
        self.TxtNodeCount2.text = data.Kills
        self.TxtNodeScore2.text = data.KillScore
        self.TxtNodeCount3.text = data.Hp
        self.TxtNodeScore3.text = data.HpScore
        self.TxtNodeCount4.text = data.ShoeCount
        self.TxtNodeScore4.text = data.ShoeScore
    else
        self.PanelWin.gameObject:SetActive(false)
        self.PanelLost.gameObject:SetActive(true)
    end

    local stageId = data.StageId
    self._StageId = stageId
    local targetList = self._Control:GetTargetList(stageId, data.Score)
    for i = 1, #targetList do
        local target = self._GridsTarget[i]
        if not target then
            ---@type UnityEngine.GameObject
            local gridTarget = self.GridTarget
            local ui = XUiHelper.Instantiate(gridTarget, gridTarget.transform.parent)
            target = XUiPacMan2Target.New(ui, self)
            self._GridsTarget[i] = target
        end
        target:Open()
        target:Update(targetList[i])
    end
    self:PlayAnimationList()
end

function XUiPacMan2PopupSettlement:OnEnable()
    self:UpdateBtnNext()
end

function XUiPacMan2PopupSettlement:OnDisable()

end

function XUiPacMan2PopupSettlement:UpdateBtnNext()
    -- 没有下一关
    local nextStageId = self._Control:GetNextStageId(self._StageId)
    if not nextStageId then
        self.BtnNext.gameObject:SetActiveEx(false)
        return
    end

    --没有达到解锁条件，点击下一关不不可进入
    local isInTime = self._Control:IsStageInTime(nextStageId)
    if not isInTime then
        self.BtnNext.gameObject:SetActiveEx(false)
        return
    end

    self.BtnNext.gameObject:SetActiveEx(true)
end

function XUiPacMan2PopupSettlement:OnClickAgain()
    self:Close()
    XLuaUiManager.Remove("UiPacMan2Game")
    XScheduleManager.ScheduleNextFrame(function()
        XLuaUiManager.Open("UiPacMan2Game", self._StageId)
    end)
end

function XUiPacMan2PopupSettlement:OnClickNext()
    local nextStageId = self._Control:GetNextStageId(self._StageId)
    if nextStageId then
        self:Close()
        XLuaUiManager.Remove("UiPacMan2Game")
        XScheduleManager.ScheduleNextFrame(function()
            XLuaUiManager.Open("UiPacMan2Game", nextStageId)
        end)
    end
end

function XUiPacMan2PopupSettlement:OnClickExit()
    self:Close()
    XLuaUiManager.Close("UiPacMan2Game")
end

function XUiPacMan2PopupSettlement:PlayAnimationList()
    for i = 1, #self._GridsTarget do
        local target = self._GridsTarget[i]
        local timer
        target:Close()
        timer = XScheduleManager.ScheduleOnce(function()
            target:Open()
            target:PlayAnimation("GridTargetEnable")
            self:_RemoveTimerIdAndDoCallback(timer)
        end, i * 200 + 200)
        self:_AddTimerId(timer)
    end
end

return XUiPacMan2PopupSettlement