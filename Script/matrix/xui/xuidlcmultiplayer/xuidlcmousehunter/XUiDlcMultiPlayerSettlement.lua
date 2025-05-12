local XUiDlcSettlementBase = require("XUi/XUiDlcBase/XUiDlcSettlementBase")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XSpecialTrainActionRandom = require("XUi/XUiSpecialTrainBreakthrough/XSpecialTrainActionRandom")
local XUiDlcMultiPlayerTitleCommon = require(
    "XUi/XUiDlcMultiPlayer/XUiDlcMultiPlayerCommon/XUiDlcMultiPlayerTitleCommon")

---@class XUiDlcMultiPlayerSettlement : XUiDlcSettlementBase
---@field BtnClose XUiComponent.XUiButton
---@field BtnData XUiComponent.XUiButton
---@field ImgMvp UnityEngine.UI.Image
---@field TxtNum UnityEngine.UI.Text
---@field TxtScore UnityEngine.UI.Text
---@field PanelTitle UnityEngine.RectTransform
---@field ListTitle UnityEngine.RectTransform
---@field TxtCoinNum UnityEngine.UI.Text
---@field RImgCoin UnityEngine.UI.RawImage
---@field TxtTips UnityEngine.UI.Text
---@field TxtItemTitle UnityEngine.UI.Text
---@field TitleGrid UnityEngine.RectTransform
---@field PanelWin UnityEngine.RectTransform
---@field PanelFail UnityEngine.RectTransform
---@field WinEffect UnityEngine.RectTransform
---@field _Control XDlcMultiMouseHunterControl
local XUiDlcMultiPlayerSettlement = XClass(XUiDlcSettlementBase, "XUiDlcMultiPlayerSettlement")

-- region 生命周期

function XUiDlcMultiPlayerSettlement:OnAwake()
    ---@type XUiPanelRoleModel
    self._RoleModel = nil
    ---@type XSpecialTrainActionRandom
    self._ActionRandom = XSpecialTrainActionRandom.New()
    self._Result = nil

    self._TitleGridList = {}

    self._MainCameraFar = nil
    self._ChangeCameraFar = nil
    self._SettleCameraFar = nil
    self._MainCameraNear = nil
    self._ChangeCameraNear = nil
    self._SettleCameraNear = nil

    self._MainModelRoot = nil
    self._SettleModelRoot = nil

    self:_RegisterButtonClicks()
end

---@param result XDlcMultiMouseHunterResult
function XUiDlcMultiPlayerSettlement:OnStart(result)
    self._Result = result

    self:_Init()
    self:_InitCamera()
    self:_InitModelRoot()
    self:_InitRoleModel()
end

function XUiDlcMultiPlayerSettlement:OnEnable()
    self:_RefreshModel()
end

function XUiDlcMultiPlayerSettlement:OnDisable()
    self._ActionRandom:Stop()
end

-- endregion

-- region 按钮事件
function XUiDlcMultiPlayerSettlement:OnBtnCloseClick()
    self:Close()
end

function XUiDlcMultiPlayerSettlement:OnBtnDataClick()
    if self._Result then
        XLuaUiManager.Open("UiDlcMultiPlayerData", self._Result)
    end
end

-- endregion

-- region 私有方法
function XUiDlcMultiPlayerSettlement:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick, true)
    self:RegisterClickEvent(self.BtnData, self.OnBtnDataClick, true)
end

---@param result XDlcMultiMouseHunterResult
function XUiDlcMultiPlayerSettlement:_Init()
    if self._Result then
        local result = self._Result
        local coinIcon = self._Control:GetCoinIcon()
        local titleList = result:GetTitleRewards()
        local coinCount = result:GetCurrencyReward()
        local currentCoinCount = result:GetCurrentCurrencyReward()
        local dailyUpper = self._Control:GetCurrencyLimit()

        self.WinEffect.gameObject:SetActiveEx(result:GetIsSelfCampWin())
        self.BtnData.gameObject:SetActiveEx(not result:GetIsEarlySettlement())
        self.TxtTips.gameObject:SetActiveEx(false)
        self.TxtItemTitle.text = result:IsCatCamp() and self._Control:GetSettleDataCatTitle()
                                     or self._Control:GetSettleDataMouseTitle()
        if result:GetIsEarlySettlement() then
            self.PanelWin.gameObject:SetActiveEx(false)
            self.PanelFail.gameObject:SetActiveEx(true)
        else
            self.PanelWin.gameObject:SetActiveEx(result:GetIsSelfCampWin())
            self.PanelFail.gameObject:SetActiveEx(not result:GetIsSelfCampWin())
        end
        self.TxtNum.text = result:IsCatCamp() and result:GetEliminatePlayerCount() or result:GetSurvivalTime()
        self.TxtCoinNum.text =
            XUiHelper.GetText("DlcMultiplayerCurrencyReward", coinCount, dailyUpper, currentCoinCount)
        self.TxtScore.text = result:GetScore()
        self.ImgMvp.gameObject:SetActiveEx(result:GetIsMvp() and result:GetIsSelfCampWin())
        self.ImgSvp.gameObject:SetActiveEx(result:GetIsMvp() and not result:GetIsSelfCampWin())
        self.RImgCoin:SetRawImage(coinIcon)
        self.ListTitle.gameObject:SetActiveEx(true)
        self.PanelTitle.gameObject:SetActiveEx(false)

        if not XTool.IsTableEmpty(titleList) then
            for i, titleId in pairs(titleList) do
                local panelTitle = XUiHelper.Instantiate(self.PanelTitle, self.ListTitle)
                local titleObject = panelTitle:FindTransform("PanelDlcMultiPlayerTitle")

                panelTitle.gameObject:SetActiveEx(true)
                if titleObject then
                    self._TitleGridList[i] = XUiDlcMultiPlayerTitleCommon.New(titleObject, self, titleId)
                end
            end
        end
    end
end

function XUiDlcMultiPlayerSettlement:_InitModelRoot()
    local root = self.UiModelGo.transform

    self._MainModelRoot = root:FindTransform("PanelRoleModel")
    self._SettleModelRoot = root:FindTransform("PanelSettleRoleModel")

    self._MainModelRoot.gameObject:SetActiveEx(false)
    self._SettleModelRoot.gameObject:SetActiveEx(true)
end

function XUiDlcMultiPlayerSettlement:_InitCamera()
    local root = self.UiModelGo.transform

    self._MainCameraFar = root:FindTransform("UiMainCamFar")
    self._ChangeCameraFar = root:FindTransform("UiChangeCamFar")
    self._SettleCameraFar = root:FindTransform("UiSettleCamFar")
    self._MainCameraNear = root:FindTransform("UiMainCamNear")
    self._ChangeCameraNear = root:FindTransform("UiChangeCamNear")
    self._SettleCameraNear = root:FindTransform("UiSettleCamNear")

    self._MainCameraFar.gameObject:SetActiveEx(false)
    self._MainCameraNear.gameObject:SetActiveEx(false)
    self._ChangeCameraFar.gameObject:SetActiveEx(false)
    self._ChangeCameraNear.gameObject:SetActiveEx(false)
    self._SettleCameraFar.gameObject:SetActiveEx(true)
    self._SettleCameraNear.gameObject:SetActiveEx(true)
end

function XUiDlcMultiPlayerSettlement:_InitRoleModel()
    self._RoleModel = XUiPanelRoleModel.New(self._SettleModelRoot, self.Name, nil, true)
end

function XUiDlcMultiPlayerSettlement:_RefreshModel()
    local fightBeginData = XMVCA.XDlcRoom:GetFightBeginData()
    ---@type XDlcWorldData
    local worldData = not fightBeginData:IsWorldClear() and fightBeginData:GetWorldData() or nil
    ---@type XDlcPlayerData
    local playerData = worldData and worldData:GetPlayerDataById(XPlayer.Id) or nil
    local characterId = playerData and playerData:GetCharacterId() or 0

    if XTool.IsNumberValid(characterId) then
        self._RoleModel:ShowRoleModel()
        self._ActionRandom:Stop()
        self._Control:UpdateCharacterModelByCharacterId(self._RoleModel, characterId, function()
            local animator = self._RoleModel:GetAnimator()
            local action = nil

            if self._Result:GetIsMvp() then
                action = self._Control:GetCharacterMvpActionByCharacterId(characterId)
            elseif self._Result:GetIsSelfCampWin() then
                action = self._Control:GetCharacterVictoryActionByCharacterId(characterId)
            else
                action = self._Control:GetCharacterFailActionByCharacterId(characterId)
            end

            self._ActionRandom:SetAnimatorWithCustomActionArray(animator, {
                action,
            }, self._RoleModel, 0)
            self._ActionRandom:Play()
        end, true)
    end
end

-- endregion

return XUiDlcMultiPlayerSettlement
