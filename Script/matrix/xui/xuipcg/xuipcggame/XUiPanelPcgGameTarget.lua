---@class XUiPanelPcgGameTarget : XUiNode
---@field private _Control XPcgControl
---@field Parent XUiPcgGame
local XUiPanelPcgGameTarget = XClass(XUiNode, "XUiPanelPcgGameTarget")

function XUiPanelPcgGameTarget:OnStart()
    self:RegisterUiEvents()
end

function XUiPanelPcgGameTarget:OnEnable()
    
end

function XUiPanelPcgGameTarget:OnDisable()
    
end

function XUiPanelPcgGameTarget:OnDestroy()
    
end

function XUiPanelPcgGameTarget:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnAgain, self.OnBtnAgainClick, nil, true)
end

function XUiPanelPcgGameTarget:OnBtnAgainClick()
    -- 非出牌阶段不可操作
    if not self.Parent:IsPlayCardState() then return end
    -- 正在播放动画
    if self.Parent:IsAnim() then return end
    -- 游戏结束
    local gameState = self._Control.GameSubControl:GetGameState()
    if gameState == XEnumConst.PCG.GAME_STATE.End then return end
    
    local stageId = self.StageId
    local stageType = self._Control:GetStageType(self.StageId)
    local content = self._Control:GetClientConfig("ReStartContent")
    XLuaUiManager.Open("UiPcgPopup", content, function()
        if stageType == XEnumConst.PCG.STAGE_TYPE.ENDLESS then
            XMVCA.XPcg:PcgStageEndRequest(stageId, function()
                self.Parent:CheckGameEnd()
            end)
        else
            local characters = self._Control.GameSubControl:GetLastCharacterIds()
            XMVCA.XPcg:PcgStageRestartRequest(self.StageId, characters)
        end
    end)
end

function XUiPanelPcgGameTarget:Refresh()
    ---@type XPcgPlayingStage
    local stageData = self._Control.GameSubControl:GetPlayingStageData()
    self.StageId = stageData:GetId()
    local stageType = self._Control:GetStageType(self.StageId)
    local isNormal = stageType ~= XEnumConst.PCG.STAGE_TYPE.ENDLESS
    self.PanelNoraml.gameObject:SetActiveEx(isNormal)
    self.PanelEndless.gameObject:SetActiveEx(not isNormal)
    if isNormal then
        self:RefreshPanelNormal()
    else
        self:RefreshPanelEndless()
    end
end

function XUiPanelPcgGameTarget:RefreshPanelNormal()
    ---@type XPcgPlayingStage
    local stageData = self._Control.GameSubControl:GetPlayingStageData()
    local commander = stageData:GetCommander()
    local rebootCnt = commander:GetReboot()
    local starConditions = self._Control:GetStageStarConditions(self.StageId)
    local starDescs = self._Control:GetStageStarDescs(self.StageId)
    for i, conditionCnt in ipairs(starConditions) do
        local isReach = conditionCnt == -1 or rebootCnt <= conditionCnt
        local starUiObj = self["GridStar"..tostring(i)]
        starUiObj:GetObject("PanelActive").gameObject:SetActiveEx(isReach)
        starUiObj:GetObject("PanelUnActive").gameObject:SetActiveEx(not isReach)
        local desc = starDescs[i]
        starUiObj:GetObject("TxtUnActive").text = desc
        starUiObj:GetObject("TxtActive").text = desc
    end

    -- 重启次数
    self.TxtRebootNum.text = tostring(rebootCnt)
end

function XUiPanelPcgGameTarget:RefreshPanelEndless()
    ---@type XPcgPlayingStage
    local stageData = self._Control.GameSubControl:GetPlayingStageData()
    local score = stageData:GetScore()
    self.TxtScoreNum.text = tostring(score)
end

return XUiPanelPcgGameTarget
