--====================
--
--====================
local XUiSSBPickGridPickEnemy = XClass(nil, "XUiSSBPickGridPickEnemy")
--==============
--控件面板状态字典
--==============
local PanelStatusDic
local LONG_TIMER = 1

function XUiSSBPickGridPickEnemy:Ctor(grid, pos, rootPanel, teamData, grids)
    self.RootPanel = rootPanel --XUiSSBPickPanelPick
    self.Mode = self.RootPanel.Mode
    self.TeamData = teamData
    self.Pos = pos
    self.Grids = grids
    self.LongClickTime = 0
    self.RootUi = self.RootPanel.RootUi
    self.Camera = self.RootUi.Transform:GetComponent("Canvas").worldCamera
    XTool.InitUiObjectByUi(self, grid)
    self:InitStatusDic()
    self:InitColorPanel()
    self:InitBuffPanel()
    self:InitClickEvents()
    self.Color:ShowColor(nil)
end
--==============
--初始化面板状态字典
--==============
function XUiSSBPickGridPickEnemy:InitStatusDic()
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
function XUiSSBPickGridPickEnemy:InitColorPanel()
    local script = require("XUi/XUiSuperSmashBros/Common/XUiSSBPanelColor")
    self.Color = script.New(self.PanelColor)
    --self.RoleColor = script.New(self.PanelRoleColor)
end
--==============
--初始化增益面板
--==============
function XUiSSBPickGridPickEnemy:InitBuffPanel()
    local script = require("XUi/XUiSuperSmashBros/Common/XUiSSBPanelMonsterBuffs")
    self.Buff = script.New(self.PanelBuff)
end
--==============
--初始化点击事件
--==============
function XUiSSBPickGridPickEnemy:InitClickEvents()
    XUiHelper.RegisterClickEvent(self, self.RImgWaitSelectClick, function() self:OnClickWaitSelect() end)
    XUiHelper.RegisterClickEvent(self, self.RImgRole, function() self:OnClickRole() end)
    XUiHelper.RegisterClickEvent(self, self.RImgRoleRandom, function() self:OnClickRoleRandom() end)
    XUiHelper.RegisterClickEvent(self, self.ImgBanClick, function() self:OnClickBan() end)
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
function XUiSSBPickGridPickEnemy:OnDrag(eventData)
    self.ImgRoleRepace.transform.localPosition = XUiHelper.GetScreenClickPosition(self.RootUi.Transform, self.Camera)
end
--==============
-- 开始长按
--==============
function XUiSSBPickGridPickEnemy:OnBeginDrag(eventData)
    if not self:CheckDragEnable() then
        return
    end
    self.ImgRoleRepace.gameObject:SetActiveEx(true)
    self.ImgRoleRepace.transform.localPosition = XUiHelper.GetScreenClickPosition(self.RootUi.Transform, self.Camera)
end
--==============
-- 结束长按
--==============
function XUiSSBPickGridPickEnemy:OnEndDrag(eventData)
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
--刷新
--==============
function XUiSSBPickGridPickEnemy:Refresh(monsterGroupId)
    self:SetFirst(false)
    if monsterGroupId == XSuperSmashBrosConfig.PosState.Random then
        self:SetRandom()
    elseif monsterGroupId == XSuperSmashBrosConfig.PosState.OnlyRandom then
        self:SetOnlyRandom()
    elseif monsterGroupId == XSuperSmashBrosConfig.PosState.Empty then
        self:SetWaitSelect()
    elseif monsterGroupId == XSuperSmashBrosConfig.PosState.Ban then
        self:SetBan()
    else
        self:SetSelected(XDataCenter.SuperSmashBrosManager.GetMonsterGroupById(monsterGroupId))
    end
    self.ImgBanClick.gameObject:SetActiveEx(self.Status == XSuperSmashBrosConfig.RoleGridStatus.Ban)
end
--==============
--设置状态为已选角色
--@params
--monster: 选中的怪物对象
--==============
function XUiSSBPickGridPickEnemy:SetSelected(monsterGroup)
    if not monsterGroup then return end
    self.Status = XSuperSmashBrosConfig.RoleGridStatus.Selected
    self:SetPanelActive()
    local same = self.MonsterGroup == monsterGroup
    self.MonsterGroup = monsterGroup
    self:SetFirst(not monsterGroup:CheckIsClear())
    if self.RoleEnable and not same then
        self:SetBuff()
        self.TxtAbility.text = XUiHelper.GetText("SSBBattleAbility", self.MonsterGroup:GetAbility())
        self.RImgRole.gameObject:SetActiveEx(true)
        self.RImgRoleRandom.gameObject:SetActiveEx(false)
        self.RImgRole:SetRawImage(self.MonsterGroup:GetHalfBodyIcon())
        self.RoleEnable:Play()
    end
end

function XUiSSBPickGridPickEnemy:SetBuff()
    local buffList = self.MonsterGroup:GetBuffList()
    self.Buff:SetBuff(buffList)
    self.Buff:ShowPanel()
end
--==============
--设置状态为等待选人
--==============
function XUiSSBPickGridPickEnemy:SetWaitSelect()
    self.Status = XSuperSmashBrosConfig.RoleGridStatus.WaitSelect
    self:SetPanelActive()
end
--==============
--设置状态为禁用
--==============
function XUiSSBPickGridPickEnemy:SetBan()
    self.Status = XSuperSmashBrosConfig.RoleGridStatus.Ban
    self:SetPanelActive()
end
--==============
--设置颜色
--==============
function XUiSSBPickGridPickEnemy:SetColor(color)
    self.Color:ShowColor(color)
    --self.RoleColor:ShowColor(color)
end
--==============
--设置控件显示状态
--==============
function XUiSSBPickGridPickEnemy:SetPanelActive()
    if not PanelStatusDic then self:InitStatusDic() end
    for key, panelName in pairs(PanelStatusDic) do
        local panel = self[panelName]
        if panel then
            panel.gameObject:SetActiveEx(key == self.Status)
        end
    end
end
--==============
--设置首发标记显示
--==============
function XUiSSBPickGridPickEnemy:SetFirst(value)
    self.PanelFirst.gameObject:SetActiveEx(value)
end
--==============
--设置是否是固定随机位置
--==============
function XUiSSBPickGridPickEnemy:SetOnlyRandom()
    self.OnlyRandom = true
    self:SetRandom()
end
--==============
--设置是否是固定位置
--==============
function XUiSSBPickGridPickEnemy:SetLock()
    self.Lock = true
end
--==============
--设置为随机状态
--==============
function XUiSSBPickGridPickEnemy:SetRandom()
    self.RImgRole.gameObject:SetActiveEx(false)
    self.RImgRoleRandom.gameObject:SetActiveEx(true)
    self.PanelBuff.gameObject:SetActiveEx(false)
    self.Status = XSuperSmashBrosConfig.RoleGridStatus.Selected
    self:SetPanelActive()
    self.TxtAbility.text = ""
    self.MonsterGroup = nil
    self.Random = true
end

function XUiSSBPickGridPickEnemy:CheckDragEnable()
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
--交换怪物队伍的角色位置
--================
function XUiSSBPickGridPickEnemy:SwapTeamPos(selectPos, targetPos)
    local tempId = self.TeamData[targetPos]
    self.TeamData[targetPos] = self.TeamData[selectPos]
    self.TeamData[selectPos] = tempId

    self.RootPanel:Refresh()
end

--==============
--点击选择角色
--==============
function XUiSSBPickGridPickEnemy:OnClickWaitSelect()
    self.RootPanel:SwitchToSelect(self.Pos, XSuperSmashBrosConfig.RoleType.Monster)
end

function XUiSSBPickGridPickEnemy:OnClickRole()
    if self.Lock then
        XUiManager.TipText("SSBLockPos")
        return
    end
    self.RootPanel:SwitchToSelect(self.Pos, XSuperSmashBrosConfig.RoleType.Monster)
end

function XUiSSBPickGridPickEnemy:OnClickRoleRandom()
    if self.OnlyRandom then
        XUiManager.TipText("SSBOnlyRandom")
        return
    end
    self.RootPanel:SwitchToSelect(self.Pos, XSuperSmashBrosConfig.RoleType.Monster)
end

function XUiSSBPickGridPickEnemy:OnClickBan()
    XUiManager.TipText("SSBSelectBan")
end

function XUiSSBPickGridPickEnemy:PlayEnableAnim()
    if self.GridPickEnemyEnable then
        self.GridPickEnemyEnable:Play()
    end
end

return XUiSSBPickGridPickEnemy