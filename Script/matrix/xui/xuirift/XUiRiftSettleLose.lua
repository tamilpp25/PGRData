---@class XUiRiftSettleLose : XLuaUi 大秘境战斗失败结算界面
---@field _Control XRiftControl
local XUiRiftSettleLose = XLuaUiManager.Register(XLuaUi, "UiRiftSettleLose")

function XUiRiftSettleLose:OnAwake()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnClose)
    self:RegisterClickEvent(self.BtnBattle, self.OnBtnBattle)
end

function XUiRiftSettleLose:OnStart(settleData)
    if not settleData then
        return
    end
    self._SettleData = settleData
    self._IsLuckyStage = settleData.IsLuckyNode
    local endTime = self._Control:GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)
    self:SetMouseVisible()
end

function XUiRiftSettleLose:OnEnable()
    self.Super.OnEnable(self)
    local fightLayerId = self._Control:GetCurrFightLayerId()
    self._FightLayer = self._Control:GetEntityFightLayerById(fightLayerId)
    self.TxtStageName.text = self._FightLayer:GetConfig().Name
    self.TxtFinishTimes.text = self._SettleData.Wave - 1
    self.TxtAllTimes.text = self._SettleData.TotalWave
    self.TxtPeople.text = XUiHelper.GetText("RiftSettlePeople", self._Control:GetCurFightCharCount())
end

function XUiRiftSettleLose:OnDestroy()

end

function XUiRiftSettleLose:OnBtnBattle()
    local xChapter = self._FightLayer:GetParent()
    self._Control:CheckDayTipAndDoFun(xChapter, function()
        if self._FightLayer:CheckIsOwnFighting() then
            XLog.Error("数据错误，没有层结算完毕就再次请求刷新作战层数据 ")
            return
        end
        -- 直接再进入战斗，关闭界面会在退出战斗前通过remove移除
        local firstStageGroup = self._FightLayer:GetStageGroup()
        self._Control:SetCurrSelectRiftStage(firstStageGroup)

        local xTeam = self._Control:GetSingleTeamData()
        self._Control:EnterFight(xTeam)
    end)
end

function XUiRiftSettleLose:OnBtnClose()
    self:Close()
end

function XUiRiftSettleLose:SetMouseVisible()
    -- 这里只有PC端开启了键鼠以后才能获取到设备
    if CS.XFight.Instance and CS.XFight.Instance.InputSystem then
        local inputKeyboard = CS.XFight.Instance.InputSystem:GetDevice(typeof(CS.XInputKeyboard))
        inputKeyboard.HideMouseEvenByDrag = false
    end
    CS.UnityEngine.Cursor.lockState = CS.UnityEngine.CursorLockMode.None
    CS.UnityEngine.Cursor.visible = true
end

return XUiRiftSettleLose