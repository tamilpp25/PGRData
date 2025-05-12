---@class XUiPanelGame2048ShowCharacter: XUiNode
---@field _Control XGame2048Control
---@field _GameControl XGame2048GameControl
---@field _PanelRoleModel XUiPanelRoleModel
local XUiPanelGame2048ShowCharacter = XClass(XUiNode, 'XUiPanelGame2048ShowCharacter')
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local IpadResolution = 1.4 -- 4:3
local ShowActionOutTimeLimit = 10
local ShowActionOutTimeCheckInterval = 1

function XUiPanelGame2048ShowCharacter:OnStart()
    self._GameControl = self._Control:GetGameControl()

    local uiModelRoot = self.Parent.UiModelGo.transform
    self._PanelRoleModel = XUiPanelRoleModel.New(uiModelRoot:FindTransform("PanelRoleModel"), self.Parent.Name, true, true, false, true, false)
    self._GameControl:AddEventListener(XMVCA.XGame2048.EventIds.EVENT_GAME2048_SHOW_ACTION, self.ShowAction, self)
    self._GameControl:AddEventListener(XMVCA.XGame2048.EventIds.EVENT_GAME2048_FEVER_LEVELUP, self.OnFeverLevelUp, self)
    self._GameControl:AddEventListener(XMVCA.XGame2048.EventIds.EVENT_GAME2048_ON_OPTION, self.HideFeverLevelUpFx, self)

    self.PanelTalk.gameObject:SetActiveEx(false)
    
    local ipadResolution = self._Control:GetClientConfigNum('IpadResolutionLimit')
    if XTool.IsNumberValid(ipadResolution) then
        IpadResolution = ipadResolution
    end
    
    local showActionOutTimeLimit = self._Control:GetClientConfigNum('ShowActionOutTimeLimit')
    if XTool.IsNumberValid(showActionOutTimeLimit) then
        ShowActionOutTimeLimit = showActionOutTimeLimit
    end

    local showActionOutTimeCheckInterval = self._Control:GetClientConfigNum('ShowActionOutTimeCheckInterval')
    if XTool.IsNumberValid(showActionOutTimeCheckInterval) then
        ShowActionOutTimeCheckInterval = showActionOutTimeCheckInterval
    end
    
    self:InitCameraShow()
end

function XUiPanelGame2048ShowCharacter:OnEnable()
    self:StartCheckErrorTimer()
end

function XUiPanelGame2048ShowCharacter:OnDisable()
    self:StopCheckErrorTimer()
end

function XUiPanelGame2048ShowCharacter:InitCameraShow()
    local normalFarCam = self.Parent.UiModelGo.transform:FindTransformWithSplit("FarRoot/UiDetailCamFar")
    local normalNearCam = self.Parent.UiModelGo.transform:FindTransformWithSplit("NearRoot/UiDetailCamNear")

    local ipadFarCam = self.Parent.UiModelGo.transform:FindTransformWithSplit("FarRoot/UiModeCamFarIpad")
    local ipadNearCam = self.Parent.UiModelGo.transform:FindTransformWithSplit("NearRoot/UiModeCamNearIpad")

    local radio = self.Parent.Transform.rect.width / self.Parent.Transform.rect.height

    if radio < IpadResolution then
        normalFarCam.gameObject:SetActiveEx(false)
        normalNearCam.gameObject:SetActiveEx(false)
        
        ipadFarCam.gameObject:SetActiveEx(true)
        ipadNearCam.gameObject:SetActiveEx(true)
    else
        normalFarCam.gameObject:SetActiveEx(true)
        normalNearCam.gameObject:SetActiveEx(true)

        ipadFarCam.gameObject:SetActiveEx(false)
        ipadNearCam.gameObject:SetActiveEx(false)
    end
end

function XUiPanelGame2048ShowCharacter:InitShowCharacter()
    self.PanelTalk.gameObject:SetActiveEx(false)
    self._StageId = self._Control:GetCurStageId()
    self._CharacterId = self._Control:GetStageShowCharacterId(self._StageId)
    self._BoardShowGroupId = self._Control:GetStageBoardShowGroupId(self._StageId)

    if XTool.IsNumberValid(self._CharacterId) then
        local characterData = XMVCA.XCharacter:GetCharacter(self._CharacterId)
        local fashionId = nil
        local isOwn = not XTool.IsTableEmpty(characterData)
        if isOwn then
            ---@type XCharacterViewModel
            local characterViewModel = characterData:GetCharacterViewModel()
            fashionId = characterViewModel:GetFashionId()
        end
        
        self._PanelRoleModel:UpdateCuteModelByModelName(self._CharacterId, nil, nil, nil, nil,
                XCharacterCuteConfig.GetCuteModelModelName(self._CharacterId), function()
                    CS.XShadowHelper.AddShadow(self._PanelRoleModel.GameObject, true)
                end, true)
        self._PanelRoleModel:ShowRoleModel()
        
        self:ShowStandAction()
    end
    
    -- 初始化重置动画状态
    if self._PlayingActionShowId ~= nil then
        self._PlayingActionShowId = nil
        XLog.Warning('2048玩法新一局开始，但有动画尚未完成播放，已置空标记以保证新局动画可覆盖')
    end
    self.TxtTalk.text = ''
end

function XUiPanelGame2048ShowCharacter:ShowStandAction(isFrom)
    local standAnim = self._Control:GetBoardShowStandAnim(self._BoardShowGroupId)
    if not string.IsNilOrEmpty(standAnim) then
        if isFrom then
            self._PanelRoleModel:PlayAnimaCross(standAnim, true)
        else
            self._PanelRoleModel:PlayAnima(standAnim)
        end
    end

    self._PlayingActionShowId = nil
    self.TxtTalk.text = ''
    self.PanelTalk.gameObject:SetActiveEx(false)
end

---@param boardShowCfg XTableGame2048BoardShow
function XUiPanelGame2048ShowCharacter:ShowAction(boardShowCfg)
    if not boardShowCfg then
        return
    end
    
    if XTool.IsNumberValid(self._PlayingActionShowId) then
        -- 相同的不重播
        if self._PlayingActionShowId == boardShowCfg.Id then
            return
        end
        -- 优先级靠前的不打断
        local newConditionPriority = self._Control:GetBoardShowConditionPriorityById(boardShowCfg.ShowConditionId)
        local oldBoardShowCfg = self._Control:GetBoardShowCfgById(self._PlayingActionShowId)

        if oldBoardShowCfg then
            local oldConditionPriority = self._Control:GetBoardShowConditionPriorityById(oldBoardShowCfg.ShowConditionId)

            if oldConditionPriority < newConditionPriority then
                return
            end
        end
    end
    
    self._PlayingActionShowId = boardShowCfg.Id
    local actionAnim = boardShowCfg.ShowAct
    local actionTalk = boardShowCfg.ShowTalk

    if not string.IsNilOrEmpty(actionTalk) then
        self.PanelTalk.gameObject:SetActiveEx(true)
        self.TxtTalk.text = actionTalk
    end
    
    if not string.IsNilOrEmpty(actionAnim) then
        -- 记录最新一次动作播放的请求时间
        local now = XTime.GetServerNowTimestamp()
        self._LastTryShowActionTime = now
        
        self._PanelRoleModel:PlayAnimaCross(actionAnim, true, function()
            self:ShowStandAction(true)
            -- 完成回调后清空
            self._LastTryShowActionTime = nil
        end, function()
            self:ShowStandAction(true)
            -- 完成回调后清空
            self._LastTryShowActionTime = nil
        end)
    else
        self._PlayingActionShowId = nil
        self.PanelTalk.gameObject:SetActiveEx(false)
    end
end

--- 盘面升级特效
function XUiPanelGame2048ShowCharacter:OnFeverLevelUp()
    self.FxLevelUp.gameObject:SetActiveEx(true)
end

function XUiPanelGame2048ShowCharacter:HideFeverLevelUpFx()
    self.FxLevelUp.gameObject:SetActiveEx(false)
end

--region 检查定时器
function XUiPanelGame2048ShowCharacter:StartCheckErrorTimer()
    self:StopCheckErrorTimer()
    self._CheckErrorTimerId = XScheduleManager.ScheduleForever(handler(self, self.UpdateCheckErrorTimer), XScheduleManager.SECOND * ShowActionOutTimeCheckInterval)
end

function XUiPanelGame2048ShowCharacter:StopCheckErrorTimer()
    if self._CheckErrorTimerId then
        XScheduleManager.UnSchedule(self._CheckErrorTimerId)
        self._CheckErrorTimerId = nil
    end
end

function XUiPanelGame2048ShowCharacter:UpdateCheckErrorTimer()
    -- 当距离上次请求播动画有一定时间间隔时，需要检查
    local now = XTime.GetServerNowTimestamp()
    if XTool.IsNumberValid(self._LastTryShowActionTime) then
        local passTime = now - self._LastTryShowActionTime
        -- 如果过了n秒还是没有任意回调清空，则可能出现了问题
        if passTime > ShowActionOutTimeLimit then
            if XTool.IsNumberValid(self._PlayingActionShowId) then
                if XMain.IsEditorDebug then
                    XLog.Error('上一次的动画已超过'..tostring(ShowActionOutTimeLimit)..'秒未触发回调清空标记，当前标记的播放中动画为：'..tostring(self._PlayingActionShowId))
                end
                -- 清空标记，确保后续动画可覆盖
                self._PlayingActionShowId = nil
                self.PanelTalk.gameObject:SetActiveEx(false)
                self._LastTryShowActionTime = nil
            end
        end
    end
end
--endregion

return XUiPanelGame2048ShowCharacter