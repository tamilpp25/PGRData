
---@class XUiBlackRockChessSetUp : XLuaUi
---@field _Control XBlackRockChessControl
local XUiBlackRockChessSetUp = XLuaUiManager.Register(XLuaUi, "UiBlackRockChessSetUp")

function XUiBlackRockChessSetUp:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiBlackRockChessSetUp:OnStart()
    local stageId = self._Control:GetStageId()
    local templateId = self._Control:GetStageStarRewardTemplateId(stageId)
    local rewards = self._Control:GetStarRewardByTemplateId(templateId)
    local star = self._Control:GetStageStar(stageId)
    for i = 1, 3 do
        local reward = rewards and rewards[i]
        local go = self["GridStageStar" .. i]
        if XTool.IsTableEmpty(reward) then
            go.gameObject:SetActiveEx(false)
        else
            go.gameObject:SetActiveEx(true)
            local uiObject = {}
            XTool.InitUiObjectByUi(uiObject, go)
            local isFinished = true
            for _, conditionId in pairs(reward.Conditions) do
                if not self._Control:CheckCondition(conditionId) then
                    isFinished = false
                    break
                end
            end
            uiObject.TxtUnActive.text = reward.Desc
            uiObject.TxtActive.text = reward.Desc
            uiObject.PanelUnActive.gameObject:SetActiveEx(not isFinished)
            uiObject.PanelActive.gameObject:SetActiveEx(isFinished)
        end
    end
end

function XUiBlackRockChessSetUp:InitUi()
end

function XUiBlackRockChessSetUp:InitCb()
    
    self.BtnContinue.CallBack = function() 
        self:OnBtnContinueClick()
    end
    
    self.BtnLeave.CallBack = function() 
        self:OnBtnLeaveClick()
    end
    
    self.BtnRePlay.CallBack = function() 
        self:OnBtnRePlayClick()
    end
end

function XUiBlackRockChessSetUp:InitView()
end

function XUiBlackRockChessSetUp:OnBtnContinueClick()
    self:Close()
end

function XUiBlackRockChessSetUp:OnBtnLeaveClick()
    if self._Control:GetChessPartner():IsPassPreparationStage() then
        self:OnLeaveView()
    else
        self._Control:RequestBlackRockChessPartnerLayout(handler(self, self.OnLeaveView))
    end
end

function XUiBlackRockChessSetUp:OnLeaveView()
    self:Close()
    XLuaUiManager.SafeClose("UiBlackRockChessBattleShop")
    XLuaUiManager.SafeClose("UiBlackRockChessBubbleSkill")
    XLuaUiManager.SafeClose("UiBlackRockChessBattle")
end

function XUiBlackRockChessSetUp:OnBtnRePlayClick()
    local content = self._Control:GetSecondaryConfirmationText(2)
    XLuaUiManager.Open("UiBlackRockChessTip", content, nil, function()
        --将战斗界面隐藏
        self._Control:OnCancelSkill(false)
        XLuaUiManager.Open("UiBiancaTheatreBlack")
        self._Control:GiveUpStage(function(res)
            XLuaUiManager.Close("UiBiancaTheatreBlack")
            local stageId = self._Control:GetStageId()
            self._Control:ProcessSettle(stageId, res.SettleResult)
        end)
    end)
end