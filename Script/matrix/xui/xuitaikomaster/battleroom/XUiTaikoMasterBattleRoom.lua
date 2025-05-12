local XUiButtonLongClick = require("XUi/XUiCommon/XUiButtonLongClick")
local XUiTaikoMasterGridRole = require("XUi/XUiTaikoMaster/BattleRoom/XUiTaikoMasterGridRole")

---@class XUiTaikoMasterBattleRoom : XLuaUi
---@field _Control XTaikoMasterControl
local XUiTaikoMasterBattleRoom = XLuaUiManager.Register(XLuaUi, "UiTaikoMasterBattleRoom")

function XUiTaikoMasterBattleRoom:OnAwake()
    self:AddBtnListener()
end

function XUiTaikoMasterBattleRoom:OnStart(stageId)
    self._Control:SetJustEnterStageId(stageId)
    self._StageId = stageId
    self:InitTeam()
    self:InitStage()
    self:InitDragReplace()
    self:InitSceneEffect()
    self:InitAutoClose()
end

function XUiTaikoMasterBattleRoom:OnEnable()
    self:RefreshTeam()
end

function XUiTaikoMasterBattleRoom:OnDestroy()
    self:ReleaseButtonLongClick()
end

--region Ui - AutoClose
function XUiTaikoMasterBattleRoom:InitAutoClose()
    local uiData = self._Control:GetUiData()
    self:SetAutoCloseInfo(XFunctionManager.GetEndTimeByTimeId(uiData and uiData.TimeId), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)
end
--endregion

--region Ui - Stage
function XUiTaikoMasterBattleRoom:InitStage()
    ---@type XFubenAgency
    local fubenAgency = XMVCA:GetAgency(ModuleId.XFuben)
    local chapterName, stageName = fubenAgency:GetFubenNames(self._StageId)
    self.TxtChapterName.text = chapterName
    self.TxtStageName.text = stageName
end
--endregion

--region Ui - Team
function XUiTaikoMasterBattleRoom:InitTeam()
    ---@type UnityEngine.Transform[]
    local modelPanelList = {}
    if self.UiModelGo then
        for i = 1, 4 do
            modelPanelList[i] = self.UiModelGo.transform:FindTransform("PanelRoleModel"..i)
        end
    end
    self._Control:SetTeamByStage(self._StageId)
    ---@type XUiTaikoMasterGridRole[]
    self._TeamGridList = {
        XUiTaikoMasterGridRole.New(self.BtnChar1, self, 1, modelPanelList[1], self._StageId),
        XUiTaikoMasterGridRole.New(self.BtnChar2, self, 2, modelPanelList[2], self._StageId),
        XUiTaikoMasterGridRole.New(self.BtnChar3, self, 3, modelPanelList[3], self._StageId),
        XUiTaikoMasterGridRole.New(self.BtnChar4, self, 4, modelPanelList[4], self._StageId)
    }
end

function XUiTaikoMasterBattleRoom:RefreshTeam()
    for _, grid in ipairs(self._TeamGridList) do
        grid:Refresh()
    end
end
--endregion

--region Ui - DragReplace
function XUiTaikoMasterBattleRoom:InitDragReplace()
    self._LongClickTime = 0
    ---@type function[]
    self._LongClickedList = {}
    ---@type function[]
    self._LongClickUp = {}
    self._Camera = self.Transform:GetComponent("Canvas").worldCamera
    for i = 1, 4 do
        self._LongClickedList[i] = function(_, time) self:OnBtnCharLongClick(i, time) end
        self._LongClickUp[i] = function() self:SwitchCharPos(i) end
    end
    ---@type XUiButtonLongClick[]
    self._LongClickButtonList = {
        XUiButtonLongClick.New(self.BtnChar1, 10, self, nil, self._LongClickedList[1], self._LongClickUp[1], false),
        XUiButtonLongClick.New(self.BtnChar2, 10, self, nil, self._LongClickedList[2], self._LongClickUp[2], false),
        XUiButtonLongClick.New(self.BtnChar3, 10, self, nil, self._LongClickedList[3], self._LongClickUp[3], false),
        XUiButtonLongClick.New(self.BtnChar4, 10, self, nil, self._LongClickedList[4], self._LongClickUp[4], false)
    }
end

function XUiTaikoMasterBattleRoom:ReleaseButtonLongClick()
    for _, buttonLongClick in ipairs(self._LongClickButtonList) do
        buttonLongClick:Destroy()
    end
    self._LongClickButtonList = nil
end

function XUiTaikoMasterBattleRoom:OnBtnCharLongClick(index, time)
    local team = self._Control:GetTeam()
    -- 无实体直接不处理
    if team:GetEntityId(index) == 0 then return end
    self._LongClickTime = self._LongClickTime + time / 1000
    if self._LongClickTime > 1 then
        self.ImgRoleRepace.gameObject:SetActiveEx(true)
        self.ImgRoleRepace.transform.localPosition = self:GetClickPosition()
    end
end

function XUiTaikoMasterBattleRoom:SwitchCharPos(index)
    if XTool.UObjIsNil(self.ImgRoleRepace) then
        return
    end
    -- 未激活不处理
    if not self.ImgRoleRepace.gameObject.activeSelf then return end
    self._LongClickTime = 0
    self.ImgRoleRepace.gameObject:SetActiveEx(false)
    local positionNum = self._Control:GetStagePositionNum(self._StageId)
    local transformWidth = self.Transform.rect.width
    local targetX = math.floor(self:GetClickPosition().x + transformWidth / 2)
    local targetIndex
    if targetX <= transformWidth / 4 then
        targetIndex = 1
    elseif targetX > transformWidth / 4 and targetX <= transformWidth / 4 * 2 then
        targetIndex = 2
    elseif targetX > transformWidth / 4 * 2 and targetX <= transformWidth / 4 * 3 then
        targetIndex = 3
    else
        targetIndex = 4
    end
    -- 相同直接不处理
    if index == targetIndex then return end
    -- 超出关卡限定的不处理
    if targetIndex > positionNum then
        XUiManager.TipErrorWithKey("TaikoMasterFightTeamCountTip", positionNum)
        return
    end
    
    self._Control:SwitchTeamPos(index, targetIndex)
    -- 刷新角色信息
    self._TeamGridList[index]:Refresh()
    self._TeamGridList[targetIndex]:Refresh()
end

function XUiTaikoMasterBattleRoom:GetClickPosition()
    return XUiHelper.GetScreenClickPosition(self.ImgRoleRepace.transform.parent, self._Camera)
end
--endregion

--region Scene - Effect
function XUiTaikoMasterBattleRoom:InitSceneEffect()
    if XTool.UObjIsNil(self.UiModelGo) then
        return
    end
    ---@type UnityEngine.Transform
    self.ImgEffectHuanren = self.UiModelGo.transform:FindTransform("ImgEffectHuanren")
    ---@type UnityEngine.Transform
    self.ImgEffectHuanren1 = self.UiModelGo.transform:FindTransform("ImgEffectHuanren1")
    self:_PlayEffect(self.ImgEffectHuanren, false)
    self:_PlayEffect(self.ImgEffectHuanren1, false)
end

function XUiTaikoMasterBattleRoom:RefreshEffect(pos)

end

function XUiTaikoMasterBattleRoom:_PlayEffect(effect, active)
    if XTool.UObjIsNil(effect) then
        return
    end
    effect.gameObject:SetActiveEx(active)
end
--endregion

--region Ui - BtnListener
function XUiTaikoMasterBattleRoom:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.BtnEnterFight, self.OnBtnEnterFightClick)
end

function XUiTaikoMasterBattleRoom:OnBtnBackClick()
    self:Close()
end

function XUiTaikoMasterBattleRoom:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiTaikoMasterBattleRoom:OnBtnEnterFightClick()
    local team = self._Control:GetTeam()
    local positionNum = self._Control:GetStagePositionNum(self._StageId)
    if team:GetEntityCount() ~= positionNum then
        XUiManager.TipErrorWithKey("TaikoMasterFightTeamCountTip", positionNum)
        return
    end
    if not XTool.IsNumberValid(team:GetEntityId(team:GetFirstFightPos())) then
        XUiManager.TipErrorWithKey("TeamManagerCheckFirstFightNil")
        return
    end
    ---@type XFubenAgency
    local fubenAgency = XMVCA:GetAgency(ModuleId.XFuben)
    fubenAgency:EnterFightByStageId(self._StageId, nil, false, 1, nil)
    XLuaUiManager.Remove(self.Name)
end
--endregion

return XUiTaikoMasterBattleRoom