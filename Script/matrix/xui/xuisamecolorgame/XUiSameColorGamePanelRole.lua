--######################## XUiRoleGrid ########################
local XUiRoleGrid = XClass(nil, "XUiRoleGrid")

function XUiRoleGrid:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.RootUi = rootUi
    -- XSCRole
    self.Role = nil
    self.BtnSelf.CallBack = function() self:OnBtnSelfClicked() end
end

-- role : XSCRole
-- boss : XSCBoss
function XUiRoleGrid:SetData(role, boss)
    self.Role = role
    self.RImgIcon:SetRawImage(role:GetCharacterViewModel():GetSmallHeadIcon())
    -- 推荐标签
    self.PanelRecommend.gameObject:SetActiveEx(boss:CheckRoleIdIsSuggest(role:GetId()))
    -- 是否锁住
    self.PanelLock.gameObject:SetActiveEx(role:GetIsLock())
    -- 是否可购买
    self.PanelPurchase.gameObject:SetActiveEx(role:GetCanBuy())
end

function XUiRoleGrid:OnBtnSelfClicked()
    self.RootUi:UpdateCurrentRole(self.Role)
end

function XUiRoleGrid:SetSelectStatusByRole(role)
    self.PanelSelect.gameObject:SetActiveEx(self.Role == role)
end

--######################## XUiBallGrid ########################
local XUiBallGrid = XClass(nil, "XUiBallGrid")

function XUiBallGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

-- XSCBall
function XUiBallGrid:SetData(ball)
    self.RImgIcon:SetRawImage(ball:GetIcon())
    self.RImgBg:SetRawImage(ball:GetBg())
    self.TxtFactor.text = math.floor(ball:GetScore()) .. "%"
end

--######################## XUiSameColorGamePanelRole ########################
local XUiSameColorGamePanelRole = XClass(nil, "XUiSameColorGamePanelRole")

function XUiSameColorGamePanelRole:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.RootUi = rootUi
    -- XSCRole
    self.Role = nil
    self.Roles = nil
    -- XSCBoss
    self.Boss = nil
    self.BallGrids = {}
    -- XSCRoleSkill
    self.MainSkill = nil
    self.GridRole.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.SViewCharacterList)
    self.DynamicTable:SetProxy(XUiRoleGrid, self)
    self.DynamicTable:SetDelegate(self)
    self:RegisterUiEvents()
end

-- role : XSCRole
-- boss : XSCBoss
function XUiSameColorGamePanelRole:SetData(role, boss)
    self:RefreshCurrentRole(role)
    self.Boss = boss or self.Boss
    self.Roles = XDataCenter.SameColorActivityManager.GetRoleManager():GetRoles()
    self:RefreshRoles()
end

function XUiSameColorGamePanelRole:RefreshCurrentRole(role)
    self.Role = role
    self.MainSkill = XTool.Clone(role:GetMainSkill())
    local characterViewModel = role:GetCharacterViewModel()
    self.TxtName.text = characterViewModel:GetLogName()
    self.TxtTradeName.text = XUiHelper.GetText("SameColorGameRoleTip1", characterViewModel:GetTradeName())
    self:RefreshSkillInfo()
    self:RefreshDamageFactors()
end

function XUiSameColorGamePanelRole:RefreshSkillInfo()
    local mainSkill = self.MainSkill
    local isOn = mainSkill:GetIsOn()
    self.RImgSkillIcon:SetRawImage(mainSkill:GetIcon())
    self.TxtSkillName.text = mainSkill:GetName()
    self.TxtSkillCD.text = XUiHelper.GetText("SameColorGameRoleTip2", mainSkill:GetCD())
    self.TxtSkillDesc.text = mainSkill:GetDesc()
    self.TxtSkillDesc2.text = mainSkill:GetDesc()
    self.TxtPower.text = XUiHelper.GetText("SameColorGameRoleTip3", mainSkill:GetEnergyCost())
    self.TxtPower.gameObject:SetActiveEx(isOn)
    self.TxtSkillDesc.gameObject:SetActiveEx(isOn)
    self.TxtSkillDesc2.gameObject:SetActiveEx(not isOn)
    self.BtnChange.gameObject:SetActiveEx(isOn)
    self.BtnChange2.gameObject:SetActiveEx(not isOn)
    local hasOn = mainSkill:GetIsHasOnSkill()
    if not hasOn then
        self.BtnChange.gameObject:SetActiveEx(false)
        self.BtnChange2.gameObject:SetActiveEx(false)
    end
end

function XUiSameColorGamePanelRole:RefreshDamageFactors()
    local balls = self.Role:GetBalls()
    self.GridBall.gameObject:SetActiveEx(false)
    for _, ballGrid in ipairs(self.BallGrids) do
        ballGrid.GameObject:SetActiveEx(false)
    end
    local go, ballGrid
    for index, ball in ipairs(balls) do
        ballGrid = self.BallGrids[index]
        if ballGrid == nil then
            go = CS.UnityEngine.Object.Instantiate(self.GridBall, self.PanelBall)
            ballGrid = XUiBallGrid.New(go)
            self.BallGrids[index] = ballGrid
        end
        ballGrid:SetData(ball)
        ballGrid.GameObject:SetActiveEx(true)
    end
end

function XUiSameColorGamePanelRole:RefreshRoles()
    local index = table.indexof(self.Roles, self.Role)
    self.DynamicTable:SetDataSource(self.Roles)
    self.DynamicTable:ReloadDataSync(index)
end

function XUiSameColorGamePanelRole:OnDynamicTableEvent(event, index, grid)
    local entity = self.DynamicTable.DataSource[index]
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(self.Roles[index], self.Boss)
        grid:SetSelectStatusByRole(self.Role)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        for _, grid in pairs(self.DynamicTable:GetGrids()) do
            grid:SetSelectStatusByRole(self.Role)    
        end
    end
end

function XUiSameColorGamePanelRole:UpdateCurrentRole(role)
    self.AnimQieHuan:Play()
    self:RefreshCurrentRole(role)
    if self.RootUi:GetLastSelectableRole() == role then
        self.RootUi:SetIsSelected(true)
        -- self.RootUi:SetBtnReadyNormalText(XUiHelper.GetText("SameColorGameReadyTip1"))
    else
        self.RootUi:SetBtnReadyNormalText(XUiHelper.GetText("SameColorGameReadyTip3"))
    end
    self.RootUi:UpdateCurrentRole(role)
end

function XUiSameColorGamePanelRole:RegisterUiEvents()
    self.BtnBoss.CallBack = function() 
        self.RootUi:UpdateCurrentRole(self.RootUi:GetLastSelectableRole())
        self.RootUi:UpdateChildPanel(XSameColorGameConfigs.UiBossChildPanelType.Main) 
    end
    XUiHelper.RegisterClickEvent(self, self.BtnChange, self.OnBtnChangeClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnChange2, self.OnBtnChangeClicked)
end

function XUiSameColorGamePanelRole:OnBtnChangeClicked()
    self.MainSkill:ChangeSwitch()
    self:RefreshSkillInfo()
    self.AnimQieHuan2:Play()
end

return XUiSameColorGamePanelRole