--######################## XUiReformTeamUp ########################
local UiReformTeamMemberGrid = XClass(nil, "UiReformTeamMemberGrid")

function UiReformTeamMemberGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.Source = nil
end

function UiReformTeamMemberGrid:SetData(source, inTeam, isSelected)
    self.Source = source
    self.ImgInTeam.gameObject:SetActiveEx(inTeam)
    local characterViewModel = source:GetRobot():GetCharacterViewModel()
    -- 头像
    self.RImgHeadIcon:SetRawImage(source:GetSmallHeadIcon())
    -- 战力
    self.TxtFight.text = characterViewModel:GetAbility()
    -- 星级
    self.TxtLevel.text = source:GetStarLevel()
    -- 元素列表
    local elementList = characterViewModel:GetObtainElements()
    local rImg = nil
    for i = 1, 3 do
        rImg = self["RImgCharElement" .. i]
        if elementList[i] then
            rImg.gameObject:SetActiveEx(true)
            rImg:SetRawImage(XCharacterConfigs.GetCharElement(elementList[i]).Icon)
        else
            rImg.gameObject:SetActiveEx(false)
        end
    end
    -- 设置选中
    self:SetSelectStatus(isSelected)
end

function UiReformTeamMemberGrid:SetSelectStatus(value)
    self.PanelSelected.gameObject:SetActiveEx(value)
end

--######################## XUiReformTeamUp ########################
local XUiReformTeamUp = XLuaUiManager.Register(XLuaUi, "UiReformTeamUp")

function XUiReformTeamUp:OnAwake()
    self:RegisterUiEvents()
    self.Sources = nil
    self.SourceInTeamDic = nil
    self.CurrentTeamPos = nil
    self.CurrentSelectedSource = nil
    self.JoinCallback = nil
    self.CloseCallback = nil
    -- 成员列表
    self.GridCharacter.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.SViewCharacterList)
    self.DynamicTable:SetProxy(UiReformTeamMemberGrid)
    self.DynamicTable:SetDelegate(self)
    -- 模型初始化
    local panelRoleModel = self.UiModelGo.transform:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = self.UiModelGo.transform:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = self.UiModelGo.transform:FindTransform("ImgEffectHuanren1")
    self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
    self.UiPanelRoleModel = XUiPanelRoleModel.New(panelRoleModel, self.Name, nil, true)
    -- 资源
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem
    , XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    -- 自动关闭
    local endTime = XDataCenter.ReformActivityManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XDataCenter.ReformActivityManager.HandleActivityEndTime()
        end
    end)
end

function XUiReformTeamUp:OnStart(sources, sourceInTeamDic, pos, joinCallback, closeCallback)
    self.Sources = sources
    self.SourceInTeamDic = sourceInTeamDic
    self.CurrentTeamPos = pos
    self.CurrentSelectedSource = sourceInTeamDic[pos]
    self.JoinCallback = joinCallback
    self.CloseCallback = closeCallback
    local isInTeam = true
    if self.CurrentSelectedSource == nil then
        for _, source in pairs(sourceInTeamDic) do
            if source then 
                self.CurrentSelectedSource = source 
                break
            end
        end
    end
    if self.CurrentSelectedSource == nil then
        self.CurrentSelectedSource = sources[1]
        isInTeam = false
    end
    self.BtnJoinTeam.gameObject:SetActiveEx(not isInTeam)
    self.BtnQuitTeam.gameObject:SetActiveEx(isInTeam)
    -- 刷新可选择列表
    self:RefreshDynamicTable()
    self:RefreshModel()
end

--######################## 私有方法 ########################

function XUiReformTeamUp:RegisterUiEvents()
    self.BtnBack.CallBack = function() self:OnBtnBackClicked() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnJoinTeam.CallBack = function() self:OnBtnJoinTeamClicked() end
    self.BtnQuitTeam.CallBack = function() self:OnBtnQuitTeamClicked() end
end

function XUiReformTeamUp:OnBtnBackClicked()
    if self.CloseCallback then
        self.CloseCallback()
    end
    self:Close()
end

function XUiReformTeamUp:OnBtnJoinTeamClicked()
    if self.JoinCallback then
        self.JoinCallback(self.CurrentSelectedSource, true)
    end
    self:Close()
end

function XUiReformTeamUp:OnBtnQuitTeamClicked()
    if self.JoinCallback then
        self.JoinCallback(self.CurrentSelectedSource, false)
    end
    self:Close()
end

function XUiReformTeamUp:RefreshDynamicTable()
    self.DynamicTable:SetDataSource(self.Sources)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiReformTeamUp:OnDynamicTableEvent(event, index, grid)
    local source = self.Sources[index]
    local isInTeam = self:GetSourceIsInTeam(source)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(source, isInTeam, source == self.CurrentSelectedSource)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.CurrentSelectedSource = source
        self:RefreshDynamicTable()
        self.BtnJoinTeam.gameObject:SetActiveEx(not isInTeam)
        self.BtnQuitTeam.gameObject:SetActiveEx(isInTeam)
        self:RefreshModel()
    end
end

function XUiReformTeamUp:GetSourceIsInTeam(source)
    for _, data in pairs(self.SourceInTeamDic) do
        if data == source then
            return true
        end
    end
    return false
end

function XUiReformTeamUp:RefreshModel()
    local robotId = self.CurrentSelectedSource:GetRobotId()
    local robotCfg = XRobotManager.GetRobotTemplate(robotId)
    local characterId = XRobotManager.GetCharacterId(robotId)
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.UiPanelRoleModel:UpdateRobotModel(robotId, characterId, nil
    , robotCfg.FashionId, robotCfg.WeaponId, function(model)
        self.PanelDrag.Target = model.transform
        self.ImgEffectHuanren.gameObject:SetActiveEx(true)
    end)
end

return XUiReformTeamUp