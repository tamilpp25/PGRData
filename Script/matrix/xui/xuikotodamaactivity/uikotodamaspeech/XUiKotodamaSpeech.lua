---@class XUiKotodamaSpeech
---@field _Control XKotodamaActivityControl
local XUiKotodamaSpeech = XLuaUiManager.Register(XLuaUi, 'UiKotodamaSpeech')
local XUiPanelKotodamaSpeech = require('XUi/XUiKotodamaActivity/UiKotodamaSpeech/XUiPanelKotodamaSpeech')
local XUiPanelKotodamaArtifact = require('XUi/XUiKotodamaActivity/UiKotodamaSpeech/XUiPanelKotodamaArtifact')

local BtnGroupIndex = {
    BtnSpeech = 1,
    BtnArtifact = 2,
}

function XUiKotodamaSpeech:OnAwake()
    self.BtnClose.CallBack = function()
        self:Close()
    end
    self.BtnTanchuangClose.CallBack = function()
        self:Close()
    end
    
    
    self._PanelSpeech = XUiPanelKotodamaSpeech.New(self.PanelSpeechList, self)
    self._PanelArtifact = XUiPanelKotodamaArtifact.New(self.PanelArtifact, self)

    self._PanelSpeech:Close()
    self._PanelArtifact:Close()
    
    self.ButtonGroup:InitBtns({self.BtnSpeech, self.BtnArtifact}, handler(self, self.OnBtnGroupClickEvent))

    self._SpeechRedId = self:AddRedPointEvent(self.BtnSpeech, self.OnBtnSpeechRedPointEvent, self, { XRedPointConditions.Types.CONDITION_KOTODAMA_NEW_SPEECH })
end

function XUiKotodamaSpeech:OnStart(cbClose, selectIndex)
    self.CbClose = cbClose

    if XTool.IsNumberValid(selectIndex) and table.contains(BtnGroupIndex, selectIndex) then
        self.ButtonGroup:SelectIndex(selectIndex)
    else
        self.ButtonGroup:SelectIndex(BtnGroupIndex.BtnSpeech)
    end
end

function XUiKotodamaSpeech:OnDestroy()
    if self.CbClose then
        self.CbClose()
        self.CbClose = nil
    end
end

function XUiKotodamaSpeech:OnBtnGroupClickEvent(index)
    if index == self._CurBtnGroupIndex then
        return
    else
        self._CurBtnGroupIndex = index
    end
    

    self._PanelSpeech:Close()
    self._PanelArtifact:Close()
    
    if index == BtnGroupIndex.BtnSpeech then
        self._PanelSpeech:Open()
    elseif index == BtnGroupIndex.BtnArtifact then
        self._PanelArtifact:Open()
    end
    
    -- 刷新红点
    XRedPointManager.Check(self._SpeechRedId)
end

function XUiKotodamaSpeech:OnBtnSpeechRedPointEvent(count)
    self.BtnSpeech:ShowReddot(count >= 0)
end

return XUiKotodamaSpeech