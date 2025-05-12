local XUiDlcSettlementBase = require("XUi/XUiDlcBase/XUiDlcSettlementBase")

---@class XUiDlcCasualplayerSettlement : XUiDlcSettlementBase
---@field GridChar UnityEngine.RectTransform
---@field RoomCharCase1 UnityEngine.RectTransform
---@field RoomCharCase2 UnityEngine.RectTransform
---@field RoomCharCase3 UnityEngine.RectTransform
---@field BtnClose XUiComponent.XUiButton
---@field ImgScoring UnityEngine.UI.RawImage
---@field TxtScore UnityEngine.UI.Text
---@field BtnData XUiComponent.XUiButton
---@field _Control XDlcCasualControl
local XUiDlcCasualplayerSettlement = XLuaUiManager.Register(XUiDlcSettlementBase, "UiDlcCasualplayerSettlement")
local XUiDlcCasualplayerSettlementGrid = require("XUi/XUiDlcCasualGame/XUiDlcCasualplayerSettlementGrid")
---@type XUiDlcCasualGamesUtility
local XUiDlcCasualGamesUtility = require("XUi/XUiDlcCasualGame/XUiDlcCasualGamesUtility")

function XUiDlcCasualplayerSettlement:Ctor()
    ---@type XUiDlcCasualplayerSettlementGrid[]
    self._CharGirdList = {}
    ---@type XDlcCasualResult
    self._Result = nil
    self._ModelCaseList = nil
    self._CloseTimer = nil
    self._IsCanClose = false
end

function XUiDlcCasualplayerSettlement:OnAwake()
    local root = self.UiModelGo.transform

    self._ModelCaseList = {
        root:FindTransform("PanelModelCase1"),
        root:FindTransform("PanelModelCase2"),
        root:FindTransform("PanelModelCase3"),
    }
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnData, self.OnBtnDataClick)
    self:_StartCloseTimer()
end

---@param result XDlcCasualResult
function XUiDlcCasualplayerSettlement:OnStart(result)
    if not result or result:IsPlayerResultListEmpty() then
        self:Close()
        return
    end

    self._Result = result
    self:_HideEffect()
    self:_Init()
end

function XUiDlcCasualplayerSettlement:OnDestroy()
    self:_StopCloseTimer()
    self._CharGirdList = nil
end

function XUiDlcCasualplayerSettlement:OnBtnDataClick()
    XLuaUiManager.Open("UiDlcCasualDate", self._Result)
end

function XUiDlcCasualplayerSettlement:OnBtnCloseClick()
    if self._IsCanClose then
        if XMVCA.XDlcCasual:ExCheckInTime() then
            self:Close()
        else
            self._Control:AutoCloseHandler()
        end
    end
end

function XUiDlcCasualplayerSettlement:_Init()
    local result = self._Result
    local players = result:GetPlayerResultList()
    local isMvpSameScore, players = XUiDlcCasualGamesUtility.GetResultHasMvpAndPlayerList(players)
    
    XUiDlcCasualGamesUtility.InitRoomCharCase("RoomCharCase", self.GridChar, function(index, grid)
        local playerData = players[index]
        local isMvp = index == 1 and not isMvpSameScore
        local case = self._ModelCaseList[index]
        ---@type XUiDlcCasualplayerSettlementGrid
        local charGrid = XUiDlcCasualplayerSettlementGrid.New(grid, self, playerData, isMvp, case)
        local score = playerData:GetPersonalScore()

        charGrid:Refresh(score)
        self._CharGirdList[index] = charGrid
    end, self, #players, true)

    if self.ImgScoring then
        self.ImgScoring:SetRawImage(self._Control:GetScoreJudgeLevel(result:GetWorldId(), result:GetTeamScore()))
    end
    self.TxtScore.text = XUiHelper.GetText("DlcCasualTeamScore", result:GetTeamScore()) 
    self.PanelNew.gameObject:SetActiveEx(result:IsTeamNewRecord())
end

function XUiDlcCasualplayerSettlement:_HideEffect()
    local root = self.UiModelGo.transform
    local fullScreenBackground = self.Transform:FindTransform("FullScreenBackground")

    if fullScreenBackground then
        local starEffect = fullScreenBackground:FindTransform("Effect")

        if starEffect then
            starEffect.gameObject:SetActiveEx(false)
        end
    end 

    for i = 1, 3 do
        local effectObj = root:FindTransform("ImgEffectTongDiao" .. i)

        if not XTool.UObjIsNil(effectObj) then
            effectObj.gameObject:SetActiveEx(false)
        end
    end
end

function XUiDlcCasualplayerSettlement:_StartCloseTimer()
    if not self._CloseTimer then
        self:_StopCloseTimer()
    end
    local countDownTime = CS.XGame.Config:GetInt("OnlinePraiseCountDown")

    self._CloseTimer = XScheduleManager.ScheduleOnce(function()
        self._IsCanClose = true
        self._CloseTimer = nil
    end, countDownTime * XScheduleManager.SECOND)
end

function XUiDlcCasualplayerSettlement:_StopCloseTimer()
    if self._CloseTimer then
        XScheduleManager.UnSchedule(self._CloseTimer)
        self._CloseTimer = nil
    end
end

return XUiDlcCasualplayerSettlement
