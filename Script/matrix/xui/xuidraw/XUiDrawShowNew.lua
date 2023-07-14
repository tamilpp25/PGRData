local XUiDrawShowNew = XLuaUiManager.Register(XLuaUi, "UiDrawShowNew")
local XUiGridDrawShowReward = require("XUi/XUiDraw/XUiGridDrawShowReward")
local XUiGridDrawResult = require("XUi/XUiDraw/XUiGridDrawResult")
local ODD_TYPE = 1
local EVEN_TYPE = 0
local EVEN_MAX = 10
local ODD_MAX = 9
local DrawState = {
    Show = 1,
    Result = 2
}
local MAX_DRAW_COUNT = 10
function XUiDrawShowNew:OnStart(drawInfo, rewardList, resultCb, state, closeCb)
    self.DrawInfo = drawInfo
    self.RewardList = rewardList
    self.GridRewardList = {}
    self.ResultCb = resultCb
    self.CloseCb = closeCb
    self.CurrIndex = 1
    self.CurrState = state or DrawState.Show
    self:InitUi()
    self:RegisterButton()
    
    self.TxtTips = self.GameObject:FindTransform("TxtTips")
    self.TxtTips.gameObject:SetActiveEx(false)
    if #self.RewardList == 1 then
        self.BtnSkip.gameObject:SetActiveEx(false)
    end

    self.MaxEffectGroupId = 0
end

function XUiDrawShowNew:OnEnable()
   self:RefreshByState()
end

function XUiDrawShowNew:OnDisable()
   self:StopCv()
end

function XUiDrawShowNew:OnDestroy()
    self:StopCv()
    for _, grid in pairs(self.GridRewardList) do
        grid:OnDestroy()
    end
end

function XUiDrawShowNew:RegisterButton()
    self.BtnSkip.CallBack = function()
        if self.CurrState == DrawState.Result then
            self:OnClose()
        else
            self.CurrState = DrawState.Result
            if self.LastReward then
                self.LastReward:OnShowEnd()
            end
            self:RefreshByState()
        end
    end
    self:RegisterClickEvent(self.BtnClick, function()
        if self.CurrState == DrawState.Result then
            self:OnClose()
        else
            self:PlayNext()
        end
    end)
end

function XUiDrawShowNew:InitUi()
    self.FarCameraList = {}
    self.NearCameraList = {}
    self.ModelPanelList = {}
    self.UiPanelList = {}
    self.UiCameraList = {}
    for i = 1, MAX_DRAW_COUNT do
        self.FarCameraList[i] = self.UiModelGo.transform:Find("FarRoot/FarCamera" .. i)
        self.NearCameraList[i] = self.UiModelGo.transform:Find("NearRoot/NearCamera" .. i)
        self.ModelPanelList[i] = self.UiModelGo.transform:Find("NearRoot/PanelModelCase" .. i)
        self.UiPanelList[i] = self.UiModelGo.transform:Find("UiRoot/PanelUi" .. i)
        self.UiCameraList[i] = self.UiModelGo.transform:Find("UiRoot/UiCamera" .. i)
    end
    self.GridUiTemplate = self.UiModelGo.transform:Find("UiRoot/GridUi")
    self.GridUiTemplate.gameObject:SetActiveEx(false)
    self.GridModelTemplate = self.UiModelGo.transform:Find("NearRoot/GridModelCase")
    self.GridModelTemplate.gameObject:SetActiveEx(false)

    self.GridPanelDic = {}
    self.GridPanelDic[EVEN_TYPE] = {}
    self.GridPanelDic[ODD_TYPE] = {}
    self.PanelTen = self.UiModelGo.transform:Find("UiRoot/GridExhibition/PanelTen")
    self.PanelNine = self.UiModelGo.transform:Find("UiRoot/GridExhibition/PanelNine")
    for i = 1, EVEN_MAX do
        local obj = self.PanelTen:Find(string.format("Grid%02d",i))
        self.GridPanelDic[EVEN_TYPE][i] = XUiGridDrawResult.New(obj, self)
        self.GridPanelDic[EVEN_TYPE][i]:SetActive(false)
    end
    for i = 1, ODD_MAX do
        local obj = self.PanelNine:Find(string.format("Grid%02d",i))
        self.GridPanelDic[ODD_TYPE][i] = XUiGridDrawResult.New(obj, self)
        self.GridPanelDic[ODD_TYPE][i]:SetActive(false)
    end
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

function XUiDrawShowNew:PlayNext()
    if self.LastReward then
        self.LastReward:OnShowEnd()
    end
    if self.CurrIndex > #self.RewardList then
        self.CurrState = DrawState.Result
        self:ShowResult()
        return
    end
    self.LastReward = self.GridRewardList[self.CurrIndex]
    if not self.LastReward then
        local modelObj = CS.UnityEngine.GameObject.Instantiate(self.GridModelTemplate, self.ModelPanelList[self.CurrIndex])
        modelObj.gameObject:SetActiveEx(true)
        local uiObj = CS.UnityEngine.GameObject.Instantiate(self.GridUiTemplate, self.UiPanelList[self.CurrIndex])
        uiObj.gameObject:SetActiveEx(true)
        self.GridRewardList[self.CurrIndex] = XUiGridDrawShowReward.New(self, self.ModelPanelList[self.CurrIndex], self.UiPanelList[self.CurrIndex], self.FarCameraList[self.CurrIndex], self.NearCameraList[self.CurrIndex], self.UiCameraList[self.CurrIndex])
        self.LastReward = self.GridRewardList[self.CurrIndex]
    end
    self.LastReward:OnShow(self.RewardList[self.CurrIndex])
    self.CurrIndex = self.CurrIndex + 1
end

function XUiDrawShowNew:ShowResult()
    self.TxtTips.gameObject:SetActiveEx(true)
    self.BtnSkip.gameObject:SetActiveEx(false)
    if #self.RewardList == 1 then
        self.UiCamera.gateFit = CS.UnityEngine.Camera.GateFitMode.Vertical
        self:OnClose()
        return
    end
    self.UiCamera.gateFit = CS.UnityEngine.Camera.GateFitMode.Horizontal
    local finishCallback = function()
        self.BtnClick.gameObject:SetActiveEx(true)
    end
    local beginCallback = function()
        self.BtnClick.gameObject:SetActiveEx(false)
    end
    if #self.RewardList == 10 then
        self.PanelTenEnableAnim:PlayTimelineAnimation(finishCallback, beginCallback)
    else
        self.PanelNineEnableAnim:PlayTimelineAnimation(finishCallback, beginCallback)
    end
    self.ResultNearCamera.gameObject:SetActiveEx(true)
    self.ResultFarCamera.gameObject:SetActiveEx(true)
    self.ResultUiCamera.gameObject:SetActiveEx(true)
    if #self.RewardList % 2 == 0 then
        self.PanelTen.gameObject:SetActiveEx(true)
        local offset = (EVEN_MAX - #self.RewardList)/2
        for i = 1, #self.RewardList do
            local grid = self.GridPanelDic[EVEN_TYPE][offset + i]
            if grid then
                grid:SetData(self.RewardList[i])
                grid:SetActive(true)
            end
        end
    else
        self.PanelNine.gameObject:SetActiveEx(true)
        local offset = (ODD_MAX - #self.RewardList)/2
        for i = 1, #self.RewardList do
            local grid = self.GridPanelDic[ODD_TYPE][offset + i]
            if grid then
                grid:SetData(self.RewardList[i])
                grid:SetActive(true)
            end
        end
    end
    self:PlayCardEffectSound()
end

function XUiDrawShowNew:RefreshByState()
    if self.CurrState == DrawState.Show then
        self:PlayNext()
    elseif self.CurrState == DrawState.Result then
        self:ShowResult()
    end
end

function XUiDrawShowNew:SetDrawEffectGroupId(effectGroupId)
    if effectGroupId > self.MaxEffectGroupId then
        self.MaxEffectGroupId = effectGroupId
    end
end

function XUiDrawShowNew:PlayCardEffectSound()
    local voiceId = XDrawConfigs.GetCardEffectSound(self.MaxEffectGroupId)
    if voiceId and voiceId > 0 then
        self.CvInfo = XSoundManager.PlaySoundByType(voiceId, XSoundManager.SoundType.Sound)
    end
end

function XUiDrawShowNew:StopCv()
    if self.CvInfo then
        self.CvInfo:Stop()
        self.CvInfo = nil
    end
end

function XUiDrawShowNew:OnClose()
    self:Close()
    if self.CloseCb then
        self.CloseCb()
    end
end

return XUiDrawShowNew