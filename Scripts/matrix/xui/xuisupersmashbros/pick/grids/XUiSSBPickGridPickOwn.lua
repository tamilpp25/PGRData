--==============
--我方角色选人控件
--==============
local XUiSSBPickGridPickOwn = XClass(nil, "XUiSSBPickGridPickOwn")
--==============
--控件面板状态字典
--==============
local PanelStatusDic
local LONG_TIMER = 1

function XUiSSBPickGridPickOwn:Ctor(grid, pos, rootPanel, grids, hideTextOrder)
    self.RootPanel = rootPanel --XUiSSBPickPanelPick
    self.Pos = pos
    self.Mode = self.RootPanel.Mode
    self.Grids = grids
    XTool.InitUiObjectByUi(self, grid)
    self.LongClickTime = 0
    self.RootUi = self.RootPanel.RootUi
    self.Camera = self.RootUi.Transform:GetComponent("Canvas").worldCamera

    self:InitStatusDic()
    self:InitColorPanel()
    self:InitClickEvents()
    if hideTextOrder then
        self.TxtPlayOrder.gameObject:SetActiveEx(false)
    else
        self.TxtPlayOrder.gameObject:SetActiveEx(true)
        self.TxtPlayOrder.text = "P" .. self.Pos
    end
end
--==============
--初始化面板状态字典
--==============
function XUiSSBPickGridPickOwn:InitStatusDic()
    if PanelStatusDic then return end
    PanelStatusDic = {}
    local status = XSuperSmashBrosConfig.RoleGridStatus
    for key, value in pairs(status) do
        PanelStatusDic[key] = "Panel" .. value
    end
end
--==============
--初始化颜色面板
--==============
function XUiSSBPickGridPickOwn:InitColorPanel()
    local script = require("XUi/XUiSuperSmashBros/Common/XUiSSBPanelColor")
    self.Color = script.New(self.PanelColor)
    self.RoleColor = script.New(self.PanelRoleColor)
end
--==============
--初始化点击事件
--==============
function XUiSSBPickGridPickOwn:InitClickEvents()
    XUiHelper.RegisterClickEvent(self, self.RImgWaitSelectClick, function() self:OnClickRole() end)
    XUiHelper.RegisterClickEvent(self, self.RImgRole, function() self:OnClickRole() end)
    XUiHelper.RegisterClickEvent(self, self.RImgRoleRandom, function() self:OnClickRole() end)
    XUiHelper.RegisterClickEvent(self, self.ImgBanClick, function() self:OnClickBan() end)
    XUiHelper.RegisterClickEvent(self, self.PanelCoreIn, function() self:OnClickCore() end)
    XUiHelper.RegisterClickEvent(self, self.PanelCoreOut, function() self:OnClickCore() end)
    
    -- 长按拖拽相关 cxldV2
    self.UiWidgetRImgRole = self.RImgRole.gameObject:GetComponent(typeof(CS.XUiWidget))
    self.UiWidgetRImgRole:AddBeginDragListener(function(eventData)
        self:OnBeginDrag(eventData)
    end)

    self.UiWidgetRImgRole:AddEndDragListener(function(eventData)
        self:OnEndDrag(eventData)
    end)

    self.UiWidgetRImgRole:AddDragListener(function (eventData)
        self:OnDrag(eventData)
    end)
end
--==============
-- 长按中
--==============
function XUiSSBPickGridPickOwn:OnDrag(eventData)
    self.ImgRoleRepace.transform.localPosition = XUiHelper.GetScreenClickPosition(self.RootUi.Transform, self.Camera)
end
--==============
-- 开始长按
--==============
function XUiSSBPickGridPickOwn:OnBeginDrag(eventData)
    if not self:CheckDragEnable() then
        return
    end
    self.ImgRoleRepace.gameObject:SetActiveEx(true)
    self.ImgRoleRepace.transform.localPosition = XUiHelper.GetScreenClickPosition(self.RootUi.Transform, self.Camera)
end
--==============
-- 结束长按
--==============
function XUiSSBPickGridPickOwn:OnEndDrag(eventData)
    -- 未激活不处理
    if not self.ImgRoleRepace.gameObject.activeSelf then return end
    self.ImgRoleRepace.gameObject:SetActiveEx(false)

    local targetIndex = 0
    for index, grid in pairs(self.Grids) do
        local isInRest = CS.UnityEngine.RectTransformUtility.RectangleContainsScreenPoint(grid.Transform:GetComponent("RectTransform"), eventData.position, eventData.pressEventCamera)
        if isInRest then
            targetIndex = index
            break
        end
    end
    if targetIndex == self.Pos or targetIndex == 0 then
        return
    end
    self:SwapTeamPos(self.Pos, targetIndex)
end
--==============
--设置状态为已选人
--@params
--xRole: 选中角色对象
--==============
function XUiSSBPickGridPickOwn:SetSelected(role, teamData)
    if not role then return end
    self.Status = XSuperSmashBrosConfig.RoleGridStatus.Selected
    self:SetPanelActive()
    local same = self.Role == role
    self.Role = role
    self.TxtAbility.text = XUiHelper.GetText("SSBBattleAbility", self.Role:GetAbility())
    if teamData.Assistance[self.Pos] then
        self.PanelCoreIn.gameObject:SetActiveEx(false)
        self.PanelCoreOut.gameObject:SetActiveEx(false)
    else
        local core = self.Role:GetCore()
        self.PanelCoreIn.gameObject:SetActiveEx(core ~= nil)
        self.PanelCoreOut.gameObject:SetActiveEx(core == nil)
        if core then self.RImgCoreIcon:SetRawImage(core:GetIcon()) end
    end
    if self.RoleEnable and not same then
        self.RImgRoleRandom.gameObject:SetActiveEx(false)
        self.RImgRole.gameObject:SetActiveEx(true)
        self.RImgRole:SetRawImage(self.Role:GetHalfBodyCommonIcon())
        self.RoleEnable:Play()
    end
end
--==============
--设置状态为等待选人
--==============
function XUiSSBPickGridPickOwn:SetWaitSelect()
    self.Status = XSuperSmashBrosConfig.RoleGridStatus.WaitSelect
    self.Role = nil
    self:SetPanelActive()
end
--==============
--设置状态为禁用
--==============
function XUiSSBPickGridPickOwn:SetBan()
    self.Status = XSuperSmashBrosConfig.RoleGridStatus.Ban
    self:SetPanelActive()
    self.Color:HidePanel()
end
--==============
--设置状态为禁止编辑
--==============
function XUiSSBPickGridPickOwn:SetLock(flag)
    self.Lock = flag
end
--==============
--设置状态为强制随机 (Refresh之前调用)
--==============
function XUiSSBPickGridPickOwn:SetOnlyRandom(flag)
    self.Unknown = flag
    self:SetLock(flag)
end
--==============
--设置颜色
--==============
function XUiSSBPickGridPickOwn:SetColor(color)
    self.Color:ShowColor(color)
    self.RoleColor:ShowColor(color)
end
--==============
--设置随机
--==============
function XUiSSBPickGridPickOwn:SetRandom()
    self.Status = XSuperSmashBrosConfig.RoleGridStatus.Selected
    self:SetPanelActive()
    self.Color:ShowColor()
    self.RImgRoleRandom.gameObject:SetActiveEx(true)
    self.RImgRole.gameObject:SetActiveEx(false)
    self.Role = nil
    self.TxtAbility.text = ""
    self.PanelCoreIn.gameObject:SetActiveEx(false)
    self.PanelCoreOut.gameObject:SetActiveEx(false)
end
--==============
--设置控件显示状态
--==============
function XUiSSBPickGridPickOwn:SetPanelActive()
    if not PanelStatusDic then self:InitStatusDic() end
    for key, panelName in pairs(PanelStatusDic) do
        local panel = self[panelName]
        if panel then
            panel.gameObject:SetActiveEx(key == self.Status)
        end
    end
end

function XUiSSBPickGridPickOwn:Refresh(teamData)
    self:SetColor(XSuperSmashBrosConfig.ColorTypeIndex[teamData.Color[self.Pos]])
    local roleId = teamData.RoleIds[self.Pos]
    if roleId == XSuperSmashBrosConfig.PosState.Random then
        self:SetRandom()
    elseif roleId == XSuperSmashBrosConfig.PosState.Empty then
        self:SetWaitSelect()
    elseif roleId == XSuperSmashBrosConfig.PosState.OnlyRandom then
        self:SetRandom()
    elseif roleId == XSuperSmashBrosConfig.PosState.Ban then
        self:SetBan()
    else
        self:SetSelected(XDataCenter.SuperSmashBrosManager.GetRoleById(roleId), teamData)
    end
end

function XUiSSBPickGridPickOwn:CheckDragEnable()
    -- 空的或随机不能拖拽
    if self.Status == XSuperSmashBrosConfig.RoleGridStatus.Ban or self.Status == XSuperSmashBrosConfig.RoleGridStatus.WaitSelect then
        return false
    end   
    -- 线性模式不能拖拽
    if self.Mode:GetIsLinearStage() then
        return false
    end
    -- 强随机模式不能拖拽
    if self.Mode:GetRoleRandomStartIndex() then
        return false
    end

    return true
end
--================
--交换队伍中的角色位置
--================
function XUiSSBPickGridPickOwn:SwapTeamPos(selectPos, targetPos)
    local teamData = XDataCenter.SuperSmashBrosManager.GetDefaultTeamInfoByModeId(self.Mode:GetId())
    local teamIds = teamData.RoleIds
    local teamRoleId = teamIds[targetPos]
    teamIds[targetPos] = teamIds[selectPos]
    teamIds[selectPos] = teamRoleId
    XDataCenter.SuperSmashBrosManager.SaveDefaultTeamByModeId(self.Mode:GetId())
    self.RootPanel:Refresh()
end

function XUiSSBPickGridPickOwn:OnClickWaitSelect()
    self.RootPanel:SwitchToSelect(self.Pos, XSuperSmashBrosConfig.RoleType.Chara)
end

function XUiSSBPickGridPickOwn:OnClickRole()
    if self.Lock then
        XUiManager.TipText("SSBLockPos")
        return
    end
    -- 支援角色
    local teamData = XDataCenter.SuperSmashBrosManager.GetDefaultTeamInfoByModeId(self.Mode:GetId())
    if teamData.Assistance[self.Pos] then
        XLuaUiManager.Open("UiSuperSmashBrosRoleSelection", teamData.RoleIds[self.Pos], function(roleSelected)
            local roleId = roleSelected and roleSelected:GetId() or XSuperSmashBrosConfig.PosState.Empty
            if roleId == teamData.RoleIds[self.Pos] then
                self.RootPanel.RootUi:SwitchPage(XSuperSmashBrosConfig.PickPage.Pick)
                return
            end
            XDataCenter.SuperSmashBrosManager.SetTeamAssistanceMember(self.Mode, roleId, self.Pos)
            self.RootPanel.RootUi:SwitchPage(XSuperSmashBrosConfig.PickPage.Pick)
        end)
        return
    end
    self.RootPanel:SwitchToSelect(self.Pos, XSuperSmashBrosConfig.RoleType.Chara)
end

function XUiSSBPickGridPickOwn:OnClickRoleRandom()
    self.RootPanel:SwitchToSelect(self.Pos, XSuperSmashBrosConfig.RoleType.Chara)
end

function XUiSSBPickGridPickOwn:OnClickBan()
    XUiManager.TipText("SSBSelectBan")
end

function XUiSSBPickGridPickOwn:PlayEnableAnim()
    if self.GridPickOwnEnable then
        self.GridPickOwnEnable:Play()
    end
end

function XUiSSBPickGridPickOwn:OnClickCore()
    XLuaUiManager.Open("UiSuperSmashBrosCharacter", XDataCenter.SuperSmashBrosManager.GetDefaultTeamInfoByModeId(self.Mode:GetId()).RoleIds, true)
end

return XUiSSBPickGridPickOwn