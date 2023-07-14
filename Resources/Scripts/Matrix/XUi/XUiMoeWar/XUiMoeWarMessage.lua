local ipairs = ipairs
local XUiMessageGridPlayer = require("XUi/XUiMoeWar/ChildItem/XUiMessageGridPlayer")
local XUiMessageGridAction = require("XUi/XUiMoeWar/ChildItem/XUiMessageGridAction")

local XUiMoeWarMessage = XLuaUiManager.Register(XLuaUi, "UiMoeWarMessage")

local CurrentActionSchedule
local CurrentCvInstance

function XUiMoeWarMessage:OnAwake()
    self:AutoAddListener()
    self:InitDynamicTable()

    self.PlayerIds = {}
    for _, v in ipairs(XMoeWarConfig.GetPlayers()) do
        self.PlayerIds[#self.PlayerIds + 1] = v.Id
    end

    self.ActionList = {}
    self.ActionList[XMoeWarConfig.ActionType.Intro] = XUiMessageGridAction.New(self, self.GridActionIntro)
    self.ActionList[XMoeWarConfig.ActionType.Thank] = XUiMessageGridAction.New(self, self.GridActionThank)

    self.ActInfo = XDataCenter.MoeWarManager.GetActivityInfo()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)
    XDataCenter.ItemManager.AddCountUpdateListener(self.ActInfo.CurrencyId[1], function()
        self.AssetActivityPanel:Refresh(self.ActInfo.CurrencyId)
    end, self.AssetActivityPanel)
    self.GridPlayer.gameObject:SetActiveEx(false)
end

function XUiMoeWarMessage:OnStart()
    self:InitSceneRoot()
    self.AssetActivityPanel:Refresh(self.ActInfo.CurrencyId)
    self.SelectPlayerId = 1
    self.SelectPlayer = XDataCenter.MoeWarManager.GetPlayer(self.SelectPlayerId)
    self:UpdateCurrentPlayer()
    self:UpdateActionGrid()

    self.DynamicTable:SetDataSource(self.PlayerIds)
    self.DynamicTable:ReloadDataASync()

    self.LastMatchType = XDataCenter.MoeWarManager.GetCurMatch():GetType()
end

function XUiMoeWarMessage:OnEnable()
    self:CheckIsNeedPop()
end

function XUiMoeWarMessage:OnDisable()
    self:StopAction()
end

function XUiMoeWarMessage:OnGetEvents()
    return { XEventId.EVENT_MOE_WAR_UPDATE,
             XEventId.EVENT_MOE_WAR_ACTIVITY_END}
end

function XUiMoeWarMessage:OnNotify(evt, ...)
    if evt == XEventId.EVENT_MOE_WAR_UPDATE then
        self:CheckIsNeedPop()
    elseif evt == XEventId.EVENT_MOE_WAR_ACTIVITY_END then
        XDataCenter.MoeWarManager.OnActivityEnd()
    end
end

function XUiMoeWarMessage:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PlayerList)
    self.DynamicTable:SetProxy(XUiMessageGridPlayer)
    self.DynamicTable:SetDelegate(self)
end

function XUiMoeWarMessage:InitSceneRoot()
    local root = self.UiModelGo.transform
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true, nil, true)
end

function XUiMoeWarMessage:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateData(self.PlayerIds[index])

        if self.SelectPlayerId == grid.Id then
            grid:SetSelect(true)
            self.LastSelectPlayerGrid = grid
        else
            grid:SetSelect(false)
        end

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if self.SelectPlayerId == grid.Id then
            return
        end

        if self.LastSelectPlayerGrid then
            self.LastSelectPlayerGrid:SetSelect(false)
        end

        self:ResetAction(false)
        self.LastSelectPlayerGrid = grid
        grid:SetSelect(true)

        self.SelectPlayerId = grid.Id
        self.SelectPlayer = XDataCenter.MoeWarManager.GetPlayer(self.SelectPlayerId)
        self:UpdateCurrentPlayer()
        self:UpdateActionGrid()
        self:PlayAnimation("QieHuan")
    end
end

function XUiMoeWarMessage:UpdateCurrentPlayer()
    self.TxtName.text = self.SelectPlayer:GetName()
    self.TxtJob.text = self.SelectPlayer:GetJob()
    self.RImgCareer:SetRawImage(self.SelectPlayer:GetCareerIcon())
    self.TxtCamp.text = self.SelectPlayer:GetCamp()
    self.TxtDescription.text = self.SelectPlayer:GetDesc()

    self:UpdateCurrentPlayerModel(true)
end

function XUiMoeWarMessage:UpdateActionGrid()
    for i, v in pairs(self.ActionList) do
        local actionData = {
            HeadIcon = self.SelectPlayer:GetActionBg(),
            ActionType = i
        }
        v:Refresh(actionData)
    end
end

function XUiMoeWarMessage:UpdateCurrentPlayerModel(isChangeChar)
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.RoleModelPanel:UpdateRoleModel(self.SelectPlayer:GetModel(), self.PanelRoleModel, XModelManager.MODEL_UINAME.XUiMoeWarMessage, function(model)
        self.ImgEffectHuanren.gameObject:SetActiveEx(isChangeChar)
        self.PanelDrag.Target = model.transform
    end, nil, true, true)
end

function XUiMoeWarMessage:AutoAddListener()
    self.BtnBack.CallBack = function() self:OnClickBtnBack() end
    self.BtnMainUi.CallBack = function() self:OnClickBtnMainUi() end
    self.BtnPanelDrag.CallBack = function() self:OnClickPlayer() end
end

function XUiMoeWarMessage:OnClickBtnBack()
    self:Close()
end

function XUiMoeWarMessage:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end

function XUiMoeWarMessage:OnClickPlayer()
    if self.CurrentPlayAction then
        return
    end
    self:OnActionClick(self.ActionList[1].ActionData, self.ActionList[1])
end

function XUiMoeWarMessage:GetSelectPlayerId()
    return self.PlayerIds[self.SelectPlayerId]
end

-- 被XUiMessageGridAction调用
function XUiMoeWarMessage:OnActionClick(actionData, grid)
    if self.CurrentPlayAction then
        local action = self.CurrentPlayAction
        self:ResetAction(true)
        if action.ActionType == actionData.ActionType then
            return
        end
    end
    --XDataCenter.FavorabilityManager.SetDontStopCvContent(true)
    --停止正在播放的动作，准备播放新动作
    self.RoleModelPanel:PlayAnima(self.SelectPlayer:GetAnim(actionData.ActionType), true)
    --CurrentCvInstance = XSoundManager.PlaySoundByType(self.SelectPlayer:GetCv(actionData.ActionType) ,XSoundManager.SoundType.CV)
    --海外萌战由于语音不全所以屏蔽语音
    self.CurrentPlayAction = actionData
    self.CurrentPlayAction.IsPlay = true
    grid:UpdatePlayStatus(true)
    local isFinish = false
    local progress = 0
    local updateCount = 0
    local startTime = CS.UnityEngine.Time.realtimeSinceStartup
    local duration = self.SelectPlayer:GetLength(actionData.ActionType)

    CurrentActionSchedule = XScheduleManager.ScheduleForever(function()
        if self.CurrentPlayAction then
            local time = CS.UnityEngine.Time.realtimeSinceStartup
            progress = (time - startTime) / duration
            if progress >= 1 then
                progress = 1
                isFinish = true
            end
            --判断当前grid存放的数据是不是正在播放的数据
            if grid:GetActionType() == actionData.ActionType then
                grid:UpdateProgress(progress)
                grid:UpdateActionAlpha(updateCount)
            end
            updateCount = updateCount + 1
        end
        if not self.CurrentPlayAction or isFinish then
            actionData.IsPlay = false
            if grid:GetActionType() == actionData.ActionType then
                grid:UpdatePlayStatus(false)
                grid:UpdateProgress(0)
            end
            --自然结束动作，不播放打断特效
            self:ResetAction(false)
        end
    end, 20)
end

function XUiMoeWarMessage:ResetAction(isForce)
    self.CurrentPlayAction = nil
    self:StopAction(isForce)

    for _, v in pairs(self.ActionList) do
        v:Refresh()
    end

    --self:UpdateActionGrid()
end

function XUiMoeWarMessage:StopAction(isForce)
    if isForce then
        self.RoleModelPanel:HideRoleModel()
        self.RoleModelPanel:ShowRoleModel()
    end

    if CurrentActionSchedule then
        XScheduleManager.UnSchedule(CurrentActionSchedule)
    end

    --[[if CurrentCvInstance then
        CurrentCvInstance:Stop()
    end--]]
end

function XUiMoeWarMessage:CheckIsNeedPop()
    local match = XDataCenter.MoeWarManager.GetCurMatch()
    if match:GetType() == XMoeWarConfig.MatchType.Voting and self.LastMatchType == XMoeWarConfig.MatchType.Publicity then
        XUiManager.TipText("MoeWarMatchEnd")
        XLuaUiManager.Remove("XUiMoeWarVote")
        self:Close()
        return true
    else
        self.LastMatchType = match:GetType()
    end
end