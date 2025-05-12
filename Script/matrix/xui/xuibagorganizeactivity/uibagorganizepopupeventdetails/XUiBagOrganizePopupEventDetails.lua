--- 限时玩法随机事件的事件详情界面
---@class XUiBagOrganizePopupEventDetails: XLuaUi
---@field private _Control XBagOrganizeActivityControl
---@field private _GameControl XBagOrganizeActivityGameControl
local XUiBagOrganizePopupEventDetails = XLuaUiManager.Register(XLuaUi, 'UiBagOrganizePopupEventDetails')
local XUiGridBagOrganizeEventOption = require('XUi/XUiBagOrganizeActivity/UiBagOrganizePopupEventDetails/XUiGridBagOrganizeEventOption')

function XUiBagOrganizePopupEventDetails:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self._OptionGrids = {}
end

function XUiBagOrganizePopupEventDetails:OnStart()
    self._GameControl = self._Control:GetGameControl()
    ---@type XTableBagOrganizeEvent
    self._RandomEventCfg = self._GameControl.TimelimitControl:GetCurPeriodRandomEventCfg()
    self._GameControl.TimelimitControl:PauseTimelimit()
    self._HadSelectedOption = false
    self._HadAnimationPlayComplete = false
    self:InitEventShow()
end

function XUiBagOrganizePopupEventDetails:OnDestroy()
    self._GameControl.TimelimitControl:ResumeTimelimit()
end

function XUiBagOrganizePopupEventDetails:InitEventShow()
    self.PanelChatEvent.gameObject:SetActiveEx(true)
    self.PanelChatSelect.gameObject:SetActiveEx(false)
    self.PanelChatEventAnswer.gameObject:SetActiveEx(false)
    
    self.TxtEventWord.text = self._RandomEventCfg.Desc
    self.RImgCharacter:SetRawImage(self._RandomEventCfg.EventImg)
    if self.TxtCharacter then
        self.TxtCharacter.text = self._RandomEventCfg.EventRoleName
    end
    
    self.PanelBuff.gameObject:SetActiveEx(false)
    self.PanelBtn.gameObject:SetActiveEx(true)
    self.BtnClose.gameObject:SetActiveEx(false)

    if not XTool.IsTableEmpty(self._OptionGrids) then
        for i, v in pairs(self._OptionGrids) do
            v:Close()
        end
    end
    
    XUiHelper.RefreshCustomizedList(self.PanelBtn, self.BtnOption, self._RandomEventCfg.OptionTexts and #self._RandomEventCfg.OptionTexts or 0, function(index, go)
        local grid = self._OptionGrids[go]

        if not grid then
            grid = XUiGridBagOrganizeEventOption.New(go, self)
            self._OptionGrids[go] = grid
        end
        
        grid:Open()
        grid:RefreshShow(index, self._RandomEventCfg.OptionTexts[index])
    end)
end

---@param resultCfg XTableBagOrganizeEventResult
function XUiBagOrganizePopupEventDetails:RefreshEventResultShow(resultCfg, optionTxt)
    -- 对话中显示玩家选择的选项
    self.PanelChatSelect.gameObject:SetActiveEx(true)
    self.TxtSelectWord.text = optionTxt
    
    -- 如果结果有回复文本，则显示
    local hasAnswerDecs = not string.IsNilOrEmpty(resultCfg.Desc)
    
    self.PanelChatEventAnswer.gameObject:SetActiveEx(hasAnswerDecs)

    if hasAnswerDecs then
        self.TxtAnswerWord.text = resultCfg.Desc
    end
    
    -- 显示效果描述
    self.TxtBuff.text = resultCfg.EffectDesc

    self.PanelBtn.gameObject:SetActiveEx(false)
    self.BtnClose.gameObject:SetActiveEx(true)

    if hasAnswerDecs then
        self.PanelChatSelectEnableAnim:PlayTimelineAnimation(function()
            self.PanelChatAnswerAnim:PlayTimelineAnimation(function()
                self.PanelBuff.gameObject:SetActiveEx(true)
                self._HadAnimationPlayComplete = true
            end, nil,  CS.UnityEngine.Playables.DirectorWrapMode.Hold)
        end, nil,  CS.UnityEngine.Playables.DirectorWrapMode.Hold)
    else
        self.PanelChatSelectEnableAnim:PlayTimelineAnimation(function() 
            self.PanelBuff.gameObject:SetActiveEx(true)
            self._HadAnimationPlayComplete = true
        end, nil,  CS.UnityEngine.Playables.DirectorWrapMode.Hold)
    end
end

function XUiBagOrganizePopupEventDetails:OnBtnCloseClick()
    if self._HadSelectedOption and self._HadAnimationPlayComplete then
        self:Close()
    end
end

function XUiBagOrganizePopupEventDetails:OnOptionSelect(index)
    if XTool.IsNumberValid(index) then
        local resultId = self._RandomEventCfg.OptionResultIds[index]

        if XTool.IsNumberValid(resultId) then
            ---@type XTableBagOrganizeEventResult
            local resultCfg = self._Control:GetBagOrganizeEventResultCfgById(resultId)

            if resultCfg then
                self._GameControl.TimelimitControl:AddValidEventEffect(resultCfg)
                self:RefreshEventResultShow(resultCfg, self._RandomEventCfg.OptionTexts[index])
                self._GameControl.TimelimitControl:ClearEventForUsed()
                
                self._GameControl:RecordEventAfterEffectValid(self._RandomEventCfg.Id, resultCfg.Id)
            end
        else
            XLog.Error('随机事件:'..tostring(self._RandomEventCfg.Id)..' 不存在索引为'..tostring(index)..' 的选项Id')
        end
    end
    
    -- 无论是否成功触发buff，都允许玩家关闭界面
    self._HadSelectedOption = true
end

return XUiBagOrganizePopupEventDetails