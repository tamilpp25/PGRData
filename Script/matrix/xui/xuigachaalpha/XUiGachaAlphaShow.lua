---@class XUiGachaAlphaShow : XLuaUi
local XUiGachaAlphaShow = XLuaUiManager.Register(XLuaUi, "UiGachaAlphaShow")

local ODD_MAX = 9
local ODD_TYPE = 1
local EVEN_TYPE = 0
local EVEN_MAX = 10
local MAX_DRAW_COUNT = 10
local DrawState = {
    Show = 1,
    Result = 2
}

function XUiGachaAlphaShow:OnStart(gachaId, rewardList, state, isSkip)
    self._GachaId = gachaId
    self._GachaCfg = XGachaConfigs.GetGachaCfgById(self._GachaId)
    self._RewardList = rewardList
    ---@type XUiGridGachaShowReward[]
    self._GridRewardList = {}
    self._CurrIndex = 1
    self._CurrState = state or DrawState.Show
    self._IsSkip = isSkip
    self:InitUi()
    self:RegisterButton()

    self.TxtTips = self.GameObject:FindTransform("TxtTips")
    self.TxtTips.gameObject:SetActiveEx(false)
    if #self._RewardList == 1 then
        self.BtnSkip.gameObject:SetActiveEx(false)
    end

    self._MaxEffectGroupId = 0
end

function XUiGachaAlphaShow:OnEnable()
    if self._IsSkip then
        self:OnBtnSkipClick()
        return
    end
    self:RefreshByState()
end

function XUiGachaAlphaShow:OnDisable()
    self:StopCv()
end

function XUiGachaAlphaShow:OnDestroy()
    self:StopCv()
    for _, grid in pairs(self._GridRewardList) do
        grid:OnDestroy()
    end
    XDataCenter.KickOutManager.Unlock(XEnumConst.KICK_OUT.LOCK.GACHA, false)
end

function XUiGachaAlphaShow:RegisterButton()
    self.BtnSkip.CallBack = function()
        self:OnBtnSkipClick()
    end
    self:RegisterClickEvent(self.BtnClick, function()
        if self._CurrState == DrawState.Result then
            self:Close()
        else
            self:PlayNext()
        end
    end)
end

function XUiGachaAlphaShow:InitUi()
    self._FarCameraList = {}
    self._NearCameraList = {}
    self._ModelPanelList = {}
    self._UiPanelList = {}
    self._UiCameraList = {}
    for i = 1, MAX_DRAW_COUNT do
        self._FarCameraList[i] = self.UiModelGo.transform:Find("FarRoot/FarCamera" .. i)
        self._NearCameraList[i] = self.UiModelGo.transform:Find("NearRoot/NearCamera" .. i)
        self._ModelPanelList[i] = self.UiModelGo.transform:Find("NearRoot/PanelModelCase" .. i)
        self._UiPanelList[i] = self.UiModelGo.transform:Find("UiRoot/PanelUi" .. i)
        self._UiCameraList[i] = self.UiModelGo.transform:Find("UiRoot/UiCamera" .. i)
    end
    self.GridUiTemplate = self.UiModelGo.transform:Find("UiRoot/GridUi")
    self.GridUiTemplate.gameObject:SetActiveEx(false)
    self.GridModelTemplate = self.UiModelGo.transform:Find("NearRoot/GridModelCase")
    self.GridModelTemplate.gameObject:SetActiveEx(false)
    self.PanelTen = self.UiModelGo.transform:Find("UiRoot/GridExhibition/PanelTen")
    self.PanelNine = self.UiModelGo.transform:Find("UiRoot/GridExhibition/PanelNine")
    self.PanelTen.gameObject:SetActiveEx(false)
    self.PanelNine.gameObject:SetActiveEx(false)
    self.ResultNearCamera = self.UiModelGo.transform:Find("NearRoot/NearCamera11")
    self.ResultFarCamera = self.UiModelGo.transform:Find("FarRoot/FarCamera11")
    self.ResultUiCamera = self.UiModelGo.transform:Find("UiRoot/UiCamera11")
    self.ResultUiCamera.gameObject:SetActiveEx(false)
    ---@type UnityEngine.Camera
    self.UiCamera = self.UiModelGo.transform:Find("UiRoot/Camera"):GetComponent("Camera")
    ---@type UnityEngine.Transform
    self.PanelTenEnableAnim = self.UiModelGo.transform:Find("Animation/PanelTenEnable")
    ---@type UnityEngine.Transform
    self.PanelNineEnableAnim = self.UiModelGo.transform:Find("Animation/PanelNineEnable")
end

function XUiGachaAlphaShow:PlayNext()
    if self._LastReward then
        self._LastReward:OnShowEnd()
    end
    if self._CurrIndex > #self._RewardList then
        self._CurrState = DrawState.Result
        self:ShowResult()
        return
    end
    self._LastReward = self._GridRewardList[self._CurrIndex]
    if not self._LastReward then
        local modelObj = CS.UnityEngine.GameObject.Instantiate(self.GridModelTemplate, self._ModelPanelList[self._CurrIndex])
        modelObj.gameObject:SetActiveEx(true)
        local uiObj = CS.UnityEngine.GameObject.Instantiate(self.GridUiTemplate, self._UiPanelList[self._CurrIndex])
        uiObj.gameObject:SetActiveEx(true)
        self._GridRewardList[self._CurrIndex] = require("XUi/XUiGachaAlpha/Grid/XUiGridGachaAlphaShowReward").New(self._ModelPanelList[self._CurrIndex], self, self._UiPanelList[self._CurrIndex], self._FarCameraList[self._CurrIndex], self._NearCameraList[self._CurrIndex], self._UiCameraList[self._CurrIndex])
        self._LastReward = self._GridRewardList[self._CurrIndex]
    end
    self._LastReward:OnShow(self._RewardList[self._CurrIndex])
    self._CurrIndex = self._CurrIndex + 1
end

function XUiGachaAlphaShow:ShowResult()
    self.TxtTips.gameObject:SetActiveEx(true)
    self.BtnSkip.gameObject:SetActiveEx(false)
    if #self._RewardList == 1 then
        self.UiCamera.gateFit = CS.UnityEngine.Camera.GateFitMode.Vertical
        self:Close()
        return
    end
    self.UiCamera.gateFit = CS.UnityEngine.Camera.GateFitMode.Horizontal
    local finishCallback = function()
        self.BtnClick.gameObject:SetActiveEx(true)
    end
    local beginCallback = function()
        self.BtnClick.gameObject:SetActiveEx(false)
    end
    if #self._RewardList == 10 then
        self.PanelTenEnableAnim:PlayTimelineAnimation(finishCallback, beginCallback)
    else
        self.PanelNineEnableAnim:PlayTimelineAnimation(finishCallback, beginCallback)
    end
    self.ResultNearCamera.gameObject:SetActiveEx(true)
    self.ResultFarCamera.gameObject:SetActiveEx(true)
    self.ResultUiCamera.gameObject:SetActiveEx(true)
    local offset
    if #self._RewardList % 2 == 0 then
        self.PanelTen.gameObject:SetActiveEx(true)
        offset = (EVEN_MAX - #self._RewardList) / 2
    else
        self.PanelNine.gameObject:SetActiveEx(true)
        offset = (ODD_MAX - #self._RewardList) / 2
    end
    local showObjs = {}
    for i = 1, #self._RewardList do
        local index = offset + i
        local obj = self.PanelTen:Find(string.format("Grid%02d", index))
        if XTool.UObjIsNil(obj) then
            XLog.Error(string.format("Grid%02d", index) .. " not found. 很大可能是赠品的问题 策划老师看看")
        end
        local grid = require("XUi/XUiGachaAlpha/Grid/XUiGridGachaAlphaResult").New(obj, self)
        grid:SetData(self._RewardList[i])
        showObjs[index] = true
    end
    for i = 1, EVEN_MAX do
        if not showObjs[i] then
            local obj = self.PanelTen:Find(string.format("Grid%02d", i))
            obj.gameObject:SetActiveEx(false)
        end
    end
    self:PlayCardEffectSound()
end

function XUiGachaAlphaShow:RefreshByState()
    if self._CurrState == DrawState.Show then
        self:PlayNext()
    elseif self._CurrState == DrawState.Result then
        self:ShowResult()
    end
end

function XUiGachaAlphaShow:SetDrawEffectGroupId(effectGroupId)
    if effectGroupId > self._MaxEffectGroupId then
        self._MaxEffectGroupId = effectGroupId
    end
end

function XUiGachaAlphaShow:PlayCardEffectSound()
    local voiceId = XDrawConfigs.GetCardEffectSound(self._MaxEffectGroupId)
    if voiceId and voiceId > 0 then
        self._CvInfo = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, voiceId)
    end
end

function XUiGachaAlphaShow:StopCv()
    if self._CvInfo then
        self._CvInfo:Stop()
        self._CvInfo = nil
    end
end
function XUiGachaAlphaShow:OnBtnSkipClick()
    if self._CurrState == DrawState.Result then
        self:Close()
    else
        self._CurrState = DrawState.Result
        if self._LastReward then
            self._LastReward:OnShowEnd()
        end
        self:RefreshByState()
        self.BtnClick.gameObject:SetActiveEx(false) -- 不能跳过最终展示
    end
end

return XUiGachaAlphaShow