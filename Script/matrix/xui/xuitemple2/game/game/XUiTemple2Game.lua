local XUiTemple2CheckBoard = require("XUi/XUiTemple2/Game/XUiTemple2CheckBoard")
local XUiTemple2GameBlockOption = require("XUi/XUiTemple2/Game/Game/XUiTemple2GameBlockOption")
local XUiTemple2GameBlockGridOption = require("XUi/XUiTemple2/Game/Game/XUiTemple2GameBlockGridOption")

---@class XUiTemple2Game : XLuaUi
---@field _Control XTemple2Control
local XUiTemple2Game = XLuaUiManager.Register(XLuaUi, "UiTemple2Game")

function XUiTemple2Game:OnAwake()
    self:BindExitBtns()
    --self:BindHelpBtn(nil, "Temple2Help")
    XUiHelper.RegisterClickEvent(self, self.BtnHelp, self._OnClickHelp)

    self._OptionGrids = {}
    self._OptionBlockGrids = {}

    self:RegisterClickEvent(self.BtnCloseBlock, self.OnClickHideBlockOptions)
    self:RegisterClickEvent(self.BtnStart, self.OnClickStart)
    self:RegisterClickEvent(self.BtnLeave, self.OnClickLeave)
    self:RegisterClickEvent(self.BtnShare, self.OnClickShare)
    self:RegisterClickEvent(self.BtnEdit, self.OnClickReplay)
    --self.BtnSkip
    --self.BtnLeave

    ---@type XUiTemple2CheckBoard
    self._CheckBoard = XUiTemple2CheckBoard.New(self.PanelCheckerboard, self, self._Control:GetGameControl())
    self.PanelBlock.gameObject:SetActiveEx(false)

    self._OldBlockOptionData = false

    ---@type UnityEngine.UI.Toggle
    local toggle = self.ToggleMode
    toggle.isOn = self._Control:GetGameControl():IsModeScore()
    toggle.onValueChanged:AddListener(function(value)
        self._Control:GetGameControl():SetModeScore(value)
        self._CheckBoard:UpdateBlockAndMap()
    end)

    self.PanelSettlement.gameObject:SetActiveEx(false)
    self:UpdateStartBtnText()
end

function XUiTemple2Game:OnStart()
    self:Update()
    self:UpdateBlockOption()
    self:UpdateScore()
end

function XUiTemple2Game:OnEnable()
    self.PanelSpeak.gameObject:SetActiveEx(false)
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE2_CLICK_BLOCK_OPTION, self.OnClickBlockOption, self)
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE2_UPDATE_SCORE, self.UpdateScore, self)
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE2_SETTLE, self.ShowUiSettlement, self)
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE2_UPDATE_BLOCK_OPTION, self.UpdateBlockOptionOnShow, self)
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE2_UPDATE_AFTER_REPLAY, self.UpdateAfterReplay, self)

    self._Timer = XScheduleManager.ScheduleForever(function()
        self:UpdateGame()
    end, 0, 0)
    self:UpdateHead()
end

function XUiTemple2Game:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE2_CLICK_BLOCK_OPTION, self.OnClickBlockOption, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE2_UPDATE_SCORE, self.UpdateScore, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE2_SETTLE, self.ShowUiSettlement, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE2_UPDATE_BLOCK_OPTION, self.UpdateBlockOptionOnShow, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE2_UPDATE_AFTER_REPLAY, self.UpdateAfterReplay, self)
    XScheduleManager.UnSchedule(self._Timer)
    self._Timer = false
end

function XUiTemple2Game:UpdateGame()
    self._Control:GetGameControl():UpdateGame(self._CheckBoard)
    local chat = self._Control:GetGameControl():GetChat()
    if chat then
        self.PanelSpeak.gameObject:SetActiveEx(true)
        self.TxtSpeak.text = chat
    else
        self.PanelSpeak.gameObject:SetActiveEx(false)
    end
end

function XUiTemple2Game:Update()
    self._CheckBoard:Update()
    self._CheckBoard:UpdateBg()
end

---@param text UnityEngine.UI.Text
function XUiTemple2Game:_SetScore(text, score)
    if score > 0 then
        text.text = score
        text.transform.parent.gameObject:SetActiveEx(true)
    else
        text.transform.parent.gameObject:SetActiveEx(false)
    end
end

function XUiTemple2Game:UpdateScore()
    local scoreData = self._Control:GetGameControl():GetUiData().Score
    self.TxtNumScore1.text = scoreData.Total
    self.TxtNumScore2.text = scoreData.Grid
    self.TxtNumScore3.text = scoreData.Path
    self.TxtNumScore4.text = scoreData.Like
    self:_SetScore(self.TxtNumScore5, scoreData.Task)
end

function XUiTemple2Game:UpdateBlockOption()
    local options = self._Control:GetGameControl():GetUiDataBlockOptions()
    XTool.UpdateDynamicItem(self._OptionGrids, options, self.GridLand, XUiTemple2GameBlockOption, self)
end

---@param data XUiTemple2GameBlockOptionData
function XUiTemple2Game:OnClickBlockOption(data)
    if not self._Control:GetGameControl():IsCanPlay() then
        return
    end
    if self._OldBlockOptionData == data then
        self:OnClickHideBlockOptions()
        return
    end
    self._OldBlockOptionData = data
    if data.Desc then
        self.TxtBlock.text = data.Name
        if self.TxtBlock2 then
            self.TxtBlock2.text = data.Desc
        end
    else
        self.TxtBlock.text = data.Name
        self.TxtBlock2.text = ""
    end
    self.PanelBlock.gameObject:SetActiveEx(true)
    self:PlayAnimation("PanelBlockEnable")
    self:UpdateBlockOptionList(data.BlockArray)
end

function XUiTemple2Game:UpdateBlockOptionList(blockArray)
    XTool.UpdateDynamicItem(self._OptionBlockGrids, blockArray, self.GridBlock, XUiTemple2GameBlockGridOption, self)
end

function XUiTemple2Game:UpdateBlockOptionOnShow()
    if self._OldBlockOptionData then
        self:UpdateBlockOptionList(self._OldBlockOptionData.BlockArray)
    end
end

function XUiTemple2Game:OnClickHideBlockOptions()
    self._OldBlockOptionData = false
    self:PlayAnimation("PanelBlockDisable", function()
        self.PanelBlock.gameObject:SetActiveEx(false)
    end)
end

function XUiTemple2Game:OnClickStart()
    if self._Control:GetGameControl():OnClickStart() then
        -- 结算时，隐藏分数模式
        self._CheckBoard:Update()

        self:OnClickHideBlockOptions()
        self._CheckBoard:UpdateBlockAndPreview()
        self.PanelLandBag.gameObject:SetActiveEx(false)
    end
    self:UpdateStartBtnText()
end

function XUiTemple2Game:ShowUiSettlement()
    CS.UnityEngine.Time.timeScale = 1
    self.PanelSettlement.gameObject:SetActiveEx(true)
    self.TxtScore1.text = self._Control:GetGameControl():GetUiData().Score.Total
    self.TxtScore2.text = self._Control:GetGameControl():GetUiData().Score.Grid
    self.TxtScore3.text = self._Control:GetGameControl():GetUiData().Score.Path
    self.TxtScore4.text = self._Control:GetGameControl():GetUiData().Score.Like
    self.TxtScore5.text = self._Control:GetGameControl():GetUiData().Score.Task
    if self.HideOnSettle then
        self.HideOnSettle.gameObject:SetActiveEx(false)
    end
    self:UpdateStartBtnText()
    if self.RImgCharacterSettle then
        self.RImgCharacterSettle:SetSprite(self._Control:GetGameControl():GetCharacterIcon())
    end
    self.TxtSpeakSettle = self.TxtSpeakSettle or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelUpperUi/PanelSettlement/PanelSpeak/TxtSpeak", "Text")
    if self.TxtSpeakSettle then
        self.TxtSpeakSettle.text = self._Control:GetGameControl():GetCharacterSettleDesc()
    end
end

function XUiTemple2Game:OnClickLeave()
    self:Close()
end

function XUiTemple2Game:OnDestroy()
    -- 复原速度
    CS.UnityEngine.Time.timeScale = 1
    XDataCenter.PhotographManager.ClearTextureCache()
    if self.ShareTexture then
        CS.UnityEngine.Object.Destroy(self.ShareTexture)
        self.ShareTexture = false
    end
    self._Control:ClearCurrentGameStageId()
end

function XUiTemple2Game:UpdateStartBtnText()
    local text = self._Control:GetGameControl():GetText4StartBtn()
    self.BtnStart:SetNameByGroup(0, text)
end

function XUiTemple2Game:OnClickShare()
    if self._IsShotScreen then
        return
    end

    -- 截屏期间打开图文会出事, 应该是模糊也要截屏导致的
    self._IsShotScreen = true
    self.BtnBack.gameObject:SetActiveEx(false)
    self.BtnMainUi.gameObject:SetActiveEx(false)
    self.BtnHelp.gameObject:SetActiveEx(false)

    local camera = CS.XUiManager.Instance.UiCamera
    XCameraHelper.ScreenShotNew(self.ImageForSnapShot, camera, function(screenShot)
        -- 把合成后的图片渲染到游戏UI中的照片展示(最终要分享的图片)
        CsXUiManager.Instance:ChangeCanvasTypeCamera(CsXUiType.Hud, CS.XUiManager.Instance.UiCamera)
        self.ShareTexture = screenShot
        local photoName = "[" .. tostring(XPlayer.Id) .. "]" .. XTime.GetServerNowTimestamp()
        XLuaUiManager.OpenWithCallback("UiTemple2Share", function()
            self._IsShotScreen = false
        end, photoName, screenShot, self.ImageForSnapShot.sprite)

        self.BtnBack.gameObject:SetActiveEx(true)
        self.BtnMainUi.gameObject:SetActiveEx(true)
        self.BtnHelp.gameObject:SetActiveEx(true)

    end, function()
        CsXUiManager.Instance:ChangeCanvasTypeCamera(CsXUiType.Hud, self.CameraCupture)
    end)
end

function XUiTemple2Game:OnClickReplay()
    self._Control:GetGameControl():Replay()
end

function XUiTemple2Game:UpdateAfterReplay()
    self:Update()
    self:UpdateBlockOption()
    self:UpdateScore()
    self:UpdateStartBtnText()
    self._CheckBoard:HideCharacter()
    self.PanelSettlement.gameObject:SetActiveEx(false)
    self.PanelLandBag.gameObject:SetActiveEx(true)
    if self.HideOnSettle then
        self.HideOnSettle.gameObject:SetActiveEx(true)
    end
end

function XUiTemple2Game:UpdateHead()
    self._CheckBoard:SetCharacterIcon(self._Control:GetGameControl():GetCharacterIcon())
end

function XUiTemple2Game:_OnClickHelp()
    if self._IsShotScreen then
        return
    end
    self._IsShotScreen = true
    XUiManager.ShowHelpTip("Temple2Help", function()
        self._IsShotScreen = false
    end)
end

return XUiTemple2Game